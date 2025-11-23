#import "MHFoundation_Private.h"
#import "MHFeature_Private.h"
#import "MHCluster.h"

#import "MHPointAnnotation.h"
#import "MHPolyline.h"
#import "MHPolygon.h"
#import "MHValueEvaluator.h"

#import "MHShape_Private.h"
#import "MHPointCollection_Private.h"
#import "MHPolyline_Private.h"
#import "MHPolygon_Private.h"

#import "NSDictionary+MHAdditions.h"
#import "NSArray+MHAdditions.h"
#import "NSExpression+MHPrivateAdditions.h"
#import "MHLoggingConfiguration_Private.h"

#import <mbgl/util/geometry.hpp>
#import <mbgl/style/conversion/geojson.hpp>
#import <mapbox/feature.hpp>

// Cluster constants
static NSString * const MHClusterIdentifierKey = @"cluster_id";
static NSString * const MHClusterCountKey = @"point_count";
const NSUInteger MHClusterIdentifierInvalid = NSUIntegerMax;

@interface MHEmptyFeature ()
@end

@implementation MHEmptyFeature

@synthesize identifier;
@synthesize attributes = _attributes;

MH_DEFINE_FEATURE_INIT_WITH_CODER();
MH_DEFINE_FEATURE_ENCODE();
MH_DEFINE_FEATURE_IS_EQUAL();
MH_DEFINE_FEATURE_ATTRIBUTES_GETTER();

- (id)attributeForKey:(NSString *)key {
    MHLogDebug(@"Retrieving attributeForKey: %@", key);
    return self.attributes[key];
}

- (NSDictionary *)geoJSONDictionary {
    return NSDictionaryFeatureForGeometry([super geoJSONDictionary], self.attributes, self.identifier);
}

- (mbgl::GeoJSON)geoJSONObject {
    return mbglFeature({[self geometryObject]}, identifier, self.attributes);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; identifier = %@, attributes = %@>",
            NSStringFromClass([self class]), (void *)self,
            self.identifier ? [NSString stringWithFormat:@"\"%@\"", self.identifier] : self.identifier,
            self.attributes.count ? self.attributes : @"none"];
}

@end

@interface MHPointFeature ()
@end

@implementation MHPointFeature

@synthesize identifier;
@synthesize attributes = _attributes;

MH_DEFINE_FEATURE_INIT_WITH_CODER();
MH_DEFINE_FEATURE_ENCODE();
MH_DEFINE_FEATURE_IS_EQUAL();
MH_DEFINE_FEATURE_ATTRIBUTES_GETTER();

- (id)attributeForKey:(NSString *)key {
    MHLogDebug(@"Retrieving attributeForKey: %@", key);
    return self.attributes[key];
}

- (NSDictionary *)geoJSONDictionary {
    return NSDictionaryFeatureForGeometry([super geoJSONDictionary], self.attributes, self.identifier);
}

- (mbgl::GeoJSON)geoJSONObject {
    return mbglFeature({[self geometryObject]}, identifier, self.attributes);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; identifier = %@, coordinate = %f, %f, attributes = %@>",
            NSStringFromClass([self class]), (void *)self,
            self.identifier ? [NSString stringWithFormat:@"\"%@\"", self.identifier] : self.identifier,
            self.coordinate.latitude, self.coordinate.longitude,
            self.attributes.count ? self.attributes : @"none"];
}

@end

@implementation MHPointFeatureCluster

- (NSUInteger)clusterIdentifier {
    NSNumber *clusterNumber = MH_OBJC_DYNAMIC_CAST([self attributeForKey:MHClusterIdentifierKey], NSNumber);
    MHAssert(clusterNumber, @"Clusters should have a cluster_id");
    
    if (!clusterNumber) {
        return MHClusterIdentifierInvalid;
    }
    
    NSUInteger clusterIdentifier = [clusterNumber unsignedIntegerValue];
    MHAssert(clusterIdentifier <= UINT32_MAX, @"Cluster identifiers are 32bit");
    
    return clusterIdentifier;
}

- (NSUInteger)clusterPointCount {
    NSNumber *count = MH_OBJC_DYNAMIC_CAST([self attributeForKey:MHClusterCountKey], NSNumber);
    MHAssert(count, @"Clusters should have a point_count");
    
    return [count unsignedIntegerValue];
}
@end


