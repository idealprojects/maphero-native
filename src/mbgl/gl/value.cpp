#include <mbgl/gl/value.hpp>
#include <mbgl/gl/context.hpp>
#include <mbgl/gl/vertex_buffer_resource.hpp>
#include <mbgl/gl/defines.hpp>
#include <mbgl/gl/enum.hpp>
#include <mbgl/util/instrumentation.hpp>

namespace mbgl {
namespace gl {
namespace value {

using namespace platform;

const constexpr ClearDepth::Type ClearDepth::Default;

void ClearDepth::Set(const Type& value) {
    MH_TRACE_ZONE(ClearDepth::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glClearDepthf(value));
}

ClearDepth::Type ClearDepth::Get() {
    MH_TRACE_ZONE(ClearDepth::Get);
    MH_TRACE_FUNC_GL();
    GLfloat clearDepth;
    MBGL_CHECK_ERROR(glGetFloatv(GL_DEPTH_CLEAR_VALUE, &clearDepth));
    return clearDepth;
}

const ClearColor::Type ClearColor::Default{0, 0, 0, 0};

void ClearColor::Set(const Type& value) {
    MH_TRACE_ZONE(ClearColor::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glClearColor(value.r, value.g, value.b, value.a));
}

ClearColor::Type ClearColor::Get() {
    MH_TRACE_ZONE(ClearColor::Get);
    MH_TRACE_FUNC_GL();
    GLfloat clearColor[4];
    MBGL_CHECK_ERROR(glGetFloatv(GL_COLOR_CLEAR_VALUE, clearColor));
    return {clearColor[0], clearColor[1], clearColor[2], clearColor[3]};
}

const constexpr ClearStencil::Type ClearStencil::Default;

void ClearStencil::Set(const Type& value) {
    MH_TRACE_ZONE(ClearStencil::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glClearStencil(value));
}

ClearStencil::Type ClearStencil::Get() {
    MH_TRACE_ZONE(ClearStencil::Get);
    MH_TRACE_FUNC_GL();
    GLint clearStencil;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_STENCIL_CLEAR_VALUE, &clearStencil));
    return clearStencil;
}

const constexpr StencilMask::Type StencilMask::Default;

void StencilMask::Set(const Type& value) {
    MH_TRACE_ZONE(StencilMask::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glStencilMask(value));
}

StencilMask::Type StencilMask::Get() {
    MH_TRACE_ZONE(StencilMask::Get);
    MH_TRACE_FUNC_GL();
    GLint stencilMask;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_STENCIL_WRITEMASK, &stencilMask));
    return stencilMask;
}

const constexpr DepthMask::Type DepthMask::Default;

void DepthMask::Set(const Type& value) {
    MH_TRACE_ZONE(DepthMask::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glDepthMask(Enum<gfx::DepthMaskType>::to(value)));
}

DepthMask::Type DepthMask::Get() {
    MH_TRACE_ZONE(DepthMask::Get);
    MH_TRACE_FUNC_GL();
    GLboolean depthMask;
    MBGL_CHECK_ERROR(glGetBooleanv(GL_DEPTH_WRITEMASK, &depthMask));
    return Enum<gfx::DepthMaskType>::from(depthMask);
}

const constexpr ColorMask::Type ColorMask::Default;

void ColorMask::Set(const Type& value) {
    MH_TRACE_ZONE(ColorMask::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glColorMask(value.r, value.g, value.b, value.a));
}

ColorMask::Type ColorMask::Get() {
    MH_TRACE_ZONE(ColorMask::Get);
    MH_TRACE_FUNC_GL();
    GLboolean bools[4];
    MBGL_CHECK_ERROR(glGetBooleanv(GL_COLOR_WRITEMASK, bools));
    return {static_cast<bool>(bools[0]),
            static_cast<bool>(bools[1]),
            static_cast<bool>(bools[2]),
            static_cast<bool>(bools[3])};
}

const constexpr StencilFunc::Type StencilFunc::Default;

void StencilFunc::Set(const Type& value) {
    MH_TRACE_ZONE(StencilFunc::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glStencilFunc(Enum<gfx::StencilFunctionType>::to(value.func), value.ref, value.mask));
}

