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

/**
 An ``MHCustomStyleLayer`` is a style layer that is rendered by OpenGL / Metal code that
 you provide.

 By default, this class does nothing. You can subclass this class to provide
 custom OpenGL or Metal drawing code that is run on each frame of the map. Your subclass
 should override the `-didMoveToMapView:`, `-willMoveFromMapView:`, and
 `-drawInMapView:withContext:` methods.

 You can access an existing MHCustomStyleLayer using the
 ``MHStyle/layerWithIdentifier:`` method if you know its identifier;
 otherwise, find it using the ``MHStyle/layers`` property. You can also create a
 new MHCustomStyleLayer and add it to the style using a method such as
 ``MHStyle/addLayer:``.

 @warning This API is undocumented and therefore unsupported. It may change at
    any time without notice.
 */
@interface MHCustomStyleLayer ()

@property (nonatomic, readonly) mbgl::style::CustomLayer *rawLayer;

@property (nonatomic, readonly, nullable) MHMapView *mapView;

/**
 The style currently containing the layer.

 If the layer is not currently part of any style, this property is
 set to `nil`.
 */
@property (nonatomic, weak, readwrite) MHStyle *style;

@end

@implementation MHCustomStyleLayer

/**
 Returns an MHCustomStyleLayer style layer object initialized with the given identifier.

 After initializing and configuring the style layer, add it to a map view’s
 style using the ``MHStyle/addLayer:`` or
 ``MHStyle/insertLayer:belowLayer:`` method.

 @param identifier A string that uniquely identifies the layer in the style to
    which it is added.
 @return An initialized OpenGL style layer.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier {
    auto layer = std::make_unique<mbgl::style::CustomLayer>(identifier.UTF8String,
                                                            std::make_unique<MHCustomLayerHost>(self));
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

// MARK: - Adding to and removing from a map view
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

/**
 Called immediately after a layer is added to a map view’s style.

 This method is intended to be overridden in a subclass. You can use this method
 to perform any setup work before the layer is used to draw a frame. For
 example, you might use this method to compile an OpenGL shader. The default
 implementation of this method does nothing.

 Any resource acquired in this method must be released in
 `-willMoveFromMapView:`.

 @param mapView The map view to whose style the layer has been added.
 */
- (void)didMoveToMapView:(MHMapView *)mapView {

}

/**
 Called immediately before a layer is removed from a map view’s style.

 This method is intended to be overridden in a subclass. You can use this method
 to perform any teardown work once the layer has drawn its last frame and is
 about to be removed from the style. The default implementation of this method
 does nothing.

 This method may be called even if `-didMoveToMapView:` has not been called.

 @param mapView The map view from whose style the layer is about to be removed.
 */
- (void)willMoveFromMapView:(MHMapView *)mapView {

}

/**
 Called each time the layer needs to draw a new frame in a map view.

 This method is intended to be overridden in a subclass. You can use this method
 to draw the layer’s content. The default implementation of this method does
 nothing.

 Your implementation should not make any assumptions about the OpenGL state,
 other than that the current OpenGL context is active. It may make changes to
 the OpenGL state. It is not required to reset values such as the depth mask,
 stencil mask, or corresponding test flags to their original values.

 Be sure to draw your fragments with a <var>z</var> value of 1 to take advantage
 of the opaque fragment culling, in case the style contains any opaque layers
 above this layer.

 @param mapView The map view to which the layer draws.
 @param context A context structure with information defining the frame to draw.
 */
- (void)drawInMapView:(MHMapView *)mapView withContext:(MHStyleLayerDrawingContext)context {

}

/**
 Forces the map view associated with this style to redraw the receiving layer,
 causing the `-drawInMapView:withContext:` method to be called.
 */
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
        if(!layer) return;

#if MH_RENDER_BACKEND_METAL
        MTL::RenderCommandEncoder* ptr = static_cast<const mbgl::style::mtl::CustomLayerRenderParameters&>(parameters).encoder.get();
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

    void contextLost() {}

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

