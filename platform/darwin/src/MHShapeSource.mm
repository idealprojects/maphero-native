#import "MHFoundation_Private.h"
#import "MHShapeSource_Private.h"

#import "MHLoggingConfiguration_Private.h"
#import "MHStyle_Private.h"
#import "MHStyleValue_Private.h"
#import "MHMapView_Private.h"
#import "MHSource_Private.h"
#import "MHFeature_Private.h"
#import "MHShape_Private.h"
#import "MHCluster.h"

#import "NSPredicate+MHPrivateAdditions.h"
#import "NSURL+MHAdditions.h"

#include <mbgl/map/map.hpp>
#include <mbgl/style/sources/geojson_source.hpp>
#include <mbgl/renderer/renderer.hpp>

const MHShapeSourceOption MHShapeSourceOptionBuffer = @"MHShapeSourceOptionBuffer";
const MHShapeSourceOption MHShapeSourceOptionClusterRadius = @"MHShapeSourceOptionClusterRadius";
const MHShapeSourceOption MHShapeSourceOptionClustered = @"MHShapeSourceOptionClustered";
const MHShapeSourceOption MHShapeSourceOptionClusterProperties = @"MHShapeSourceOptionClusterProperties";
const MHShapeSourceOption MHShapeSourceOptionMaximumZoomLevel = @"MHShapeSourceOptionMaximumZoomLevel";
const MHShapeSourceOption MHShapeSourceOptionMaximumZoomLevelForClustering = @"MHShapeSourceOptionMaximumZoomLevelForClustering";
const MHShapeSourceOption MHShapeSourceOptionMinimumZoomLevel = @"MHShapeSourceOptionMinimumZoomLevel";
const MHShapeSourceOption MHShapeSourceOptionSimplificationTolerance = @"MHShapeSourceOptionSimplificationTolerance";
const MHShapeSourceOption MHShapeSourceOptionLineDistanceMetrics = @"MHShapeSourceOptionLineDistanceMetrics";

mbgl::Immutable<mbgl::style::GeoJSONOptions> MHGeoJSONOptionsFromDictionary(NSDictionary<MHShapeSourceOption, id> *options) {
    auto geoJSONOptions = mbgl::makeMutable<mbgl::style::GeoJSONOptions>();

    if (NSNumber *value = options[MHShapeSourceOptionMinimumZoomLevel]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionMaximumZoomLevel must be an NSNumber."];
        }
        geoJSONOptions->minzoom = value.integerValue;
    }

    if (NSNumber *value = options[MHShapeSourceOptionMaximumZoomLevel]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionMaximumZoomLevel must be an NSNumber."];
        }
        geoJSONOptions->maxzoom = value.integerValue;
    }

    if (NSNumber *value = options[MHShapeSourceOptionBuffer]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionBuffer must be an NSNumber."];
        }
        geoJSONOptions->buffer = value.integerValue;
    }

    if (NSNumber *value = options[MHShapeSourceOptionSimplificationTolerance]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionSimplificationTolerance must be an NSNumber."];
        }
        geoJSONOptions->tolerance = value.doubleValue;
    }

    if (NSNumber *value = options[MHShapeSourceOptionClusterRadius]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionClusterRadius must be an NSNumber."];
        }
        geoJSONOptions->clusterRadius = value.integerValue;
    }

    if (NSNumber *value = options[MHShapeSourceOptionMaximumZoomLevelForClustering]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionMaximumZoomLevelForClustering must be an NSNumber."];
        }
        geoJSONOptions->clusterMaxZoom = value.integerValue;
    }

    if (NSNumber *value = options[MHShapeSourceOptionClustered]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionClustered must be an NSNumber."];
        }
        geoJSONOptions->cluster = value.boolValue;
    }

    if (NSDictionary *value = options[MHShapeSourceOptionClusterProperties]) {
        if (![value isKindOfClass:[NSDictionary<NSString *, NSArray *> class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionClusterProperties must be an NSDictionary with an NSString as a key and an array containing two NSExpression objects as a value."];
        }

        NSEnumerator *stringEnumerator = [value keyEnumerator];
        NSString *key;

        while (key = [stringEnumerator nextObject]) {
            NSArray *expressionsArray = value[key];
            if (![expressionsArray isKindOfClass:[NSArray class]]) {
                [NSException raise:NSInvalidArgumentException
                            format:@"MHShapeSourceOptionClusterProperties dictionary member value must be an array containing two objects."];
            }
            // Check that the array has 2 values. One should be a the reduce expression and one should be the map expression.
            if ([expressionsArray count] != 2) {
                [NSException raise:NSInvalidArgumentException
                            format:@"MHShapeSourceOptionClusterProperties member value requires array of two objects."];
            }

            // reduceExpression should be a valid NSExpression
            NSExpression *reduceExpression = expressionsArray[0];
            if (![reduceExpression isKindOfClass:[NSExpression class]]) {
                [NSException raise:NSInvalidArgumentException
                format:@"MHShapeSourceOptionClusterProperties array value requires two expression objects."];
            }
            auto reduce = MHClusterPropertyFromNSExpression(reduceExpression);
            if (!reduce) {
                [NSException raise:NSInvalidArgumentException
                            format:@"Failed to convert MHShapeSourceOptionClusterProperties reduce expression."];
            }

            // mapExpression should be a valid NSExpression
            NSExpression *mapExpression = expressionsArray[1];
            if (![mapExpression isKindOfClass:[NSExpression class]]) {
                [NSException raise:NSInvalidArgumentException
                            format:@"MHShapeSourceOptionClusterProperties member value must contain a valid NSExpression."];
            }
            auto map = MHClusterPropertyFromNSExpression(mapExpression);
            if (!map) {
                [NSException raise:NSInvalidArgumentException
                            format:@"Failed to convert MHShapeSourceOptionClusterProperties map expression."];
            }

            std::string keyString = std::string([key UTF8String]);

            geoJSONOptions->clusterProperties.emplace(keyString, std::make_pair(std::move(map), std::move(reduce)));
        }
    }

    if (NSNumber *value = options[MHShapeSourceOptionLineDistanceMetrics]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionLineDistanceMetrics must be an NSNumber."];
        }
        geoJSONOptions->lineMetrics = value.boolValue;
    }

    return geoJSONOptions;
}

