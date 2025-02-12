#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "MHFoundation.h"
#import "MHShape.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An ``MHPointAnnotation`` object represents a one-dimensional shape located at a
 single geographical coordinate. Depending on how it is used, an
 ``MHPointAnnotation`` object is known as a point annotation or point shape. For
 example, you could use a point shape to represent a city at low zoom levels, an
 address at high zoom levels, or the location of a long press gesture.

 You can add point shapes to the map by adding them to an ``MHShapeSource``
 object. Configure the appearance of an ``MHShapeSource``’s or
 ``MHVectorTileSource``’s point shapes collectively using an ``MHVectorTileSource`` or
 ``MHSymbolStyleLayer`` object.

 For more interactivity, add a selectable point annotation to a map view using
 the ``MHMapView/addAnnotation:`` method. Alternatively, define your own model
 class that conforms to the ``MHAnnotation`` protocol. Configure a point
 annotation’s appearance using
 ``MHMapViewDelegate/mapView:imageForAnnotation:`` or
 ``MHMapViewDelegate/mapView:viewForAnnotation:`` (iOS only). A point
 annotation’s ``MHShape/title`` and ``MHShape/title`` properties define the
 default content of the annotation’s callout (on iOS) or popover (on macOS).

 To group multiple related points together in one shape, use an
 ``MHPointCollection`` or ``MHPointCollection`` object. To access
 a point’s attributes, use an ``MHPointFeature`` object.

 A point shape is known as a
 <a href="https://tools.ietf.org/html/rfc7946#section-3.1.2">Point</a> geometry
 in GeoJSON.

 #### Related examples
 TODO: Mark a place on the map with an annotation
 TODO: Mark a place on the map with an image
 TODO: Default callout usage
 Learn how to add ``MHPointAnnotation`` objects to your map.
 */
MH_EXPORT
@interface MHPointAnnotation : MHShape

/**
 The coordinate point of the shape, specified as a latitude and longitude.
 */
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@end

NS_ASSUME_NONNULL_END