StencilFunc::Type StencilFunc::Get() {
    MH_TRACE_ZONE(StencilFunc::Get);
    MH_TRACE_FUNC_GL();
    GLint func;
    GLint ref;
    GLint mask;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_STENCIL_FUNC, &func));
    MBGL_CHECK_ERROR(glGetIntegerv(GL_STENCIL_REF, &ref));
    MBGL_CHECK_ERROR(glGetIntegerv(GL_STENCIL_VALUE_MASK, &mask));
    return {Enum<gfx::StencilFunctionType>::from(func), ref, static_cast<uint32_t>(mask)};
}

const constexpr StencilTest::Type StencilTest::Default;

void StencilTest::Set(const Type& value) {
    MH_TRACE_ZONE(StencilTest::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(value ? glEnable(GL_STENCIL_TEST) : glDisable(GL_STENCIL_TEST));
}

StencilTest::Type StencilTest::Get() {
    MH_TRACE_ZONE(StencilTest::Get);
    MH_TRACE_FUNC_GL();
    Type stencilTest;
    MBGL_CHECK_ERROR(stencilTest = glIsEnabled(GL_STENCIL_TEST));
    return stencilTest;
}

const constexpr StencilOp::Type StencilOp::Default;

void StencilOp::Set(const Type& value) {
    MH_TRACE_ZONE(StencilOp::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glStencilOp(Enum<gfx::StencilOpType>::to(value.sfail),
                                 Enum<gfx::StencilOpType>::to(value.dpfail),
                                 Enum<gfx::StencilOpType>::to(value.dppass)));
}

StencilOp::Type StencilOp::Get() {
    MH_TRACE_ZONE(StencilOp::Get);
    MH_TRACE_FUNC_GL();
    GLint sfail;
    GLint dpfail;
    GLint dppass;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_STENCIL_FAIL, &sfail));
    MBGL_CHECK_ERROR(glGetIntegerv(GL_STENCIL_PASS_DEPTH_FAIL, &dpfail));
    MBGL_CHECK_ERROR(glGetIntegerv(GL_STENCIL_PASS_DEPTH_PASS, &dppass));
    return {Enum<gfx::StencilOpType>::from(sfail),
            Enum<gfx::StencilOpType>::from(dpfail),
            Enum<gfx::StencilOpType>::from(dppass)};
}

#if MH_RENDER_BACKEND_OPENGL
const constexpr DepthRange::Type DepthRange::Default;

void DepthRange::Set(const Type& value) {
    MH_TRACE_ZONE(DepthRange::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glDepthRangef(value.min, value.max));
}

DepthRange::Type DepthRange::Get() {
    MH_TRACE_ZONE(DepthRange::Get);
    MH_TRACE_FUNC_GL();
    GLfloat floats[2];
    MBGL_CHECK_ERROR(glGetFloatv(GL_DEPTH_RANGE, floats));
    return {floats[0], floats[1]};
}
#endif

const constexpr DepthTest::Type DepthTest::Default;

void DepthTest::Set(const Type& value) {
    MH_TRACE_ZONE(DepthTest::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(value ? glEnable(GL_DEPTH_TEST) : glDisable(GL_DEPTH_TEST));
}

DepthTest::Type DepthTest::Get() {
    MH_TRACE_ZONE(DepthTest::Get);
    MH_TRACE_FUNC_GL();
    Type depthTest;
    MBGL_CHECK_ERROR(depthTest = glIsEnabled(GL_DEPTH_TEST));
    return depthTest;
}

const constexpr DepthFunc::Type DepthFunc::Default;

void DepthFunc::Set(const DepthFunc::Type& value) {
    MH_TRACE_ZONE(DepthFunc::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glDepthFunc(Enum<gfx::DepthFunctionType>::to(value)));
}

DepthFunc::Type DepthFunc::Get() {
    MH_TRACE_ZONE(DepthFunc::Get);
    MH_TRACE_FUNC_GL();
    GLint depthFunc;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_DEPTH_FUNC, &depthFunc));
    return Enum<gfx::DepthFunctionType>::from(depthFunc);
}

