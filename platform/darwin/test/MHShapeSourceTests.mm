#import <XCTest/XCTest.h>

#import <Mapbox.h>
#import "MHFeature_Private.h"
#import "MHShapeSource_Private.h"
#import "MHSource_Private.h"

#include <mbgl/style/sources/geojson_source.hpp>

@interface MHShapeSourceTests : XCTestCase
@end

@implementation MHShapeSourceTests

- (void)testGeoJSONOptionsFromDictionary {
    NSExpression *reduceExpression = [NSExpression expressionForFunction:@"sum:" arguments:@[[NSExpression expressionForKeyPath:@"featureAccumulated"], [NSExpression expressionForKeyPath:@"sumValue"]]];
    NSExpression *mapExpression = [NSExpression expressionForKeyPath:@"mag"];
    NSArray *clusterPropertyArray = @[reduceExpression, mapExpression];
    NSDictionary *options = @{MHShapeSourceOptionClustered: @YES,
                              MHShapeSourceOptionClusterRadius: @42,
                              MHShapeSourceOptionClusterProperties: @{@"sumValue": clusterPropertyArray},
                              MHShapeSourceOptionMaximumZoomLevelForClustering: @98,
                              MHShapeSourceOptionMaximumZoomLevel: @99,
                              MHShapeSourceOptionBuffer: @1976,
                              MHShapeSourceOptionSimplificationTolerance: @0.42,
                              MHShapeSourceOptionLineDistanceMetrics: @YES};

    auto mbglOptions = MHGeoJSONOptionsFromDictionary(options);
    XCTAssertTrue(mbglOptions->cluster);
    XCTAssertEqual(mbglOptions->clusterRadius, 42);
    XCTAssertEqual(mbglOptions->clusterMaxZoom, 98);
    XCTAssertEqual(mbglOptions->maxzoom, 99);
    XCTAssertEqual(mbglOptions->buffer, 1976);
    XCTAssertEqual(mbglOptions->tolerance, 0.42);
    XCTAssertTrue(mbglOptions->lineMetrics);
    XCTAssertTrue(!mbglOptions->clusterProperties.empty());

    options = @{MHShapeSourceOptionClustered: @"number 1"};
    XCTAssertThrows(MHGeoJSONOptionsFromDictionary(options));
}

- (void)testNilShape {
    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"id" shape:nil options:nil];
    XCTAssertNil(source.shape);
}

- (void)testUnclusterableShape {
    NSDictionary *options = @{
        MHShapeSourceOptionClustered: @YES,
    };

    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"id" shape:[[MHPointFeatureClusterFeature alloc] init] options:options];
    XCTAssertTrue([source.shape isKindOfClass:[MHPointFeatureClusterFeature class]]);

    MHShapeCollectionFeature *feature = [MHShapeCollectionFeature shapeCollectionWithShapes:@[]];
    source = [[MHShapeSource alloc] initWithIdentifier:@"id" shape:feature options:options];
    XCTAssertTrue([source.shape isKindOfClass:[MHShapeCollectionFeature class]]);
}

