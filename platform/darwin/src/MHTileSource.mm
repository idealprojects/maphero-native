#import "MHTileSource_Private.h"

#import "MHAttributionInfo_Private.h"
#import "MHGeometry_Private.h"
#import "MHRasterDEMSource.h"
#import "NSString+MHAdditions.h"
#import "NSValue+MHAdditions.h"

#if TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#else
    #import <Cocoa/Cocoa.h>
#endif

#include <mbgl/util/tileset.hpp>

const MHTileSourceOption MHTileSourceOptionMinimumZoomLevel = @"MHTileSourceOptionMinimumZoomLevel";
const MHTileSourceOption MHTileSourceOptionMaximumZoomLevel = @"MHTileSourceOptionMaximumZoomLevel";
const MHTileSourceOption MHTileSourceOptionCoordinateBounds = @"MHTileSourceOptionCoordinateBounds";
const MHTileSourceOption MHTileSourceOptionAttributionHTMLString = @"MHTileSourceOptionAttributionHTMLString";
const MHTileSourceOption MHTileSourceOptionAttributionInfos = @"MHTileSourceOptionAttributionInfos";
const MHTileSourceOption MHTileSourceOptionTileCoordinateSystem = @"MHTileSourceOptionTileCoordinateSystem";
const MHTileSourceOption MHTileSourceOptionDEMEncoding = @"MHTileSourceOptionDEMEncoding";

@implementation MHTileSource

- (NSURL *)configurationURL {
    [NSException raise:MHAbstractClassException
                format:@"MHTileSource is an abstract class"];
    return nil;
}

- (NSArray<MHAttributionInfo *> *)attributionInfos {
    return [self attributionInfosWithFontSize:0 linkColor:nil];
}

- (NSArray<MHAttributionInfo *> *)attributionInfosWithFontSize:(CGFloat)fontSize linkColor:(nullable MHColor *)linkColor {
    return [MHAttributionInfo attributionInfosFromHTMLString:self.attributionHTMLString
                                                     fontSize:fontSize
                                                    linkColor:linkColor];
}

- (NSString *)attributionHTMLString {
    [NSException raise:MHAbstractClassException
                format:@"MHTileSource is an abstract class"];
    return nil;
}

@end

mbgl::Tileset MHTileSetFromTileURLTemplates(NSArray<NSString *> *tileURLTemplates, NSDictionary<MHTileSourceOption, id> * _Nullable options) {
    mbgl::Tileset tileSet;

    for (NSString *tileURLTemplate in tileURLTemplates) {
        tileSet.tiles.push_back(tileURLTemplate.UTF8String);
    }

    // set the minimum / maximum zoom range to the values specified by this class if they
    // were set. otherwise, use the core objects default values
    if (NSNumber *minimumZoomLevel = options[MHTileSourceOptionMinimumZoomLevel]) {
        if (![minimumZoomLevel isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHTileSourceOptionMinimumZoomLevel must be set to an NSNumber."];
        }
        tileSet.zoomRange.min = minimumZoomLevel.integerValue;
    }
    if (NSNumber *maximumZoomLevel = options[MHTileSourceOptionMaximumZoomLevel]) {
        if (![maximumZoomLevel isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHTileSourceOptionMinimumZoomLevel must be set to an NSNumber."];
        }
        tileSet.zoomRange.max = maximumZoomLevel.integerValue;
    }
    if (tileSet.zoomRange.min > tileSet.zoomRange.max) {
        [NSException raise:NSInvalidArgumentException
                    format:@"MHTileSourceOptionMinimumZoomLevel must be less than MHTileSourceOptionMaximumZoomLevel."];
    }
    
    if (NSValue *coordinateBounds = options[MHTileSourceOptionCoordinateBounds]) {
        if (![coordinateBounds isKindOfClass:[NSValue class]]
            && strcmp(coordinateBounds.objCType, @encode(MHCoordinateBounds)) == 0) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHTileSourceOptionCoordinateBounds must be set to an NSValue containing an MHCoordinateBounds."];
        }
        tileSet.bounds = MHLatLngBoundsFromCoordinateBounds(coordinateBounds.MHCoordinateBoundsValue);
    }

    if (NSString *attribution = options[MHTileSourceOptionAttributionHTMLString]) {
        if (![attribution isKindOfClass:[NSString class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHTileSourceOptionAttributionHTMLString must be set to a string."];
        }
        tileSet.attribution = attribution.UTF8String;
    }

    if (NSArray *attributionInfos = options[MHTileSourceOptionAttributionInfos]) {
        if (![attributionInfos isKindOfClass:[NSArray class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHTileSourceOptionAttributionInfos must be set to a string."];
        }

        NSAttributedString *attributedString = [MHAttributionInfo attributedStringForAttributionInfos:attributionInfos];
#if TARGET_OS_IPHONE
        static NSString * const NSExcludedElementsDocumentAttribute = @"ExcludedElements";
#endif
        NSDictionary *documentAttributes = @{
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding),
            // The attribution string is meant to be a simple, inline fragment, not a full-fledged, validating document.
            NSExcludedElementsDocumentAttribute: @[@"XML", @"DOCTYPE", @"html", @"head", @"meta", @"title", @"style", @"body", @"p"],
        };
        NSData *data = [attributedString dataFromRange:attributedString.mgl_wholeRange documentAttributes:documentAttributes error:NULL];
        NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        tileSet.attribution = html.UTF8String;
    }

    if (NSNumber *tileCoordinateSystemNumber = options[MHTileSourceOptionTileCoordinateSystem]) {
        if (![tileCoordinateSystemNumber isKindOfClass:[NSValue class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHTileSourceOptionTileCoordinateSystem must be set to an NSValue or NSNumber."];
        }
        MHTileCoordinateSystem tileCoordinateSystem;
        [tileCoordinateSystemNumber getValue:&tileCoordinateSystem];
        switch (tileCoordinateSystem) {
            case MHTileCoordinateSystemXYZ:
                tileSet.scheme = mbgl::Tileset::Scheme::XYZ;
                break;
            case MHTileCoordinateSystemTMS:
                tileSet.scheme = mbgl::Tileset::Scheme::TMS;
                break;
        }
    }

    if (NSNumber *demEncodingNumber = options[MHTileSourceOptionDEMEncoding]) {
        if (![demEncodingNumber isKindOfClass:[NSValue class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHTileSourceOptionDEMEncoding must be set to an NSValue or NSNumber."];
        }
        MHDEMEncoding demEncoding;
        [demEncodingNumber getValue:&demEncoding];
        switch (demEncoding) {
            case MHDEMEncodingMapbox:
                tileSet.encoding = mbgl::Tileset::DEMEncoding::Mapbox;
                break;
            case MHDEMEncodingTerrarium:
                tileSet.encoding = mbgl::Tileset::DEMEncoding::Terrarium;
                break;
        }
    }

    return tileSet;
}
