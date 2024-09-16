#import <Mapbox.h>

#import "NSBundle+MHAdditions.h"
#import "MHVectorTileSource_Private.h"

#import <XCTest/XCTest.h>
#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#else
    #import <Cocoa/Cocoa.h>
#endif
#import <objc/runtime.h>

@interface MHStyleTests : XCTestCase <MHMapViewDelegate>

@property (nonatomic) MHMapView *mapView;
@property (nonatomic) MHStyle *style;

@end

@implementation MHStyleTests {
    XCTestExpectation *_styleLoadingExpectation;
}

- (void)setUp {
    [super setUp];
    
    [MHSettings useWellKnownTileServer:MHMapTiler];
    [MHSettings setApiKey:@"pk.feedcafedeadbeefbadebede"];
    
    NSURL *styleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"one-liner" withExtension:@"json"];
    self.mapView = [[MHMapView alloc] initWithFrame:CGRectMake(0, 0, 100, 100) styleURL:styleURL];
    self.mapView.delegate = self;
    if (!self.mapView.style) {
        _styleLoadingExpectation = [self expectationWithDescription:@"Map view should finish loading style."];
        [self waitForExpectationsWithTimeout:10 handler:nil];
    }
}

- (void)mapView:(MHMapView *)mapView didFinishLoadingStyle:(MHStyle *)style {
    XCTAssertNotNil(mapView.style);
    XCTAssertEqual(mapView.style, style);

    [_styleLoadingExpectation fulfill];
}

- (void)tearDown {
    _styleLoadingExpectation = nil;
    self.mapView = nil;

    [super tearDown];
}

// TODO: remove backed property _style
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-property-ivar"
- (MHStyle *)style {
    return self.mapView.style;
}
#pragma clang diagnostic pop

- (void)testName {
    XCTAssertNil(self.style.name);
}

- (void)testSources {
    NSSet<MHSource *> *initialSources = self.style.sources;
    if ([initialSources.anyObject.identifier isEqualToString:@"org.maplibre.annotations"]) {
        XCTAssertEqual(self.style.sources.count, 1UL);
    } else {
        XCTAssertEqual(self.style.sources.count, 0UL);
    }
    MHShapeSource *shapeSource = [[MHShapeSource alloc] initWithIdentifier:@"shapeSource" shape:nil options:nil];
    [self.style addSource:shapeSource];
    XCTAssertEqual(self.style.sources.count, initialSources.count + 1);
    XCTAssertEqual(shapeSource, [self.style sourceWithIdentifier:@"shapeSource"]);
    [self.style removeSource:shapeSource];
    XCTAssertEqual(self.style.sources.count, initialSources.count);
}

- (void)testAddingSourcesTwice {
    MHShapeSource *shapeSource = [[MHShapeSource alloc] initWithIdentifier:@"shapeSource" shape:nil options:nil];
    [self.style addSource:shapeSource];
    XCTAssertThrowsSpecificNamed([self.style addSource:shapeSource], NSException, MHRedundantSourceException);

    MHRasterTileSource *rasterTileSource = [[MHRasterTileSource alloc] initWithIdentifier:@"rasterTileSource" configurationURL:[NSURL URLWithString:@".json"] tileSize:42];
    [self.style addSource:rasterTileSource];
    XCTAssertThrowsSpecificNamed([self.style addSource:rasterTileSource], NSException, MHRedundantSourceException);

    MHVectorTileSource *vectorTileSource = [[MHVectorTileSource alloc] initWithIdentifier:@"vectorTileSource" configurationURL:[NSURL URLWithString:@".json"]];
    [self.style addSource:vectorTileSource];
    XCTAssertThrowsSpecificNamed([self.style addSource:vectorTileSource], NSException, MHRedundantSourceException);
}

- (void)testAddingSourcesWithDuplicateIdentifiers {
    MHVectorTileSource *source1 = [[MHVectorTileSource alloc] initWithIdentifier:@"my-source" configurationURL:[NSURL URLWithString:@"maptiler://sources/hillshades"]];
    MHVectorTileSource *source2 = [[MHVectorTileSource alloc] initWithIdentifier:@"my-source" configurationURL:[NSURL URLWithString:@"maptiler://sources/hillshades"]];

    [self.style addSource: source1];
    XCTAssertThrowsSpecificNamed([self.style addSource: source2], NSException, MHRedundantSourceIdentifierException);
}