const constexpr Blend::Type Blend::Default;

void Blend::Set(const Type& value) {
    MH_TRACE_ZONE(Blend::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(value ? glEnable(GL_BLEND) : glDisable(GL_BLEND));
}

Blend::Type Blend::Get() {
    MH_TRACE_ZONE(Blend::Get);
    MH_TRACE_FUNC_GL();
    Type blend;
    MBGL_CHECK_ERROR(blend = glIsEnabled(GL_BLEND));
    return blend;
}

const constexpr BlendEquation::Type BlendEquation::Default;

void BlendEquation::Set(const Type& value) {
    MH_TRACE_ZONE(BlendEquation::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glBlendEquation(Enum<gfx::ColorBlendEquationType>::to(value)));
}

BlendEquation::Type BlendEquation::Get() {
    MH_TRACE_ZONE(BlendEquation::Get);
    MH_TRACE_FUNC_GL();
    GLint blend;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_BLEND_EQUATION_RGB, &blend));
    return Enum<gfx::ColorBlendEquationType>::from(blend);
}

const constexpr BlendFunc::Type BlendFunc::Default;

void BlendFunc::Set(const Type& value) {
    MH_TRACE_ZONE(BlendFunc::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glBlendFunc(Enum<gfx::ColorBlendFactorType>::to(value.sfactor),
                                 Enum<gfx::ColorBlendFactorType>::to(value.dfactor)));
}

BlendFunc::Type BlendFunc::Get() {
    MH_TRACE_ZONE(BlendFunc::Get);
    MH_TRACE_FUNC_GL();
    GLint sfactor;
    GLint dfactor;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_BLEND_SRC_ALPHA, &sfactor));
    MBGL_CHECK_ERROR(glGetIntegerv(GL_BLEND_DST_ALPHA, &dfactor));
    return {Enum<gfx::ColorBlendFactorType>::from(sfactor), Enum<gfx::ColorBlendFactorType>::from(dfactor)};
}

const BlendColor::Type BlendColor::Default{0, 0, 0, 0};

void BlendColor::Set(const Type& value) {
    MH_TRACE_ZONE(BlendColor::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glBlendColor(value.r, value.g, value.b, value.a));
}

BlendColor::Type BlendColor::Get() {
    MH_TRACE_ZONE(BlendColor::Get);
    MH_TRACE_FUNC_GL();
    GLfloat floats[4];
    MBGL_CHECK_ERROR(glGetFloatv(GL_BLEND_COLOR, floats));
    return {floats[0], floats[1], floats[2], floats[3]};
}

const constexpr Program::Type Program::Default;

void Program::Set(const Type& value) {
    MH_TRACE_ZONE(Program::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glUseProgram(value));
}

Program::Type Program::Get() {
    MH_TRACE_ZONE(Program::Get);
    MH_TRACE_FUNC_GL();
    GLint program;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_CURRENT_PROGRAM, &program));
    return program;
}

const constexpr LineWidth::Type LineWidth::Default;

void LineWidth::Set(const Type& value) {
    MH_TRACE_ZONE(LineWidth::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glLineWidth(value));
}

LineWidth::Type LineWidth::Get() {
    MH_TRACE_ZONE(LineWidth::Get);
    MH_TRACE_FUNC_GL();
    GLfloat lineWidth;
    MBGL_CHECK_ERROR(glGetFloatv(GL_LINE_WIDTH, &lineWidth));
    return lineWidth;
}

const constexpr ActiveTextureUnit::Type ActiveTextureUnit::Default;

void ActiveTextureUnit::Set(const Type& value) {
    MH_TRACE_ZONE(ActiveTextureUnit::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glActiveTexture(GL_TEXTURE0 + value));
}

ActiveTextureUnit::Type ActiveTextureUnit::Get() {
    MH_TRACE_ZONE(ActiveTextureUnit::Get);
    MH_TRACE_FUNC_GL();
    GLint activeTexture;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_ACTIVE_TEXTURE, &activeTexture));
    return static_cast<Type>(activeTexture - GL_TEXTURE0);
}

