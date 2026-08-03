#import <Foundation/Foundation.h>

#import "MHFoundation.h"
#import "MHShape.h"

#import "MHTypes.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An ``MHShapeCollection`` object represents a shape consisting of zero or more
 distinct but related shapes that are instances of ``MHShape``. The constituent
 shapes can be a mixture of different kinds of shapes.

 ``MHShapeCollection`` is most commonly used to add multiple shapes to a single
 ``MHShapeSource``. Configure the appearance of an ``MHShapeSource``’s or
 ``MHVectorTileSource``’s shape collection collectively using an
 ``MHSymbolStyleLayer`` object, or use multiple instances of
 ``MHCircleStyleLayer``, ``MHCircleStyleLayer``, and ``MHCircleStyleLayer`` to
 configure the appearance of each kind of shape inside the collection.

 You cannot add an ``MHShapeCollection`` object directly to a map view as an
 annotation. However, you can create individual ``MHPointAnnotation``,
 ``MHPolyline``, and ``MHPolyline`` objects from the `shapes` array and add those
 annotation objects to the map view using the ``MHMapView/addAnnotations:``
 method.

 To represent a collection of point, polyline, or polygon shapes, it may be more
 convenient to use an ``MHPointCollection``, ``MHPointCollection``, or
 ``MHMultiPolygon`` object, respectively. To access a shape collection’s
 attributes, use the corresponding ``MHFeature`` object.

 A shape collection is known as a
 <a href="https://tools.ietf.org/html/rfc7946#section-3.1.8">GeometryCollection</a>
 geometry in GeoJSON.
 */
MH_EXPORT
@interface MHShapeCollection : MHShape

/**
 An array of shapes forming the shape collection.
 */
@property (nonatomic, copy, readonly) NSArray<MHShape *> *shapes;

/**
 Creates and returns a shape collection consisting of the given shapes.

 @param shapes The array of shapes defining the shape collection. The data in
    this array is copied to the new object.
 @return A new shape collection object.
 */
+ (instancetype)shapeCollectionWithShapes:(NSArray<MHShape *> *)shapes;

@end

NS_ASSUME_NONNULL_END
