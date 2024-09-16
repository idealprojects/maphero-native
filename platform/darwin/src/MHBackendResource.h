#if MH_RENDER_BACKEND_METAL

#import <MetalKit/MetalKit.h>

typedef struct {
    MTKView *mtkView;
    id<MTLDevice> device;
    MTLRenderPassDescriptor *renderPassDescriptor;
    id<MTLCommandBuffer> commandBuffer;
} MHBackendResource;

#else

typedef struct {
} MHBackendResource;

#endif