- (void)testRemovingSourcesBeforeAddingThem {
    MHRasterTileSource *rasterTileSource = [[MHRasterTileSource alloc] initWithIdentifier:@"raster-tile-source" tileURLTemplates:@[] options:nil];
    [self.style removeSource:rasterTileSource];
    [self.style addSource:rasterTileSource];
    XCTAssertNotNil([self.style sourceWithIdentifier:rasterTileSource.identifier]);

    MHShapeSource *shapeSource = [[MHShapeSource alloc] initWithIdentifier:@"shape-source" shape:nil options:nil];
    [self.style removeSource:shapeSource];
    [self.style addSource:shapeSource];
    XCTAssertNotNil([self.style sourceWithIdentifier:shapeSource.identifier]);

    MHVectorTileSource *vectorTileSource = [[MHVectorTileSource alloc] initWithIdentifier:@"vector-tile-source" tileURLTemplates:@[] options:nil];
    [self.style removeSource:vectorTileSource];
    [self.style addSource:vectorTileSource];
    XCTAssertNotNil([self.style sourceWithIdentifier:vectorTileSource.identifier]);
}

- (void)testAddingSourceOfTypeABeforeSourceOfTypeBWithSameIdentifier {
    // Add a raster tile source
    MHRasterTileSource *rasterTileSource = [[MHRasterTileSource alloc] initWithIdentifier:@"some-identifier" tileURLTemplates:@[] options:nil];
    [self.style addSource:rasterTileSource];

    // Attempt to remove an image source with the same identifier as the raster tile source
    MHImageSource *imageSource = [[MHImageSource alloc] initWithIdentifier:@"some-identifier" coordinateQuad: { } URL:[NSURL URLWithString:@"http://host/image.png"]];
    [self.style removeSource:imageSource];
    // The raster tile source should still be added
    XCTAssertTrue([[self.style sourceWithIdentifier:rasterTileSource.identifier] isMemberOfClass:[MHRasterTileSource class]]);

    // Remove the raster tile source
    [self.style removeSource:rasterTileSource];

    // Add the shape source
    [self.style addSource:imageSource];

    // Attempt to remove a vector tile source with the same identifer as the shape source
    MHVectorTileSource *vectorTileSource = [[MHVectorTileSource alloc] initWithIdentifier:@"some-identifier" tileURLTemplates:@[] options:nil];
    [self.style removeSource:vectorTileSource];
    // The image source should still be added
    XCTAssertTrue([[self.style sourceWithIdentifier:imageSource.identifier] isMemberOfClass:[MHImageSource class]]);

    // Remove the image source
    [self.style removeSource:imageSource];

    // Add the vector tile source
    [self.style addSource:vectorTileSource];

    // Attempt to remove the previously created raster tile source that has the same identifer as the shape source
    [self.style removeSource:rasterTileSource];
    // The vector tile source should still be added
    XCTAssertTrue([[self.style sourceWithIdentifier:imageSource.identifier] isMemberOfClass:[MHVectorTileSource class]]);
}

- (void)testRemovingSourceInUse {
    // Add a raster tile source
    MHVectorTileSource *vectorTileSource = [[MHVectorTileSource alloc] initWithIdentifier:@"some-identifier" tileURLTemplates:@[] options:nil];
    [self.style addSource:vectorTileSource];
    
    // Add a layer using it
    MHFillStyleLayer *fillLayer = [[MHFillStyleLayer alloc] initWithIdentifier:@"fillLayer" source:vectorTileSource];
    [self.style addLayer:fillLayer];

    // Attempt to remove the raster tile source
    NSError *error;
    BOOL result = [self.style removeSource:vectorTileSource error:&error];
    
    XCTAssertFalse(result);
    XCTAssertEqualObjects(error.domain, MHErrorDomain);
    XCTAssertEqual(error.code, MHErrorCodeSourceIsInUseCannotRemove);
    
    // Ensure it is still there
    XCTAssertTrue([[self.style sourceWithIdentifier:vectorTileSource.identifier] isMemberOfClass:[MHVectorTileSource class]]);
}

- (void)testLayers {
    NSArray<MHStyleLayer *> *initialLayers = self.style.layers;
    if ([initialLayers.firstObject.identifier isEqualToString:@"org.maplibre.annotations.points"]) {
        XCTAssertEqual(self.style.layers.count, 1UL);
    } else {
        XCTAssertEqual(self.style.layers.count, 0UL);
    }
    MHShapeSource *shapeSource = [[MHShapeSource alloc] initWithIdentifier:@"shapeSource" shape:nil options:nil];
    [self.style addSource:shapeSource];
    MHFillStyleLayer *fillLayer = [[MHFillStyleLayer alloc] initWithIdentifier:@"fillLayer" source:shapeSource];
    [self.style addLayer:fillLayer];
    XCTAssertEqual(self.style.layers.count, initialLayers.count + 1);
    XCTAssertEqual(fillLayer, [self.style layerWithIdentifier:@"fillLayer"]);
    [self.style removeLayer:fillLayer];
    XCTAssertEqual(self.style.layers.count, initialLayers.count);
}

