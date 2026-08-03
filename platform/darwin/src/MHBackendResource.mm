#if MH_RENDER_BACKEND_METAL

#import "MHBackendResource.h"

@implementation MHBackendResource

- (instancetype)initWithMTKView:(MTKView *)mtkView
                         device:(id<MTLDevice>)device
           renderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor
                  commandBuffer:(id<MTLCommandBuffer>)commandBuffer {
    self = [super init];
    if (self) {
        _mtkView = mtkView;
        _device = device;
        _renderPassDescriptor = renderPassDescriptor;
        _commandBuffer = commandBuffer;
    }
    return self;
}

@end

#else

#import "MHBackendResource.h"

@implementation MHBackendResource

- (instancetype)init {
    self = [super init];
    return self;
}

@end

#endif
