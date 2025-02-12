#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "MHFoundation.h"
#import "MHMultiPoint.h"
#import "MHOverlay.h"

#import "MHTypes.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An ``MHPolygon`` object represents a closed shape consisting of four or more
 vertices, specified as `CLLocationCoordinate2D` instances, and the edges that
 connect them. For example, you could use a polygon shape to represent a
 building, a lake, or an area you want to highlight.

 You can add polygon shapes to the map by adding them to an ``MHShapeSource``
 object. Configure the appearance of an ``MHShapeSource``’s or
 ``MHVectorTileSource``’s polygons collectively using an ``MHVectorTileSource`` or
 ``MHSymbolStyleLayer`` object. To access a polygon’s attributes, use an
 ``MHPolygonFeature`` object.

 Alternatively, you can add a polygon overlay directly to a map view using the
 ``MHMapView/addAnnotation:`` or ``MHMapView/addOverlay:`` method. Configure
 a polygon overlay’s appearance using
 ``MHMapViewDelegate/mapView:strokeColorForShapeAnnotation:`` and
 ``MHMapViewDelegate/mapView:fillColorForPolygonAnnotation:``.

 The vertices are automatically connected in the order in which you provide
 them. You should close the polygon by specifying the same
 `CLLocationCoordinate2D` as the first and last vertices; otherwise, the
 polygon’s fill may not cover the area you expect it to. To avoid filling the
 space within the shape, give the polygon a transparent fill or use an
 ``MHPolyline`` object.

 A polygon may have one or more interior polygons, or holes, that you specify as
 ``MHPolygon`` objects with the `+polygonWithCoordinates:count:interiorPolygons:`
 method. For example, if a polygon represents a lake, it could exclude an island
 within the lake using an interior polygon. Interior polygons may not themselves
 have interior polygons. To represent a shape that includes a polygon within a
 hole or, more generally, to group multiple polygons together in one shape, use
 an ``MHMultiPolygon`` or ``MHMultiPolygon`` object.

 To make the polygon straddle the antimeridian, specify some longitudes less
 than −180 degrees or greater than 180 degrees.

 #### Related examples
 TODO: Add a polygon annotation, learn how to initialize an
 ``MHPolygon`` object from an array of coordinates.
 */
MH_EXPORT
@interface MHPolygon : MHMultiPoint <MHOverlay>

/**
 The array of polygons nested inside the receiver.

 The area occupied by any interior polygons is excluded from the overall shape.
 Interior polygons should not overlap. An interior polygon should not have
 interior polygons of its own.

 If there are no interior polygons, the value of this property is `nil`.
 */
@property (nonatomic, nullable, readonly) NSArray<MHPolygon *> *interiorPolygons;

/**
 Creates and returns an ``MHPolygon`` object from the specified set of
 coordinates.

 @param coords The array of coordinates defining the shape. The data in this
    array is copied to the new object.
 @param count The number of items in the `coords` array.
 @return A new polygon object.
 */
+ (instancetype)polygonWithCoordinates:(const CLLocationCoordinate2D *)coords
                                 count:(NSUInteger)count;

/**
 Creates and returns an ``MHPolygon`` object from the specified set of
 coordinates and interior polygons.

 @param coords The array of coordinates defining the shape. The data in this
    array is copied to the new object.
 @param count The number of items in the `coords` array.
 @param interiorPolygons An array of ``MHPolygon`` objects that define regions
    excluded from the overall shape. If this array is `nil` or empty, the shape
    is considered to have no interior polygons.
 @return A new polygon object.
 */
+ (instancetype)polygonWithCoordinates:(const CLLocationCoordinate2D *)coords
                                 count:(NSUInteger)count
                      interiorPolygons:(nullable NSArray<MHPolygon *> *)interiorPolygons;

@end

/**
 An ``MHMultiPolygon`` object represents a shape consisting of one or more
 polygons that do not overlap. For example, you could use a multipolygon shape
 to represent the body of land that consists of an island surrounded by an
 atoll: the inner island would be one ``MHPolygon`` object, while the surrounding
 atoll would be another. You could also use a multipolygon shape to represent a
 group of disconnected but related buildings.

 You can add multipolygon shapes to the map by adding them to an
 ``MHShapeSource`` object. Configure the appearance of an ``MHShapeSource``’s or
 ``MHVectorTileSource``’s multipolygons collectively using an ``MHVectorTileSource``
 or ``MHSymbolStyleLayer`` object.

 You cannot add an ``MHMultiPolygon`` object directly to a map view using
 ``MHMapView/addAnnotation:`` or ``MHMapView/addOverlay:``. However, you can
 add the `polygons` array’s items as overlays individually.
 */
MH_EXPORT
@interface MHMultiPolygon : MHShape <MHOverlay>

/**
 An array of polygons forming the multipolygon.
 */
@property (nonatomic, copy, readonly) NSArray<MHPolygon *> *polygons;

/**
 Creates and returns a multipolygon object consisting of the given polygons.

 @param polygons The array of polygons defining the shape.
 @return A new multipolygon object.
 */
+ (instancetype)multiPolygonWithPolygons:(NSArray<MHPolygon *> *)polygons;

@end

NS_ASSUME_NONNULL_END