- (void)testAddingLayersTwice {
    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"shapeSource" shape:nil options:nil];

    MHBackgroundStyleLayer *backgroundLayer = [[MHBackgroundStyleLayer alloc] initWithIdentifier:@"backgroundLayer"];
    [self.style addLayer:backgroundLayer];
    XCTAssertThrowsSpecificNamed([self.style addLayer:backgroundLayer], NSException, MHRedundantLayerException);

    MHCircleStyleLayer *circleLayer = [[MHCircleStyleLayer alloc] initWithIdentifier:@"circleLayer" source:source];
    [self.style addLayer:circleLayer];
    XCTAssertThrowsSpecificNamed([self.style addLayer:circleLayer], NSException, MHRedundantLayerException);

    MHFillStyleLayer *fillLayer = [[MHFillStyleLayer alloc] initWithIdentifier:@"fillLayer" source:source];
    [self.style addLayer:fillLayer];
    XCTAssertThrowsSpecificNamed([self.style addLayer:fillLayer], NSException, MHRedundantLayerException);

    MHLineStyleLayer *lineLayer = [[MHLineStyleLayer alloc] initWithIdentifier:@"lineLayer" source:source];
    [self.style addLayer:lineLayer];
    XCTAssertThrowsSpecificNamed([self.style addLayer:lineLayer], NSException, MHRedundantLayerException);

    MHRasterStyleLayer *rasterLayer = [[MHRasterStyleLayer alloc] initWithIdentifier:@"rasterLayer" source:source];
    [self.style addLayer:rasterLayer];
    XCTAssertThrowsSpecificNamed([self.style addLayer:rasterLayer], NSException, MHRedundantLayerException);

    MHSymbolStyleLayer *symbolLayer = [[MHSymbolStyleLayer alloc] initWithIdentifier:@"symbolLayer" source:source];
    [self.style addLayer:symbolLayer];
    XCTAssertThrowsSpecificNamed([self.style addLayer:symbolLayer], NSException, MHRedundantLayerException);
}

- (void)testAddingLayersWithDuplicateIdentifiers {
    // Just some source
    MHVectorTileSource *source = [[MHVectorTileSource alloc] initWithIdentifier:@"my-source" configurationURL:[NSURL URLWithString:@"maptiler://sources/hillshades"]];
    [self.style addSource: source];

    // Add initial layer
    MHFillStyleLayer *initial = [[MHFillStyleLayer alloc] initWithIdentifier:@"my-layer" source:source];
    [self.style addLayer:initial];

    // Try to add the duplicate
    XCTAssertThrowsSpecificNamed([self.style addLayer:[[MHFillStyleLayer alloc] initWithIdentifier:@"my-layer" source:source]], NSException, @"MHRedundantLayerIdentifierException");
    XCTAssertThrowsSpecificNamed([self.style insertLayer:[[MHFillStyleLayer alloc] initWithIdentifier:@"my-layer" source:source] belowLayer:initial],NSException, @"MHRedundantLayerIdentifierException");
    XCTAssertThrowsSpecificNamed([self.style insertLayer:[[MHFillStyleLayer alloc] initWithIdentifier:@"my-layer" source:source] aboveLayer:initial], NSException, @"MHRedundantLayerIdentifierException");
    XCTAssertThrowsSpecificNamed([self.style insertLayer:[[MHFillStyleLayer alloc] initWithIdentifier:@"my-layer" source:source] atIndex:0], NSException, @"MHRedundantLayerIdentifierException");
    XCTAssertThrowsSpecificNamed([self.style insertLayer:[[MHCustomStyleLayer alloc] initWithIdentifier:@"my-layer"] atIndex:0], NSException, @"MHRedundantLayerIdentifierException");
}

