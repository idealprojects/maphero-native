#import "MHMapView+Impl.h"
#import "MHMapView_Private.h"

#include <mbgl/gfx/renderable.hpp>
#include <mbgl/gl/renderer_backend.hpp>

/// Adapter responsible for bridging calls from mbgl to MHMapView and Cocoa.
class MHMapViewOpenGLImpl final : public MHMapViewImpl,
                                   public mbgl::gl::RendererBackend,
                                   public mbgl::gfx::Renderable {
public:
    MHMapViewOpenGLImpl(MHMapView*);
    ~MHMapViewOpenGLImpl() override = default;

public:
    void restoreFramebufferBinding();

    // Implementation of mbgl::gfx::RendererBackend
public:
    mbgl::gfx::Renderable& getDefaultRenderable() override { return *this; }

private:
    void activate() override;
    void deactivate() override;
    // End implementation of mbgl::gfx::RendererBackend

    // Implementation of mbgl::gl::RendererBackend
public:
    void updateAssumedState() override;

private:
    mbgl::gl::ProcAddress getExtensionFunctionPointer(const char* name) override;
    // End implementation of mbgl::gl::Rendererbackend

    // Implementation of MHMapViewImpl
public:
    mbgl::gfx::RendererBackend& getRendererBackend() override { return *this; }

    mbgl::PremultipliedImage readStillImage() override;
    CGLContextObj getCGLContextObj() override;
};