@interface MHPolylineFeature ()
@end

@implementation MHPolylineFeature

@synthesize identifier;
@synthesize attributes = _attributes;

MH_DEFINE_FEATURE_INIT_WITH_CODER();
MH_DEFINE_FEATURE_ENCODE();
MH_DEFINE_FEATURE_IS_EQUAL();
MH_DEFINE_FEATURE_ATTRIBUTES_GETTER();

- (id)attributeForKey:(NSString *)key {
    MHLogDebug(@"Retrieving attributeForKey: %@", key);
    return self.attributes[key];
}

- (NSDictionary *)geoJSONDictionary {
    return NSDictionaryFeatureForGeometry([super geoJSONDictionary], self.attributes, self.identifier);
}

- (mbgl::GeoJSON)geoJSONObject {
    return mbglFeature({[self geometryObject]}, identifier, self.attributes);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; identifier = %@, count = %lu, bounds = %@, attributes = %@>",
            NSStringFromClass([self class]), (void *)self,
            self.identifier ? [NSString stringWithFormat:@"\"%@\"", self.identifier] : self.identifier,
            (unsigned long)[self pointCount],
            MHStringFromCoordinateBounds(self.overlayBounds),
            self.attributes.count ? self.attributes : @"none"];
}

@end

@interface MHPolygonFeature ()
@end

@implementation MHPolygonFeature

@synthesize identifier;
@synthesize attributes = _attributes;

MH_DEFINE_FEATURE_INIT_WITH_CODER();
MH_DEFINE_FEATURE_ENCODE();
MH_DEFINE_FEATURE_IS_EQUAL();
MH_DEFINE_FEATURE_ATTRIBUTES_GETTER();

- (id)attributeForKey:(NSString *)key {
    MHLogDebug(@"Retrieving attributeForKey: %@", key);
    return self.attributes[key];
}

- (NSDictionary *)geoJSONDictionary {
    return NSDictionaryFeatureForGeometry([super geoJSONDictionary], self.attributes, self.identifier);
}

- (mbgl::GeoJSON)geoJSONObject {
    return mbglFeature({[self geometryObject]}, identifier, self.attributes);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; identifier = %@, count = %lu, bounds = %@, attributes = %@>",
            NSStringFromClass([self class]), (void *)self,
            self.identifier ? [NSString stringWithFormat:@"\"%@\"", self.identifier] : self.identifier,
            (unsigned long)[self pointCount],
            MHStringFromCoordinateBounds(self.overlayBounds),
            self.attributes.count ? self.attributes : @"none"];
}

@end

@interface MHPointCollectionFeature ()
@end

@implementation MHPointCollectionFeature

@synthesize identifier;
@synthesize attributes = _attributes;

MH_DEFINE_FEATURE_INIT_WITH_CODER();
MH_DEFINE_FEATURE_ENCODE();
MH_DEFINE_FEATURE_IS_EQUAL();
MH_DEFINE_FEATURE_ATTRIBUTES_GETTER();

- (id)attributeForKey:(NSString *)key {
    MHLogDebug(@"Retrieving attributeForKey: %@", key);
    return self.attributes[key];
}

- (NSDictionary *)geoJSONDictionary {
    return NSDictionaryFeatureForGeometry([super geoJSONDictionary], self.attributes, self.identifier);
}

- (mbgl::GeoJSON)geoJSONObject {
    return mbglFeature({[self geometryObject]}, identifier, self.attributes);
}

@end

@interface MHMultiPolylineFeature ()
@end

@implementation MHMultiPolylineFeature

@synthesize identifier;
@synthesize attributes = _attributes;

MH_DEFINE_FEATURE_INIT_WITH_CODER();
MH_DEFINE_FEATURE_ENCODE();
MH_DEFINE_FEATURE_IS_EQUAL();
MH_DEFINE_FEATURE_ATTRIBUTES_GETTER();

- (id)attributeForKey:(NSString *)key {
    MHLogDebug(@"Retrieving attributeForKey: %@", key);
    return self.attributes[key];
}

- (NSDictionary *)geoJSONDictionary {
    return NSDictionaryFeatureForGeometry([super geoJSONDictionary], self.attributes, self.identifier);
}

