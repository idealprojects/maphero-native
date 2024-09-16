#import <Mapbox.h>
#import <XCTest/XCTest.h>

#import "../../ios/src/MHMapAccessibilityElement.h"

@interface MHMapAccessibilityElementTests : XCTestCase
@end

@implementation MHMapAccessibilityElementTests

- (void)testFeatureLabels {
    MHPointFeatureClusterFeature *feature = [[MHPointFeatureClusterFeature alloc] init];
    feature.attributes = @{
        @"name": @"Local",
        @"name_en": @"English",
        @"name_es": @"Spanish",
        @"name_fr": @"French",
        @"name_tlh": @"Klingon",
    };
    MHFeatureAccessibilityElement *element = [[MHFeatureAccessibilityElement alloc] initWithAccessibilityContainer:self feature:feature];
    XCTAssertEqualObjects(element.accessibilityLabel, @"English", @"Accessibility label should be localized.");

    feature.attributes = @{
        @"name": @"Цинциннати",
        @"name_en": @"Цинциннати",
    };
    element = [[MHFeatureAccessibilityElement alloc] initWithAccessibilityContainer:self feature:feature];
    XCTAssertEqualObjects(element.accessibilityLabel, @"Cincinnati", @"Accessibility label should be romanized.");
}

- (void)testPlaceFeatureValues {
    MHPointFeatureClusterFeature *feature = [[MHPointFeatureClusterFeature alloc] init];
    feature.attributes = @{
        @"type": @"village_green",
    };
    MHPlaceFeatureAccessibilityElement *element = [[MHPlaceFeatureAccessibilityElement alloc] initWithAccessibilityContainer:self feature:feature];
    XCTAssertEqualObjects(element.accessibilityValue, @"village green");
    
    feature = [[MHPointFeatureClusterFeature alloc] init];
    feature.attributes = @{
        @"maki": @"cat",
    };
    element = [[MHPlaceFeatureAccessibilityElement alloc] initWithAccessibilityContainer:self feature:feature];
    XCTAssertEqualObjects(element.accessibilityValue, @"cat");
    
    feature = [[MHPointFeatureClusterFeature alloc] init];
    feature.attributes = @{
        @"elevation_ft": @31337,
        @"elevation_m": @1337,
    };
    element = [[MHPlaceFeatureAccessibilityElement alloc] initWithAccessibilityContainer:self feature:feature];
    // TODO: this is system-dependent ((element.accessibilityValue) equal to (@"31,337 feet")) failed: ("1.337 meters") is not equal to ("31,337 feet")
    // XCTAssertEqualObjects(element.accessibilityValue, @"31,337 feet");
}

- (void)testRoadFeatureValues {
    CLLocationCoordinate2D coordinates[] = {
        CLLocationCoordinate2DMake(0, 0),
        CLLocationCoordinate2DMake(0, 1),
        CLLocationCoordinate2DMake(1, 2),
        CLLocationCoordinate2DMake(2, 2),
    };
    MHPolylineFeature *roadFeature = [MHPolylineFeature polylineWithCoordinates:coordinates count:sizeof(coordinates) / sizeof(coordinates[0])];
    roadFeature.attributes = @{
        @"ref": @"42",
        @"oneway": @"true",
    };
    MHRoadFeatureAccessibilityElement *element = [[MHRoadFeatureAccessibilityElement alloc] initWithAccessibilityContainer:self feature:roadFeature];
    XCTAssertEqualObjects(element.accessibilityValue, @"Route 42, One way, southwest to northeast");
    
    CLLocationCoordinate2D opposingCoordinates[] = {
        CLLocationCoordinate2DMake(2, 1),
        CLLocationCoordinate2DMake(1, 0),
    };
    MHPolylineFeature *opposingRoadFeature = [MHPolylineFeature polylineWithCoordinates:opposingCoordinates count:sizeof(opposingCoordinates) / sizeof(opposingCoordinates[0])];
    opposingRoadFeature.attributes = @{
        @"ref": @"42",
        @"oneway": @"true",
    };
    MHMultiPolylineFeature *dividedRoadFeature = [MHMultiPolylineFeature multiPolylineWithPolylines:@[roadFeature, opposingRoadFeature]];
    dividedRoadFeature.attributes = @{
        @"ref": @"42",
    };
    element = [[MHRoadFeatureAccessibilityElement alloc] initWithAccessibilityContainer:self feature:dividedRoadFeature];
    XCTAssertEqualObjects(element.accessibilityValue, @"Route 42, Divided road, southwest to northeast");
}

@end
