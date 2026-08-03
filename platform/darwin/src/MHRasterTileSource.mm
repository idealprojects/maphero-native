#import "MHRasterTileSource_Private.h"

#import "MHLoggingConfiguration_Private.h"
#import "MHMapView_Private.h"
#import "MHSource_Private.h"
#import "MHTileSource_Private.h"
#import "NSURL+MHAdditions.h"

#include <mbgl/map/map.hpp>
#include <mbgl/style/sources/raster_source.hpp>

const MHTileSourceOption MHTileSourceOptionTileSize = @"MHTileSourceOptionTileSize";

static const CGFloat MHRasterTileSourceClassicTileSize = 256;
static const CGFloat MHRasterTileSourceRetinaTileSize = 512;

@interface MHRasterTileSource ()

@property (nonatomic, readonly) mbgl::style::RasterSource *rawSource;

@end

@implementation MHRasterTileSource

- (instancetype)initWithIdentifier:(NSString *)identifier configurationURL:(NSURL *)configurationURL {
    // The style specification default is 512, but 256 is the expected value for
    // any tile set that would be accessed through a mapbox: URL and therefore
    // any tile URL that this option currently affects.
    BOOL isMapboxURL = ([configurationURL.scheme isEqualToString:@"mapbox"]
                        && [configurationURL.host containsString:@"."]
                        && (!configurationURL.path.length || [configurationURL.path isEqualToString:@"/"]));
    CGFloat tileSize = isMapboxURL ? MHRasterTileSourceClassicTileSize : MHRasterTileSourceRetinaTileSize;
    return [self initWithIdentifier:identifier configurationURL:configurationURL tileSize:tileSize];
}

- (instancetype)initWithIdentifier:(NSString *)identifier configurationURL:(NSURL *)configurationURL tileSize:(CGFloat)tileSize {
    NSString *configurationURLString = configurationURL.mgl_URLByStandardizingScheme.absoluteString;
    auto source = [self pendingSourceWithIdentifier:identifier urlOrTileset:configurationURLString.UTF8String tileSize:uint16_t(round(tileSize))];
    return self = [super initWithPendingSource:std::move(source)];
}

- (std::unique_ptr<mbgl::style::RasterSource>)pendingSourceWithIdentifier:(NSString *)identifier urlOrTileset:(mbgl::variant<std::string, mbgl::Tileset>)urlOrTileset tileSize:(uint16_t)tileSize {
    auto source = std::make_unique<mbgl::style::RasterSource>(identifier.UTF8String,
                                                              urlOrTileset,
                                                              tileSize);
    return source;
}

- (instancetype)initWithIdentifier:(NSString *)identifier tileURLTemplates:(NSArray<NSString *> *)tileURLTemplates options:(nullable NSDictionary<MHTileSourceOption, id> *)options {
    mbgl::Tileset tileSet = MHTileSetFromTileURLTemplates(tileURLTemplates, options);

    uint16_t tileSize = MHRasterTileSourceRetinaTileSize;
    if (NSNumber *tileSizeNumber = options[MHTileSourceOptionTileSize]) {
        if (![tileSizeNumber isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHTileSourceOptionTileSize must be set to an NSNumber."];
        }
        tileSize = static_cast<uint16_t>(round(tileSizeNumber.doubleValue));
    }

    auto source = [self pendingSourceWithIdentifier:identifier urlOrTileset:tileSet tileSize:tileSize];
    return self = [super initWithPendingSource:std::move(source)];
}

- (mbgl::style::RasterSource *)rawSource {
    return (mbgl::style::RasterSource *)super.rawSource;
}

- (NSURL *)configurationURL {
    MHAssertStyleSourceIsValid();
    auto url = self.rawSource->getURL();
    return url ? [NSURL URLWithString:@(url->c_str())] : nil;
}

- (NSString *)attributionHTMLString {
    if (!self.rawSource) {
        MHAssert(0, @"Source with identifier `%@` was invalidated after a style change", self.identifier);
        return nil;
    }

    auto attribution = self.rawSource->getAttribution();
    return attribution ? @(attribution->c_str()) : nil;
}

@end