- (mbgl::GeoJSON)geoJSONObject {
    return mbglFeature({[self geometryObject]}, identifier, self.attributes);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; identifier = %@, count = %lu, bounds = %@, attributes = %@>",
            NSStringFromClass([self class]), (void *)self,
            self.identifier ? [NSString stringWithFormat:@"\"%@\"", self.identifier] : self.identifier,
            (unsigned long)self.polylines.count,
            MHStringFromCoordinateBounds(self.overlayBounds),
            self.attributes.count ? self.attributes : @"none"];
}

@end

@interface MHMultiPolygonFeature ()
@end

@implementation MHMultiPolygonFeature

@synthesize identifier;
@synthesize attributes = _attributes;

MH_DEFINE_FEATURE_INIT_WITH_CODER();
MH_DEFINE_FEATURE_ENCODE();
MH_DEFINE_FEATURE_IS_EQUAL();
MH_DEFINE_FEATURE_ATTRIBUTES_GETTER();

- (id)attributeForKey:(NSString *)key {
    MHLogDebug(@"Retrieving attributeForKey: %@", key);
    return self.attributes[key];
}

- (NSDictionary *)geoJSONDictionary {
    return NSDictionaryFeatureForGeometry([super geoJSONDictionary], self.attributes, self.identifier);
}

- (mbgl::GeoJSON)geoJSONObject {
    return mbglFeature({[self geometryObject]}, identifier, self.attributes);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; identifier = %@, count = %lu, bounds = %@, attributes = %@>",
            NSStringFromClass([self class]), (void *)self,
            self.identifier ? [NSString stringWithFormat:@"\"%@\"", self.identifier] : self.identifier,
            (unsigned long)self.polygons.count,
            MHStringFromCoordinateBounds(self.overlayBounds),
            self.attributes.count ? self.attributes : @"none"];
}

@end

@interface MHShapeCollectionFeature ()
@end

@implementation MHShapeCollectionFeature

@synthesize identifier;
@synthesize attributes = _attributes;

@dynamic shapes;

+ (instancetype)shapeCollectionWithShapes:(NSArray<MHShape<MHFeature> *> *)shapes {
    return [super shapeCollectionWithShapes:shapes];
}

MH_DEFINE_FEATURE_INIT_WITH_CODER();
MH_DEFINE_FEATURE_ENCODE();
MH_DEFINE_FEATURE_IS_EQUAL();
MH_DEFINE_FEATURE_ATTRIBUTES_GETTER();

- (id)attributeForKey:(NSString *)key {
    return self.attributes[key];
}

- (NSDictionary *)geoJSONDictionary {
    return NSDictionaryFeatureForGeometry([super geoJSONDictionary], self.attributes, self.identifier);
}

- (mbgl::GeoJSON)geoJSONObject {
    mbgl::FeatureCollection featureCollection;
    featureCollection.reserve(self.shapes.count);
    for (MHShape <MHFeature> *feature in self.shapes) {
        auto geoJSONObject = feature.geoJSONObject;
        MHAssert(geoJSONObject.is<mbgl::GeoJSONFeature>(), @"Feature collection must only contain features.");
        featureCollection.push_back(geoJSONObject.get<mbgl::GeoJSONFeature>());
    }
    return featureCollection;
}

@end

/**
 Transforms an `mbgl::geometry::geometry` type into an instance of the
 corresponding Objective-C geometry class.
 */
template <typename T>
class GeometryEvaluator {
private:
    const mbgl::PropertyMap *shared_properties;
    const bool is_in_feature;
    
public:
    GeometryEvaluator(const mbgl::PropertyMap *properties = nullptr, const bool isInFeature = false):
        shared_properties(properties),
        is_in_feature(isInFeature)
    {}
    
    MHShape * operator()(const mbgl::EmptyGeometry &) const {
        return is_in_feature ? [[MHEmptyFeature alloc] init] : [[MHShape alloc] init];
    }