- (void)testMHShapeSourceWithDataMultipleFeatures {

    NSString *geoJSON = @"{\"type\": \"FeatureCollection\",\"features\": [{\"type\": \"Feature\",\"properties\": {},\"geometry\": {\"type\": \"LineString\",\"coordinates\": [[-107.75390625,40.329795743702064],[-104.34814453125,37.64903402157866]]}}]}";

    NSData *data = [geoJSON dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    MHShape *shape = [MHShape shapeWithData:data encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(shape);
    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"source-id" shape:shape options:nil];

    MHShapeCollection *collection = (MHShapeCollection *)source.shape;
    XCTAssertNotNil(collection);
    XCTAssertEqual(collection.shapes.count, 1UL);
    XCTAssertTrue([collection.shapes.firstObject isMemberOfClass:[MHPolylineFeature class]]);
}

- (void)testMHShapeSourceWithSingleGeometry {
    NSData *data = [@"{\"type\": \"Point\", \"coordinates\": [0, 0]}" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    MHShape *shape = [MHShape shapeWithData:data encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(shape);
    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"geojson" shape:shape options:nil];
    XCTAssertNotNil(source.shape);
    XCTAssert([source.shape isKindOfClass:[MHPointAnnotation class]]);
}

- (void)testMHGeoJSONSourceWithSingleFeature {
    NSString *geoJSON = @"{\"type\": \"Feature\", \"properties\": {\"color\": \"green\"}, \"geometry\": { \"type\": \"Point\", \"coordinates\": [ -114.06847000122069, 51.050459433092655 ] }}";
    NSData *data = [geoJSON dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    MHShape *shape = [MHShape shapeWithData:data encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(shape);
    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"geojson" shape:shape options:nil];
    XCTAssertNotNil(source.shape);
    XCTAssert([source.shape isKindOfClass:[MHPointFeatureClusterFeature class]]);
    MHPointFeatureClusterFeature *feature = (MHPointFeatureClusterFeature *)source.shape;
    XCTAssert([feature.attributes.allKeys containsObject:@"color"]);
}

- (void)testMHShapeSourceWithPolylineFeatures {
    CLLocationCoordinate2D coordinates[] = { CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(10, 10)};
    MHPolylineFeature *polylineFeature = [MHPolylineFeature polylineWithCoordinates:coordinates count:2];

    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"source-id" shape:polylineFeature options:nil];

    XCTAssertNotNil(source.shape);
    XCTAssertTrue([source.shape isMemberOfClass:[MHPolylineFeature class]]);
}

- (void)testMHShapeSourceWithPolygonFeatures {
    CLLocationCoordinate2D coordinates[] = {
        CLLocationCoordinate2DMake(0.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 100.0)};

    MHPolygonFeature *polygonFeature = [MHPolygonFeature polygonWithCoordinates:coordinates count:5];
    polygonFeature.identifier = @"feature-id";
    NSString *stringAttribute = @"string";
    NSNumber *boolAttribute = [NSNumber numberWithBool:YES];
    NSNumber *doubleAttribute = [NSNumber numberWithDouble:1.23];
    NSDictionary *nestedDictionaryValue = @{@"nested-key-1": @"nested-string-value"};
    NSArray *arrayValue = @[@"string-value", @2];
    NSDictionary *dictionaryValue = @{@"key-1": @"string-value",
                                      @"key-2": @1,
                                      @"key-3": nestedDictionaryValue,
                                      @"key-4": arrayValue};
    NSArray *arrayOfArrays = @[@[@1, @"string-value", @[@"jagged"]]];
    NSArray *arrayOfDictionaries = @[@{@"key": @"value"}];

    polygonFeature.attributes = @{@"name": stringAttribute,
                                  @"bool": boolAttribute,
                                  @"double": doubleAttribute,
                                  @"dictionary-attribute": dictionaryValue,
                                  @"array-attribute": arrayValue,
                                  @"array-of-array-attribute": arrayOfArrays,
                                  @"array-of-dictionary-attribute": arrayOfDictionaries};

    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"source-id" shape:polygonFeature options:nil];

    XCTAssertNotNil(source.shape);
    MHPolygonFeature *expectedPolygonFeature = (MHPolygonFeature *)source.shape;
    XCTAssertEqualObjects(expectedPolygonFeature.identifier, polygonFeature.identifier);
    XCTAssertTrue([expectedPolygonFeature isMemberOfClass:[MHPolygonFeature class]]);
    XCTAssertEqualObjects(expectedPolygonFeature.identifier, polygonFeature.identifier);
    XCTAssertEqualObjects(expectedPolygonFeature.attributes[@"name"], stringAttribute);
    XCTAssertEqualObjects(expectedPolygonFeature.attributes[@"bool"], boolAttribute);
    XCTAssertEqualObjects(expectedPolygonFeature.attributes[@"double"], doubleAttribute);
    XCTAssertEqualObjects(expectedPolygonFeature.attributes[@"dictionary-attribute"], dictionaryValue);
    XCTAssertEqualObjects(expectedPolygonFeature.attributes[@"array-attribute"], arrayValue);
    XCTAssertEqualObjects(expectedPolygonFeature.attributes[@"array-of-array-attribute"], arrayOfArrays);
    XCTAssertEqualObjects(expectedPolygonFeature.attributes[@"array-of-dictionary-attribute"], arrayOfDictionaries);
}

- (void)testMHShapeSourceWithPolygonFeaturesInculdingInteriorPolygons {
    CLLocationCoordinate2D coordinates[] = {
        CLLocationCoordinate2DMake(0.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 100.0)};

    CLLocationCoordinate2D interiorCoordinates[] = {
        CLLocationCoordinate2DMake(0.2, 100.2),
        CLLocationCoordinate2DMake(0.2, 100.8),
        CLLocationCoordinate2DMake(0.8, 100.8),
        CLLocationCoordinate2DMake(0.8, 100.2),
        CLLocationCoordinate2DMake(0.2, 100.2)};

    MHPolygon *polygon = [MHPolygon polygonWithCoordinates:interiorCoordinates count:5];

    MHPolygonFeature *polygonFeature = [MHPolygonFeature polygonWithCoordinates:coordinates count:5 interiorPolygons:@[polygon]];

    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"source-id" shape:polygonFeature options:nil];

    XCTAssertNotNil(source.shape);
    XCTAssertTrue([source.shape isMemberOfClass:[MHPolygonFeature class]]);
}

