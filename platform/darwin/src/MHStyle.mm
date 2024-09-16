#import "MHStyle_Private.h"

#import "MHMapView_Private.h"
#import "MHStyleLayer.h"
#import "MHStyleLayer_Private.h"
#import "MHFillStyleLayer.h"
#import "MHFillExtrusionStyleLayer.h"
#import "MHLineStyleLayer.h"
#import "MHCircleStyleLayer.h"
#import "MHSymbolStyleLayer.h"
#import "MHHeatmapStyleLayer.h"
#import "MHHillshadeStyleLayer.h"
#import "MHRasterStyleLayer.h"
#import "MHBackgroundStyleLayer.h"
#import "MHStyleLayerManager.h"

#import "MHSource.h"
#import "MHSource_Private.h"
#import "MHLight_Private.h"
#import "MHTileSource_Private.h"
#import "MHVectorTileSource_Private.h"
#import "MHRasterTileSource.h"
#import "MHRasterDEMSource.h"
#import "MHShapeSource.h"
#import "MHImageSource.h"

#import "MHAttributionInfo_Private.h"
#import "MHLoggingConfiguration_Private.h"

#include <mbgl/map/map.hpp>
#include <mbgl/style/style.hpp>
#include <mbgl/style/image.hpp>
#include <mbgl/style/light.hpp>
#include <mbgl/style/sources/geojson_source.hpp>
#include <mbgl/style/sources/vector_source.hpp>
#include <mbgl/style/sources/raster_source.hpp>
#include <mbgl/style/sources/raster_dem_source.hpp>
#include <mbgl/style/sources/image_source.hpp>

#import "NSDate+MHAdditions.h"

#import "MHCustomStyleLayer.h"

#if TARGET_OS_IPHONE
    #import "UIImage+MHAdditions.h"
#else
    #import "NSImage+MHAdditions.h"
#endif

const MHExceptionName MHInvalidStyleURLException = @"MHInvalidStyleURLException";
const MHExceptionName MHRedundantLayerException = @"MHRedundantLayerException";
const MHExceptionName MHRedundantLayerIdentifierException = @"MHRedundantLayerIdentifierException";
const MHExceptionName MHRedundantSourceException = @"MHRedundantSourceException";
const MHExceptionName MHRedundantSourceIdentifierException = @"MHRedundantSourceIdentifierException";

/**
 Model class for localization changes.
 */
@interface MHTextLanguage: NSObject
@property (strong, nonatomic) NSString *originalTextField;
@property (strong, nonatomic) NSString *updatedTextField;

- (instancetype)initWithTextLanguage:(NSString *)originalTextField updatedTextField:(NSString *)updatedTextField;

@end

@implementation MHTextLanguage
- (instancetype)initWithTextLanguage:(NSString *)originalTextField updatedTextField:(NSString *)updatedTextField
{
    if (self = [super init]) {
        _originalTextField = originalTextField;
        _updatedTextField = updatedTextField;
    }
    return self;
}
@end

@interface MHStyle()

@property (nonatomic, readonly, weak) id <MHStylable> stylable;
@property (nonatomic, readonly) mbgl::style::Style *rawStyle;
@property (readonly, copy, nullable) NSURL *URL;
@property (nonatomic, readwrite, strong) NSMutableDictionary<NSString *, MHCustomStyleLayer *> *customLayers;
@property (nonatomic) NSMutableDictionary<NSString *, NSDictionary<NSObject *, MHTextLanguage *> *> *localizedLayersByIdentifier;

@end

@implementation MHStyle

// MARK: Predefined style URLs

+ (NSArray<MHDefaultStyle*>*) predefinedStyles {
    return MHSettings.tileServerOptions.defaultStyles;
}

+ (MHDefaultStyle*) defaultStyle {
    MHTileServerOptions* opts = MHSettings.tileServerOptions;
    return opts.defaultStyle;
}

+ (NSURL*) defaultStyleURL {
    MHDefaultStyle* styleDefinition = [MHStyle defaultStyle];
    if (styleDefinition != nil){
        return styleDefinition.url;
    }
    
    return nil;
}

+ (MHDefaultStyle*) predefinedStyle:(NSString*)withStyleName {
    for (MHDefaultStyle* style in MHSettings.tileServerOptions.defaultStyles) {
        if ([style.name isEqualToString:withStyleName]) {
            return style;
        }
    }
    return nil;
}

