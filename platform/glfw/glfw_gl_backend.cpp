#include "glfw_gl_backend.hpp"

#include <mbgl/gfx/backend_scope.hpp>
#include <mbgl/gl/renderable_resource.hpp>
#include <mbgl/util/instrumentation.hpp>

#include <GLFW/glfw3.h>

class GLFWGLRenderableResource final : public mbgl::gl::RenderableResource {
public:
    explicit GLFWGLRenderableResource(GLFWGLBackend& backend_)
        : backend(backend_) {}

    void bind() override {
        MH_TRACE_FUNC();

        backend.setFramebufferBinding(0);
        backend.setViewport(0, 0, backend.getSize());
    }

    void swap() override {
        MH_TRACE_FUNC();

        backend.swap();
    }

private:
    GLFWGLBackend& backend;
};

GLFWGLBackend::GLFWGLBackend(GLFWwindow* window_, const bool capFrameRate)
    : mbgl::gl::RendererBackend(mbgl::gfx::ContextMode::Unique),
      mbgl::gfx::Renderable(
          [window_] {
              int fbWidth;
              int fbHeight;
              glfwGetFramebufferSize(window_, &fbWidth, &fbHeight);
              return mbgl::Size{static_cast<uint32_t>(fbWidth), static_cast<uint32_t>(fbHeight)};
          }(),
          std::make_unique<GLFWGLRenderableResource>(*this)),
      window(window_) {
    MH_TRACE_FUNC();

    glfwMakeContextCurrent(window);
    if (!capFrameRate) {
        // Disables vsync on platforms that support it.
        glfwSwapInterval(0);
    } else {
        glfwSwapInterval(1);
    }
}

GLFWGLBackend::~GLFWGLBackend() = default;

void GLFWGLBackend::activate() {
    MH_TRACE_FUNC();

    glfwMakeContextCurrent(window);
}

void GLFWGLBackend::deactivate() {
    MH_TRACE_FUNC();

    glfwMakeContextCurrent(nullptr);
}

mbgl::gl::ProcAddress GLFWGLBackend::getExtensionFunctionPointer(const char* name) {
    return glfwGetProcAddress(name);
}

void GLFWGLBackend::updateAssumedState() {
    MH_TRACE_FUNC();

    assumeFramebufferBinding(0);
    setViewport(0, 0, size);
}

mbgl::Size GLFWGLBackend::getSize() const {
    return size;
}

void GLFWGLBackend::setSize(const mbgl::Size newSize) {
    size = newSize;
}

void GLFWGLBackend::swap() {
    MH_TRACE_FUNC();

    glfwSwapBuffers(window);
}

namespace mbgl {
namespace gfx {

template <>
std::unique_ptr<GLFWBackend> Backend::Create<mbgl::gfx::Backend::Type::OpenGL>(GLFWwindow* window, bool capFrameRate) {
    MH_TRACE_FUNC();

    return std::make_unique<GLFWGLBackend>(window, capFrameRate);
}

} // namespace gfx
} // namespace mbgl
