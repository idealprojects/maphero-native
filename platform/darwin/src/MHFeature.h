#import <Foundation/Foundation.h>

#import "MHCluster.h"
#import "MHFoundation.h"
#import "MHPointAnnotation.h"
#import "MHPointCollection.h"
#import "MHPolygon.h"
#import "MHPolyline.h"
#import "MHShapeCollection.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The ``MHFeature``  protocol is used to provide details about geographic features
 contained in an ``MHShapeSource`` or ``MHVectorTileSource`` object. Each concrete
 subclass of ``MHShape`` in turn has a subclass that conforms to this protocol. A
 feature object associates a shape with an optional identifier and attributes.

 You can add custom data to display on the map by creating feature objects and
 adding them to an ``MHShapeSource`` using the
 ``MHShapeSource/initWithIdentifier:shape:options:`` method or
 ``MHShapeSource/shape`` property.

 In addition to adding data to the map, you can also extract data from the map:
 ``MHMapView/visibleFeaturesAtPoint:`` and related methods return feature
 objects that correspond to features in the source. This enables you to inspect
 the properties of features in vector tiles loaded by ``MHVectorTileSource``
 objects. You also reuse these feature objects as overlay annotations.

 While it is possible to add ``MHFeature``-conforming objects to the map as
 annotations using ``MHMapView/addAnnotations:`` and related methods, doing so
 has trade-offs:

 - Features added as annotations will not have ``identifier`` or ``attributes``
 properties when used with feature querying.

 - Features added as annotations become interactive. Taps and selection can be
 handled in ``MHMapViewDelegate/mapView:didSelectAnnotation:``.
 */
@protocol MHFeature <MHAnnotation>

/**
 An object that uniquely identifies the feature in its containing content
 source.

 You can configure an ``MHVectorStyleLayer`` object to include or exclude a
 specific feature in an ``MHShapeSource`` or ``MHVectorTileSource``. In the
 ``MHVectorStyleLayer/predicate`` property, compare the special `$id` attribute
 to the feature’s identifier.

 In vector tiles loaded by ``MHVectorTileSource`` objects, the identifier
 corresponds to the
 <a href="https://github.com/mapbox/vector-tile-spec/tree/master/2.1#42-features">feature
 identifier</a>
 (`id`). If the source does not specify the feature’s identifier, the value of
 this property is `nil`. If specified, the identifier may be an integer,
 floating-point number, or string. These data types are mapped to instances of
 the following Foundation classes:

 | In the tile source        | This property |
 |---------------------------|-------------------------------------------------------------------------------|
 | Integer                   | `NSNumber` (use the `unsignedLongLongValue` or `longLongValue`
 property)      | | Floating-point number      | `NSNumber` (use the `doubleValue` property) | |
 String                    | `NSString` |

 The identifier should be set before adding the feature to an ``MHShapeSource``
 object; setting it afterwards has no effect on the map’s contents. While it is
 possible to change this value on feature instances obtained from
 ``MHMapView/visibleFeaturesAtPoint:`` and related methods, doing so likewise
 has no effect on the map’s contents.
 */
@property (nonatomic, copy, nullable) id identifier;

/**
 A dictionary of attributes for this feature.

 You can configure an ``MHVectorStyleLayer`` object to include or exclude a
 specific feature in an ``MHShapeSource`` or ``MHVectorTileSource``. In the
 ``MHVectorStyleLayer/predicate`` property, compare a key of the attribute
 dictionary to the value you want to include. For example, if you want an
 ``MHLineStyleLayer`` object to display only important features, you might assign
 a value above 50 to the important features’ `importance` attribute, then set
 ``MHVectorStyleLayer/predicate`` to an
 [`NSPredicate`](https://developer.apple.com/documentation/foundation/nspredicate) with the format
 `importance > 50`.

 You can also configure many layout and paint attributes of an ``MHStyleLayer``
 object to match the value of an attribute in this dictionary whenever it
 renders this feature. For example, if you display features in an
 ``MHShapeSource`` using an ``MHCircleStyleLayer``, you can assign a `halfway`
 attribute to each of the source’s features, then set
 ``MHCircleStyleLayer/circleRadius`` to an expression for the key path `halfway`.

 The ``MHSymbolStyleLayer/text`` and ``MHSymbolStyleLayer/iconImageName``
 properties allow you to use attributes yet another way. For example, to label
 features in an ``MHShapeSource`` object by their names, you can assign a `name`
 attribute to each of the source’s features, then set
 ``MHSymbolStyleLayer/text`` to an expression for the constant string value
 `{name}`. See the
 <a href="../predicates-and-expressions.html">Predicates and Expressions</a>
 guide for more information about expressions.

 In vector tiles loaded by ``MHVectorTileSource`` objects, the keys and values of
 each feature’s attribute dictionary are determined by the source. Each
 attribute name is a string, while each attribute value may be a null value,
 Boolean value, integer, floating-point number, or string. These data types are
 mapped to instances of the following Foundation classes:

 | In the tile source        | In this dictionary |
 |---------------------------|-------------------------------------------------------------------------------|
 | Null                      | `NSNull` | | Boolean                   | `NSNumber` (use the
 `boolValue` property)                                     | | Integer                   |
 `NSNumber` (use the `unsignedLongLongValue` or `longLongValue` property)      | | Floating-point
 number      | `NSNumber` (use the `doubleValue` property)                                  | |
 String                    | `NSString` |

 When adding a feature to an ``MHShapeSource``, use the same Foundation types
 listed above for each attribute value. In addition to the Foundation types, you
 may also set an attribute to an `NSColor` (macOS) or `UIColor` (iOS), which
 will be converted into its
 <a href="https://maplibre.org/maplibre-style-spec/types/#color">CSS string representation</a>
 when the feature is added to an ``MHShapeSource``. This can be convenient when
 using the attribute to supply a value for a color-typed layout or paint
 attribute via a key path expression.

 Note that while it is possible to change this value on feature
 instances obtained from ``MHMapView/visibleFeaturesAtPoint:`` and related
 methods, there will be no effect on the map. Setting this value can be useful
 when the feature instance is used to initialize an ``MHShapeSource`` and that
 source is added to the map and styled.
 */