// MARK: -

- (instancetype)initWithRawStyle:(mbgl::style::Style *)rawStyle stylable:(id <MHStylable>)stylable {
    MHLogInfo(@"Initializing %@ with stylable: %@", NSStringFromClass([self class]), stylable);
    if (self = [super init]) {
        _stylable = stylable;
        _rawStyle = rawStyle;
        _customLayers = [NSMutableDictionary dictionary];
        _localizedLayersByIdentifier = [NSMutableDictionary dictionary];
        MHLogDebug(@"Initializing with style name: %@ stylable: %@", self.name, stylable);
    }
    return self;
}

- (NSURL *)URL {
    return [NSURL URLWithString:@(self.rawStyle->getURL().c_str())];
}

- (NSString *)name {
    std::string name = self.rawStyle->getName();
    return name.empty() ? nil : @(name.c_str());
}

// MARK: Sources

- (NSSet<__kindof MHSource *> *)sources {
    auto rawSources = self.rawStyle->getSources();
    NSMutableSet<__kindof MHSource *> *sources = [NSMutableSet setWithCapacity:rawSources.size()];
    for (auto rawSource = rawSources.begin(); rawSource != rawSources.end(); ++rawSource) {
        MHSource *source = [self sourceFromMBGLSource:*rawSource];
        [sources addObject:source];
    }
    return sources;
}

- (void)setSources:(NSSet<__kindof MHSource *> *)sources {
    MHLogDebug(@"Setting: %lu sources", sources.count);
    for (MHSource *source in self.sources) {
        [self removeSource:source];
    }
    for (MHSource *source in sources) {
        [self addSource:source];
    }
}

- (NSUInteger)countOfSources {
    return self.rawStyle->getSources().size();
}

- (MHSource *)memberOfSources:(MHSource *)object {
    return [self sourceWithIdentifier:object.identifier];
}

- (MHSource *)sourceWithIdentifier:(NSString *)identifier
{
    MHLogDebug(@"Querying source with identifier: %@", identifier);
    auto rawSource = self.rawStyle->getSource(identifier.UTF8String);
    
    return rawSource ? [self sourceFromMBGLSource:rawSource] : nil;
}

- (MHSource *)sourceFromMBGLSource:(mbgl::style::Source *)rawSource {
    if (MHSource *source = rawSource->peer.has_value() ? rawSource->peer.get<SourceWrapper>().source : nil) {
        return source;
    }

    // TODO: Fill in options specific to the respective source classes
    // https://github.com/mapbox/mapbox-gl-native/issues/6584
    if (auto vectorSource = rawSource->as<mbgl::style::VectorSource>()) {
        return [[MHVectorTileSource alloc] initWithRawSource:vectorSource stylable:self.stylable];
    } else if (auto geoJSONSource = rawSource->as<mbgl::style::GeoJSONSource>()) {
        return [[MHShapeSource alloc] initWithRawSource:geoJSONSource stylable:self.stylable];
    } else if (auto rasterSource = rawSource->as<mbgl::style::RasterSource>()) {
        return [[MHRasterTileSource alloc] initWithRawSource:rasterSource stylable:self.stylable];
    } else if (auto rasterDEMSource = rawSource->as<mbgl::style::RasterDEMSource>()) {
        return [[MHRasterDEMSource alloc] initWithRawSource:rasterDEMSource stylable:self.stylable];
    } else if (auto imageSource = rawSource->as<mbgl::style::ImageSource>()) {
        return [[MHImageSource alloc] initWithRawSource:imageSource stylable:self.stylable];
    } else {
        return [[MHSource alloc] initWithRawSource:rawSource stylable:self.stylable];
    }
}

- (void)addSource:(MHSource *)source
{
    MHLogDebug(@"Adding source: %@", source);
    if (!source.rawSource) {
        [NSException raise:NSInvalidArgumentException format:
         @"The source %@ cannot be added to the style. "
         @"Make sure the source was created as a member of a concrete subclass of MHSource.",
         source];
    }

    try {
        [source addToStylable:self.stylable];
    } catch (std::runtime_error & err) {
        [NSException raise:MHRedundantSourceIdentifierException format:@"%s", err.what()];
    }
}