const constexpr Viewport::Type Viewport::Default;

void Viewport::Set(const Type& value) {
    MH_TRACE_ZONE(Viewport::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glViewport(value.x, value.y, value.size.width, value.size.height));
}

Viewport::Type Viewport::Get() {
    MH_TRACE_ZONE(Viewport::Get);
    MH_TRACE_FUNC_GL();
    GLint viewport[4];
    MBGL_CHECK_ERROR(glGetIntegerv(GL_VIEWPORT, viewport));
    return {static_cast<int32_t>(viewport[0]),
            static_cast<int32_t>(viewport[1]),
            {static_cast<uint32_t>(viewport[2]), static_cast<uint32_t>(viewport[3])}};
}

const constexpr ScissorTest::Type ScissorTest::Default;

void ScissorTest::Set(const Type& value) {
    MH_TRACE_ZONE(ScissorTest::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(value ? glEnable(GL_SCISSOR_TEST) : glDisable(GL_SCISSOR_TEST));
}

ScissorTest::Type ScissorTest::Get() {
    MH_TRACE_ZONE(ScissorTest::Get);
    MH_TRACE_FUNC_GL();
    Type scissorTest;
    MBGL_CHECK_ERROR(scissorTest = glIsEnabled(GL_SCISSOR_TEST));
    return scissorTest;
}

const constexpr BindFramebuffer::Type BindFramebuffer::Default;

void BindFramebuffer::Set(const Type& value) {
    MH_TRACE_ZONE(BindFramebuffer::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glBindFramebuffer(GL_FRAMEBUFFER, value));
}

BindFramebuffer::Type BindFramebuffer::Get() {
    MH_TRACE_ZONE(BindFramebuffer::Get);
    MH_TRACE_FUNC_GL();
    GLint binding;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_FRAMEBUFFER_BINDING, &binding));
    return binding;
}

const constexpr BindRenderbuffer::Type BindRenderbuffer::Default;

void BindRenderbuffer::Set(const Type& value) {
    MH_TRACE_ZONE(BindRenderbuffer::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glBindRenderbuffer(GL_RENDERBUFFER, value));
}

BindRenderbuffer::Type BindRenderbuffer::Get() {
    MH_TRACE_ZONE(BindRenderbuffer::Get);
    MH_TRACE_FUNC_GL();
    GLint binding;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_RENDERBUFFER_BINDING, &binding));
    return binding;
}

const constexpr CullFace::Type CullFace::Default;

void CullFace::Set(const Type& value) {
    MH_TRACE_ZONE(CullFace::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(value ? glEnable(GL_CULL_FACE) : glDisable(GL_CULL_FACE));
}

CullFace::Type CullFace::Get() {
    MH_TRACE_ZONE(CullFace::Get);
    MH_TRACE_FUNC_GL();
    GLboolean cullFace;
    MBGL_CHECK_ERROR(cullFace = glIsEnabled(GL_CULL_FACE));
    return cullFace;
}

const constexpr CullFaceSide::Type CullFaceSide::Default;

void CullFaceSide::Set(const Type& value) {
    MH_TRACE_ZONE(CullFaceSide::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glCullFace(Enum<gfx::CullFaceSideType>::to(value)));
}

CullFaceSide::Type CullFaceSide::Get() {
    MH_TRACE_ZONE(CullFaceSide::Get);
    MH_TRACE_FUNC_GL();
    GLint cullFaceMode;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_CULL_FACE_MODE, &cullFaceMode));
    return Enum<gfx::CullFaceSideType>::from(cullFaceMode);
}

const constexpr CullFaceWinding::Type CullFaceWinding::Default;

void CullFaceWinding::Set(const Type& value) {
    MH_TRACE_ZONE(CullFaceWinding::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glFrontFace(Enum<gfx::CullFaceWindingType>::to(value)));
}

CullFaceWinding::Type CullFaceWinding::Get() {
    MH_TRACE_ZONE(CullFaceWinding::Get);
    MH_TRACE_FUNC_GL();
    GLint frontFace;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_FRONT_FACE, &frontFace));
    return Enum<gfx::CullFaceWindingType>::from(frontFace);
}

