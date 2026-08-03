#import <Mapbox.h>
#import <XCTest/XCTest.h>
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
    #define MHEdgeInsetsZero UIEdgeInsetsZero
#else
    #define MHEdgeInsetsZero NSEdgeInsetsZero
#endif

static MHMapView *mapView;
@interface MHMapViewTests : XCTestCase <MHMapViewDelegate>
@end

@implementation MHMapViewTests {
    XCTestExpectation *_styleLoadingExpectation;
    XCTestExpectation *_styleLoadErrorExpectation;
}

- (void)setUp {
    [super setUp];

    [MHSettings setApiKey:@"pk.feedcafedeadbeefbadebede"];
    NSURL *styleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"one-liner" withExtension:@"json"];
    mapView = [[MHMapView alloc] initWithFrame:CGRectMake(0, 0, 64, 64) styleURL:styleURL];
    mapView.delegate = self;
    if (!mapView.style) {
        _styleLoadingExpectation = [self expectationWithDescription:@"Map view should finish loading style."];
        [self waitForExpectationsWithTimeout:10 handler:nil];
    }
}

- (void)tearDown {
    _styleLoadingExpectation = nil;
    mapView = nil;
    [MHSettings setApiKey:nil];
    [super tearDown];
}

- (void)mapView:(MHMapView *)mapView didFinishLoadingStyle:(MHStyle *)style {
    XCTAssertNotNil(mapView.style);
    XCTAssertEqual(mapView.style, style);

    [_styleLoadingExpectation fulfill];
}

- (void)mapViewDidFailLoadingMap:(MHMapView *)mapView withError:(NSError *)error {
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, MHErrorDomain);
    if (error.code == MHErrorCodeLoadStyleFailed || error.code == MHErrorCodeParseStyleFailed) {
        [_styleLoadErrorExpectation fulfill];
    }
}

- (void)testCoordinateBoundsConversion {
    [mapView setCenterCoordinate:CLLocationCoordinate2DMake(33, 179)];

    MHCoordinateBounds leftAntimeridianBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(-75, 175), CLLocationCoordinate2DMake(75, 180));
    CGRect leftAntimeridianBoundsRect = [mapView convertCoordinateBounds:leftAntimeridianBounds toRectToView:mapView];

    MHCoordinateBounds rightAntimeridianBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(-75, -180), CLLocationCoordinate2DMake(75, -175));
    CGRect rightAntimeridianBoundsRect = [mapView convertCoordinateBounds:rightAntimeridianBounds toRectToView:mapView];

    MHCoordinateBounds spanningBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(24, 140), CLLocationCoordinate2DMake(44, 240));
    CGRect spanningBoundsRect = [mapView convertCoordinateBounds:spanningBounds toRectToView:mapView];

    // If the resulting CGRect from -convertCoordinateBounds:toRectToView:
    // intersects the set of bounds to the left and right of the
    // antimeridian, then we know that the CGRect spans across the antimeridian
    XCTAssertTrue(CGRectIntersectsRect(spanningBoundsRect, leftAntimeridianBoundsRect), @"Resulting");
    XCTAssertTrue(CGRectIntersectsRect(spanningBoundsRect, rightAntimeridianBoundsRect), @"Something");
}

#if TARGET_OS_IPHONE
- (void)testUserTrackingModeCompletion {
    __block BOOL completed = NO;
    [mapView setUserTrackingMode:MHUserTrackingModeNone animated:NO completionHandler:^{
        completed = YES;
    }];
    XCTAssertTrue(completed, @"Completion block should get called synchronously when the mode is unchanged.");

    completed = NO;
    [mapView setUserTrackingMode:MHUserTrackingModeNone animated:YES completionHandler:^{
        completed = YES;
    }];
    XCTAssertTrue(completed, @"Completion block should get called synchronously when the mode is unchanged.");

    completed = NO;
    [mapView setUserTrackingMode:MHUserTrackingModeFollow animated:NO completionHandler:^{
        completed = YES;
    }];
    XCTAssertTrue(completed, @"Completion block should get called synchronously when there’s no location.");

    completed = NO;
    [mapView setUserTrackingMode:MHUserTrackingModeFollowWithHeading animated:YES completionHandler:^{
        completed = YES;
    }];
    XCTAssertTrue(completed, @"Completion block should get called synchronously when there’s no location.");
}

