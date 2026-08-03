#if MH_RENDER_BACKEND_METAL

#import <MetalKit/MetalKit.h>

@interface MHBackendResource : NSObject

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) MTLRenderPassDescriptor *renderPassDescriptor;
@property (nonatomic, strong) id<MTLCommandBuffer> commandBuffer;

- (instancetype)initWithMTKView:(MTKView *)mtkView
                         device:(id<MTLDevice>)device
           renderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor
                  commandBuffer:(id<MTLCommandBuffer>)commandBuffer;

@end

#else

#import <Foundation/Foundation.h>
#import "MHFoundation.h"

MH_EXPORT
@interface MHBackendResource : NSObject

@end

#endif