- (void)testMHShapeSourceWithMultiPolylineFeatures {
    CLLocationCoordinate2D firstCoordinates[] = { CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(10, 10)};
    MHPolylineFeature *firstPolylineFeature = [MHPolylineFeature polylineWithCoordinates:firstCoordinates count:2];
    CLLocationCoordinate2D secondCoordinates[] = { CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(10, 10)};
    MHPolylineFeature *secondPolylineFeature = [MHPolylineFeature polylineWithCoordinates:secondCoordinates count:2];
    MHMultiPolylineFeature *multiPolylineFeature = [MHMultiPolylineFeature multiPolylineWithPolylines:@[firstPolylineFeature, secondPolylineFeature]];

    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"source-id" shape:multiPolylineFeature options:nil];

    XCTAssertNotNil(source.shape);
    XCTAssertTrue([source.shape isMemberOfClass:[MHMultiPolylineFeature class]]);
}

- (void)testMHShapeSourceWithMultiPolygonFeatures {
    CLLocationCoordinate2D coordinates[] = {
        CLLocationCoordinate2DMake(0.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 100.0)};

    CLLocationCoordinate2D interiorCoordinates[] = {
        CLLocationCoordinate2DMake(0.2, 100.2),
        CLLocationCoordinate2DMake(0.2, 100.8),
        CLLocationCoordinate2DMake(0.8, 100.8),
        CLLocationCoordinate2DMake(0.8, 100.2),
        CLLocationCoordinate2DMake(0.2, 100.2)};

    MHPolygon *polygon = [MHPolygon polygonWithCoordinates:interiorCoordinates count:5];

    MHPolygonFeature *firstPolygon = [MHPolygonFeature polygonWithCoordinates:coordinates count:5 interiorPolygons:@[polygon]];
    MHPolygonFeature *secondPolygon = [MHPolygonFeature polygonWithCoordinates:coordinates count:5 interiorPolygons:@[polygon]];

    MHMultiPolygonFeature *multiPolygonFeature = [MHMultiPolygonFeature multiPolygonWithPolygons:@[firstPolygon, secondPolygon]];

    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"source-id" shape:multiPolygonFeature options:nil];

    XCTAssertNotNil(source.shape);
    XCTAssertTrue([source.shape isMemberOfClass:[MHMultiPolygonFeature class]]);
}

- (void)testMHShapeSourceWithPointFeature {
    MHPointFeatureClusterFeature *pointFeature = [MHPointFeatureClusterFeature new];
    pointFeature.coordinate = CLLocationCoordinate2DMake(0.2, 100.2);

    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"souce-id" shape:pointFeature options:nil];

    XCTAssertNotNil(source.shape);
    XCTAssertTrue([source.shape isMemberOfClass:[MHPointFeatureClusterFeature class]]);
}

- (void)testMHShapeSourceWithPointCollectionFeature {
    CLLocationCoordinate2D coordinates[] = {
        CLLocationCoordinate2DMake(0.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 100.0)};
    MHPointCollectionFeature *pointCollectionFeature = [MHPointCollectionFeature pointCollectionWithCoordinates:coordinates count:5];
    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"souce-id" shape:pointCollectionFeature options:nil];

    XCTAssertNotNil(source.shape);
    XCTAssertTrue([source.shape isMemberOfClass:[MHPointCollectionFeature class]]);
}

