#import <Mapbox.h>
#import <XCTest/XCTest.h>

#import "../../darwin/src/MHGeometry_Private.h"

@interface MHGeometryTests : XCTestCase
@end

@implementation MHGeometryTests

- (void)testCoordinateBoundsIsEmpty {
    MHCoordinateBounds emptyBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(10, 0));
    XCTAssertTrue(MHCoordinateBoundsIsEmpty(emptyBounds));
    XCTAssertFalse(MHCoordinateSpanEqualToCoordinateSpan(MHCoordinateSpanZero, MHCoordinateBoundsGetCoordinateSpan(emptyBounds)));
}

- (void)testAngleConversions {
    XCTAssertEqualWithAccuracy(-180, MHDegreesFromRadians(-M_PI), 1e-5);
    XCTAssertEqual(0, MHDegreesFromRadians(0));
    XCTAssertEqualWithAccuracy(45, MHDegreesFromRadians(M_PI_4), 1e-5);
    XCTAssertEqualWithAccuracy(90, MHDegreesFromRadians(M_PI_2), 1e-5);
    XCTAssertEqualWithAccuracy(180, MHDegreesFromRadians(M_PI), 1e-5);
    XCTAssertEqualWithAccuracy(360, MHDegreesFromRadians(2 * M_PI), 1e-5);
    XCTAssertEqualWithAccuracy(720, MHDegreesFromRadians(4 * M_PI), 1e-5);
    
    XCTAssertEqualWithAccuracy(-360, MHDegreesFromRadians(MHRadiansFromDegrees(-360)), 1e-4);
    XCTAssertEqualWithAccuracy(-180, MHDegreesFromRadians(MHRadiansFromDegrees(-180)), 1e-5);
    XCTAssertEqualWithAccuracy(-90, MHDegreesFromRadians(MHRadiansFromDegrees(-90)), 1e-5);
    XCTAssertEqualWithAccuracy(-45, MHDegreesFromRadians(MHRadiansFromDegrees(-45)), 1e-5);
    XCTAssertEqualWithAccuracy(0, MHDegreesFromRadians(MHRadiansFromDegrees(0)), 1e-5);
    XCTAssertEqualWithAccuracy(45, MHDegreesFromRadians(MHRadiansFromDegrees(45)), 1e-5);
    XCTAssertEqualWithAccuracy(90, MHDegreesFromRadians(MHRadiansFromDegrees(90)), 1e-5);
    XCTAssertEqualWithAccuracy(180, MHDegreesFromRadians(MHRadiansFromDegrees(180)), 1e-5);
    XCTAssertEqualWithAccuracy(360, MHDegreesFromRadians(MHRadiansFromDegrees(360)), 1e-4);
}

- (void)testAltitudeConversions {
    CGSize tallSize = CGSizeMake(600, 1200);
    CGSize midSize = CGSizeMake(600, 800);
    CGSize shortSize = CGSizeMake(600, 400);
    
    XCTAssertEqualWithAccuracy(1800, MHAltitudeForZoomLevel(MHZoomLevelForAltitude(1800, 0, 0, midSize), 0, 0, midSize), 1e-8);
    XCTAssertLessThan(MHZoomLevelForAltitude(1800, 0, 0, midSize), MHZoomLevelForAltitude(1800, 0, 0, tallSize));
    XCTAssertGreaterThan(MHZoomLevelForAltitude(1800, 0, 0, midSize), MHZoomLevelForAltitude(1800, 0, 0, shortSize));
    
    XCTAssertEqualWithAccuracy(0, MHZoomLevelForAltitude(MHAltitudeForZoomLevel(0, 0, 0, midSize), 0, 0, midSize), 1e-8);
    XCTAssertEqualWithAccuracy(18, MHZoomLevelForAltitude(MHAltitudeForZoomLevel(18, 0, 0, midSize), 0, 0, midSize), 1e-8);
    
    XCTAssertEqualWithAccuracy(0, MHZoomLevelForAltitude(MHAltitudeForZoomLevel(0, 0, 40, midSize), 0, 40, midSize), 1e-8);
    XCTAssertEqualWithAccuracy(18, MHZoomLevelForAltitude(MHAltitudeForZoomLevel(18, 0, 40, midSize), 0, 40, midSize), 1e-8);
    
    XCTAssertEqualWithAccuracy(0, MHZoomLevelForAltitude(MHAltitudeForZoomLevel(0, 60, 40, midSize), 60, 40, midSize), 1e-8);
    XCTAssertEqualWithAccuracy(18, MHZoomLevelForAltitude(MHAltitudeForZoomLevel(18, 60, 40, midSize), 60, 40, midSize), 1e-8);
}