    MHShape * operator()(const mbgl::Point<T> &geometry) const {
        Class shapeClass = is_in_feature ? [MHPointFeature class] : [MHPointAnnotation class];
        
        // If we're dealing with a cluster, we should change the class type.
        // This could be generic and build the subclass at runtime if it turns
        // out we need to support more than point clusters.
        if (shared_properties) {
            auto clusterIt = shared_properties->find("cluster");
            if (clusterIt != shared_properties->end()) {
                auto clusterValue = clusterIt->second;
                if (clusterValue.template is<bool>()) {
                    if (clusterValue.template get<bool>()) {
                        shapeClass = [MHPointFeatureCluster class];
                    }
                }
            }
        }
        
        MHPointAnnotation *shape = [[shapeClass alloc] init];
        shape.coordinate = toLocationCoordinate2D(geometry);
        return shape;
    }

    MHShape * operator()(const mbgl::LineString<T> &geometry) const {
        std::vector<CLLocationCoordinate2D> coordinates = toLocationCoordinates2D(geometry);
        Class shapeClass = is_in_feature ? [MHPolylineFeature class] : [MHPolyline class];
        return [shapeClass polylineWithCoordinates:&coordinates[0] count:coordinates.size()];
    }

    MHShape * operator()(const mbgl::Polygon<T> &geometry) const {
        return toShape<MHPolygon, MHPolygonFeature>(geometry, is_in_feature);
    }

    MHShape * operator()(const mbgl::MultiPoint<T> &geometry) const {
        std::vector<CLLocationCoordinate2D> coordinates = toLocationCoordinates2D(geometry);
        Class shapeClass = is_in_feature ? [MHPointCollectionFeature class] : [MHPointCollection class];
        return [[shapeClass alloc] initWithCoordinates:&coordinates[0] count:coordinates.size()];
    }

    MHShape * operator()(const mbgl::MultiLineString<T> &geometry) const {
        NSMutableArray *polylines = [NSMutableArray arrayWithCapacity:geometry.size()];
        for (auto &lineString : geometry) {
            std::vector<CLLocationCoordinate2D> coordinates = toLocationCoordinates2D(lineString);
            MHPolyline *polyline = [MHPolyline polylineWithCoordinates:&coordinates[0] count:coordinates.size()];
            [polylines addObject:polyline];
        }

        Class shapeClass = is_in_feature ? [MHMultiPolylineFeature class] : [MHMultiPolyline class];
        return [shapeClass multiPolylineWithPolylines:polylines];
    }

    MHShape * operator()(const mbgl::MultiPolygon<T> &geometry) const {
        NSMutableArray *polygons = [NSMutableArray arrayWithCapacity:geometry.size()];
        for (auto &polygon : geometry) {
            [polygons addObject:toShape(polygon, false)];
        }

        Class shapeClass = is_in_feature ? [MHMultiPolygonFeature class] : [MHMultiPolygon class];
        return [shapeClass multiPolygonWithPolygons:polygons];
    }

    MHShape * operator()(const mapbox::geometry::geometry_collection<T> &collection) const {
        NSMutableArray *shapes = [NSMutableArray arrayWithCapacity:collection.size()];
        for (auto &geometry : collection) {
            // This is very much like the transformation that happens in MHFeaturesFromMBGLFeatures(), but these are raw geometries with no associated feature IDs or attributes.
            MHShape *shape = mapbox::geometry::geometry<T>::visit(geometry, *this);
            [shapes addObject:shape];
        }
        Class shapeClass = is_in_feature ? [MHShapeCollectionFeature class] : [MHShapeCollection class];
        return [shapeClass shapeCollectionWithShapes:shapes];
    }

private:
    static CLLocationCoordinate2D toLocationCoordinate2D(const mbgl::Point<T> &point) {
        return CLLocationCoordinate2DMake(point.y, point.x);
    }

    static std::vector<CLLocationCoordinate2D> toLocationCoordinates2D(const std::vector<mbgl::Point<T>> &points) {
        std::vector<CLLocationCoordinate2D> coordinates;
        coordinates.reserve(points.size());
        std::transform(points.begin(), points.end(), std::back_inserter(coordinates), toLocationCoordinate2D);
        return coordinates;
    }

