#import "StyleLayerIconTransformer.h"

#import <Mapbox.h>

@implementation StyleLayerIconTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(MHStyleLayer *)layer {
    if ([layer isKindOfClass:[MHBackgroundStyleLayer class]]) {
        return [NSImage imageNamed:@"background"];
    }
    if ([layer isKindOfClass:[MHCircleStyleLayer class]]) {
        return [NSImage imageNamed:@"circle"];
    }
    if ([layer isKindOfClass:[MHFillStyleLayer class]]) {
        return [NSImage imageNamed:@"fill"];
    }
    if ([layer isKindOfClass:[MHFillExtrusionStyleLayer class]]) {
        return [NSImage imageNamed:@"fill-extrusion"];
    }
    if ([layer isKindOfClass:[MHLineStyleLayer class]]) {
        return [NSImage imageNamed:@"NSListViewTemplate"];
    }
    if ([layer isKindOfClass:[MHRasterStyleLayer class]]) {
        return [[NSWorkspace sharedWorkspace] iconForFileType:@"jpg"];
    }
    if ([layer isKindOfClass:[MHSymbolStyleLayer class]]) {
        return [NSImage imageNamed:@"symbol"];
    }
    if ([layer isKindOfClass:[MHHeatmapStyleLayer class]]) {
        return [NSImage imageNamed:@"heatmap"];
    }
    if ([layer isKindOfClass:[MHHillshadeStyleLayer class]]) {
        return [NSImage imageNamed:@"hillshade"];
    }
    
    return nil;
}

@end
