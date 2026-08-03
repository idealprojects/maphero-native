// Renderer for the "model3d" style layer. The glTF parsing and coordinate math are
// backend-neutral (baked on the CPU); only buffer upload + draw differ per backend:
//  - OpenGL ES (Android): port of the device-verified Doroob NDK renderer.
//  - Metal (iOS/macOS): metal-cpp port of the device-verified Doroob ObjC++ renderer.
//  - Vulkan: not implemented yet (renders nothing, logs once).

#include <mbgl/renderer/layers/model3d_host.hpp>
#include <mbgl/util/logging.hpp>

#define TINYGLTF_IMPLEMENTATION
#define TINYGLTF_NO_STB_IMAGE
#define TINYGLTF_NO_STB_IMAGE_WRITE
#define TINYGLTF_NO_EXTERNAL_IMAGE
// Vendored header; keep the core's -Werror out of it.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wshadow"
#pragma clang diagnostic ignored "-Wmissing-field-initializers"
#include <tiny_gltf.h>
#pragma clang diagnostic pop

#include <cmath>
#include <cstring>
#include <string>
#include <vector>

#if MH_RENDER_BACKEND_OPENGL
#include <GLES2/gl2.h>
#include <EGL/egl.h>
#elif MH_RENDER_BACKEND_METAL
#include <mbgl/style/layers/mtl/custom_layer_render_parameters.hpp>
#include <Foundation/Foundation.hpp>
#include <Metal/Metal.hpp>
#endif

