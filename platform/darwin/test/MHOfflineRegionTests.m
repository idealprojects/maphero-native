#import <Mapbox.h>

#import <XCTest/XCTest.h>

@interface MHOfflineRegionTests : XCTestCase

@end

@implementation MHOfflineRegionTests

- (void)setUp {
    [super setUp];
    [MHSettings useWellKnownTileServer:MHMapTiler];
}

- (void)testStyleURLs {
    MHCoordinateBounds bounds = MHCoordinateBoundsMake(kCLLocationCoordinate2DInvalid, kCLLocationCoordinate2DInvalid);
    MHTilePyramidOfflineRegion *region = [[MHTilePyramidOfflineRegion alloc] initWithStyleURL:nil bounds:bounds fromZoomLevel:0 toZoomLevel:DBL_MAX];
    XCTAssertEqualObjects(region.styleURL, [MHStyle defaultStyleURL], @"Default style expected.");
    
    NSURL *localURL = [NSURL URLWithString:@"beautiful.style"];
    XCTAssertThrowsSpecificNamed([[MHTilePyramidOfflineRegion alloc] initWithStyleURL:localURL bounds:bounds fromZoomLevel:0 toZoomLevel:DBL_MAX], NSException, MHInvalidStyleURLException, @"No exception raised when initializing region with a local file URL as the style URL.");
}

- (void)testTilePyramidRegionEquality {
    [MHSettings useWellKnownTileServer:MHMapTiler];
    MHCoordinateBounds bounds = MHCoordinateBoundsMake(kCLLocationCoordinate2DInvalid, kCLLocationCoordinate2DInvalid);
    MHTilePyramidOfflineRegion *original = [[MHTilePyramidOfflineRegion alloc] initWithStyleURL:[[MHStyle predefinedStyle:@"Bright"] url] bounds:bounds fromZoomLevel:5 toZoomLevel:10];
    MHTilePyramidOfflineRegion *copy = [original copy];
    XCTAssertEqualObjects(original, copy, @"Tile pyramid region should be equal to its copy.");
    
    XCTAssertEqualObjects(original.styleURL, copy.styleURL, @"Style URL has changed.");
    XCTAssert(MHCoordinateBoundsEqualToCoordinateBounds(original.bounds, copy.bounds), @"Bounds have changed.");
    XCTAssertEqual(original.minimumZoomLevel, copy.minimumZoomLevel, @"Minimum zoom level has changed.");
    XCTAssertEqual(original.maximumZoomLevel, copy.maximumZoomLevel, @"Maximum zoom level has changed.");
    XCTAssertEqual(original.includesIdeographicGlyphs, copy.includesIdeographicGlyphs, @"Include ideographs has changed.");
}

- (void)testGeometryRegionEquality {
    NSString *geojson = @"{\"type\": \"Point\", \"coordinates\": [-3.8671874999999996, 52.482780222078226] }";
    NSError *error;
    MHShape *shape = [MHShape shapeWithData: [geojson dataUsingEncoding:NSUTF8StringEncoding] encoding: NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    
    MHShapeOfflineRegion *original = [[MHShapeOfflineRegion alloc] initWithStyleURL:[[MHStyle predefinedStyle:@"Bright"] url] shape:shape fromZoomLevel:5 toZoomLevel:10];
    original.includesIdeographicGlyphs = NO;
    MHShapeOfflineRegion *copy = [original copy];
    XCTAssertEqualObjects(original, copy, @"Shape region should be equal to its copy.");
    
    XCTAssertEqualObjects(original.styleURL, copy.styleURL, @"Style URL has changed.");
    XCTAssertEqualObjects(original.shape, copy.shape, @"Geometry has changed.");
    XCTAssertEqual(original.minimumZoomLevel, copy.minimumZoomLevel, @"Minimum zoom level has changed.");
    XCTAssertEqual(original.maximumZoomLevel, copy.maximumZoomLevel, @"Maximum zoom level has changed.");
    XCTAssertEqual(original.includesIdeographicGlyphs, copy.includesIdeographicGlyphs, @"Include ideographs has changed.");
}

- (void)testIncludesIdeographicGlyphsByDefault {
    
    // Tile pyramid offline region
    {
        MHCoordinateBounds bounds = MHCoordinateBoundsMake(kCLLocationCoordinate2DInvalid, kCLLocationCoordinate2DInvalid);
        MHTilePyramidOfflineRegion *tilePyramidOfflineRegion = [[MHTilePyramidOfflineRegion alloc] initWithStyleURL:[[MHStyle predefinedStyle:@"Bright"] url] bounds:bounds fromZoomLevel:5 toZoomLevel:10];
        XCTAssertFalse(tilePyramidOfflineRegion.includesIdeographicGlyphs, @"tile pyramid offline region should not include ideographic glyphs");
    }
    
    // Shape offline region
    {
        NSString *geojson = @"{\"type\": \"Point\", \"coordinates\": [-3.8671874999999996, 52.482780222078226] }";
        NSError *error;
        MHShape *shape = [MHShape shapeWithData: [geojson dataUsingEncoding:NSUTF8StringEncoding] encoding: NSUTF8StringEncoding error:&error];
        XCTAssertNil(error);
        MHShapeOfflineRegion *shapeOfflineRegion = [[MHShapeOfflineRegion alloc] initWithStyleURL:[[MHStyle predefinedStyle:@"Bright"] url] shape:shape fromZoomLevel:5 toZoomLevel:10];
        XCTAssertFalse(shapeOfflineRegion.includesIdeographicGlyphs, @"tile pyramid offline region should not include ideographic glyphs");
    }
}

@end