- (void)testRemovingLayerBeforeAddingSameLayer {
    {
        MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"shape-source-removing-before-adding" shape:nil options:nil];
        
        // Attempting to find a layer with identifier will trigger an exception if the source associated with the layer is not added
        [self.style addSource:source];
        
        MHFillStyleLayer *fillLayer = [[MHFillStyleLayer alloc] initWithIdentifier:@"fill-layer" source:source];
        [self.style removeLayer:fillLayer];
        [self.style addLayer:fillLayer];
        XCTAssertNotNil([self.style layerWithIdentifier:fillLayer.identifier]);
        
        MHSymbolStyleLayer *symbolLayer = [[MHSymbolStyleLayer alloc] initWithIdentifier:@"symbol-layer" source:source];
        [self.style removeLayer:symbolLayer];
        [self.style addLayer:symbolLayer];
        XCTAssertNotNil([self.style layerWithIdentifier:symbolLayer.identifier]);
        
        MHLineStyleLayer *lineLayer = [[MHLineStyleLayer alloc] initWithIdentifier:@"line-layer" source:source];
        [self.style removeLayer:lineLayer];
        [self.style addLayer:lineLayer];
        XCTAssertNotNil([self.style layerWithIdentifier:lineLayer.identifier]);
        
        MHCircleStyleLayer *circleLayer = [[MHCircleStyleLayer alloc] initWithIdentifier:@"circle-layer" source:source];
        [self.style removeLayer:circleLayer];
        [self.style addLayer:circleLayer];
        XCTAssertNotNil([self.style layerWithIdentifier:circleLayer.identifier]);
        
        MHBackgroundStyleLayer *backgroundLayer = [[MHBackgroundStyleLayer alloc] initWithIdentifier:@"background-layer"];
        [self.style removeLayer:backgroundLayer];
        [self.style addLayer:backgroundLayer];
        XCTAssertNotNil([self.style layerWithIdentifier:backgroundLayer.identifier]);
    }
    
    {
        MHRasterTileSource *rasterSource = [[MHRasterTileSource alloc] initWithIdentifier:@"raster-tile-source" tileURLTemplates:@[] options:nil];
        [self.style addSource:rasterSource];
        
        MHRasterStyleLayer *rasterLayer = [[MHRasterStyleLayer alloc] initWithIdentifier:@"raster-layer" source:rasterSource];
        [self.style removeLayer:rasterLayer];
        [self.style addLayer:rasterLayer];
        XCTAssertNotNil([self.style layerWithIdentifier:rasterLayer.identifier]);
    }
}

- (void)testAddingLayerOfTypeABeforeRemovingLayerOfTypeBWithSameIdentifier {
    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"shape-source-identifier" shape:nil options:nil];
    [self.style addSource:source];
    
    // Add a fill layer
    MHFillStyleLayer *fillLayer = [[MHFillStyleLayer alloc] initWithIdentifier:@"some-identifier" source:source];
    [self.style addLayer:fillLayer];
    
    // Attempt to remove a line layer with the same identifier as the fill layer
    MHLineStyleLayer *lineLayer = [[MHLineStyleLayer alloc] initWithIdentifier:fillLayer.identifier source:source];
    [self.style removeLayer:lineLayer];
    
    XCTAssertTrue([[self.style layerWithIdentifier:fillLayer.identifier] isMemberOfClass:[MHFillStyleLayer class]]);
}

- (NSString *)stringWithContentsOfStyleHeader {
    NSURL *styleHeaderURL = [[[NSBundle mgl_frameworkBundle].bundleURL
                              URLByAppendingPathComponent:@"Headers" isDirectory:YES]
                             URLByAppendingPathComponent:@"MHStyle.h"];
    NSError *styleHeaderError;
    NSString *styleHeader = [NSString stringWithContentsOfURL:styleHeaderURL usedEncoding:nil error:&styleHeaderError];
    XCTAssertNil(styleHeaderError, @"Error getting contents of MHStyle.h.");
    return styleHeader;
}

- (void)testImages {
    NSString *imageName = @"TrackingLocationMask";
#if TARGET_OS_IPHONE
    MHImage *image = [MHImage imageNamed:imageName
                                  inBundle:[NSBundle bundleForClass:[self class]]
             compatibleWithTraitCollection:nil];
#else
    MHImage *image = [[NSBundle bundleForClass:[self class]] imageForResource:imageName];
#endif
    XCTAssertNotNil(image);
    
    [self.style setImage:image forName:imageName];
    MHImage *styleImage = [self.style imageForName:imageName];
    
    XCTAssertNotNil(styleImage);
    XCTAssertEqual(image.size.width, styleImage.size.width);
    XCTAssertEqual(image.size.height, styleImage.size.height);
}