namespace mbgl {

namespace {

constexpr double kPi = 3.14159265358979323846;
constexpr double kEarthRadiusMeters = 6378137.0;
constexpr double kTileSize = 512.0;
constexpr double kDefaultSizeMeters = 180.0;

// ---------------------------------------------------------------------------
// Backend-neutral matrix helpers (column-major, double precision)

void matrixMultiply(const double* a, const double* b, double* m) {
    double r[16];
    for (int col = 0; col < 4; col++) {
        for (int row = 0; row < 4; row++) {
            double sum = 0.0;
            for (int k = 0; k < 4; k++) {
                sum += a[k * 4 + row] * b[col * 4 + k];
            }
            r[col * 4 + row] = sum;
        }
    }
    std::memcpy(m, r, sizeof(r));
}

void matrixIdentity(double* m) {
    std::memset(m, 0, 16 * sizeof(double));
    m[0] = m[5] = m[10] = m[15] = 1.0;
}

void transformPoint(const double* m, const float* p, double* out) {
    for (int i = 0; i < 3; i++) {
        out[i] = m[0 + i] * p[0] + m[4 + i] * p[1] + m[8 + i] * p[2] + m[12 + i];
    }
}
void transformDir(const double* m, const float* d, double* out) {
    for (int i = 0; i < 3; i++) {
        out[i] = m[0 + i] * d[0] + m[4 + i] * d[1] + m[8 + i] * d[2];
    }
}

void nodeLocalMatrix(const tinygltf::Node& node, double* m) {
    if (node.matrix.size() == 16) {
        for (int i = 0; i < 16; i++) m[i] = node.matrix[i];
        return;
    }
    matrixIdentity(m);
    double t[16], r[16], s[16];
    matrixIdentity(t);
    if (node.translation.size() == 3) {
        t[12] = node.translation[0];
        t[13] = node.translation[1];
        t[14] = node.translation[2];
    }
    matrixIdentity(r);
    if (node.rotation.size() == 4) {
        const double x = node.rotation[0], y = node.rotation[1], z = node.rotation[2], w = node.rotation[3];
        r[0] = 1 - 2 * (y * y + z * z); r[1] = 2 * (x * y + z * w); r[2] = 2 * (x * z - y * w);
        r[4] = 2 * (x * y - z * w); r[5] = 1 - 2 * (x * x + z * z); r[6] = 2 * (y * z + x * w);
        r[8] = 2 * (x * z + y * w); r[9] = 2 * (y * z - x * w); r[10] = 1 - 2 * (x * x + y * y);
    }
    matrixIdentity(s);
    if (node.scale.size() == 3) {
        s[0] = node.scale[0];
        s[5] = node.scale[1];
        s[10] = node.scale[2];
    }
    matrixMultiply(t, r, m);
    matrixMultiply(m, s, m);
}

// ---------------------------------------------------------------------------
// Backend-neutral glTF baking: parse + bake node transforms into CPU buffers.

struct BakedPrim {
    std::vector<float> verts; // interleaved pos(3) + normal(3)
    std::vector<uint32_t> idx32;
    std::vector<uint16_t> idx16;
    bool wideIndices = false;
    float color[4] = {0.8f, 0.8f, 0.8f, 1.0f};
};

struct BakedModel {
    std::vector<BakedPrim> prims;
    // model-space fit parameters (post node-transform bake, Z-up convention)
    double centerX = 0, centerY = 0, minUp = 0, horizExtent = 1;
    bool ok = false;
};

const unsigned char* accessorData(
    const tinygltf::Model& model, int accessorIdx, size_t* stride, size_t* count, int* componentType) {
    const auto& acc = model.accessors[accessorIdx];
    const auto& bv = model.bufferViews[acc.bufferView];
    const auto& buf = model.buffers[bv.buffer];
    *count = acc.count;
    *componentType = acc.componentType;
    const size_t compSize = tinygltf::GetComponentSizeInBytes(acc.componentType);
    const size_t numComp = tinygltf::GetNumComponentsInType(acc.type);
    *stride = bv.byteStride ? bv.byteStride : compSize * numComp;
    return buf.data.data() + bv.byteOffset + acc.byteOffset;
}

void materialColor(const tinygltf::Model& model, int matIdx, float* out) {
    out[0] = 0.8f; out[1] = 0.8f; out[2] = 0.8f; out[3] = 1.0f;
    if (matIdx < 0 || matIdx >= static_cast<int>(model.materials.size())) return;
    const auto& mat = model.materials[matIdx];
    auto ext = mat.extensions.find("KHR_materials_pbrSpecularGlossiness");
    if (ext != mat.extensions.end() && ext->second.Has("diffuseFactor")) {
        const auto& df = ext->second.Get("diffuseFactor");
        for (int i = 0; i < 4 && i < static_cast<int>(df.ArrayLen()); i++) {
            const auto& v = df.Get(i);
            out[i] = static_cast<float>(v.IsNumber() ? v.GetNumberAsDouble() : 1.0);
        }
        return;
    }
    const auto& base = mat.pbrMetallicRoughness.baseColorFactor;
    for (int i = 0; i < 4 && i < static_cast<int>(base.size()); i++) {
        out[i] = static_cast<float>(base[i]);
    }
}

void bakeNode(const tinygltf::Model& gltf,
              int nodeIdx,
              const double* parent,
              BakedModel& out,
              double* bboxMin,
              double* bboxMax) {
    const auto& node = gltf.nodes[nodeIdx];
    double local[16], world[16];
    nodeLocalMatrix(node, local);
    matrixMultiply(parent, local, world);

    if (node.mesh >= 0) {
        for (const auto& prim : gltf.meshes[node.mesh].primitives) {
            if (prim.mode != TINYGLTF_MODE_TRIANGLES) continue;
            auto posIt = prim.attributes.find("POSITION");
            if (posIt == prim.attributes.end() || prim.indices < 0) continue;

            size_t posStride, posCount;
            int posType;
            const unsigned char* posData = accessorData(gltf, posIt->second, &posStride, &posCount, &posType);
            if (posType != TINYGLTF_COMPONENT_TYPE_FLOAT) continue;

            const unsigned char* normData = nullptr;
            size_t normStride = 0, normCount = 0;
            int normType = 0;
            auto normIt = prim.attributes.find("NORMAL");
            if (normIt != prim.attributes.end()) {
                normData = accessorData(gltf, normIt->second, &normStride, &normCount, &normType);
                if (normType != TINYGLTF_COMPONENT_TYPE_FLOAT) normData = nullptr;
            }

            BakedPrim bp;
            materialColor(gltf, prim.material, bp.color);
            bp.verts.resize(posCount * 6);
            for (size_t v = 0; v < posCount; v++) {
                const float* p = reinterpret_cast<const float*>(posData + v * posStride);
                double wp[3];
                transformPoint(world, p, wp);
                bp.verts[v * 6 + 0] = static_cast<float>(wp[0]);
                bp.verts[v * 6 + 1] = static_cast<float>(wp[1]);
                bp.verts[v * 6 + 2] = static_cast<float>(wp[2]);
                for (int k = 0; k < 3; k++) {
                    bboxMin[k] = std::min(bboxMin[k], wp[k]);
                    bboxMax[k] = std::max(bboxMax[k], wp[k]);
                }
                double wn[3] = {0, 1, 0};
                if (normData != nullptr && v < normCount) {
                    const float* n = reinterpret_cast<const float*>(normData + v * normStride);
                    transformDir(world, n, wn);
                    const double len = std::sqrt(wn[0] * wn[0] + wn[1] * wn[1] + wn[2] * wn[2]);
                    if (len > 1e-9) {
                        wn[0] /= len; wn[1] /= len; wn[2] /= len;
                    }
                }
                bp.verts[v * 6 + 3] = static_cast<float>(wn[0]);
                bp.verts[v * 6 + 4] = static_cast<float>(wn[1]);
                bp.verts[v * 6 + 5] = static_cast<float>(wn[2]);
            }

            size_t idxStride, idxCount;
            int idxType;
            const unsigned char* idxData = accessorData(gltf, prim.indices, &idxStride, &idxCount, &idxType);
            if (idxType == TINYGLTF_COMPONENT_TYPE_UNSIGNED_INT) {
                bp.wideIndices = true;
                bp.idx32.resize(idxCount);
                for (size_t k = 0; k < idxCount; k++) {
                    bp.idx32[k] = *reinterpret_cast<const uint32_t*>(idxData + k * idxStride);
                }
            } else {
                bp.wideIndices = false;
                bp.idx16.resize(idxCount);
                for (size_t k = 0; k < idxCount; k++) {
                    bp.idx16[k] = (idxType == TINYGLTF_COMPONENT_TYPE_UNSIGNED_SHORT)
                                      ? *reinterpret_cast<const uint16_t*>(idxData + k * idxStride)
                                      : *reinterpret_cast<const uint8_t*>(idxData + k * idxStride);
                }
            }
            out.prims.push_back(std::move(bp));
        }
    }

    for (int child : node.children) {
        bakeNode(gltf, child, world, out, bboxMin, bboxMax);
    }
}

BakedModel bakeModel(const std::string& path) {
    BakedModel out;
    tinygltf::Model gltf;
    tinygltf::TinyGLTF loader;
    std::string err, warn;
    if (!loader.LoadBinaryFromFile(&gltf, &err, &warn, path)) {
        Log::Error(Event::Style, "model3d: glb load failed " + path + ": " + err);
        return out;
    }
    if (!warn.empty()) {
        Log::Warning(Event::Style, "model3d: glb warn " + path + ": " + warn);
    }

    double bboxMin[3] = {1e30, 1e30, 1e30};
    double bboxMax[3] = {-1e30, -1e30, -1e30};
    double identity[16];
    matrixIdentity(identity);
    const int sceneIdx = gltf.defaultScene >= 0 ? gltf.defaultScene : 0;
    if (sceneIdx >= static_cast<int>(gltf.scenes.size())) return out;
    for (int nodeIdx : gltf.scenes[sceneIdx].nodes) {
        bakeNode(gltf, nodeIdx, identity, out, bboxMin, bboxMax);
    }
    if (out.prims.empty()) {
        Log::Error(Event::Style, "model3d: glb produced no primitives: " + path);
        return out;
    }
    out.centerX = (bboxMin[0] + bboxMax[0]) * 0.5;
    out.centerY = (bboxMin[1] + bboxMax[1]) * 0.5;
    out.minUp = bboxMin[2];
    out.horizExtent = std::max(bboxMax[0] - bboxMin[0], bboxMax[1] - bboxMin[1]);
    if (out.horizExtent < 1e-9) out.horizExtent = 1.0;
    out.ok = true;
    Log::Info(Event::Style,
              "model3d: baked " + path + " (" + std::to_string(out.prims.size()) + " prims)");
    return out;
}

// Per-model anchor/fit matrix ("A", model space -> world offset around the anchor),
// then m = projection * translate(anchor) * A. Identical math on both backends.
void computeModelMatrix(const style::Model3DEntry& entry,
                        const BakedModel& baked,
                        const std::array<double, 16>& projection,
                        double zoom,
                        double* outMatrix) {
    const double worldSize = kTileSize * std::pow(2.0, zoom);
    const double anchorX = (entry.longitude + 180.0) / 360.0 * worldSize;
    const double mercY = std::log(std::tan(kPi / 4.0 + entry.latitude * kPi / 360.0));
    const double anchorY = (0.5 - mercY / (2.0 * kPi)) * worldSize;
    const double ppm = worldSize / (2.0 * kPi * kEarthRadiusMeters * std::cos(entry.latitude * kPi / 180.0));

    const double sizeMeters = entry.sizeMeters > 0 ? entry.sizeMeters : kDefaultSizeMeters;
    const double s = sizeMeters / baked.horizExtent;

    const double h = entry.headingDegrees * kPi / 180.0;
    const double ch = std::cos(h), sh = std::sin(h);
    double a[16] = {0};
    // east' = ch*gx - sh*gy ; north' = sh*gx + ch*gy ; world_y = -north'
    a[0] = ppm * s * ch;
    a[1] = -ppm * s * sh;
    a[4] = -ppm * s * sh;
    a[5] = -ppm * s * ch;
    a[10] = s; // input gz (up): meters
    a[15] = 1.0;
    // recenter/ground offsets (applied in model space before the axis map)
    const double ox = -baked.centerX, oy = -baked.centerY, oup = -baked.minUp;
    a[12] = a[0] * ox + a[4] * oy;
    a[13] = a[1] * ox + a[5] * oy;
    a[14] = a[10] * oup;

    double translate[16];
    matrixIdentity(translate);
    translate[12] = anchorX;
    translate[13] = anchorY;

    matrixMultiply(projection.data(), translate, outMatrix);
    matrixMultiply(outMatrix, a, outMatrix);
}

} // namespace

// ===========================================================================
#if MH_RENDER_BACKEND_OPENGL
// OpenGL ES backend (Android)

namespace {

const char* kVertexShaderGL = R"GLSL(
    #version 100
    uniform mat4 u_matrix;
    attribute vec3 a_pos;
    attribute vec3 a_normal;
    varying float v_light;
    void main() {
        vec3 lightDir = normalize(vec3(0.4, 0.45, 0.8));
        v_light = 0.55 + 0.45 * abs(dot(normalize(a_normal), lightDir));
        gl_Position = u_matrix * vec4(a_pos, 1.0);
    }
)GLSL";

const char* kFragmentShaderGL = R"GLSL(
    #version 100
    precision mediump float;
    uniform vec4 u_color;
    varying float v_light;
    void main() {
        gl_FragColor = vec4(u_color.rgb * v_light, u_color.a);
    }
)GLSL";