- (void)removeSource:(MHSource *)source
{
    [self removeSource:source error:nil];
}

- (BOOL)removeSource:(MHSource *)source error:(NSError * __nullable * __nullable)outError {
    MHLogDebug(@"Removing source: %@", source);
    
    if (!source.rawSource) {
        NSString *errorMessage = [NSString stringWithFormat:
                                  @"The source %@ cannot be removed from the style. "
                                  @"Make sure the source was created as a member of a concrete subclass of MHSource."
                                  @"Automatic re-addition of sources after style changes is not currently supported.",
                                  source];
        
        if (outError) {
            *outError = [NSError errorWithDomain:MHErrorDomain
                                            code:MHErrorCodeSourceCannotBeRemovedFromStyle
                                        userInfo:@{ NSLocalizedDescriptionKey : errorMessage }];
            return NO;
        }
        else {
            [NSException raise:NSInvalidArgumentException format:@"%@", errorMessage];
        }
    }
    
    return [source removeFromStylable:self.stylable error:outError];
}


- (nullable NSArray<MHAttributionInfo *> *)attributionInfosWithFontSize:(CGFloat)fontSize linkColor:(nullable MHColor *)linkColor {
    // It’d be incredibly convenient to use -sources here, but this operation
    // depends on the sources being sorted in ascending order by creation, as
    // with the std::vector used in mbgl.
    auto rawSources = self.rawStyle->getSources();
    NSMutableArray *infos = [NSMutableArray arrayWithCapacity:rawSources.size()];
    for (auto rawSource = rawSources.begin(); rawSource != rawSources.end(); ++rawSource) {
        MHTileSource *source = (MHTileSource *)[self sourceFromMBGLSource:*rawSource];
        if (![source isKindOfClass:[MHTileSource class]]) {
            continue;
        }

        NSArray *tileSetInfos = [source attributionInfosWithFontSize:fontSize linkColor:linkColor];
        [infos growArrayByAddingAttributionInfosFromArray:tileSetInfos];
    }
    return infos;
}

// MARK: Style layers

- (NSArray<__kindof MHStyleLayer *> *)layers
{
    auto layers = self.rawStyle->getLayers();
    NSMutableArray<__kindof MHStyleLayer *> *styleLayers = [NSMutableArray arrayWithCapacity:layers.size()];
    for (auto layer : layers) {
        MHStyleLayer *styleLayer = [self layerFromMBGLLayer:layer];
        [styleLayers addObject:styleLayer];
    }
    return styleLayers;
}

- (void)setLayers:(NSArray<__kindof MHStyleLayer *> *)layers {
    MHLogDebug(@"Setting: %lu layers", layers.count);
    for (MHStyleLayer *layer in self.layers) {
        [self removeLayer:layer];
    }
    for (MHStyleLayer *layer in layers) {
        [self addLayer:layer];
    }
}

- (NSUInteger)countOfLayers
{
    return self.rawStyle->getLayers().size();
}

- (MHStyleLayer *)objectInLayersAtIndex:(NSUInteger)index
{
    auto layers = self.rawStyle->getLayers();
    if (index >= layers.size()) {
        [NSException raise:NSRangeException
                    format:@"No style layer at index %lu.", (unsigned long)index];
        return nil;
    }
    auto layer = layers.at(index);
    return [self layerFromMBGLLayer:layer];
}

- (void)getLayers:(MHStyleLayer **)buffer range:(NSRange)inRange
{
    auto layers = self.rawStyle->getLayers();
    if (NSMaxRange(inRange) > layers.size()) {
        [NSException raise:NSRangeException
                    format:@"Style layer range %@ is out of bounds.", NSStringFromRange(inRange)];
    }
    NSUInteger i = 0;
    for (auto layer = *(layers.rbegin() + inRange.location); i < inRange.length; ++layer, ++i) {
        MHStyleLayer *styleLayer = [self layerFromMBGLLayer:layer];
        buffer[i] = styleLayer;
    }
}