    template<typename U = MHPolygon, typename V = MHPolygonFeature>
    static U *toShape(const mbgl::Polygon<T> &geometry, const bool isInFeature) {
        auto &linearRing = geometry.front();
        std::vector<CLLocationCoordinate2D> coordinates = toLocationCoordinates2D(linearRing);
        NSMutableArray *innerPolygons;
        if (geometry.size() > 1) {
            innerPolygons = [NSMutableArray arrayWithCapacity:geometry.size() - 1];
            for (auto iter = geometry.begin() + 1; iter != geometry.end(); iter++) {
                auto &innerRing = *iter;
                std::vector<CLLocationCoordinate2D> innerCoordinates = toLocationCoordinates2D(innerRing);
                MHPolygon *innerPolygon = [MHPolygon polygonWithCoordinates:&innerCoordinates[0] count:innerCoordinates.size()];
                [innerPolygons addObject:innerPolygon];
            }
        }

        Class shapeClass = isInFeature ? [V class] : [U class];
        return [shapeClass polygonWithCoordinates:&coordinates[0] count:coordinates.size() interiorPolygons:innerPolygons];
    }
};

template <typename T>
class GeoJSONEvaluator {
public:
    MHShape * operator()(const mbgl::Geometry<T> &geometry) const {
        GeometryEvaluator<T> evaluator;
        MHShape *shape = mapbox::geometry::geometry<T>::visit(geometry, evaluator);
        return shape;
    }

    MHShape <MHFeature> * operator()(const mbgl::GeoJSONFeature &feature) const {
        MHShape <MHFeature> *shape = (MHShape <MHFeature> *)MHFeatureFromMBGLFeature(feature);
        return shape;
    }

    MHShape <MHFeature> * operator()(const mbgl::FeatureCollection &collection) const {
        NSMutableArray *shapes = [NSMutableArray arrayWithCapacity:collection.size()];
        for (const auto &feature : collection) {
            [shapes addObject:MHFeatureFromMBGLFeature(feature)];
        }
        return [MHShapeCollectionFeature shapeCollectionWithShapes:shapes];
    }
};

NSArray<MHShape <MHFeature> *> *MHFeaturesFromMBGLFeatures(const std::vector<mbgl::Feature> &features) {
    NSMutableArray *shapes = [NSMutableArray arrayWithCapacity:features.size()];
    for (const auto &feature : features) {
        [shapes addObject:MHFeatureFromMBGLFeature(static_cast<mbgl::GeoJSONFeature>(feature))];
    }
    return shapes;
}

NSArray<MHShape <MHFeature> *> *MHFeaturesFromMBGLFeatures(const std::vector<mbgl::GeoJSONFeature> &features) {
    NSMutableArray *shapes = [NSMutableArray arrayWithCapacity:features.size()];
    for (const auto &feature : features) {
        [shapes addObject:MHFeatureFromMBGLFeature(feature)];
    }
    return shapes;
}

id <MHFeature> MHFeatureFromMBGLFeature(const mbgl::GeoJSONFeature &feature) {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:feature.properties.size()];
    for (auto &pair : feature.properties) {
        auto &value = pair.second;
        ValueEvaluator evaluator;
        attributes[@(pair.first.c_str())] = mbgl::Value::visit(value, evaluator);
    }
    GeometryEvaluator<double> evaluator(&feature.properties, true);
    MHShape <MHFeature> *shape = (MHShape <MHFeature> *)mapbox::geometry::geometry<double>::visit(feature.geometry, evaluator);
    if (!feature.id.is<mapbox::feature::null_value_t>()) {
        shape.identifier = mbgl::FeatureIdentifier::visit(feature.id, ValueEvaluator());
    }
    shape.attributes = attributes;

    return shape;
}

MHShape* MHShapeFromGeoJSON(const mapbox::geojson::geojson &geojson) {
    GeoJSONEvaluator<double> evaluator;
    MHShape *shape = mapbox::geojson::geojson::visit(geojson, evaluator);
    return shape;
}

mbgl::GeoJSONFeature mbglFeature(mbgl::GeoJSONFeature feature, id identifier, NSDictionary *attributes)
{
    if (identifier) {
        NSExpression *identifierExpression = [NSExpression expressionForConstantValue:identifier];
        feature.id = [identifierExpression mgl_featureIdentifier];
    }
    feature.properties = [attributes mgl_propertyMap];
    return feature;
}

NSDictionary<NSString *, id> *NSDictionaryFeatureForGeometry(NSDictionary *geometry, NSDictionary *attributes, id identifier) {
    NSMutableDictionary *feature = [@{@"type": @"Feature",
                                      @"properties": attributes,
                                      @"geometry": geometry} mutableCopy];
    feature[@"id"] = identifier;
    return [feature copy];
}