GLuint compileShaderGL(GLenum type, const char* source) {
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);
    GLint ok = GL_FALSE;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
    if (ok != GL_TRUE) {
        char log[512];
        glGetShaderInfoLog(shader, sizeof(log), nullptr, log);
        Log::Error(Event::Style, std::string("model3d: shader compile failed: ") + log);
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}

using PfnBindVertexArray = void (*)(GLuint);
PfnBindVertexArray resolveBindVertexArray() {
    auto fn = reinterpret_cast<PfnBindVertexArray>(eglGetProcAddress("glBindVertexArray"));
    if (fn == nullptr) {
        fn = reinterpret_cast<PfnBindVertexArray>(eglGetProcAddress("glBindVertexArrayOES"));
    }
    return fn;
}

} // namespace

struct Model3DHost::BackendState {
    struct Prim {
        GLuint vbo = 0;
        GLuint ibo = 0;
        GLsizei indexCount = 0;
        GLenum indexType = GL_UNSIGNED_INT;
        float color[4] = {0.8f, 0.8f, 0.8f, 1.0f};
    };
    struct Model {
        std::vector<Prim> prims;
        double centerX = 0, centerY = 0, minUp = 0, horizExtent = 1;
        bool ok = false;
    };
    std::vector<Model> models;
    GLuint program = 0;
    GLint uMatrix = -1;
    GLint uColor = -1;
    GLint aPos = -1;
    GLint aNormal = -1;
    PfnBindVertexArray bindVertexArray = nullptr;

