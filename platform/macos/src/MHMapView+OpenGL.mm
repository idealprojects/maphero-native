#import "MHMapView+OpenGL.h"
#import "MHOpenGLLayer.h"

#include <mbgl/gl/renderable_resource.hpp>

#import <OpenGL/gl.h>

class MHMapViewOpenGLRenderableResource final : public mbgl::gl::RenderableResource {
public:
    MHMapViewOpenGLRenderableResource(MHMapViewOpenGLImpl& backend_) : backend(backend_) {
    }

    void bind() override {
        backend.restoreFramebufferBinding();
    }

private:
    MHMapViewOpenGLImpl& backend;

public:
    // The current framebuffer of the NSOpenGLLayer we are painting to.
    GLint fbo = 0;

    // The reference counted count of activation calls
    NSUInteger activationCount = 0;
};

MHMapViewOpenGLImpl::MHMapViewOpenGLImpl(MHMapView* nativeView_)
    : MHMapViewImpl(nativeView_),
      mbgl::gl::RendererBackend(mbgl::gfx::ContextMode::Unique),
      mbgl::gfx::Renderable(mapView.framebufferSize,
                            std::make_unique<MHMapViewOpenGLRenderableResource>(*this)) {

    // Install the OpenGL layer. Interface Builder’s synchronous drawing means
    // we can’t display a map, so don’t even bother to have a map layer.
    mapView.layer =
        mapView.isTargetingInterfaceBuilder ? [CALayer layer] : [MHOpenGLLayer layer];
}

mbgl::gl::ProcAddress MHMapViewOpenGLImpl::getExtensionFunctionPointer(const char* name) {
    static CFBundleRef framework = CFBundleGetBundleWithIdentifier(CFSTR("com.apple.opengl"));
    if (!framework) {
        throw std::runtime_error("Failed to load OpenGL framework.");
    }

    return reinterpret_cast<mbgl::gl::ProcAddress>(CFBundleGetFunctionPointerForName(
        framework, (__bridge CFStringRef)[NSString stringWithUTF8String:name]));
}

void MHMapViewOpenGLImpl::activate() {
    auto& resource = getResource<MHMapViewOpenGLRenderableResource>();
    if (resource.activationCount++) {
        return;
    }

    MHOpenGLLayer* layer = (MHOpenGLLayer*)mapView.layer;
    [layer.openGLContext makeCurrentContext];
}

void MHMapViewOpenGLImpl::deactivate() {
    auto& resource = getResource<MHMapViewOpenGLRenderableResource>();
    if (--resource.activationCount) {
        return;
    }

    [NSOpenGLContext clearCurrentContext];
}

void MHMapViewOpenGLImpl::updateAssumedState() {
    auto& resource = getResource<MHMapViewOpenGLRenderableResource>();
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &resource.fbo);
    assumeFramebufferBinding(resource.fbo);
    assumeViewport(0, 0, mapView.framebufferSize);
}

void MHMapViewOpenGLImpl::restoreFramebufferBinding() {
    auto& resource = getResource<MHMapViewOpenGLRenderableResource>();
    setFramebufferBinding(resource.fbo);
    setViewport(0, 0, mapView.framebufferSize);
}

mbgl::PremultipliedImage MHMapViewOpenGLImpl::readStillImage() {
    return readFramebuffer(mapView.framebufferSize);
}

CGLContextObj MHMapViewOpenGLImpl::getCGLContextObj() {
    MHOpenGLLayer* layer = (MHOpenGLLayer*)mapView.layer;
    return layer.openGLContext.CGLContextObj;
}
