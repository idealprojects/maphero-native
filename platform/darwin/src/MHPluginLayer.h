#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import "MHFoundation.h"
#import "MHGeometry.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum {
  MHPluginLayerPropertyTypeUnknown,
  MHPluginLayerPropertyTypeSingleFloat,
  MHPluginLayerPropertyTypeColor
} MHPluginLayerPropertyType;

MH_EXPORT
@interface MHPluginLayerProperty : NSObject

+ (MHPluginLayerProperty *)propertyWithName:(NSString *)propertyName
                                propertyType:(MHPluginLayerPropertyType)propertyType
                                defaultValue:(id)defaultValue;

// The name of the property
@property (copy) NSString *propertyName;

// The type of property
@property MHPluginLayerPropertyType propertyType;

// Single float default value
@property float singleFloatDefaultValue;

// Color default value
#if TARGET_OS_IPHONE
@property (copy) UIColor *colorDefaultValue;
#else
@property NSColor *colorDefaultValue;
#endif

@end

typedef enum {
  MHPluginLayerTileKindGeometry,
  MHPluginLayerTileKindRaster,
  MHPluginLayerTileKindRasterDEM,
  MHPluginLayerTileKindNotRequired
} MHPluginLayerTileKind;

MH_EXPORT
@interface MHPluginLayerCapabilities : NSObject

@property (copy) NSString *layerID;
@property BOOL requiresPass3D;

//! This is a list of layer properties that this layer supports.
@property (copy) NSArray<MHPluginLayerProperty *> *layerProperties;

@end

@class MHMapView;

// Copied initially from MHStyleLayerDrawingContext.  Decided to copy instead of use since we
// might add additional properties here
/// A structure containing context needed to draw a frame in an ``MHCustomStyleLayer``.
typedef struct MHPluginLayerDrawingContext {
  /// The size of the drawable area, in points.
  CGSize size;
  /// The center coordinate of the map view.
  CLLocationCoordinate2D centerCoordinate;
  /// The current zoom level of the map view.
  double zoomLevel;
  /// The heading (direction) in degrees clockwise from true north.
  CLLocationDirection direction;
  /// The current pitch of the map view in degrees, measured from the map plane.
  CGFloat pitch;
  /// The vertical field of view, in degrees, for the map’s perspective.
  CGFloat fieldOfView;
  /// A 4×4 matrix representing the map view’s current projection state.
  MHMatrix4 projectionMatrix;
  /// A 4×4 matrix representing the map view’s current near clip projection state.
  MHMatrix4 nearClippedProjMatrix;

} MHPluginLayerDrawingContext;

MH_EXPORT
@interface MHPluginLayer : NSObject

/// Returns the layer capabilities of the plugin layer.
/// This must be overridden by the plug-in layer and return a set of capabilities
+ (MHPluginLayerCapabilities *)layerCapabilities;

// These are public methods that can be overridden by the plugin layer
/// Called when the layer is rendered
- (void)onRenderLayer:(MHMapView *)mapView
        renderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder;

/// Called when the layer is updated in the render loop.  This would update animations/etc
- (void)onUpdateLayer:(MHPluginLayerDrawingContext)drawingContext;

/// Called when the layer properties are updated.  Can be on initial load from the JSON or when
/// dynamic properties are updated
- (void)onUpdateLayerProperties:(NSDictionary *)layerProperties;

/// Added to a map view
- (void)didMoveToMapView:(MHMapView *)mapView;

@end

NS_ASSUME_NONNULL_END