    void release(bool contextAlive) {
        if (contextAlive) {
            for (auto& m : models) {
                for (auto& p : m.prims) {
                    if (p.vbo) glDeleteBuffers(1, &p.vbo);
                    if (p.ibo) glDeleteBuffers(1, &p.ibo);
                }
            }
            if (program) glDeleteProgram(program);
        }
        models.clear();
        program = 0;
    }

    bool setup(const std::vector<style::Model3DEntry>& entries) {
        bindVertexArray = resolveBindVertexArray();
        if (bindVertexArray != nullptr) bindVertexArray(0);

        GLuint vs = compileShaderGL(GL_VERTEX_SHADER, kVertexShaderGL);
        GLuint fs = compileShaderGL(GL_FRAGMENT_SHADER, kFragmentShaderGL);
        if (vs == 0 || fs == 0) return false;
        program = glCreateProgram();
        glAttachShader(program, vs);
        glAttachShader(program, fs);
        glLinkProgram(program);
        glDeleteShader(vs);
        glDeleteShader(fs);
        GLint ok = GL_FALSE;
        glGetProgramiv(program, GL_LINK_STATUS, &ok);
        if (ok != GL_TRUE) {
            Log::Error(Event::Style, "model3d: program link failed");
            glDeleteProgram(program);
            program = 0;
            return false;
        }
        uMatrix = glGetUniformLocation(program, "u_matrix");
        uColor = glGetUniformLocation(program, "u_color");
        aPos = glGetAttribLocation(program, "a_pos");
        aNormal = glGetAttribLocation(program, "a_normal");

        models.resize(entries.size());
        for (size_t i = 0; i < entries.size(); i++) {
            BakedModel baked = bakeModel(entries[i].path);
            if (!baked.ok) continue;
            Model& m = models[i];
            m.centerX = baked.centerX;
            m.centerY = baked.centerY;
            m.minUp = baked.minUp;
            m.horizExtent = baked.horizExtent;
            for (const auto& bp : baked.prims) {
                Prim gp;
                std::memcpy(gp.color, bp.color, sizeof(gp.color));
                glGenBuffers(1, &gp.vbo);
                glBindBuffer(GL_ARRAY_BUFFER, gp.vbo);
                glBufferData(GL_ARRAY_BUFFER,
                             static_cast<GLsizeiptr>(bp.verts.size() * sizeof(float)),
                             bp.verts.data(),
                             GL_STATIC_DRAW);
                glGenBuffers(1, &gp.ibo);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gp.ibo);
                if (bp.wideIndices) {
                    gp.indexType = GL_UNSIGNED_INT;
                    gp.indexCount = static_cast<GLsizei>(bp.idx32.size());
                    glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                                 static_cast<GLsizeiptr>(bp.idx32.size() * 4),
                                 bp.idx32.data(),
                                 GL_STATIC_DRAW);
                } else {
                    gp.indexType = GL_UNSIGNED_SHORT;
                    gp.indexCount = static_cast<GLsizei>(bp.idx16.size());
                    glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                                 static_cast<GLsizeiptr>(bp.idx16.size() * 2),
                                 bp.idx16.data(),
                                 GL_STATIC_DRAW);
                }
                m.prims.push_back(gp);
            }
            m.ok = !m.prims.empty();
        }
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        return true;
    }

    void draw(const std::vector<style::Model3DEntry>& entries, const style::CustomLayerRenderParameters& params) {
        if (bindVertexArray != nullptr) bindVertexArray(0);

        glUseProgram(program);
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LEQUAL);
        glDepthMask(GL_TRUE);
        // Same trick as the map's own 3D pass (depthModeFor3D): remap our depth into a
        // window in front of the constant depth values the 2D layers write near the far
        // plane — otherwise at low zoom camera-facing walls lose the depth test.
        glDepthRangef(0.0f, 0.998f);
        glDisable(GL_STENCIL_TEST);
        glDisable(GL_CULL_FACE);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        for (size_t i = 0; i < entries.size() && i < models.size(); i++) {
            const Model& m = models[i];
            if (!m.ok) continue;

            BakedModel fit;
            fit.centerX = m.centerX;
            fit.centerY = m.centerY;
            fit.minUp = m.minUp;
            fit.horizExtent = m.horizExtent;

            double matrix[16];
            computeModelMatrix(entries[i], fit, params.projectionMatrix, params.zoom, matrix);

            GLfloat mf[16];
            for (int k = 0; k < 16; k++) mf[k] = static_cast<GLfloat>(matrix[k]);
            glUniformMatrix4fv(uMatrix, 1, GL_FALSE, mf);

            for (const Prim& prim : m.prims) {
                glUniform4fv(uColor, 1, prim.color);
                glBindBuffer(GL_ARRAY_BUFFER, prim.vbo);
                glEnableVertexAttribArray(static_cast<GLuint>(aPos));
                glEnableVertexAttribArray(static_cast<GLuint>(aNormal));
                glVertexAttribPointer(
                    static_cast<GLuint>(aPos), 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), reinterpret_cast<void*>(0));
                glVertexAttribPointer(static_cast<GLuint>(aNormal),
                                      3,
                                      GL_FLOAT,
                                      GL_FALSE,
                                      6 * sizeof(GLfloat),
                                      reinterpret_cast<void*>(3 * sizeof(GLfloat)));
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, prim.ibo);
                glDrawElements(GL_TRIANGLES, prim.indexCount, prim.indexType, nullptr);
            }
        }

        glDisableVertexAttribArray(static_cast<GLuint>(aPos));
        glDisableVertexAttribArray(static_cast<GLuint>(aNormal));
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
};

