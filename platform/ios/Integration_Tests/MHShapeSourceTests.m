//
//  MBShapeSourceTests.m
//  integration
//
//  Created by Julian Rex on 4/5/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

#import "MHMapViewIntegrationTest.h"

@interface MHShapeSourceTests : MHMapViewIntegrationTest
@end

@implementation MHShapeSourceTests

- (void)testSettingShapeSourceToNilInRegionDidChange {

    NSMutableArray *features = [[NSMutableArray alloc] init];

    for (NSUInteger i = 0; i <= 180; i+=5) {
        CLLocationCoordinate2D coord[4] = {
            CLLocationCoordinate2DMake(round(0), round(i)),
            CLLocationCoordinate2DMake(round(20), round(i)),
            CLLocationCoordinate2DMake(round(0), round(i / 2 )),
            CLLocationCoordinate2DMake(round(20), round(i / 2))};

        MHPolygonFeature *feature = [MHPolygonFeature polygonWithCoordinates:coord count:4];
        [features addObject:feature];
    }

    MHShapeSource *shapeSource = [[MHShapeSource alloc] initWithIdentifier:@"source" features:features options:nil];
    [self.style addSource:shapeSource];

    MHFillStyleLayer *layer = [[MHFillStyleLayer alloc] initWithIdentifier:@"layer" source:shapeSource];
    layer.fillOpacity = [NSExpression expressionForConstantValue:@0.5];
    [self.style addLayer:layer];

    XCTestExpectation *expectation = [self expectationWithDescription:@"regionDidChange expectation"];
    expectation.expectedFulfillmentCount = 1;
    expectation.assertForOverFulfill = YES;

    __weak typeof(self) weakself = self;
    __block NSInteger delegateCallCount = 0;

    self.regionDidChange = ^(MHMapView *mapView, MHCameraChangeReason reason, BOOL animated) {

        MHShapeSourceTests *strongSelf = weakself;

        if (!strongSelf)
            return;

        delegateCallCount++;

        // Setting the shapeSource.shape = nil, was causing an infinite loop, so here
        // we check for a runaway call. 10 here is arbitrary. We could argue that this
        // should check that the call count is only 1, however in this case we particularly
        // want to check for the infinite loop.
        // See https://github.com/mapbox/mapbox-gl-native/issues/11180

        if (delegateCallCount > 10) {
            MHTestFail(strongSelf);
        }
        else {
            shapeSource.shape = nil;
        }

        [expectation fulfill];
    };

    // setCenterCoordinate is NOT animated here.
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(10.0, 10.0)];
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testSettingShapeSourceToNilInRegionIsChanging {

    NSMutableArray *features = [[NSMutableArray alloc] init];

    for (NSUInteger i = 0; i <= 180; i+=5) {
        CLLocationCoordinate2D coord[4] = {
            CLLocationCoordinate2DMake(round(0), round(i)),
            CLLocationCoordinate2DMake(round(20), round(i)),
            CLLocationCoordinate2DMake(round(0), round(i / 2 )),
            CLLocationCoordinate2DMake(round(20), round(i / 2))};

        MHPolygonFeature *feature = [MHPolygonFeature polygonWithCoordinates:coord count:4];
        [features addObject:feature];
    }

    MHShapeSource *shapeSource = [[MHShapeSource alloc] initWithIdentifier:@"source" features:features options:nil];
    [self.style addSource:shapeSource];

    MHFillStyleLayer *layer = [[MHFillStyleLayer alloc] initWithIdentifier:@"layer" source:shapeSource];
    layer.fillOpacity = [NSExpression expressionForConstantValue:@0.5];
    [self.style addLayer:layer];

    XCTestExpectation *expectation = [self expectationWithDescription:@"regionDidChange expectation"];
    expectation.expectedFulfillmentCount = 1;
    expectation.assertForOverFulfill = YES;

    __block NSInteger delegateCallCount = 0;
    __weak typeof(self) weakself = self;

    self.regionIsChanging = ^(MHMapView *mapView) {
        // See https://github.com/mapbox/mapbox-gl-native/issues/11180
        shapeSource.shape = nil;
    };

    self.regionDidChange = ^(MHMapView *mapView, MHCameraChangeReason reason, BOOL animated) {

        delegateCallCount++;

        if (delegateCallCount > 1) {
            MHTestFail(weakself);
        }

        [expectation fulfill];
    };

    // Should take MHAnimationDuration seconds (0.3)
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(10.0, 10.0) animated:YES];
    [self waitForExpectations:@[expectation] timeout:1.0];
}

- (void)testShapeSourceWithLineDistanceMetrics {
    CLLocationCoordinate2D coordinates[] = {
        CLLocationCoordinate2DMake(9.6315313, 52.4133574),
        CLLocationCoordinate2DMake(24.9410248, 60.1733244)};

    MHPolylineFeature *polylineFeature = [MHPolylineFeature polylineWithCoordinates:coordinates count:sizeof(coordinates)/sizeof(coordinates[0])];
    NSDictionary *options = @{MHShapeSourceOptionLineDistanceMetrics: @YES};
    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"route" shape:polylineFeature options:options];
    MHLineStyleLayer *lineLayer = [[MHLineStyleLayer alloc] initWithIdentifier:@"lineLayer" source:source];

    [self.style addSource:source];
    [self.style addLayer:lineLayer];
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(9.6315313, 52.4133574) animated:YES];

    XCTestExpectation *expectation = [self expectationWithDescription:@"regionDidChange expectation"];
    expectation.expectedFulfillmentCount = 1;
    expectation.assertForOverFulfill = YES;

    __weak id weakself = self;
    self.regionDidChange = ^(MHMapView *mapView, MHCameraChangeReason reason, BOOL animated) {

        id strongSelf = weakself;
        if (!strongSelf)
            return;

        NSArray *features = [source featuresMatchingPredicate:nil];
        MHTestAssert(strongSelf, features.count == 1UL, @"Should contain one Feature");

        MHPolylineFeature *feature = [features objectAtIndex:0];
        MHTestAssertNotNil(strongSelf, [feature.attributes objectForKey:@"mapbox_clip_start"], @"Attributes should contain mapbox_clip_start property");
        MHTestAssertNotNil(strongSelf, [feature.attributes objectForKey:@"mapbox_clip_end"], @"Attributes should contain mapbox_clip_end property");

        [expectation fulfill];
    };

    [self waitForExpectations:@[expectation] timeout:1.0];
}

@end