- (void)insertObject:(MHStyleLayer *)styleLayer inLayersAtIndex:(NSUInteger)index
{
    if (!styleLayer.rawLayer) {
        [NSException raise:NSInvalidArgumentException format:
         @"The style layer %@ cannot be inserted into the style. "
         @"Make sure the style layer was created as a member of a concrete subclass of MHStyleLayer.",
         styleLayer];
    }
    auto layers = self.rawStyle->getLayers();
    if (index > layers.size()) {
        [NSException raise:NSRangeException
                    format:@"Cannot insert style layer at out-of-bounds index %lu.", (unsigned long)index];
    } else if (index == 0) {
        try {
            MHStyleLayer *sibling = layers.size() ? [self layerFromMBGLLayer:layers.at(0)] : nil;
            [styleLayer addToStyle:self belowLayer:sibling];
        } catch (const std::runtime_error & err) {
            [NSException raise:MHRedundantLayerIdentifierException format:@"%s", err.what()];
        }
    } else {
        try {
            MHStyleLayer *sibling = [self layerFromMBGLLayer:layers.at(index)];
            [styleLayer addToStyle:self belowLayer:sibling];
        } catch (std::runtime_error & err) {
            [NSException raise:MHRedundantLayerIdentifierException format:@"%s", err.what()];
        }
    }
}

- (void)removeObjectFromLayersAtIndex:(NSUInteger)index
{
    auto layers = self.rawStyle->getLayers();
    if (index >= layers.size()) {
        [NSException raise:NSRangeException
                    format:@"Cannot remove style layer at out-of-bounds index %lu.", (unsigned long)index];
    }
    auto layer = layers.at(index);
    MHStyleLayer *styleLayer = [self layerFromMBGLLayer:layer];
    [styleLayer removeFromStyle:self];
}

- (MHStyleLayer *)layerFromMBGLLayer:(mbgl::style::Layer *)rawLayer
{
    NSParameterAssert(rawLayer);

    if (MHStyleLayer *layer = rawLayer->peer.has_value() ? rawLayer->peer.get<LayerWrapper>().layer : nil) {
        return layer;
    }

    return mbgl::LayerManagerDarwin::get()->createPeer(rawLayer);
}

- (MHStyleLayer *)layerWithIdentifier:(NSString *)identifier
{
    MHLogDebug(@"Querying layerWithIdentifier: %@", identifier);
    auto mbglLayer = self.rawStyle->getLayer(identifier.UTF8String);
    return mbglLayer ? [self layerFromMBGLLayer:mbglLayer] : nil;
}

- (void)removeLayer:(MHStyleLayer *)layer
{
    MHLogDebug(@"Removing layer: %@", layer);
    if (!layer.rawLayer) {
        [NSException raise:NSInvalidArgumentException format:
         @"The style layer %@ cannot be removed from the style. "
         @"Make sure the style layer was created as a member of a concrete subclass of MHStyleLayer.",
         layer];
    }
    [self willChangeValueForKey:@"layers"];
    [layer removeFromStyle:self];
    [self didChangeValueForKey:@"layers"];
}

- (void)addLayer:(MHStyleLayer *)layer
{
    MHLogDebug(@"Adding layer: %@", layer);
    if (!layer.rawLayer) {
        [NSException raise:NSInvalidArgumentException format:
         @"The style layer %@ cannot be added to the style. "
         @"Make sure the style layer was created as a member of a concrete subclass of MHStyleLayer.",
         layer];
    }
    [self willChangeValueForKey:@"layers"];
    try {
        [layer addToStyle:self belowLayer:nil];
    } catch (std::runtime_error & err) {
        [NSException raise:MHRedundantLayerIdentifierException format:@"%s", err.what()];
    }
    [self didChangeValueForKey:@"layers"];
}

- (void)insertLayer:(MHStyleLayer *)layer atIndex:(NSUInteger)index {
    [self insertObject:layer inLayersAtIndex:index];
}

- (void)insertLayer:(MHStyleLayer *)layer belowLayer:(MHStyleLayer *)sibling
{
    MHLogDebug(@"Inseting layer: %@ belowLayer: %@", layer, sibling);
    if (!layer.rawLayer) {
        [NSException raise:NSInvalidArgumentException
                    format:
         @"The style layer %@ cannot be added to the style. "
         @"Make sure the style layer was created as a member of a concrete subclass of MHStyleLayer.",
         layer];
    }
    if (!sibling.rawLayer) {
        [NSException raise:NSInvalidArgumentException
                    format:
         @"A style layer cannot be placed below %@ in the style. "
         @"Make sure sibling was obtained using -[MHStyle layerWithIdentifier:].",
         sibling];
    }
    [self willChangeValueForKey:@"layers"];
    try {
        [layer addToStyle:self belowLayer:sibling];
    } catch (std::runtime_error & err) {
        [NSException raise:MHRedundantLayerIdentifierException format:@"%s", err.what()];
    }
    [self didChangeValueForKey:@"layers"];
}