// ===========================================================================
#elif MH_RENDER_BACKEND_METAL
// Metal backend (iOS / macOS), via metal-cpp. Mirrors the verified ObjC++ renderer:
// pipeline bgra8Unorm + depth32Float_stencil8, cull off, blend on, and the
// glDepthRangef(0, 0.998) trick baked into the matrix clip-z row (Metal NDC z is
// [0, 1] in this fork's custom-layer parameters, which carry the raw projMatrix).

namespace {

const char* kShaderSourceMSL = R"MSL(
#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float4x4 matrix;
    float4 color;
};

struct Vtx {
    packed_float3 pos;
    packed_float3 normal;
};

struct VOut {
    float4 position [[position]];
    float light;
};

vertex VOut model3d_vertex(const device Vtx* verts [[buffer(0)]],
                           constant Uniforms& u [[buffer(1)]],
                           uint vid [[vertex_id]]) {
    Vtx v = verts[vid];
    float3 n = float3(v.normal);
    float len = length(n);
    n = len > 1e-9f ? n / len : float3(0.0, 1.0, 0.0);
    float3 lightDir = normalize(float3(0.4, 0.45, 0.8));
    VOut out;
    out.position = u.matrix * float4(float3(v.pos), 1.0);
    out.light = 0.55 + 0.45 * abs(dot(n, lightDir));
    return out;
}

