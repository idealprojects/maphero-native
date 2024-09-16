#import <Mapbox.h>
#import <XCTest/XCTest.h>

#import <mbgl/util/geometry.hpp>
#import "MHFoundation_Private.h"
#import "../../darwin/src/MHFeature_Private.h"

@interface MHFeatureTests : XCTestCase

@end

@implementation MHFeatureTests

- (void)testGeometryConversion {
    std::vector<mbgl::Feature> features;

    mbgl::Point<double> point = { -90.066667, 29.95 };
    features.push_back(mbgl::Feature { point });

    mbgl::LineString<double> lineString = {
        { -84.516667, 39.1 },
        { -90.066667, 29.95 },
    };
    features.push_back(mbgl::Feature { lineString });

    mbgl::Polygon<double> polygon = {
        {
            { 1, 1 },
            { 4, 1 },
            { 4, 4 },
            { 1, 4 },
        },
        {
            { 2, 2 },
            { 3, 2 },
            { 3, 3 },
            { 2, 3 },
        },
    };
    features.push_back(mbgl::Feature { polygon });

    NSArray<MHShape <MHFeature> *> *shapes = MHFeaturesFromMBGLFeatures(features);
    XCTAssertEqual(shapes.count, 3UL, @"All features should be converted into shapes");

    MHPointFeatureClusterFeature *pointShape = (MHPointFeatureClusterFeature *)shapes[0];
    XCTAssertTrue([pointShape isKindOfClass:[MHPointFeatureClusterFeature class]]);
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:pointShape.coordinate],
                          [NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(29.95, -90.066667)]);

    MHPolylineFeature *polylineShape = (MHPolylineFeature *)shapes[1];
    XCTAssertTrue([polylineShape isKindOfClass:[MHPolylineFeature class]]);
    XCTAssertEqual(polylineShape.pointCount, 2UL);
    CLLocationCoordinate2D polylineCoordinates[2];
    [polylineShape getCoordinates:polylineCoordinates range:NSMakeRange(0, polylineShape.pointCount)];
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:polylineCoordinates[0]],
                          [NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(39.1, -84.516667)]);
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:polylineCoordinates[1]],
                          [NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(29.95, -90.066667)]);

    MHPolygonFeature *polygonShape = (MHPolygonFeature *)shapes[2];
    XCTAssertTrue([polygonShape isKindOfClass:[MHPolygonFeature class]]);
    XCTAssertEqual(polygonShape.pointCount, 4UL);
    CLLocationCoordinate2D *polygonCoordinates = polygonShape.coordinates;
    XCTAssertNotEqual(polygonCoordinates, nil);
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:polygonCoordinates[0]],
                          [NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(1, 1)]);
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:polygonCoordinates[1]],
                          [NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(1, 4)]);
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:polygonCoordinates[2]],
                          [NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(4, 4)]);
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:polygonCoordinates[3]],
                          [NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(4, 1)]);
    NSArray<MHPolygon *> *interiorPolygons = polygonShape.interiorPolygons;
    XCTAssertEqual(interiorPolygons.count, 1UL);
    MHPolygon *interiorPolygon = interiorPolygons.firstObject;
    XCTAssertEqual(interiorPolygon.pointCount, 4UL);
    CLLocationCoordinate2D interiorPolygonCoordinates[4];
    [interiorPolygon getCoordinates:interiorPolygonCoordinates range:NSMakeRange(0, interiorPolygon.pointCount)];
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:interiorPolygonCoordinates[0]],
                          [NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(2, 2)]);
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:interiorPolygonCoordinates[1]],
                          [NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(2, 3)]);
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:interiorPolygonCoordinates[2]],
                          [NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(3, 3)]);
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:interiorPolygonCoordinates[3]],
                          [NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(3, 2)]);
}

- (void)testClusterGeometryConversion {    
    mbgl::Point<double> point = { -90.066667, 29.95 };
    mbgl::Feature pointFeature { point };
    pointFeature.id = { UINT64_MAX };
    pointFeature.properties["cluster"] = true;
    pointFeature.properties["cluster_id"] = 1ULL;
    pointFeature.properties["point_count"] = 5ULL;
    
    id<MHFeature> feature = MHFeatureFromMBGLFeature(pointFeature);
    
    XCTAssert([feature conformsToProtocol:@protocol(MHFeature)]);
    
    id<MHCluster> cluster = MH_OBJC_DYNAMIC_CAST_AS_PROTOCOL(feature, MHCluster);
    XCTAssert(cluster);
    XCTAssert(cluster.clusterIdentifier == 1);
    XCTAssert(cluster.clusterPointCount == 5);
    
    XCTAssert([cluster isMemberOfClass:[MHPointFeatureClusterFeatureCluster class]]);
}