- (void)testGeometryBoxing {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(38.9131982, -77.0325453144239);
    CLLocationCoordinate2D roundTrippedCoordinate = [NSValue valueWithMHCoordinate:coordinate].MHCoordinateValue;

    XCTAssertEqual(coordinate.latitude, roundTrippedCoordinate.latitude, @"Latitude should round-trip.");
    XCTAssertEqual(coordinate.longitude, roundTrippedCoordinate.longitude, @"Longitude should round-trip.");

    MHCoordinateSpan span = MHCoordinateSpanMake(4.383333333333335, -4.299999999999997);
    MHCoordinateSpan roundTrippedSpan = [NSValue valueWithMHCoordinateSpan:span].MHCoordinateSpanValue;

    XCTAssertEqual(span.latitudeDelta, roundTrippedSpan.latitudeDelta, @"Latitude delta should round-trip.");
    XCTAssertEqual(span.longitudeDelta, roundTrippedSpan.longitudeDelta, @"Longitude delta should round-trip.");

    MHCoordinateBounds bounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(38.9131982, -77.0325453144239),
                                                         CLLocationCoordinate2DMake(37.7757368, -122.4135302));
    MHCoordinateBounds roundTrippedBounds = [NSValue valueWithMHCoordinateBounds:bounds].MHCoordinateBoundsValue;

    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:bounds.sw],
                          [NSValue valueWithMHCoordinate:roundTrippedBounds.sw],
                          @"Southwest should round-trip.");
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:bounds.ne],
                          [NSValue valueWithMHCoordinate:roundTrippedBounds.ne],
                          @"Northeast should round-trip.");
}

- (void)testCoordinateInCoordinateBounds {
    CLLocationCoordinate2D ne = CLLocationCoordinate2DMake(45, -104);
    CLLocationCoordinate2D sw = CLLocationCoordinate2DMake(41, -111);
    MHCoordinateBounds wyoming = MHCoordinateBoundsMake(sw, ne);

    CLLocationCoordinate2D centerOfWyoming = CLLocationCoordinate2DMake(43, -107.5);

    XCTAssertTrue(MHCoordinateInCoordinateBounds(ne, wyoming));
    XCTAssertTrue(MHCoordinateInCoordinateBounds(sw, wyoming));
    XCTAssertTrue(MHCoordinateInCoordinateBounds(centerOfWyoming, wyoming));

    CLLocationCoordinate2D australia = CLLocationCoordinate2DMake(-25, 135);
    CLLocationCoordinate2D brazil = CLLocationCoordinate2DMake(-12, -50);
    CLLocationCoordinate2D china = CLLocationCoordinate2DMake(35, 100);

    XCTAssertFalse(MHCoordinateInCoordinateBounds(australia, wyoming));
    XCTAssertFalse(MHCoordinateInCoordinateBounds(brazil, wyoming));
    XCTAssertFalse(MHCoordinateInCoordinateBounds(china, wyoming));
    XCTAssertFalse(MHCoordinateInCoordinateBounds(kCLLocationCoordinate2DInvalid, wyoming));
}