fragment float4 model3d_fragment(VOut in [[stage_in]],
                                 constant Uniforms& u [[buffer(0)]]) {
    return float4(u.color.rgb * in.light, u.color.a);
}
)MSL";

struct UniformsMTL {
    float m[16];
    float color[4];
};

} // namespace

struct Model3DHost::BackendState {
    struct Prim {
        MTL::Buffer* vbo = nullptr;
        MTL::Buffer* ibo = nullptr;
        NS::UInteger indexCount = 0;
        MTL::IndexType indexType = MTL::IndexTypeUInt32;
        float color[4] = {0.8f, 0.8f, 0.8f, 1.0f};
    };
    struct Model {
        std::vector<Prim> prims;
        double centerX = 0, centerY = 0, minUp = 0, horizExtent = 1;
        bool ok = false;
    };
    std::vector<Model> models;
    MTL::RenderPipelineState* pipeline = nullptr;
    MTL::DepthStencilState* depthState = nullptr;

    void release(bool /*contextAlive*/) {
        for (auto& m : models) {
            for (auto& p : m.prims) {
                if (p.vbo) p.vbo->release();
                if (p.ibo) p.ibo->release();
            }
        }
        models.clear();
        if (pipeline) pipeline->release();
        pipeline = nullptr;
        if (depthState) depthState->release();
        depthState = nullptr;
    }