- (void)insertLayer:(MHStyleLayer *)layer aboveLayer:(MHStyleLayer *)sibling {
    MHLogDebug(@"Inseting layer: %@ aboveLayer: %@", layer, sibling);
    if (!layer.rawLayer) {
        [NSException raise:NSInvalidArgumentException
                    format:
         @"The style layer %@ cannot be added to the style. "
         @"Make sure the style layer was created as a member of a concrete subclass of MHStyleLayer.",
         layer];
    }
    if (!sibling.rawLayer) {
        [NSException raise:NSInvalidArgumentException
                    format:
         @"A style layer cannot be placed above %@ in the style. "
         @"Make sure sibling was obtained using -[MHStyle layerWithIdentifier:].",
         sibling];
    }

    auto layers = self.rawStyle->getLayers();
    std::string siblingIdentifier = sibling.identifier.UTF8String;
    NSUInteger index = 0;
    for (auto siblingLayer : layers) {
        if (siblingLayer->getID() == siblingIdentifier) {
            break;
        }
        index++;
    }

    [self willChangeValueForKey:@"layers"];
    if (index + 1 > layers.size()) {
        [NSException raise:NSInvalidArgumentException
                    format:
         @"A style layer cannot be placed above %@ in the style. "
         @"Make sure sibling was obtained using -[MHStyle layerWithIdentifier:].",
         sibling];
    } else if (index + 1 == layers.size()) {
        try {
            [layer addToStyle:self belowLayer:nil];
        } catch (std::runtime_error & err) {
            [NSException raise:MHRedundantLayerIdentifierException format:@"%s", err.what()];
        }
    } else {
        MHStyleLayer *nextSibling = [self layerFromMBGLLayer:layers.at(index + 1)];
        try {
            [layer addToStyle:self belowLayer:nextSibling];
        } catch (std::runtime_error & err) {
            [NSException raise:MHRedundantLayerIdentifierException format:@"%s", err.what()];
        }
    }
    [self didChangeValueForKey:@"layers"];
}

// MARK: Style images

- (void)setImage:(MHImage *)image forName:(NSString *)name
{
    MHLogDebug(@"Setting image: %@ forName: %@", image, name);
    if (!image) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Cannot assign nil image to “%@”.", name];
    }
    if (!name) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Cannot assign image %@ to a nil name.", image];
    }

    self.rawStyle->addImage([image mgl_styleImageWithIdentifier:name]);
}

- (void)removeImageForName:(NSString *)name
{
    MHLogDebug(@"Removing imageForName: %@", name);
    if (!name) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Cannot remove image with nil name."];
    }

    self.rawStyle->removeImage([name UTF8String]);
}

- (MHImage *)imageForName:(NSString *)name
{
    MHLogDebug(@"Querying imageForName: %@", name);
    if (!name) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Cannot get image with nil name."];
    }

    auto styleImage = self.rawStyle->getImage([name UTF8String]);
    return styleImage ? [[MHImage alloc] initWithMHStyleImage:*styleImage] : nil;
}

// MARK: Style transitions

- (void)setTransition:(MHTransition)transition
{
    self.rawStyle->setTransitionOptions(MHOptionsFromTransition(transition));
}

- (MHTransition)transition
{
    const mbgl::style::TransitionOptions transitionOptions = self.rawStyle->getTransitionOptions();
    
    return MHTransitionFromOptions(transitionOptions);
}

- (void)setPerformsPlacementTransitions:(BOOL)performsPlacementTransitions
{
    mbgl::style::TransitionOptions transitionOptions = self.rawStyle->getTransitionOptions();
    transitionOptions.enablePlacementTransitions = static_cast<bool>(performsPlacementTransitions);
    self.rawStyle->setTransitionOptions(transitionOptions);
}