- (void)testGeoJSONDeserialization {
    NSData *data = [@"{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [0, 0]}, \"properties\": {}}" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    MHPointFeatureClusterFeature *feature = (MHPointFeatureClusterFeature *)[MHShape shapeWithData:data encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"Valid GeoJSON data should produce no error on deserialization.");
    XCTAssertNotNil(feature, @"Valid GeoJSON data should produce an object on deserialization.");
    XCTAssertTrue([feature isKindOfClass:[MHPointFeatureClusterFeature class]], @"Valid GeoJSON point feature data should produce an MHPointFeatureClusterFeature.");
    XCTAssertEqual(feature.attributes.count, 0UL);
    XCTAssertEqual(feature.coordinate.latitude, 0);
    XCTAssertEqual(feature.coordinate.longitude, 0);

    data = [@"{\"type\": \"Feature\", \"feature\": {\"type\": \"Point\", \"coordinates\": [0, 0]}}" dataUsingEncoding:NSUTF8StringEncoding];
    error = nil;
    MHShape *shape = [MHShape shapeWithData:data encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNotNil(error, @"Invalid GeoJSON data should produce an error on deserialization.");
    XCTAssertNil(shape, @"Invalid GeoJSON data should produce no object on deserialization.");
}

- (void)testGeoJSONSerialization {
    MHPointFeatureClusterFeature *feature = [[MHPointFeatureClusterFeature alloc] init];
    feature.identifier = @504;
    feature.coordinate = CLLocationCoordinate2DMake(29.95, -90.066667);

    NSData *data = [feature geoJSONDataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNotNil(data, @"MHPointFeatureClusterFeature should serialize as an UTF-8 string data object.");
    NSError *error;
    NSDictionary *serializedGeoJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    XCTAssertNil(error, @"Serialized GeoJSON data should be deserializable JSON.");
    XCTAssertNotNil(serializedGeoJSON, @"Serialized GeoJSON data should be valid JSON.");
    XCTAssertTrue([serializedGeoJSON isKindOfClass:[NSDictionary class]], @"Serialized GeoJSON data should be a JSON object.");
    NSDictionary *geoJSON = @{
        @"type": @"Feature",
        @"id": @504,
        @"geometry": @{
            @"type": @"Point",
            @"coordinates": @[
                @(-90.066667),
                @29.95,
            ],
        },
        @"properties": @{},
    };
    XCTAssertEqualObjects(serializedGeoJSON, geoJSON, @"MHPointFeatureClusterFeature should serialize as a GeoJSON point feature.");
}

- (void)testMHCoordinateBoundsToMHCoordinateQuad {
    MHCoordinateBounds bounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(37.936, -80.425),
                                                         CLLocationCoordinate2DMake(46.437, -71.516));

    MHCoordinateQuad quad = MHCoordinateQuadFromCoordinateBounds(bounds);
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:bounds.sw],
                          [NSValue valueWithMHCoordinate:quad.bottomLeft],
                          @"Bounds southwest should be bottom left of quad.");
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:bounds.ne],
                          [NSValue valueWithMHCoordinate:quad.topRight],
                          @"Bounds northeast should be top right of quad.");

    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(46.437, -80.425)],
                          [NSValue valueWithMHCoordinate:quad.topLeft],
                          @"Quad top left should be computed correctly.");
    XCTAssertEqualObjects([NSValue valueWithMHCoordinate:CLLocationCoordinate2DMake(37.936, -71.516)],
                          [NSValue valueWithMHCoordinate:quad.bottomRight],
                          @"Quad bottom right should be computed correctly.");
}

- (void)testMHMapPoint {
    MHMapPoint point = MHMapPointForCoordinate(CLLocationCoordinate2DMake(37.936, -80.425), 0.0);
    
    MHMapPoint roundTrippedPoint = [NSValue valueWithMHMapPoint:point].MHMapPointValue;
    XCTAssertEqual(point.x, roundTrippedPoint.x);
    XCTAssertEqual(point.y, roundTrippedPoint.y);
    XCTAssertEqual(point.zoomLevel, roundTrippedPoint.zoomLevel);
}

- (void)testMHLocationCoordinate2DIsValid {
    {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(37.936, -71.516);
        XCTAssertTrue(MHLocationCoordinate2DIsValid(coordinate));
    }
    {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(46.816368, 5.844469);
        XCTAssertTrue(MHLocationCoordinate2DIsValid(coordinate));
    }
    {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(-21.512680, 23.334703);
        XCTAssertTrue(MHLocationCoordinate2DIsValid(coordinate));
    }
    {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(-44.947936, -73.081313);
        XCTAssertTrue(MHLocationCoordinate2DIsValid(coordinate));
    }
    {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(19.333630, 203.555405);
        XCTAssertTrue(MHLocationCoordinate2DIsValid(coordinate));
    }
    {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(23.254696, -240.795323);
        XCTAssertTrue(MHLocationCoordinate2DIsValid(coordinate));
    }
    {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(91, 361);
        XCTAssertFalse(MHLocationCoordinate2DIsValid(coordinate));
    }
    {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(-91, -361);
        XCTAssertFalse(MHLocationCoordinate2DIsValid(coordinate));
    }
}

@end