- (void)testTargetCoordinateCompletion {
    __block BOOL completed = NO;
    [mapView setTargetCoordinate:kCLLocationCoordinate2DInvalid animated:NO completionHandler:^{
        completed = YES;
    }];
    XCTAssertTrue(completed, @"Completion block should get called synchronously when the target coordinate is unchanged.");

    completed = NO;
    [mapView setTargetCoordinate:kCLLocationCoordinate2DInvalid animated:YES completionHandler:^{
        completed = YES;
    }];
    XCTAssertTrue(completed, @"Completion block should get called synchronously when the target coordinate is unchanged.");

    completed = NO;
    [mapView setUserTrackingMode:MHUserTrackingModeFollow animated:NO completionHandler:nil];
    [mapView setTargetCoordinate:CLLocationCoordinate2DMake(39.128106, -84.516293) animated:YES completionHandler:^{
        completed = YES;
    }];
    XCTAssertTrue(completed, @"Completion block should get called synchronously when not tracking user course.");

    completed = NO;
    [mapView setUserTrackingMode:MHUserTrackingModeFollowWithCourse animated:NO completionHandler:nil];
    [mapView setTargetCoordinate:CLLocationCoordinate2DMake(39.224407, -84.394957) animated:YES completionHandler:^{
        completed = YES;
    }];
    XCTAssertTrue(completed, @"Completion block should get called synchronously when there’s no location.");
}
#endif

- (void)testVisibleCoordinatesCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block should get called when not animated"];
    MHCoordinateBounds unitBounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(1, 1));
    [mapView setVisibleCoordinateBounds:unitBounds edgePadding:MHEdgeInsetsZero animated:NO completionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:1];

#if TARGET_OS_IPHONE
    expectation = [self expectationWithDescription:@"Completion block should get called when animated"];
    CLLocationCoordinate2D antiunitCoordinates[] = {
        CLLocationCoordinate2DMake(0, 0),
        CLLocationCoordinate2DMake(-1, -1),
    };
    [mapView setVisibleCoordinates:antiunitCoordinates
                             count:sizeof(antiunitCoordinates) / sizeof(antiunitCoordinates[0])
                       edgePadding:UIEdgeInsetsZero
                         direction:0
                          duration:0
           animationTimingFunction:nil
                 completionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:1];
#endif
}