    bool setup(const std::vector<style::Model3DEntry>& entries, MTL::Device* device) {
        NS::Error* error = nullptr;
        NS::String* source = NS::String::alloc()->init(kShaderSourceMSL, NS::UTF8StringEncoding);
        MTL::Library* library = device->newLibrary(source, nullptr, &error);
        source->release();
        if (library == nullptr) {
            Log::Error(Event::Style, "model3d: MSL compile failed");
            return false;
        }
        NS::String* vName = NS::String::alloc()->init("model3d_vertex", NS::UTF8StringEncoding);
        NS::String* fName = NS::String::alloc()->init("model3d_fragment", NS::UTF8StringEncoding);
        MTL::Function* vertexFn = library->newFunction(vName);
        MTL::Function* fragmentFn = library->newFunction(fName);
        vName->release();
        fName->release();
        library->release();
        if (vertexFn == nullptr || fragmentFn == nullptr) {
            if (vertexFn) vertexFn->release();
            if (fragmentFn) fragmentFn->release();
            Log::Error(Event::Style, "model3d: MSL functions missing");
            return false;
        }

        MTL::RenderPipelineDescriptor* desc = MTL::RenderPipelineDescriptor::alloc()->init();
        desc->setVertexFunction(vertexFn);
        desc->setFragmentFunction(fragmentFn);
        auto* color0 = desc->colorAttachments()->object(0);
        color0->setPixelFormat(MTL::PixelFormatBGRA8Unorm);
        color0->setBlendingEnabled(true);
        color0->setSourceRGBBlendFactor(MTL::BlendFactorSourceAlpha);
        color0->setDestinationRGBBlendFactor(MTL::BlendFactorOneMinusSourceAlpha);
        color0->setSourceAlphaBlendFactor(MTL::BlendFactorSourceAlpha);
        color0->setDestinationAlphaBlendFactor(MTL::BlendFactorOneMinusSourceAlpha);
        desc->setDepthAttachmentPixelFormat(MTL::PixelFormatDepth32Float_Stencil8);
        desc->setStencilAttachmentPixelFormat(MTL::PixelFormatDepth32Float_Stencil8);

        pipeline = device->newRenderPipelineState(desc, &error);
        desc->release();
        vertexFn->release();
        fragmentFn->release();
        if (pipeline == nullptr) {
            Log::Error(Event::Style, "model3d: pipeline creation failed");
            return false;
        }

        MTL::DepthStencilDescriptor* depthDesc = MTL::DepthStencilDescriptor::alloc()->init();
        depthDesc->setDepthCompareFunction(MTL::CompareFunctionLessEqual);
        depthDesc->setDepthWriteEnabled(true);
        depthState = device->newDepthStencilState(depthDesc);
        depthDesc->release();

        models.resize(entries.size());
        for (size_t i = 0; i < entries.size(); i++) {
            BakedModel baked = bakeModel(entries[i].path);
            if (!baked.ok) continue;
            Model& m = models[i];
            m.centerX = baked.centerX;
            m.centerY = baked.centerY;
            m.minUp = baked.minUp;
            m.horizExtent = baked.horizExtent;
            for (const auto& bp : baked.prims) {
                Prim gp;
                std::memcpy(gp.color, bp.color, sizeof(gp.color));
                gp.vbo = device->newBuffer(
                    bp.verts.data(), bp.verts.size() * sizeof(float), MTL::ResourceStorageModeShared);
                if (bp.wideIndices) {
                    gp.indexType = MTL::IndexTypeUInt32;
                    gp.indexCount = bp.idx32.size();
                    gp.ibo = device->newBuffer(bp.idx32.data(), bp.idx32.size() * 4, MTL::ResourceStorageModeShared);
                } else {
                    gp.indexType = MTL::IndexTypeUInt16;
                    gp.indexCount = bp.idx16.size();
                    gp.ibo = device->newBuffer(bp.idx16.data(), bp.idx16.size() * 2, MTL::ResourceStorageModeShared);
                }
                if (gp.vbo && gp.ibo) {
                    m.prims.push_back(gp);
                } else {
                    if (gp.vbo) gp.vbo->release();
                    if (gp.ibo) gp.ibo->release();
                }
            }
            m.ok = !m.prims.empty();
        }
        return true;
    }

