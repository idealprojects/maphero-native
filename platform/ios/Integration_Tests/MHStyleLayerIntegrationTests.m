#import "MHMapViewIntegrationTest.h"

@interface MHStyleLayerIntegrationTests : MHMapViewIntegrationTest
@end

@implementation MHStyleLayerIntegrationTests

- (MHCircleStyleLayer*)setupCircleStyleLayer {
    // Adapted from https://docs.mapbox.com/ios/examples/dds-circle-layer/

    // "mapbox://examples.2uf7qges" is a tileset ID. For more
    // more information, see docs.mapbox.com/help/glossary/tileset-id/
    MHSource *source = [[MHVectorTileSource alloc] initWithIdentifier:@"trees" configurationURL:[NSURL URLWithString:@"mapbox://examples.2uf7qges"]];
    [self.mapView.style addSource:source];

    MHCircleStyleLayer *layer = [[MHCircleStyleLayer alloc] initWithIdentifier: @"tree-style" source:source];

    // The source name from the source's TileJSON metadata: mapbox.com/api-documentation/maps/#retrieve-tilejson-metadata
    layer.sourceLayerIdentifier = @"yoshino-trees-a0puw5";

    return layer;
}

- (void)testForInterpolatingExpressionRenderCrashWithEmptyStops {
    // Tests: https://github.com/mapbox/mapbox-gl-native/issues/9539
    // Adapted from https://docs.mapbox.com/ios/examples/dds-circle-layer/
    self.mapView.centerCoordinate = CLLocationCoordinate2DMake(38.897,-77.039);
    self.mapView.zoomLevel = 10.5;

    MHCircleStyleLayer *layer = [self setupCircleStyleLayer];

    NSExpression *interpExpression = [NSExpression mgl_expressionForInterpolatingExpression:NSExpression.zoomLevelVariableExpression
                                                                              withCurveType:MHExpressionInterpolationModeLinear
                                                                                 parameters:nil
                                                                                      stops:[NSExpression expressionForConstantValue:@{}]];

    XCTAssertThrowsSpecificNamed((layer.circleColor = interpExpression), NSException, NSInvalidArgumentException);

    [self.mapView.style addLayer:layer];
    [self waitForMapViewToBeRenderedWithTimeout:10];
}

- (void)testForSteppingExpressionRenderCrashWithEmptyStops {
    // Tests: https://github.com/mapbox/mapbox-gl-native/issues/9539
    // Adapted from https://docs.mapbox.com/ios/examples/dds-circle-layer/
    self.mapView.centerCoordinate = CLLocationCoordinate2DMake(38.897,-77.039);
    self.mapView.zoomLevel = 10.5;

    MHCircleStyleLayer *layer = [self setupCircleStyleLayer];

    NSExpression *steppingExpression = [NSExpression mgl_expressionForSteppingExpression:NSExpression.zoomLevelVariableExpression
                                                                          fromExpression:[NSExpression expressionForConstantValue:[UIColor greenColor]]
                                                                                   stops:[NSExpression expressionForConstantValue:@{}]];

    XCTAssertThrowsSpecificNamed((layer.circleColor = steppingExpression), NSException, NSInvalidArgumentException);

    [self.mapView.style addLayer:layer];
    [self waitForMapViewToBeRenderedWithTimeout:10];
}

- (void)testForRaisingExceptionsOnStaleStyleObjects {
    self.mapView.centerCoordinate = CLLocationCoordinate2DMake(38.897,-77.039);
    self.mapView.zoomLevel = 10.5;
    
    MHVectorTileSource *source = [[MHVectorTileSource alloc] initWithIdentifier:@"trees" configurationURL:[NSURL URLWithString:@"mapbox://examples.2uf7qges"]];
    [self.mapView.style addSource:source];

    self.styleLoadingExpectation = nil;
    [self.mapView setStyleURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"one-liner" withExtension:@"json"]];
    [self waitForMapViewToFinishLoadingStyleWithTimeout:10];

    XCTAssertNotNil(source.description);
    XCTAssertThrowsSpecificNamed(source.configurationURL, NSException, MHInvalidStyleSourceException, @"MHSource should raise an exception if its core peer got invalidated");
}

- (void)testForRaisingExceptionsOnStaleLayerObject {
    self.mapView.centerCoordinate = CLLocationCoordinate2DMake(38.897,-77.039);
    self.mapView.zoomLevel = 10.5;
    
    MHPointFeature *feature = [[MHPointFeature alloc] init];
    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"sourceID" shape:feature options:nil];
    
    // Testing generated layers
    MHLineStyleLayer *lineLayer = [[MHLineStyleLayer alloc] initWithIdentifier:@"lineLayerID" source:source];
    MHCircleStyleLayer *circleLayer = [[MHCircleStyleLayer alloc] initWithIdentifier:@"circleLayerID" source:source];
    
    [self.mapView.style addSource:source];
    [self.mapView.style addLayer:lineLayer];
    [self.mapView.style addLayer:circleLayer];

    XCTAssertNoThrow(lineLayer.isVisible);
    XCTAssertNoThrow(circleLayer.isVisible);
    
    XCTAssert(![source.description containsString:@"<unknown>"]);
    XCTAssert(![lineLayer.description containsString:@"<unknown>"]);
    XCTAssert(![circleLayer.description containsString:@"<unknown>"]);

    self.styleLoadingExpectation = nil;
    [self.mapView setStyleURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"one-liner" withExtension:@"json"]];
    [self waitForMapViewToFinishLoadingStyleWithTimeout:10];

    XCTAssert([source.description containsString:@"<unknown>"]);
    XCTAssert([lineLayer.description containsString:@"<unknown>"]);
    XCTAssert([circleLayer.description containsString:@"<unknown>"]);

    XCTAssertThrowsSpecificNamed(lineLayer.isVisible, NSException, MHInvalidStyleLayerException, @"Layer should raise an exception if its core peer got invalidated");
    XCTAssertThrowsSpecificNamed(circleLayer.isVisible, NSException, MHInvalidStyleLayerException, @"Layer should raise an exception if its core peer got invalidated");
    
    XCTAssertThrowsSpecificNamed([self.mapView.style removeLayer:lineLayer], NSException, NSInvalidArgumentException, @"Style should raise an exception when attempting to remove an invalid layer (e.g. if its core peer got invalidated)");
    XCTAssertThrowsSpecificNamed([self.mapView.style removeLayer:circleLayer], NSException, NSInvalidArgumentException, @"Style should raise an exception when attempting to remove an invalid layer (e.g. if its core peer got invalidated)");
}
@end
