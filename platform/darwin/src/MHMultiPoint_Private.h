#import "MHMultiPoint.h"

#import "MHGeometry.h"

#import <mbgl/annotation/annotation.hpp>
#import <mbgl/util/feature.hpp>
#import <vector>

#import <CoreGraphics/CoreGraphics.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@class MHPolygon;
@class MHPolyline;

@protocol MHMultiPointDelegate;

@interface MHMultiPoint (Private)

- (instancetype)initWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count;
- (BOOL)intersectsOverlayBounds:(MHCoordinateBounds)overlayBounds;

/** Constructs a shape annotation object, asking the delegate for style values. */
- (mbgl::Annotation)annotationObjectWithDelegate:(id<MHMultiPointDelegate>)delegate;

@end

/** An object that tells the MHMultiPoint instance how to style itself. */
@protocol MHMultiPointDelegate <NSObject>

/** Returns the fill alpha value for the given annotation. */
- (double)alphaForShapeAnnotation:(MHShape *)annotation;

/** Returns the stroke color object for the given annotation. */
- (mbgl::Color)strokeColorForShapeAnnotation:(MHShape *)annotation;

/** Returns the fill color object for the given annotation. */
- (mbgl::Color)fillColorForPolygonAnnotation:(MHPolygon *)annotation;

/** Returns the stroke width object for the given annotation. */
- (CGFloat)lineWidthForPolylineAnnotation:(MHPolyline *)annotation;

@end

NS_ASSUME_NONNULL_END