    void draw(const std::vector<style::Model3DEntry>& entries,
              const style::CustomLayerRenderParameters& params,
              MTL::RenderCommandEncoder* encoder) {
        encoder->setRenderPipelineState(pipeline);
        encoder->setDepthStencilState(depthState);
        encoder->setCullMode(MTL::CullModeNone);

        for (size_t i = 0; i < entries.size() && i < models.size(); i++) {
            const Model& m = models[i];
            if (!m.ok) continue;

            BakedModel fit;
            fit.centerX = m.centerX;
            fit.centerY = m.centerY;
            fit.minUp = m.minUp;
            fit.horizExtent = m.horizExtent;

            double matrix[16];
            computeModelMatrix(entries[i], fit, params.projectionMatrix, params.zoom, matrix);
            // Depth-window remap (see the GL branch's glDepthRangef(0, 0.998)) baked
            // into the clip-z row, leaving the encoder's viewport untouched.
            matrix[2] *= 0.998;
            matrix[6] *= 0.998;
            matrix[10] *= 0.998;
            matrix[14] *= 0.998;

            UniformsMTL uni;
            for (int k = 0; k < 16; k++) uni.m[k] = static_cast<float>(matrix[k]);

            for (const Prim& prim : m.prims) {
                std::memcpy(uni.color, prim.color, sizeof(uni.color));
                encoder->setVertexBuffer(prim.vbo, 0, 0);
                encoder->setVertexBytes(&uni, sizeof(uni), 1);
                encoder->setFragmentBytes(&uni, sizeof(uni), 0);
                encoder->drawIndexedPrimitives(MTL::PrimitiveTypeTriangle, prim.indexCount, prim.indexType, prim.ibo, 0);
            }
        }
    }
};

// ===========================================================================
#else
// Vulkan (or other) backend: not implemented yet.

struct Model3DHost::BackendState {
    void release(bool) {}
};

#endif

// ===========================================================================
// Host lifecycle (shared)

Model3DHost::Model3DHost(std::vector<style::Model3DEntry> entries)
    : entries_(std::move(entries)) {}

Model3DHost::~Model3DHost() = default;

void Model3DHost::initialize() {
    needSetup_ = true;
    setupAttempts_ = 0;
}

void Model3DHost::contextLost() {
    if (state_) {
        state_->release(false);
        state_.reset();
    }
    needSetup_ = true;
    setupAttempts_ = 0;
}

void Model3DHost::deinitialize() {
    if (state_) {
        state_->release(true);
        state_.reset();
    }
    needSetup_ = true;
}

void Model3DHost::render([[maybe_unused]] const style::CustomLayerRenderParameters& params) {
#if MH_RENDER_BACKEND_OPENGL
    if (needSetup_) {
        if (setupAttempts_ >= 3) return;
        setupAttempts_++;
        auto state = std::make_unique<BackendState>();
        if (!state->setup(entries_)) {
            state->release(true);
            return;
        }
        state_ = std::move(state);
        needSetup_ = false;
    }
    state_->draw(entries_, params);
#elif MH_RENDER_BACKEND_METAL
    auto* encoder =
        static_cast<const style::mtl::CustomLayerRenderParameters&>(params).encoder.get();
    if (encoder == nullptr) return;
    if (needSetup_) {
        if (setupAttempts_ >= 3) return;
        setupAttempts_++;
        auto state = std::make_unique<BackendState>();
        if (!state->setup(entries_, encoder->device())) {
            state->release(true);
            return;
        }
        state_ = std::move(state);
        needSetup_ = false;
    }
    state_->draw(entries_, params, encoder);
#else
    if (setupAttempts_ == 0) {
        setupAttempts_++;
        Log::Warning(Event::Style, "model3d: not implemented on this render backend");
    }
#endif
}

} // namespace mbgl