- (void)testMHShapeSourceWithShapeCollectionFeatures {
    CLLocationCoordinate2D coordinates[] = {
        CLLocationCoordinate2DMake(0.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 100.0)};

    CLLocationCoordinate2D interiorCoordinates[] = {
        CLLocationCoordinate2DMake(0.2, 100.2),
        CLLocationCoordinate2DMake(0.2, 100.8),
        CLLocationCoordinate2DMake(0.8, 100.8),
        CLLocationCoordinate2DMake(0.8, 100.2),
        CLLocationCoordinate2DMake(0.2, 100.2)};

    MHPolygon *polygon = [MHPolygon polygonWithCoordinates:interiorCoordinates count:5];

    MHPolygonFeature *polygonFeature = [MHPolygonFeature polygonWithCoordinates:coordinates count:5 interiorPolygons:@[polygon]];

    CLLocationCoordinate2D coordinates_2[] = { CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(10, 10)};
    MHPolylineFeature *polylineFeature = [MHPolylineFeature polylineWithCoordinates:coordinates_2 count:2];

    MHMultiPolygonFeature *multiPolygonFeature = [MHMultiPolygonFeature multiPolygonWithPolygons:@[polygonFeature, polygonFeature]];

    MHMultiPolylineFeature *multiPolylineFeature = [MHMultiPolylineFeature multiPolylineWithPolylines:@[polylineFeature, polylineFeature]];

    MHPointCollectionFeature *pointCollectionFeature = [MHPointCollectionFeature pointCollectionWithCoordinates:coordinates count:5];

    MHPointFeatureClusterFeature *pointFeature = [MHPointFeatureClusterFeature new];
    pointFeature.coordinate = CLLocationCoordinate2DMake(0.2, 100.2);

    MHShapeCollectionFeature *shapeCollectionFeature = [MHShapeCollectionFeature shapeCollectionWithShapes:@[polygonFeature, polylineFeature, multiPolygonFeature, multiPolylineFeature, pointCollectionFeature, pointFeature]];

    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"source-id" shape:shapeCollectionFeature options:nil];

    MHShapeCollectionFeature *shape = (MHShapeCollectionFeature *)source.shape;
    XCTAssertNotNil(shape);
    XCTAssert(shape.shapes.count == 6, @"Shape collection should contain 6 shapes");
}

- (void)testMHShapeSourceWithFeaturesConvenienceInitializer {
    CLLocationCoordinate2D coordinates[] = {
        CLLocationCoordinate2DMake(0.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 100.0)};

    MHPolygonFeature *polygonFeature = [MHPolygonFeature polygonWithCoordinates:coordinates count:sizeof(coordinates)/sizeof(coordinates[0]) interiorPolygons:nil];

    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"source-id" features:@[polygonFeature] options:nil];
    MHShapeCollectionFeature *shape = (MHShapeCollectionFeature *)source.shape;

    XCTAssertTrue([shape isKindOfClass:[MHShapeCollectionFeature class]]);
    XCTAssertEqual(shape.shapes.count, 1UL, @"Shape collection should contain 1 shape");

    // when a shape is included in the features array
    MHPolygon *polygon = [MHPolygon polygonWithCoordinates:coordinates count:sizeof(coordinates)/sizeof(coordinates[0]) interiorPolygons:nil];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-literal-conversion"
    XCTAssertThrowsSpecificNamed([[MHShapeSource alloc] initWithIdentifier:@"source-id-invalid" features:@[polygon] options:nil], NSException, NSInvalidArgumentException, @"Shape source should raise an exception if a shape is sent to the features initializer");
#pragma clang diagnostic pop
}

- (void)testMHShapeSourceWithShapesConvenienceInitializer {
    CLLocationCoordinate2D coordinates[] = {
        CLLocationCoordinate2DMake(0.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 101.0),
        CLLocationCoordinate2DMake(1.0, 100.0),
        CLLocationCoordinate2DMake(0.0, 100.0)};

    MHPolygon *polygon = [MHPolygon polygonWithCoordinates:coordinates count:sizeof(coordinates)/sizeof(coordinates[0]) interiorPolygons:nil];

    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"source-id" shapes:@[polygon] options:nil];
    MHShapeCollectionFeature *shape = (MHShapeCollectionFeature *)source.shape;

    XCTAssertTrue([shape isKindOfClass:[MHShapeCollection class]]);
    XCTAssertEqual(shape.shapes.count, 1UL, @"Shape collection should contain 1 shape");
}

@end