const constexpr BindTexture::Type BindTexture::Default;

void BindTexture::Set(const Type& value) {
    MH_TRACE_ZONE(BindTexture::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glBindTexture(GL_TEXTURE_2D, value));
}

BindTexture::Type BindTexture::Get() {
    MH_TRACE_ZONE(BindTexture::Get);
    MH_TRACE_FUNC_GL();
    GLint binding;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_TEXTURE_BINDING_2D, &binding));
    return binding;
}

const constexpr BindVertexBuffer::Type BindVertexBuffer::Default;

void BindVertexBuffer::Set(const Type& value) {
    MH_TRACE_ZONE(BindVertexBuffer::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glBindBuffer(GL_ARRAY_BUFFER, value));
}

BindVertexBuffer::Type BindVertexBuffer::Get() {
    MH_TRACE_ZONE(BindVertexBuffer::Get);
    MH_TRACE_FUNC_GL();
    GLint binding;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &binding));
    return binding;
}

const constexpr BindElementBuffer::Type BindElementBuffer::Default;

void BindElementBuffer::Set(const Type& value) {
    MH_TRACE_ZONE(BindElementBuffer::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, value));
}

BindElementBuffer::Type BindElementBuffer::Get() {
    MH_TRACE_ZONE(BindElementBuffer::Get);
    MH_TRACE_FUNC_GL();
    GLint binding;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, &binding));
    return binding;
}

const constexpr BindVertexArray::Type BindVertexArray::Default;

void BindVertexArray::Set(const Type& value) {
    MH_TRACE_ZONE(BindVertexArray::Set);
    MH_TRACE_FUNC_GL();
    MBGL_CHECK_ERROR(glBindVertexArray(value));
}

BindVertexArray::Type BindVertexArray::Get() {
    MH_TRACE_ZONE(BindVertexArray::Get);
    MH_TRACE_FUNC_GL();
    GLint binding = 0;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_VERTEX_ARRAY_BINDING, &binding));
    return binding;
}

const VertexAttribute::Type VertexAttribute::Default{};

namespace {

GLenum vertexType(const gfx::AttributeDataType type) {
    switch (type) {
        case gfx::AttributeDataType::Byte:
        case gfx::AttributeDataType::Byte2:
        case gfx::AttributeDataType::Byte3:
        case gfx::AttributeDataType::Byte4:
            return GL_BYTE;
        case gfx::AttributeDataType::UByte:
        case gfx::AttributeDataType::UByte2:
        case gfx::AttributeDataType::UByte3:
        case gfx::AttributeDataType::UByte4:
            return GL_UNSIGNED_BYTE;
        case gfx::AttributeDataType::Short:
        case gfx::AttributeDataType::Short2:
        case gfx::AttributeDataType::Short3:
        case gfx::AttributeDataType::Short4:
            return GL_SHORT;
        case gfx::AttributeDataType::UShort:
        case gfx::AttributeDataType::UShort2:
        case gfx::AttributeDataType::UShort3:
        case gfx::AttributeDataType::UShort4:
            return GL_UNSIGNED_SHORT;
        case gfx::AttributeDataType::Int:
        case gfx::AttributeDataType::Int2:
        case gfx::AttributeDataType::Int3:
        case gfx::AttributeDataType::Int4:
            return GL_INT;
        case gfx::AttributeDataType::UInt:
        case gfx::AttributeDataType::UInt2:
        case gfx::AttributeDataType::UInt3:
        case gfx::AttributeDataType::UInt4:
            return GL_UNSIGNED_INT;
        case gfx::AttributeDataType::Float:
        case gfx::AttributeDataType::Float2:
        case gfx::AttributeDataType::Float3:
        case gfx::AttributeDataType::Float4:
            return GL_FLOAT;
        default:
            return GL_FLOAT;
    }
}

GLint components(const gfx::AttributeDataType type) {
    switch (type) {
        case gfx::AttributeDataType::Byte:
        case gfx::AttributeDataType::UByte:
        case gfx::AttributeDataType::Short:
        case gfx::AttributeDataType::UShort:
        case gfx::AttributeDataType::Int:
        case gfx::AttributeDataType::UInt:
        case gfx::AttributeDataType::Float:
            return 1;
        case gfx::AttributeDataType::Byte2:
        case gfx::AttributeDataType::UByte2:
        case gfx::AttributeDataType::Short2:
        case gfx::AttributeDataType::UShort2:
        case gfx::AttributeDataType::Int2:
        case gfx::AttributeDataType::UInt2:
        case gfx::AttributeDataType::Float2:
            return 2;
        case gfx::AttributeDataType::Byte3:
        case gfx::AttributeDataType::UByte3:
        case gfx::AttributeDataType::Short3:
        case gfx::AttributeDataType::UShort3:
        case gfx::AttributeDataType::Int3:
        case gfx::AttributeDataType::UInt3:
        case gfx::AttributeDataType::Float3:
            return 3;
        case gfx::AttributeDataType::Byte4:
        case gfx::AttributeDataType::UByte4:
        case gfx::AttributeDataType::Short4:
        case gfx::AttributeDataType::UShort4:
        case gfx::AttributeDataType::Int4:
        case gfx::AttributeDataType::UInt4:
        case gfx::AttributeDataType::Float4:
            return 4;
        default:
            return 0;
    }
}

} // namespace