@interface MHShapeSource ()

@property (nonatomic, readwrite) NSDictionary *options;
@property (nonatomic, readonly) mbgl::style::GeoJSONSource *rawSource;

@end

@implementation MHShapeSource

- (instancetype)initWithIdentifier:(NSString *)identifier URL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    auto geoJSONOptions = MHGeoJSONOptionsFromDictionary(options);
    auto source = std::make_unique<mbgl::style::GeoJSONSource>(identifier.UTF8String, std::move(geoJSONOptions));
    if (self = [super initWithPendingSource:std::move(source)]) {
        self.URL = url;
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier shape:(nullable MHShape *)shape options:(NSDictionary<MHShapeSourceOption, id> *)options {
    auto geoJSONOptions = MHGeoJSONOptionsFromDictionary(options);
    auto source = std::make_unique<mbgl::style::GeoJSONSource>(identifier.UTF8String, std::move(geoJSONOptions));
    if (self = [super initWithPendingSource:std::move(source)]) {
        if ([shape isMemberOfClass:[MHShapeCollection class]]) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                NSLog(@"MHShapeCollection initialized with MHFeatures will not retain attributes."
                        @"Use MHShapeCollectionFeature to retain attributes instead."
                        @"This will be logged only once.");
            });
        }
        self.shape = shape;
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier features:(NSArray<MHShape<MHFeature> *> *)features options:(nullable NSDictionary<MHShapeSourceOption, id> *)options {
    for (id <MHFeature> feature in features) {
        if (![feature conformsToProtocol:@protocol(MHFeature)]) {
            [NSException raise:NSInvalidArgumentException format:@"The object %@ included in the features argument does not conform to the MHFeature protocol.", feature];
        }
    }
    MHShapeCollectionFeature *shapeCollectionFeature = [MHShapeCollectionFeature shapeCollectionWithShapes:features];
    return [self initWithIdentifier:identifier shape:shapeCollectionFeature options:options];
}

- (instancetype)initWithIdentifier:(NSString *)identifier shapes:(NSArray<MHShape *> *)shapes options:(nullable NSDictionary<MHShapeSourceOption, id> *)options {
    MHShapeCollection *shapeCollection = [MHShapeCollection shapeCollectionWithShapes:shapes];
    return [self initWithIdentifier:identifier shape:shapeCollection options:options];
}

- (mbgl::style::GeoJSONSource *)rawSource {
    return (mbgl::style::GeoJSONSource *)super.rawSource;
}

- (NSURL *)URL {
    MHAssertStyleSourceIsValid();
    auto url = self.rawSource->getURL();
    return url ? [NSURL URLWithString:@(url->c_str())] : nil;
}

- (void)setURL:(NSURL *)url {
    MHAssertStyleSourceIsValid();
    if (url) {
        self.rawSource->setURL(url.mgl_URLByStandardizingScheme.absoluteString.UTF8String);
        _shape = nil;
    } else {
        self.shape = nil;
    }
}

- (void)setShape:(MHShape *)shape {
    MHAssertStyleSourceIsValid();
    self.rawSource->setGeoJSON({ shape.geoJSONObject });
    _shape = shape;
}

- (NSString *)description {
    if (self.rawSource) {
        return [NSString stringWithFormat:@"<%@: %p; identifier = %@; URL = %@; shape = %@>",
                NSStringFromClass([self class]), (void *)self, self.identifier, self.URL, self.shape];
    }
    else {
        return [NSString stringWithFormat:@"<%@: %p; identifier = %@; URL = <unknown>; shape = %@>",
                NSStringFromClass([self class]), (void *)self, self.identifier, self.shape];
    }
}

