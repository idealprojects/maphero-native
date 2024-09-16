#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "MHFoundation.h"
#import "MHGeometry.h"
#import "MHStyleLayer.h"
#import "MHStyleValue.h"

#if MH_RENDER_BACKEND_METAL
#import <MetalKit/MetalKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class MHMapView;
@class MHStyle;

typedef struct MHStyleLayerDrawingContext {
  CGSize size;
  CLLocationCoordinate2D centerCoordinate;
  double zoomLevel;
  CLLocationDirection direction;
  CGFloat pitch;
  CGFloat fieldOfView;
  MHMatrix4 projectionMatrix;
} MHStyleLayerDrawingContext;

MH_EXPORT
@interface MHCustomStyleLayer : MHStyleLayer

@property (nonatomic, weak, readonly) MHStyle *style;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#if TARGET_OS_IPHONE
@property (nonatomic, readonly) EAGLContext *context;
#else
@property (nonatomic, readonly) CGLContextObj context;
#endif
#pragma clang diagnostic pop

#if MH_RENDER_BACKEND_METAL
@property (nonatomic, weak) id<MTLRenderCommandEncoder> renderEncoder;
#endif

- (instancetype)initWithIdentifier:(NSString *)identifier;

- (void)didMoveToMapView:(MHMapView *)mapView;

- (void)willMoveFromMapView:(MHMapView *)mapView;

- (void)drawInMapView:(MHMapView *)mapView withContext:(MHStyleLayerDrawingContext)context;

- (void)setNeedsDisplay;

@end

NS_ASSUME_NONNULL_END
