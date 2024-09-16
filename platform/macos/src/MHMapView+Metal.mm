#import "MHFoundation_Private.h"
#import "MHLoggingConfiguration_Private.h"
#import "MHMapView+Metal.h"

#import <mbgl/mtl/renderable_resource.hpp>

#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#import <Metal/Metal.hpp>

@interface MHMapViewImplDelegate : NSObject <MTKViewDelegate>
@end

@implementation MHMapViewImplDelegate {
    MHMapViewMetalImpl* _impl;
}

- (instancetype)initWithImpl:(MHMapViewMetalImpl*)impl {
    if (self = [super init]) {
        _impl = impl;
    }
    return self;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

- (void)drawInMTKView:(MTKView *)view {
    _impl->render();
}

@end

class MHMapViewMetalRenderableResource final : public mbgl::mtl::RenderableResource {
public:
    MHMapViewMetalRenderableResource(MHMapViewMetalImpl& backend_)
        : backend(backend_),
          delegate([[MHMapViewImplDelegate alloc] initWithImpl:&backend]) {
    }

    void bind() override {
        if (!commandQueue) {
            commandQueue = [mtlView.device newCommandQueue];
        }

        commandBuffer = [commandQueue commandBuffer];
        commandBufferPtr = NS::RetainPtr((__bridge MTL::CommandBuffer*)commandBuffer);
    }

    const mbgl::mtl::RendererBackend& getBackend() const override { return backend; }

    const mbgl::mtl::MTLCommandBufferPtr& getCommandBuffer() const override {
        return commandBufferPtr;
    }

    virtual mbgl::mtl::MTLBlitPassDescriptorPtr getUploadPassDescriptor() const override {
        // Create from render pass descriptor?
        return NS::TransferPtr(MTL::BlitPassDescriptor::alloc()->init());
    }

    const mbgl::mtl::MTLRenderPassDescriptorPtr& getRenderPassDescriptor() const override {
        if (!cachedRenderPassDescriptor) {
            auto* mtlDesc = mtlView.currentRenderPassDescriptor;
            cachedRenderPassDescriptor = NS::RetainPtr((__bridge MTL::RenderPassDescriptor*)mtlDesc);
        }
        return cachedRenderPassDescriptor;
    }

    void swap() override {
        id<CAMetalDrawable> currentDrawable = [mtlView currentDrawable];
        [commandBuffer presentDrawable:currentDrawable];
        [commandBuffer commit];

        // Un-comment for synchronous, which can help troubleshoot rendering problems,
        // particularly those related to resource tracking and multiple queued buffers.
        //[commandBuffer waitUntilCompleted];

        commandBuffer = nil;
        commandBufferPtr.reset();

        cachedRenderPassDescriptor.reset();
    }

    mbgl::Size framebufferSize() {
        assert(mtlView);
        return { static_cast<uint32_t>(mtlView.drawableSize.width),
                 static_cast<uint32_t>(mtlView.drawableSize.height) };
    }

private:
    MHMapViewMetalImpl& backend;
    mbgl::mtl::MTLCommandBufferPtr commandBufferPtr;
    mutable mbgl::mtl::MTLRenderPassDescriptorPtr cachedRenderPassDescriptor;

public:
    MHMapViewImplDelegate* delegate = nil;
    MTKView *mtlView = nil;
    id <MTLCommandBuffer> commandBuffer;
    id <MTLCommandQueue> commandQueue;

    // We count how often the context was activated/deactivated so that we can truly deactivate it
    // after the activation count drops to 0.
    NSUInteger activationCount = 0;
};

MHMapViewMetalImpl::MHMapViewMetalImpl(MHMapView* nativeView_)
    : MHMapViewImpl(nativeView_),
      mbgl::mtl::RendererBackend(mbgl::gfx::ContextMode::Unique),
      mbgl::gfx::Renderable({ 0, 0 }, std::make_unique<MHMapViewMetalRenderableResource>(*this)) {
          
      auto& resource = getResource<MHMapViewMetalRenderableResource>();
      if (resource.mtlView) {
          return;
      }

      id<MTLDevice> device = (__bridge id<MTLDevice>)resource.getBackend().getDevice().get();

      resource.mtlView = [[MTKView alloc] initWithFrame:mapView.bounds device:device];
      resource.mtlView.delegate = resource.delegate;
      resource.mtlView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
      resource.mtlView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
      resource.mtlView.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
      resource.mtlView.layer.opaque = mapView.opaque;
      resource.mtlView.enableSetNeedsDisplay = NO;
      CAMetalLayer* metalLayer = MH_OBJC_DYNAMIC_CAST(resource.mtlView.layer, CAMetalLayer);
      metalLayer.presentsWithTransaction = presentsWithTransaction;

      [mapView addSubview:resource.mtlView positioned:NSWindowBelow relativeTo:nil];
}

MHMapViewMetalImpl::~MHMapViewMetalImpl() = default;

void MHMapViewMetalImpl::activate() {
    auto& resource = getResource<MHMapViewMetalRenderableResource>();
    if (resource.activationCount++) {
        return;
    }
}

void MHMapViewMetalImpl::deactivate() {
    auto& resource = getResource<MHMapViewMetalRenderableResource>();
    if (--resource.activationCount) {
        return;
    }
}

/// This function is called before we start rendering, when iOS invokes our rendering method.
/// iOS already sets the correct framebuffer and viewport for us, so we need to update the
/// context state with the anticipated values.
void MHMapViewMetalImpl::updateAssumedState() {
    auto& resource = getResource<MHMapViewMetalRenderableResource>();
    assumeFramebufferBinding(ImplicitFramebufferBinding);
    assumeViewport(0, 0, resource.framebufferSize());
}

mbgl::PremultipliedImage MHMapViewMetalImpl::readStillImage() {
    // return readFramebuffer(mapView.framebufferSize); // TODO: RendererBackend::readFramebuffer
    return {};
}
