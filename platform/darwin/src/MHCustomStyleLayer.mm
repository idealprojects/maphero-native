#import "MHCustomStyleLayer.h"
#import "MHCustomStyleLayer_Private.h"

#import "MHMapView_Private.h"
#import "MHStyle_Private.h"
#import "MHStyleLayer_Private.h"
#import "MHGeometry_Private.h"

#if MH_RENDER_BACKEND_METAL
#import <MetalKit/MetalKit.h>
#endif

#include <mbgl/style/layers/custom_layer.hpp>
#include <mbgl/math/wrap.hpp>

#if MH_RENDER_BACKEND_METAL
#include <mbgl/style/layers/mtl/custom_layer_render_parameters.hpp>
#endif

class MHCustomLayerHost;

@interface MHCustomStyleLayer ()
@property (nonatomic, readonly) mbgl::style::CustomLayer *rawLayer;
@property (nonatomic, readonly, nullable) MHMapView *mapView;
@property (nonatomic, weak, readwrite) MHStyle *style;
@end

@implementation MHCustomStyleLayer

- (instancetype)initWithIdentifier:(NSString *)identifier {
    auto layer = std::make_unique<mbgl::style::CustomLayer>(
        identifier.UTF8String,
        std::make_unique<MHCustomLayerHost>(self)
    );
    return self = [super initWithPendingLayer:std::move(layer)];
}

- (mbgl::style::CustomLayer *)rawLayer {
    return (mbgl::style::CustomLayer *)super.rawLayer;
}

- (MHMapView *)mapView {
    if ([self.style.stylable isKindOfClass:[MHMapView class]]) {
        return (MHMapView *)self.style.stylable;
    }
    return nil;
}

#if TARGET_OS_IPHONE
- (EAGLContext *)context {
    return self.mapView.context;
}
#else
- (CGLContextObj)context {
    return self.mapView.context;
}
#endif

- (void)addToStyle:(MHStyle *)style belowLayer:(MHStyleLayer *)otherLayer {
    self.style = style;
    self.style.customLayers[self.identifier] = self;
    [super addToStyle:style belowLayer:otherLayer];
}

- (void)removeFromStyle:(MHStyle *)style {
    [super removeFromStyle:style];
    self.style.customLayers[self.identifier] = nil;
    self.style = nil;
}

- (void)didMoveToMapView:(MHMapView *)mapView {
}

- (void)willMoveFromMapView:(MHMapView *)mapView {
}

- (void)drawInMapView:(MHMapView *)mapView withContext:(MHStyleLayerDrawingContext)context {
}

- (void)setNeedsDisplay {
    [self.mapView setNeedsRerender];
}

@end

class MHCustomLayerHost : public mbgl::style::CustomLayerHost {
public:
    MHCustomLayerHost(MHCustomStyleLayer *styleLayer) {
        layerRef = styleLayer;
        layer = nil;
    }

    void initialize() {
        if (layerRef == nil) return;
        else if (layer == nil) layer = layerRef;

        if (layer.mapView) {
            [layer didMoveToMapView:layer.mapView];
        }
    }

    void render(const mbgl::style::CustomLayerRenderParameters& parameters) {
        if (!layer) return;

#if MH_RENDER_BACKEND_METAL
        MTL::RenderCommandEncoder* ptr =
            static_cast<const mbgl::style::mtl::CustomLayerRenderParameters&>(parameters).encoder.get();
        id<MTLRenderCommandEncoder> encoder = (__bridge id<MTLRenderCommandEncoder>)ptr;
        layer.renderEncoder = encoder;
#endif

        MHStyleLayerDrawingContext drawingContext = {
            .size = CGSizeMake(parameters.width, parameters.height),
            .centerCoordinate = CLLocationCoordinate2DMake(parameters.latitude, parameters.longitude),
            .zoomLevel = parameters.zoom,
            .direction = mbgl::util::wrap(parameters.bearing, 0., 360.),
            .pitch = static_cast<CGFloat>(parameters.pitch),
            .fieldOfView = static_cast<CGFloat>(parameters.fieldOfView),
            .projectionMatrix = MHMatrix4Make(parameters.projectionMatrix)
        };

        if (layer.mapView) {
            [layer drawInMapView:layer.mapView withContext:drawingContext];
        }
    }

    void contextLost() {
    }

    void deinitialize() {
        if (layer == nil) return;

        if (layer.mapView) {
            [layer willMoveFromMapView:layer.mapView];
        }
        layerRef = layer;
        layer = nil;
    }

private:
    __weak MHCustomStyleLayer * layerRef;
    MHCustomStyleLayer * layer = nil;
};

namespace mbgl {

MHStyleLayer* CustomStyleLayerPeerFactory::createPeer(style::Layer* rawLayer) {
    return [[MHCustomStyleLayer alloc] initWithRawLayer:rawLayer];
}

}  // namespace mbgl
