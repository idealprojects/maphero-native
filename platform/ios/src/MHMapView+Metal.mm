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

namespace {
CGFloat contentScaleFactor() {
    return [UIScreen instancesRespondToSelector:@selector(nativeScale)]
        ? [[UIScreen mainScreen] nativeScale]
        : [[UIScreen mainScreen] scale];
}
} // namespace

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

        if (!commandBuffer) {
            commandBuffer = [commandQueue commandBuffer];
            commandBufferPtr = NS::RetainPtr((__bridge MTL::CommandBuffer*)commandBuffer);
        }
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
        if (currentDrawable) {
            if (presentsWithTransaction) {
                [commandBuffer commit];
                [commandBuffer waitUntilCompleted];
                [currentDrawable present];
            } else {
                [commandBuffer presentDrawable:currentDrawable];
                [commandBuffer commit];
            }
        }

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
    bool presentsWithTransaction = false;

    // We count how often the context was activated/deactivated so that we can truly deactivate it
    // after the activation count drops to 0.
    NSUInteger activationCount = 0;
};

MHMapViewMetalImpl::MHMapViewMetalImpl(MHMapView* nativeView_)
    : MHMapViewImpl(nativeView_),
      mbgl::mtl::RendererBackend(mbgl::gfx::ContextMode::Unique),
      mbgl::gfx::Renderable({ 0, 0 }, std::make_unique<MHMapViewMetalRenderableResource>(*this)) {
}

MHMapViewMetalImpl::~MHMapViewMetalImpl() = default;

void MHMapViewMetalImpl::setOpaque(const bool opaque) {
    auto& resource = getResource<MHMapViewMetalRenderableResource>();
    resource.mtlView.opaque = opaque;
    resource.mtlView.layer.opaque = opaque;
}

void MHMapViewMetalImpl::setPresentsWithTransaction(const bool value) {
    auto& resource = getResource<MHMapViewMetalRenderableResource>();
    resource.presentsWithTransaction = value;

    if (@available(iOS 13.0, *)) {
        if (CAMetalLayer* metalLayer = MH_OBJC_DYNAMIC_CAST(resource.mtlView.layer, CAMetalLayer)) {
            metalLayer.presentsWithTransaction = value;
        }
    }
}

void MHMapViewMetalImpl::display() {
    auto& resource = getResource<MHMapViewMetalRenderableResource>();

    // Calling `display` here directly causes the stuttering bug (if
    // `presentsWithTransaction` is `YES` - see above)
    // as reported in https://github.com/mapbox/mapbox-gl-native-ios/issues/350
    //
    // Since we use `presentsWithTransaction` to synchronize with UIView
    // annotations, we now let the system handle when the view is rendered. This
    // has the potential to increase latency
    [resource.mtlView setNeedsDisplay];
}

void MHMapViewMetalImpl::createView() {
    auto& resource = getResource<MHMapViewMetalRenderableResource>();
    if (resource.mtlView) {
        return;
    }

    id<MTLDevice> device = (__bridge id<MTLDevice>)resource.getBackend().getDevice().get();

    resource.mtlView = [[MTKView alloc] initWithFrame:mapView.bounds device:device];
    resource.mtlView.delegate = resource.delegate;
    resource.mtlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    resource.mtlView.contentScaleFactor = contentScaleFactor();
    resource.mtlView.contentMode = UIViewContentModeCenter;
    resource.mtlView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    resource.mtlView.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    resource.mtlView.opaque = mapView.opaque;
    resource.mtlView.layer.opaque = mapView.opaque;
    resource.mtlView.enableSetNeedsDisplay = YES;
    if (@available(iOS 13.0, *)) {
        CAMetalLayer* metalLayer = MH_OBJC_DYNAMIC_CAST(resource.mtlView.layer, CAMetalLayer);
        metalLayer.presentsWithTransaction = resource.presentsWithTransaction;
    }

    [mapView insertSubview:resource.mtlView atIndex:0];
}

UIView* MHMapViewMetalImpl::getView() {
    auto& resource = getResource<MHMapViewMetalRenderableResource>();
    return resource.mtlView;
}

void MHMapViewMetalImpl::deleteView() {
    auto& resource = getResource<MHMapViewMetalRenderableResource>();
    [resource.mtlView releaseDrawables];
}

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

UIImage* MHMapViewMetalImpl::snapshot() {
    auto& resource = getResource<MHMapViewMetalRenderableResource>();
    return nil; //TODO: resource.mtlView.snapshot;
}

void MHMapViewMetalImpl::layoutChanged() {
    const auto scaleFactor = contentScaleFactor();
    size = { static_cast<uint32_t>(mapView.bounds.size.width * scaleFactor),
             static_cast<uint32_t>(mapView.bounds.size.height * scaleFactor) };
}

MHBackendResource MHMapViewMetalImpl::getObject() {
    auto& resource = getResource<MHMapViewMetalRenderableResource>();
    auto renderPassDescriptor = resource.getRenderPassDescriptor().get();
    return {
        resource.mtlView,
        resource.mtlView.device,
        [MTLRenderPassDescriptor renderPassDescriptor],
        resource.commandBuffer
    };
}