- (NSArray<id <MHFeature>> *)featuresMatchingPredicate:(nullable NSPredicate *)predicate {
    MHAssertStyleSourceIsValid();
    std::optional<mbgl::style::Filter> optionalFilter;
    if (predicate) {
        optionalFilter = predicate.mgl_filter;
    }
    
    std::vector<mbgl::Feature> features;
    if ([self.stylable isKindOfClass:[MHMapView class]]) {
        MHMapView *mapView = (MHMapView *)self.stylable;
        features = mapView.renderer->querySourceFeatures(self.rawSource->getID(), { {}, optionalFilter });
    }
    return MHFeaturesFromMBGLFeatures(features);
}

// MARK: - MHCluster management

- (std::optional<mbgl::FeatureExtensionValue>)featureExtensionValueOfCluster:(MHShape<MHCluster> *)cluster extension:(std::string)extension options:(const std::map<std::string, mbgl::Value>)options {
    MHAssertStyleSourceIsValid();
    std::optional<mbgl::FeatureExtensionValue> extensionValue;
    
    // Check parameters
    if (!self.rawSource || !self.stylable || !cluster) {
        return extensionValue;
    }

    auto geoJSON = [cluster geoJSONObject];
    
    if (!geoJSON.is<mbgl::GeoJSONFeature>()) {
        MHAssert(0, @"cluster geoJSON object is not a feature.");
        return extensionValue;
    }
    
    auto clusterFeature = geoJSON.get<mbgl::GeoJSONFeature>();
    
    if ([self.stylable isKindOfClass:[MHMapView class]]) {
        MHMapView *mapView = (MHMapView *)self.stylable;
        extensionValue = mapView.renderer->queryFeatureExtensions(self.rawSource->getID(),
                                                                  clusterFeature,
                                                                  "supercluster",
                                                                  extension,
                                                                  options);
    }
    return extensionValue;
}

- (NSArray<id <MHFeature>> *)leavesOfCluster:(MHPointFeatureCluster *)cluster offset:(NSUInteger)offset limit:(NSUInteger)limit {
    const std::map<std::string, mbgl::Value> options = {
        { "limit", static_cast<uint64_t>(limit) },
        { "offset", static_cast<uint64_t>(offset) }
    };

    auto featureExtension = [self featureExtensionValueOfCluster:cluster extension:"leaves" options:options];

    if (!featureExtension) {
        return @[];
    }
    
    if (!featureExtension->is<mbgl::FeatureCollection>()) {
        return @[];
    }
    
    std::vector<mbgl::GeoJSONFeature> leaves = featureExtension->get<mbgl::FeatureCollection>();
    return MHFeaturesFromMBGLFeatures(leaves);
}

- (NSArray<id <MHFeature>> *)childrenOfCluster:(MHPointFeatureCluster *)cluster {
    auto featureExtension = [self featureExtensionValueOfCluster:cluster extension:"children" options:{}];
    
    if (!featureExtension) {
        return @[];
    }
    
    if (!featureExtension->is<mbgl::FeatureCollection>()) {
        return @[];
    }
    
    std::vector<mbgl::GeoJSONFeature> leaves = featureExtension->get<mbgl::FeatureCollection>();
    return MHFeaturesFromMBGLFeatures(leaves);
}

- (double)zoomLevelForExpandingCluster:(MHPointFeatureCluster *)cluster {
    auto featureExtension = [self featureExtensionValueOfCluster:cluster extension:"expansion-zoom" options:{}];

    if (!featureExtension) {
        return -1.0;
    }
    
    if (!featureExtension->is<mbgl::Value>()) {
        return -1.0;
    }
    
    auto value = featureExtension->get<mbgl::Value>();
    if (value.is<uint64_t>()) {
        auto zoom = value.get<uint64_t>();
        return static_cast<double>(zoom);
    }
    
    return -1.0;
}

- (void)debugRecursiveLogForFeature:(id <MHFeature>)feature indent:(NSUInteger)indent {
    NSString *description = feature.description;
    
    // Want our recursive log on a single line
    NSString *log = [description stringByReplacingOccurrencesOfString:@"\\s+"
                                                           withString:@" "
                                                              options:NSRegularExpressionSearch
                                                                range:NSMakeRange(0, description.length)];
    
    printf("%*s%s\n", (int)indent, "", log.UTF8String);
    
    MHPointFeatureCluster *cluster = MH_OBJC_DYNAMIC_CAST(feature, MHPointFeatureCluster);
    
    if (cluster) {
        for (id <MHFeature> child in [self childrenOfCluster:cluster]) {
            [self debugRecursiveLogForFeature:child indent:indent + 4];
        }
    }
}

@end
