#import <XCTest/XCTest.h>

#import <Mapbox.h>
#import "MHTileSource_Private.h"
#import "MHGeometry_Private.h"

#include <mbgl/util/tileset.hpp>

@interface MHTileSetTests : XCTestCase

@end

@implementation MHTileSetTests

- (void)testTileSetFromTileURLTemplates {
    // a tile set that provides an mbgl tile set
    NSArray *tileURLTemplates = @[@"tile.1", @"tile.2", @"tile.3"];
    mbgl::Tileset tileSet = MHTileSetFromTileURLTemplates(tileURLTemplates, nil);

    // has the correct URL templates
    XCTAssertEqual(tileSet.tiles.size(), 3UL);
    XCTAssertEqual(tileSet.tiles[0], "tile.1");
    XCTAssertEqual(tileSet.tiles[1], "tile.2");
    XCTAssertEqual(tileSet.tiles[2], "tile.3");

    // has the default scheme
    XCTAssertEqual(tileSet.scheme, mbgl::Tileset::Scheme::XYZ);

    // when the tile set has no min or max zoom level set
    // the mbgl object has default values for min and max zoom level
    XCTAssertEqual(tileSet.zoomRange.min, 0);
    XCTAssertEqual(tileSet.zoomRange.max, 22);

    // when the tile set has min and/or max zoom level set
    tileSet = MHTileSetFromTileURLTemplates(@[@"tile.1"], @{
        MHTileSourceOptionMinimumZoomLevel: @1,
        MHTileSourceOptionMaximumZoomLevel: @2,
    });

    // the mbgl object reflects the set values for min and max zoom level
    XCTAssertEqual(tileSet.zoomRange.min, 1);
    XCTAssertEqual(tileSet.zoomRange.max, 2);

    // when the tile set has a bounds set
    MHCoordinateBounds bounds = MHCoordinateBoundsMake(CLLocationCoordinate2DMake(12, 34), CLLocationCoordinate2DMake(56, 78));
    tileSet = MHTileSetFromTileURLTemplates(@[@"tile.1"], @{
        MHTileSourceOptionCoordinateBounds: @(bounds),
    });

    // the mbgl object reflects the set values for the bounds
    XCTAssert(!!tileSet.bounds, @"The bounds are set after setting the bounds");
    if (tileSet.bounds) {
        MHCoordinateBounds actual = MHCoordinateBoundsFromLatLngBounds(*tileSet.bounds);
        XCTAssert(MHCoordinateBoundsEqualToCoordinateBounds(bounds, actual), @"The bounds round-trip");
    }

    // when the tile set has an attribution
    NSString *attribution = @"my tileset © ©️🎈";
    tileSet = MHTileSetFromTileURLTemplates(tileURLTemplates, @{
        MHTileSourceOptionAttributionHTMLString: attribution,
    });

    // the attribution is reflected by the mbgl tileset
    XCTAssertEqual(tileSet.attribution, attribution.UTF8String);

    // when the tile set has attribution infos
    MHAttributionInfo *mapboxInfo = [[MHAttributionInfo alloc] initWithTitle:[[NSAttributedString alloc] initWithString:@"Mapbox"]
                                                                           URL:[NSURL URLWithString:@"https://www.mapbox.com/"]];
#if TARGET_OS_IPHONE
    UIColor *redColor = [UIColor redColor];
#else
    // CSS uses the sRGB color space.
    // AppKit incorrectly uses calibrated RGB when exporting HTML, so input
    // calibrated RGB to ensure round-tripping.
    // <rdar://problem/46115233> <http://www.openradar.me/46115233>
    NSColor *redColor = [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:1];
#endif
    NSAttributedString *gl = [[NSAttributedString alloc] initWithString:@"GL" attributes:@{
        NSBackgroundColorAttributeName: redColor,
    }];
    MHAttributionInfo *glInfo = [[MHAttributionInfo alloc] initWithTitle:gl URL:nil];
    tileSet = MHTileSetFromTileURLTemplates(tileURLTemplates, @{
        MHTileSourceOptionAttributionInfos: @[mapboxInfo, glInfo],
    });

    // the attribution is reflected by the mbgl tileset
#if TARGET_OS_IPHONE
    NSString *html;
    if (@available(iOS 13.0, *)) {
        // TODO: investigate visual impact
        // iOS 13 evidently changes font size from points to pixels
        html = (@"<font style=\"font-family: 'Helvetica'; font-weight: normal; font-style: normal; font-size: 12.00px\">"
                @"<a href=\"https://www.mapbox.com/\">Mapbox</a> </font>"
                @"<font style=\"font-family: 'Helvetica'; font-weight: normal; font-style: normal; font-size: 12.00px; background-color: #ff0000\">GL</font>\n");
    } else {
        html = (@"<font style=\"font-family: 'Helvetica'; font-weight: normal; font-style: normal; font-size: 12.00pt\">"
                @"<a href=\"https://www.mapbox.com/\">Mapbox</a> </font>"
                @"<font style=\"font-family: 'Helvetica'; font-weight: normal; font-style: normal; font-size: 12.00pt; background-color: #ff0000\">GL</font>\n");
    }
#else
    NSString *html = (@"<font face=\"Helvetica\" size=\"3\" style=\"font: 12.0px Helvetica\">"
                      @"<a href=\"https://www.mapbox.com/\">Mapbox</a> </font>"
                      @"<font face=\"Helvetica\" size=\"3\" style=\"font: 12.0px Helvetica; background-color: #ff0000\">GL</font>\n");
#endif
    XCTAssertEqualObjects(@(tileSet.attribution.c_str()), html);

    // when the tile coordinate system is changed using an NSNumber
    tileSet = MHTileSetFromTileURLTemplates(tileURLTemplates, @{
        MHTileSourceOptionTileCoordinateSystem: @(MHTileCoordinateSystemTMS),
    });

    // the scheme is reflected by the mbgl tileset
    XCTAssertEqual(tileSet.scheme, mbgl::Tileset::Scheme::TMS);

    // when the tile coordinate system is changed using an NSValue
    MHTileCoordinateSystem tms = MHTileCoordinateSystemTMS;
    tileSet = MHTileSetFromTileURLTemplates(tileURLTemplates, @{
        MHTileSourceOptionTileCoordinateSystem: [NSValue value:&tms withObjCType:@encode(MHTileCoordinateSystem)],
    });

    // the scheme is reflected by the mbgl tileset
    XCTAssertEqual(tileSet.scheme, mbgl::Tileset::Scheme::TMS);

    // when the dem encoding is changed using an NSNumber
    tileSet = MHTileSetFromTileURLTemplates(tileURLTemplates, @{
        MHTileSourceOptionDEMEncoding: @(MHDEMEncodingTerrarium),
    });

    // the encoding is reflected by the mbgl tileset
    XCTAssertEqual(tileSet.encoding, mbgl::Tileset::DEMEncoding::Terrarium);

    // when the dem encoding is changed using an NSValue
    MHDEMEncoding terrarium = MHDEMEncodingTerrarium;
    tileSet = MHTileSetFromTileURLTemplates(tileURLTemplates, @{
        MHTileSourceOptionDEMEncoding: [NSValue value:&terrarium withObjCType:@encode(MHDEMEncoding)],
    });

    // the encoding is reflected by the mbgl tileset
    XCTAssertEqual(tileSet.encoding, mbgl::Tileset::DEMEncoding::Terrarium);
}

- (void)testInvalidTileSet {
    // a tile set that provides an mbgl tile set and invalid (crossed) minimum and maximum zoom levels throws an exception
    XCTAssertThrowsSpecificNamed(MHTileSetFromTileURLTemplates(@[@"tile.1"], @{
        MHTileSourceOptionMinimumZoomLevel: @10,
        MHTileSourceOptionMaximumZoomLevel: @9,
    }), NSException, NSInvalidArgumentException);
}

@end