- (void)testLayersOrder {
    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"amsterdam" ofType:@"geojson"];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"sourceID" URL:url options:nil];
    [self.style addSource:source];

    MHCircleStyleLayer *layer1 = [[MHCircleStyleLayer alloc] initWithIdentifier:@"layer1" source:source];
    [self.style addLayer:layer1];

    MHCircleStyleLayer *layer3 = [[MHCircleStyleLayer alloc] initWithIdentifier:@"layer3" source:source];
    [self.style addLayer:layer3];

    MHCircleStyleLayer *layer2 = [[MHCircleStyleLayer alloc] initWithIdentifier:@"layer2" source:source];
    [self.style insertLayer:layer2 aboveLayer:layer1];

    MHCircleStyleLayer *layer4 = [[MHCircleStyleLayer alloc] initWithIdentifier:@"layer4" source:source];
    [self.style insertLayer:layer4 aboveLayer:layer3];

    MHCircleStyleLayer *layer0 = [[MHCircleStyleLayer alloc] initWithIdentifier:@"layer0" source:source];
    [self.style insertLayer:layer0 belowLayer:layer1];

    NSArray<MHStyleLayer *> *layers = [self.style layers];
    NSUInteger startIndex = 0;
    if ([layers.firstObject.identifier isEqualToString:@"org.maplibre.annotations.points"]) {
        startIndex++;
    }

    XCTAssertEqualObjects(layers[startIndex++].identifier, layer0.identifier);
    XCTAssertEqualObjects(layers[startIndex++].identifier, layer1.identifier);
    XCTAssertEqualObjects(layers[startIndex++].identifier, layer2.identifier);
    XCTAssertEqualObjects(layers[startIndex++].identifier, layer3.identifier);
    XCTAssertEqualObjects(layers[startIndex++].identifier, layer4.identifier);
}

// MARK: Localization tests

- (void)testLanguageMatching {
    {
        NSArray *preferences = @[@"en"];
        XCTAssertEqualObjects([MHVectorTileSource preferredMapboxStreetsLanguageForPreferences:preferences], @"en");
    }
    {
        NSArray *preferences = @[@"en-US"];
        XCTAssertEqualObjects([MHVectorTileSource preferredMapboxStreetsLanguageForPreferences:preferences], @"en");
    }
    {
        NSArray *preferences = @[@"fr"];
        XCTAssertEqualObjects([MHVectorTileSource preferredMapboxStreetsLanguageForPreferences:preferences], @"fr");
    }
    {
        NSArray *preferences = @[@"zh-Hans"];
        XCTAssertEqualObjects([MHVectorTileSource preferredMapboxStreetsLanguageForPreferences:preferences], @"zh-Hans");
    }
    {
        NSArray *preferences = @[@"zh-Hans", @"en"];
        XCTAssertEqualObjects([MHVectorTileSource preferredMapboxStreetsLanguageForPreferences:preferences], @"zh-Hans");
    }
    {
        NSArray *preferences = @[@"zh-Hant"];
        XCTAssertEqualObjects([MHVectorTileSource preferredMapboxStreetsLanguageForPreferences:preferences], @"zh-Hant");
    }
    {
        NSArray *preferences = @[@"en", @"fr", @"el"];
        XCTAssertEqualObjects([MHVectorTileSource preferredMapboxStreetsLanguageForPreferences:preferences], @"en");
    }
    {
        NSArray *preferences = @[@"tlh"];
        XCTAssertNil([MHVectorTileSource preferredMapboxStreetsLanguageForPreferences:preferences]);
    }
    {
        NSArray *preferences = @[@"tlh", @"en"];
        XCTAssertEqualObjects([MHVectorTileSource preferredMapboxStreetsLanguageForPreferences:preferences], @"en");
    }
    {
        NSArray *preferences = @[@"mul"];
        XCTAssertNil([MHVectorTileSource preferredMapboxStreetsLanguageForPreferences:preferences]);
    }
}

// MARK: Transition tests

- (void)testTransition
{
    MHTransition transitionTest = MHTransitionMake(5, 4);
    
    self.style.transition = transitionTest;
    
    XCTAssert(self.style.transition.delay == transitionTest.delay);
    XCTAssert(self.style.transition.duration == transitionTest.duration);
}

- (void)testPerformsPlacementTransitions
{
    XCTAssertTrue(self.style.performsPlacementTransitions, @"The default value for enabling placement transitions should be YES.");
    
    self.style.performsPlacementTransitions = NO;
    XCTAssertFalse(self.style.performsPlacementTransitions, @"Enabling placement transitions should be NO.");
}

@end