- (void)testPropertyConversion {
    std::vector<mbgl::Feature> features;

    mbgl::Point<double> point = { -90.066667, 29.95 };
    mbgl::Feature pointFeature { point };
    pointFeature.id = { UINT64_MAX };
    pointFeature.properties["null"] = mapbox::feature::null_value;
    pointFeature.properties["bool"] = true;
    pointFeature.properties["unsigned int"] = UINT64_MAX;
    pointFeature.properties["int"] = INT64_MIN;
    pointFeature.properties["double"] = DBL_MAX;
    pointFeature.properties["string"] = std::string("🚏");
    std::vector<bool> vector;
    vector.push_back(true);
    vector.push_back(false);
    vector.push_back(true);
    features.push_back(pointFeature);

    NSArray<MHShape <MHFeature> *> *shapes = MHFeaturesFromMBGLFeatures(features);
    XCTAssertEqual(shapes.count, 1UL, @"All features should be converted into shapes");

    MHShape <MHFeature> *shape = shapes.firstObject;
    XCTAssertTrue([shape conformsToProtocol:@protocol(MHFeature)]);
    XCTAssertTrue([shape isKindOfClass:[MHShape class]]);

    NSNumber *identifier = shape.identifier;
    XCTAssertTrue([identifier isKindOfClass:[NSNumber class]], @"Feature identifier should be NSNumber");
    XCTAssertEqual(strcmp(identifier.objCType, @encode(uint64_t)), 0, @"Feature identifier should be 64-bit unsigned integer");

    NSNull *null = [shape attributeForKey:@"null"];
    XCTAssertNotNil(null);
    XCTAssertTrue([null isKindOfClass:[NSNull class]]);
    XCTAssertEqual(null, shape.attributes[@"null"]);

    NSNumber *boolean = [shape attributeForKey:@"bool"];
    XCTAssertNotNil(boolean);
    XCTAssertTrue([boolean isKindOfClass:[NSNumber class]]);
    XCTAssertEqual(strcmp(boolean.objCType, @encode(char)), 0, @"Boolean property should be converted to bool NSNumber");
    XCTAssertTrue(boolean.boolValue);
    XCTAssertEqual(boolean, shape.attributes[@"bool"]);

    NSNumber *unsignedInteger = [shape attributeForKey:@"unsigned int"];
    XCTAssertNotNil(unsignedInteger);
    XCTAssertTrue([unsignedInteger isKindOfClass:[NSNumber class]]);
    XCTAssertEqual(strcmp(unsignedInteger.objCType, @encode(uint64_t)), 0, @"Unsigned integer property should be converted to unsigned long long NSNumber");
    XCTAssertEqual(unsignedInteger.unsignedLongLongValue, UINT64_MAX);
    XCTAssertEqual(unsignedInteger, shape.attributes[@"unsigned int"]);

    NSNumber *integer = [shape attributeForKey:@"int"];
    XCTAssertNotNil(integer);
    XCTAssertTrue([integer isKindOfClass:[NSNumber class]]);
    XCTAssertEqual(strcmp(integer.objCType, @encode(int64_t)), 0, @"Integer property should be converted to long long NSNumber");
    XCTAssertEqual(integer.longLongValue, INT64_MIN);
    XCTAssertEqual(integer, shape.attributes[@"int"]);

    NSNumber *floatingPointNumber = [shape attributeForKey:@"double"];
    XCTAssertNotNil(floatingPointNumber);
    XCTAssertTrue([floatingPointNumber isKindOfClass:[NSNumber class]]);
    XCTAssertEqual(strcmp(floatingPointNumber.objCType, @encode(double)), 0, @"Floating-point number property should be converted to double NSNumber");
    XCTAssertEqual(floatingPointNumber.doubleValue, DBL_MAX);
    XCTAssertEqual(floatingPointNumber, shape.attributes[@"double"]);

    NSString *string = [shape attributeForKey:@"string"];
    XCTAssertNotNil(string);
    XCTAssertTrue([string isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects(string, @"🚏");
    XCTAssertEqual(string, shape.attributes[@"string"]);
}

- (void)testPointFeatureGeoJSONDictionary {
    MHPointFeatureClusterFeature *pointFeature = [[MHPointFeatureClusterFeature alloc] init];
    CLLocationCoordinate2D coordinate = { 10, 10 };
    pointFeature.coordinate = coordinate;

    // A GeoJSON feature
    // when there are no identifier or properties
    NSDictionary *geoJSONFeature = [pointFeature geoJSONDictionary];

    // it has the correct type
    XCTAssertEqualObjects(geoJSONFeature[@"type"], @"Feature");
    // it has the correct geometry
    NSDictionary *expectedGeometry = @{@"type": @"Point",
                                       @"coordinates": @[@(coordinate.longitude), @(coordinate.latitude)]};
    XCTAssertEqualObjects(geoJSONFeature[@"geometry"], expectedGeometry);
    // it has no "id" key (or value)
    XCTAssertNil(geoJSONFeature[@"id"]);
    // it has a null representation of the properties object
    XCTAssertEqualObjects(geoJSONFeature[@"properties"], @{});

    // when there is a string identifier
    pointFeature.identifier = @"string-id";

    // it has the identifier in the result
    geoJSONFeature = [pointFeature geoJSONDictionary];
    XCTAssertEqualObjects(geoJSONFeature[@"id"], pointFeature.identifier);

    // when there are properties
    pointFeature.attributes = @{@"name": @"name-value"};

    // it has the properties value in the result
    geoJSONFeature = [pointFeature geoJSONDictionary];
    XCTAssertEqualObjects(geoJSONFeature[@"properties"], pointFeature.attributes);
}

- (void)testPolylineFeatureGeoJSONDictionary {
    CLLocationCoordinate2D coord1 = { 0, 0 };
    CLLocationCoordinate2D coord2 = { 10, 10 };
    CLLocationCoordinate2D coords[] = { coord1, coord2 };
    MHPolylineFeature *polyLineFeature = [MHPolylineFeature polylineWithCoordinates:coords count:2];

    // A GeoJSON feature
    NSDictionary *geoJSONFeature = [polyLineFeature geoJSONDictionary];

    // it has the correct geometry
    NSDictionary *expectedGeometry = @{@"type": @"LineString",
                                       @"coordinates": @[@[@(coord1.longitude), @(coord1.latitude)],
                                                         @[@(coord2.longitude), @(coord2.latitude)]]};
    XCTAssertEqualObjects(geoJSONFeature[@"geometry"], expectedGeometry);
}

- (void)testPolygonFeatureGeoJSONDictionary {
    CLLocationCoordinate2D coord1 = { 0, 0 };
    CLLocationCoordinate2D coord2 = { 10, 10 };
    CLLocationCoordinate2D coord3 = { 0, 0 };
    CLLocationCoordinate2D coords[] = { coord1, coord2, coord3 };
    MHPolygonFeature *polygonFeature = [MHPolygonFeature polygonWithCoordinates:coords count:3];

    // A GeoJSON feature
    NSDictionary *geoJSONFeature = [polygonFeature geoJSONDictionary];

    // it has the correct geometry
    NSDictionary *expectedGeometry = @{@"type": @"Polygon",
                                       @"coordinates": @[@[@[@(coord1.longitude), @(coord1.latitude)],
                                                         @[@(coord2.longitude), @(coord2.latitude)],
                                                         @[@(coord3.longitude), @(coord3.latitude)]]]};
    XCTAssertEqualObjects(geoJSONFeature[@"geometry"], expectedGeometry);
}

- (void)testMultiPolylineFeatureGeoJSONDictionary {
    CLLocationCoordinate2D coord1 = { 0, 0 };
    CLLocationCoordinate2D coord2 = { 10, 10 };
    CLLocationCoordinate2D coord3 = { 0, 0 };
    CLLocationCoordinate2D coords[] = { coord1, coord2, coord3 };

    MHPolyline *polyLine1 = [MHPolyline polylineWithCoordinates:coords count:3];
    MHPolyline *polyLine2 = [MHPolyline polylineWithCoordinates:coords count:3];

    MHMultiPolylineFeature *multiPolylineFeature = [MHMultiPolylineFeature multiPolylineWithPolylines:@[polyLine1, polyLine2]];

    // A GeoJSON feature
    NSDictionary *geoJSONFeature = [multiPolylineFeature geoJSONDictionary];

    // it has the correct geometry
    NSDictionary *expectedGeometry = @{@"type": @"MultiLineString",
                                       @"coordinates": @[@[@[@(coord1.longitude), @(coord1.latitude)],
                                                          @[@(coord2.longitude), @(coord2.latitude)],
                                                          @[@(coord3.longitude), @(coord3.latitude)]],
                                                        @[@[@(coord1.longitude), @(coord1.latitude)],
                                                          @[@(coord2.longitude), @(coord2.latitude)],
                                                          @[@(coord3.longitude), @(coord3.latitude)]]]};
    XCTAssertEqualObjects(geoJSONFeature[@"geometry"], expectedGeometry);
}

- (void)testMultiPolygonFeatureGeoJSONDictionary {
    CLLocationCoordinate2D coord1 = { 0, 0 };
    CLLocationCoordinate2D coord2 = { 10, 10 };
    CLLocationCoordinate2D coord3 = { 0, 0 };
    CLLocationCoordinate2D coords[] = { coord1, coord2, coord3 };

    MHPolygon *polygon1 = [MHPolygon polygonWithCoordinates:coords count:3];
    MHPolygon *polygon2 = [MHPolygon polygonWithCoordinates:coords count:3];

    MHMultiPolygonFeature *multiPolylineFeature = [MHMultiPolygonFeature multiPolygonWithPolygons:@[polygon1, polygon2]];

    // A GeoJSON feature
    NSDictionary *geoJSONFeature = [multiPolylineFeature geoJSONDictionary];

    // it has the correct geometry
    NSDictionary *expectedGeometry = @{@"type": @"MultiPolygon",
                                       @"coordinates": @[
                                               @[@[@[@(coord1.longitude), @(coord1.latitude)],
                                                   @[@(coord2.longitude), @(coord2.latitude)],
                                                   @[@(coord3.longitude), @(coord3.latitude)]]],
                                                   @[@[@[@(coord1.longitude), @(coord1.latitude)],
                                                   @[@(coord2.longitude), @(coord2.latitude)],
                                                   @[@(coord3.longitude), @(coord3.latitude)]]]]};
    XCTAssertEqualObjects(geoJSONFeature[@"geometry"], expectedGeometry);
}

- (void)testPointCollectionFeatureGeoJSONDictionary {
    CLLocationCoordinate2D coord1 = { 0, 0 };
    CLLocationCoordinate2D coord2 = { 10, 10 };
    CLLocationCoordinate2D coord3 = { 0, 0 };
    CLLocationCoordinate2D coords[] = { coord1, coord2, coord3 };
    MHPointCollectionFeature *pointCollectionFeature = [MHPointCollectionFeature pointCollectionWithCoordinates:coords count:3];

    // A GeoJSON feature
    NSDictionary *geoJSONFeature = [pointCollectionFeature geoJSONDictionary];

    // it has the correct geometry
    NSDictionary *expectedGeometry = @{@"type": @"MultiPoint",
                                       @"coordinates": @[@[@(coord1.longitude), @(coord1.latitude)],
                                                         @[@(coord2.longitude), @(coord2.latitude)],
                                                         @[@(coord3.longitude), @(coord3.latitude)]]};
    XCTAssertEqualObjects(geoJSONFeature[@"geometry"], expectedGeometry);

}

- (void)testShapeCollectionFeatureGeoJSONDictionary {
    MHPointFeatureClusterFeature *pointFeature = [[MHPointFeatureClusterFeature alloc] init];
    CLLocationCoordinate2D pointCoordinate = { 10, 10 };
    pointFeature.coordinate = pointCoordinate;

    CLLocationCoordinate2D coord1 = { 0, 0 };
    CLLocationCoordinate2D coord2 = { 10, 10 };
    CLLocationCoordinate2D coords[] = { coord1, coord2 };
    MHPolylineFeature *polylineFeature = [MHPolylineFeature polylineWithCoordinates:coords count:2];

    MHShapeCollectionFeature *shapeCollectionFeature = [MHShapeCollectionFeature shapeCollectionWithShapes:@[pointFeature, polylineFeature]];

    // A GeoJSON feature
    NSDictionary *geoJSONFeature = [shapeCollectionFeature geoJSONDictionary];

    // it has the correct geometry
    NSDictionary *expectedGeometry = @{@"type": @"GeometryCollection",
                                       @"geometries": @[
                                           @{ @"geometry": @{@"type": @"Point",
                                                             @"coordinates": @[@(pointCoordinate.longitude), @(pointCoordinate.latitude)]},
                                              @"properties": @{},
                                              @"type": @"Feature",
                                             },
                                            @{ @"geometry": @{@"type": @"LineString",
                                                              @"coordinates": @[@[@(coord1.longitude), @(coord1.latitude)],
                                                                                @[@(coord2.longitude), @(coord2.latitude)]]},
                                               @"properties": @{},
                                               @"type": @"Feature",
                                            }
                                        ]
                                    };
    XCTAssertEqualObjects(geoJSONFeature[@"geometry"], expectedGeometry);

    // When the shape collection is created with an empty array of shapes
    shapeCollectionFeature = [MHShapeCollectionFeature shapeCollectionWithShapes:@[]];

    // it has the correct (empty) geometry
    geoJSONFeature = [shapeCollectionFeature geoJSONDictionary];
    expectedGeometry = @{@"type": @"GeometryCollection",
                         @"geometries": @[]};
    XCTAssertEqualObjects(geoJSONFeature[@"geometry"], expectedGeometry);
}

@end