#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable : 4312) // reinterpret_cast different size
#endif

void VertexAttribute::Set(const Type& binding, Context& context, AttributeLocation location) {
    MH_TRACE_ZONE(VertexAttribute::Set);
    MH_TRACE_FUNC_GL();
    if (binding && binding->vertexBufferResource) {
        context.vertexBuffer =
            reinterpret_cast<const gl::VertexBufferResource&>(*binding->vertexBufferResource).getBuffer();
        MBGL_CHECK_ERROR(glEnableVertexAttribArray(location));
        MBGL_CHECK_ERROR(glVertexAttribPointer(
            location,
            components(binding->attribute.dataType),
            vertexType(binding->attribute.dataType),
            static_cast<GLboolean>(false),
            static_cast<GLsizei>(binding->vertexStride),
            reinterpret_cast<GLvoid*>(binding->attribute.offset + (binding->vertexStride * binding->vertexOffset))));
    } else {
        MBGL_CHECK_ERROR(glDisableVertexAttribArray(location));
    }
}

#ifdef _MSC_VER
#pragma warning(pop)
#endif

const constexpr PixelStorePack::Type PixelStorePack::Default;

void PixelStorePack::Set(const Type& value) {
    MH_TRACE_ZONE(PixelStorePack::Set);
    MH_TRACE_FUNC_GL();
    assert(value.alignment == 1 || value.alignment == 2 || value.alignment == 4 || value.alignment == 8);
    MBGL_CHECK_ERROR(glPixelStorei(GL_PACK_ALIGNMENT, value.alignment));
}

PixelStorePack::Type PixelStorePack::Get() {
    MH_TRACE_ZONE(PixelStorePack::Get);
    MH_TRACE_FUNC_GL();
    Type value;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_PACK_ALIGNMENT, &value.alignment));
    return value;
}

const constexpr PixelStoreUnpack::Type PixelStoreUnpack::Default;

void PixelStoreUnpack::Set(const Type& value) {
    MH_TRACE_ZONE(PixelStoreUnpack::Set);
    MH_TRACE_FUNC_GL();
    assert(value.alignment == 1 || value.alignment == 2 || value.alignment == 4 || value.alignment == 8);
    MBGL_CHECK_ERROR(glPixelStorei(GL_UNPACK_ALIGNMENT, value.alignment));
}

PixelStoreUnpack::Type PixelStoreUnpack::Get() {
    MH_TRACE_ZONE(PixelStoreUnpack::Get);
    MH_TRACE_FUNC_GL();
    Type value;
    MBGL_CHECK_ERROR(glGetIntegerv(GL_UNPACK_ALIGNMENT, &value.alignment));
    return value;
}

} // namespace value
} // namespace gl
} // namespace mbgl