- (BOOL)performsPlacementTransitions
{
    mbgl::style::TransitionOptions transitionOptions = self.rawStyle->getTransitionOptions();
    return transitionOptions.enablePlacementTransitions;
}

// MARK: Style light

- (void)setLight:(MHLight *)light
{
    std::unique_ptr<mbgl::style::Light> mbglLight = std::make_unique<mbgl::style::Light>([light mbglLight]);
    self.rawStyle->setLight(std::move(mbglLight));
}

- (MHLight *)light
{
    auto mbglLight = self.rawStyle->getLight();
    MHLight *light = [[MHLight alloc] initWithMBGLLight:mbglLight];
    return light;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; name = %@, URL = %@>",
            NSStringFromClass([self class]), (void *)self,
            self.name ? [NSString stringWithFormat:@"\"%@\"", self.name] : self.name,
            self.URL ? [NSString stringWithFormat:@"\"%@\"", self.URL] : self.URL];
}

// MARK: Mapbox Streets source introspection

- (void)localizeLabelsIntoLocale:(nullable NSLocale *)locale {
    NSSet<MHVectorTileSource *> *streetsSources =
        [self.sources filteredSetUsingPredicate:
         [NSPredicate predicateWithBlock:^BOOL(MHVectorTileSource * _Nullable source, NSDictionary<NSString *, id> * _Nullable bindings) {
            return [source isKindOfClass:[MHVectorTileSource class]] && [source isMapboxStreets];
        }]];
    NSSet<NSString *> *streetsSourceIdentifiers = [streetsSources valueForKey:@"identifier"];
    
    for (MHSymbolStyleLayer *layer in self.layers) {
        if (![layer isKindOfClass:[MHSymbolStyleLayer class]]) {
            continue;
        }
        if (![streetsSourceIdentifiers containsObject:layer.sourceIdentifier]) {
            continue;
        }
        
        NSExpression *text = layer.text;
        NSExpression *localizedText = [text mgl_expressionLocalizedIntoLocale:locale];
        if (![localizedText isEqual:text]) {
            layer.text = localizedText;
        }
    }
}

- (NSSet<MHVectorTileSource *> *)mapboxStreetsSources {
    return [self.sources objectsPassingTest:^BOOL (__kindof MHVectorTileSource * _Nonnull source, BOOL * _Nonnull stop) {
        return [source isKindOfClass:[MHVectorTileSource class]] && source.mapboxStreets;
    }];
}

- (NSArray<MHStyleLayer *> *)placeStyleLayers {
    NSSet *streetsSourceIdentifiers = [self.mapboxStreetsSources valueForKey:@"identifier"];
    
    NSSet *placeSourceLayerIdentifiers = [NSSet setWithObjects:@"marine_label", @"country_label", @"state_label", @"place_label", @"water_label", @"poi_label", @"rail_station_label", @"mountain_peak_label", @"natural_label", @"transit_stop_label", nil];
    NSPredicate *isPlacePredicate = [NSPredicate predicateWithBlock:^BOOL (MHVectorStyleLayer * _Nullable layer, NSDictionary<NSString *, id> * _Nullable bindings) {
        return [layer isKindOfClass:[MHVectorStyleLayer class]] && [streetsSourceIdentifiers containsObject:layer.sourceIdentifier] && [placeSourceLayerIdentifiers containsObject:layer.sourceLayerIdentifier];
    }];
    return [self.layers filteredArrayUsingPredicate:isPlacePredicate];
}

- (NSArray<MHStyleLayer *> *)roadStyleLayers {
    NSSet *streetsSourceIdentifiers = [self.mapboxStreetsSources valueForKey:@"identifier"];

    NSSet *roadStyleLayerIdentifiers = [NSSet setWithObjects:@"road_label", @"road", nil];
    NSPredicate *isPlacePredicate = [NSPredicate predicateWithBlock:^BOOL (MHVectorStyleLayer * _Nullable layer, NSDictionary<NSString *, id> * _Nullable bindings) {
        return [layer isKindOfClass:[MHVectorStyleLayer class]] && [streetsSourceIdentifiers containsObject:layer.sourceIdentifier] && [roadStyleLayerIdentifiers containsObject:layer.sourceLayerIdentifier];
    }];
    return [self.layers filteredArrayUsingPredicate:isPlacePredicate];
}

@end
