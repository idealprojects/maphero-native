#import "MHMapView+Impl.h"
#import "MHMapView_Private.h"

#include <mbgl/gfx/renderable.hpp>
#include <mbgl/mtl/renderer_backend.hpp>

@class MHMapViewImplDelegate;

/// Adapter responsible for bridging calls from mbgl to MHMapView and Cocoa.
class MHMapViewMetalImpl final : public MHMapViewImpl,
                                  public mbgl::mtl::RendererBackend,
                                  public mbgl::gfx::Renderable {
 public:
  MHMapViewMetalImpl(MHMapView*);
  ~MHMapViewMetalImpl() override;

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
  // End implementation of mbgl::gl::Rendererbackend

  // Implementation of MHMapViewImpl
 public:
  mbgl::gfx::RendererBackend& getRendererBackend() override { return *this; }

  mbgl::PremultipliedImage readStillImage() override;

 private:
  bool presentsWithTransaction = false;
};