@property (nonatomic, copy) NSDictionary<NSString *, id> *attributes;

/**
 Returns the feature attribute for the given attribute name.

 See the ``attributes`` property’s documentation for details on keys and values
 associated with this method.
 */
- (nullable id)attributeForKey:(NSString *)key;

/**
 Returns a dictionary that can be serialized as a GeoJSON Feature representation
 of an instance of an ``MHFeature`` subclass.

 The dictionary includes a `geometry` key corresponding to the receiver’s
 underlying geometry data, a `properties` key corresponding to the receiver’s
 `attributes` property, and an `id` key corresponding to the receiver’s
 ``identifier` property.
 */
- (NSDictionary<NSString *, id> *)geoJSONDictionary;

@end

/**
 An ``MHEmptyFeature`` object associates an empty shape with an optional
 identifier and attributes.
 */
MH_EXPORT
@interface MHEmptyFeature : MHShape <MHFeature>
@end

/**
 An ``MHPointFeature`` object associates a point shape with an optional
 identifier and attributes.

 #### Related examples
 - <doc:WebAPIDataExample>
 */
MH_EXPORT
@interface MHPointFeature : MHPointAnnotation <MHFeature>
@end

/**
 An ``MHPointFeatureCluster`` object associates a point shape (with an optional
 identifier and attributes) and represents a point cluster.

 @see ``MHCluster``

 #### Related examples
 TODO: Clustering point data, learn how to initialize
 clusters and add them to your map.
 */
MH_EXPORT
@interface MHPointFeatureCluster : MHPointFeature <MHCluster>
@end

/**
 An ``MHPolylineFeature`` object associates a polyline shape with an optional
 identifier and attributes.

 A polyline feature is known as a
 <a href="https://tools.ietf.org/html/rfc7946#section-3.1.4">LineString</a>
 feature in GeoJSON.

 #### Related examples
 - <doc:AnimatedLineExample>
 */
MH_EXPORT
@interface MHPolylineFeature : MHPolyline <MHFeature>
@end

/**
 An ``MHPolygonFeature`` object associates a polygon shape with an optional
 identifier and attributes.
 */
MH_EXPORT
@interface MHPolygonFeature : MHPolygon <MHFeature>
@end

/**
 An ``MHPointCollectionFeature`` object associates a point collection with an
 optional identifier and attributes.

 A point collection feature is known as a
 <a href="https://tools.ietf.org/html/rfc7946#section-3.1.3">MultiPoint</a>
 feature in GeoJSON.
 */
MH_EXPORT
@interface MHPointCollectionFeature : MHPointCollection <MHFeature>
@end

// https://github.com/mapbox/mapbox-gl-native/issues/7473
@compatibility_alias MHMultiPointFeature MHPointCollectionFeature;

/**
 An ``MHMultiPolylineFeature`` object associates a multipolyline shape with an
 optional identifier and attributes.

 A multipolyline feature is known as a
 <a href="https://tools.ietf.org/html/rfc7946#section-3.1.5">MultiLineString</a>
 feature in GeoJSON.
 */
MH_EXPORT
@interface MHMultiPolylineFeature : MHMultiPolyline <MHFeature>
@end

/**
 An ``MHMultiPolygonFeature`` object associates a multipolygon shape with an
 optional identifier and attributes.
 */
MH_EXPORT
@interface MHMultiPolygonFeature : MHMultiPolygon <MHFeature>
@end

/**
 An ``MHShapeCollectionFeature`` object associates a shape collection with an
 optional identifier and attributes.

 ``MHShapeCollectionFeature`` is most commonly used to add multiple shapes to a
 single ``MHShapeSource``. Configure the appearance of an ``MHSource``’s shape
 collection collectively using an ``MHSymbolStyleLayer`` object, or use multiple
 instances of ``MHCircleStyleLayer``, ``MHFillStyleLayer``, and
 ``MHLineStyleLayer`` to configure the appearance of each kind of shape inside
 the collection.

 A shape collection feature is known as a
 <a href="https://tools.ietf.org/html/rfc7946#section-3.3">feature collection</a>
 in GeoJSON.

 #### Related examples
 TODO: Add multiple shapes from a single shape source, learn how to
 add shape data to your map using an ``MHShapeCollectionFeature`` object.
 */
MH_EXPORT
@interface MHShapeCollectionFeature : MHShapeCollection <MHFeature>

@property (nonatomic, copy, readonly) NSArray<MHShape<MHFeature> *> *shapes;

+ (instancetype)shapeCollectionWithShapes:(NSArray<MHShape<MHFeature> *> *)shapes;

@end

NS_ASSUME_NONNULL_END