- (void)testShowAnnotationsCompletion {
    __block BOOL completed = NO;
    [mapView showAnnotations:@[] edgePadding:MHEdgeInsetsZero animated:NO completionHandler:^{
        completed = YES;
    }];
    XCTAssertTrue(completed, @"Completion block should get called synchronously when there are no annotations to show.");

    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block should get called when not animated"];
    MHPointAnnotation *annotation = [[MHPointAnnotation alloc] init];
    [mapView showAnnotations:@[annotation] edgePadding:MHEdgeInsetsZero animated:NO completionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:1];

    expectation = [self expectationWithDescription:@"Completion block should get called when animated."];
    [mapView showAnnotations:@[annotation] edgePadding:MHEdgeInsetsZero animated:YES completionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testTileCache {
    mapView.tileCacheEnabled = NO;
    XCTAssertEqual(mapView.tileCacheEnabled, NO);

    mapView.tileCacheEnabled = YES;
    XCTAssertEqual(mapView.tileCacheEnabled, YES);
}

- (void)testStyleJSONWhenMapViewInitWithStyleURL {
    // Test getting style JSON
    NSString *styleJSON = mapView.styleJSON;
    XCTAssertNotNil(styleJSON, @"Style JSON should not be nil");
    NSString * expectedJSON = @"{\"version\":8,\"sources\":{},\"layers\":[]}";
    XCTAssertEqualObjects([self normalizeJSON:expectedJSON],
                          [self normalizeJSON:styleJSON],
                         @"Style JSON should be expected");

    // Verify the JSON is valid
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:[styleJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                   options:0
                                                     error:&error];
    XCTAssertNil(error, @"Style JSON should be valid JSON");
    XCTAssertNotNil(jsonObject, @"Style JSON should parse to a valid object");
    XCTAssertTrue([jsonObject isKindOfClass:[NSDictionary class]], @"Style JSON should represent a dictionary");
}

- (void)testMapViewInitWithStyleJSON {
    // Test setting style JSON
    NSString *styleJSON = @"{\"version\": 8, \"sources\": { \"mapbox\": {\"type\": \"vector\", \"tiles\": [ \"local://tiles/{z}-{x}-{y}.mvt\" ] }}, \"layers\": [], \"metadata\": { \"test\": 1, \"type\": \"template\"}}";
    MHMapView* mapViewWithJSON = [[MHMapView alloc] initWithFrame:CGRectMake(0, 0, 64, 64) styleJSON:styleJSON];

    // Verify the style was updated
    NSString *loadedStyleJSON = mapViewWithJSON.styleJSON;
    XCTAssertEqualObjects([self normalizeJSON:loadedStyleJSON],
                          [self normalizeJSON:styleJSON],
                         @"Style JSON should match what was set");

    XCTAssertNotNil(mapViewWithJSON.style);
    XCTAssertNotNil(mapViewWithJSON.style.sources);
}

- (void)testUpdateStyleJSON {
    _styleLoadingExpectation = nil;
    _styleLoadErrorExpectation = [self expectationWithDescription:@"Style should load error"];

    // Test setting style JSON
    NSString *newStyleJSON = @"{\"version\": 8, \"sources\": { \"mapbox\": {\"type\": \"vector\", \"tiles\": [ \"local://tiles/{z}-{x}-{y}.mvt\" ] }}, \"layers\": [], \"metadata\": { \"test\": 1, \"type\": \"template\"}}";
    mapView.styleJSON = newStyleJSON;

    // Verify the style was updated
    NSString *updatedStyleJSON = mapView.styleJSON;
    XCTAssertEqualObjects([self normalizeJSON:updatedStyleJSON],
                         [self normalizeJSON:newStyleJSON],
                         @"Style JSON should match what was set");

    XCTAssertNotNil(mapView.style);
    XCTAssertNotNil(mapView.style.sources);
    // source "org.maplibre.annotations" is added by default
    XCTAssertEqual(mapView.style.sources.count, 2UL);

    // Test invalid JSON syntax
    NSString *invalidJSON = @"{invalid json";
    mapView.styleJSON = invalidJSON;
    [self waitForExpectations:@[_styleLoadErrorExpectation] timeout:10];
}

- (void)testStyleJSONAfterAddLayer {
    // Test getting style JSON
    NSString *styleJSON = mapView.styleJSON;
    XCTAssertNotNil(styleJSON, @"Style JSON should not be nil");

    // Add a raster tile source
    MHVectorTileSource *vectorTileSource = [[MHVectorTileSource alloc] initWithIdentifier:@"some-identifier" tileURLTemplates:@[] options:nil];
    [mapView.style addSource:vectorTileSource];

    // Add a layer using it
    MHFillStyleLayer *fillLayer = [[MHFillStyleLayer alloc] initWithIdentifier:@"fillLayer" source:vectorTileSource];
    [mapView.style addLayer:fillLayer];

    // Style JSON should not be updated
    NSString *updatedStyleJSON = mapView.styleJSON;

    XCTAssertEqualObjects([self normalizeJSON:updatedStyleJSON],
                          [self normalizeJSON:styleJSON],
                         @"Style JSON should be updated");
}

// Helper method to normalize JSON strings for comparison
- (NSString *)normalizeJSON:(NSString *)jsonString {
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                   options:0
                                                     error:&error];
    if (error) {
        return jsonString;
    }

    NSData *normalizedData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                           options:0
                                                             error:&error];
    if (error) {
        return jsonString;
    }

    NSString *normalizedString = [[NSString alloc] initWithData:normalizedData encoding:NSUTF8StringEncoding];
    return normalizedString ?: jsonString;
}

@end
