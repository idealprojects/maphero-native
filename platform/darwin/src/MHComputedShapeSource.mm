#import "MHComputedShapeSource_Private.h"

#import "MHMapView_Private.h"
#import "MHSource_Private.h"
#import "MHShape_Private.h"
#import "MHGeometry_Private.h"
#import "MHShapeCollection.h"

#include <mbgl/map/map.hpp>
#include <mbgl/style/sources/custom_geometry_source.hpp>
#include <mbgl/tile/tile_id.hpp>
#include <mbgl/util/geojson.hpp>

const MHExceptionName MHInvalidDatasourceException = @"MHInvalidDatasourceException";

const MHShapeSourceOption MHShapeSourceOptionWrapsCoordinates = @"MHShapeSourceOptionWrapsCoordinates";
const MHShapeSourceOption MHShapeSourceOptionClipsCoordinates = @"MHShapeSourceOptionClipsCoordinates";

mbgl::style::CustomGeometrySource::Options MBGLCustomGeometrySourceOptionsFromDictionary(NSDictionary<MHShapeSourceOption, id> *options) {
    mbgl::style::CustomGeometrySource::Options sourceOptions;

    if (NSNumber *value = options[MHShapeSourceOptionMinimumZoomLevel]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionMinimumZoomLevel must be an NSNumber."];
        }
        sourceOptions.zoomRange.min = value.integerValue;
    }

    if (NSNumber *value = options[MHShapeSourceOptionMaximumZoomLevel]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionMaximumZoomLevel must be an NSNumber."];
        }
        sourceOptions.zoomRange.max = value.integerValue;
    }

    if (NSNumber *value = options[MHShapeSourceOptionBuffer]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionBuffer must be an NSNumber."];
        }
        sourceOptions.tileOptions.buffer = value.integerValue;
    }

    if (NSNumber *value = options[MHShapeSourceOptionSimplificationTolerance]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionSimplificationTolerance must be an NSNumber."];
        }
        sourceOptions.tileOptions.tolerance = value.doubleValue;
    }

    if (NSNumber *value = options[MHShapeSourceOptionWrapsCoordinates]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionWrapsCoordinates must be an NSNumber."];
        }
        sourceOptions.tileOptions.wrap = value.boolValue;
    }

    if (NSNumber *value = options[MHShapeSourceOptionClipsCoordinates]) {
        if (![value isKindOfClass:[NSNumber class]]) {
            [NSException raise:NSInvalidArgumentException
                        format:@"MHShapeSourceOptionClipsCoordinates must be an NSNumber."];
        }
        sourceOptions.tileOptions.clip = value.boolValue;
    }

    return sourceOptions;
}

@interface MHComputedShapeSource () {
    std::unique_ptr<mbgl::style::CustomGeometrySource> _pendingSource;
}

@property (nonatomic, readwrite) NSDictionary *options;
@property (nonatomic, assign) BOOL dataSourceImplementsFeaturesForTile;
@property (nonatomic, assign) BOOL dataSourceImplementsFeaturesForBounds;

@end

@interface MHComputedShapeSourceFetchOperation : NSOperation

@property (nonatomic, readonly) uint8_t z;
@property (nonatomic, readonly) uint32_t x;
@property (nonatomic, readonly) uint32_t y;
@property (nonatomic, assign) BOOL dataSourceImplementsFeaturesForTile;
@property (nonatomic, assign) BOOL dataSourceImplementsFeaturesForBounds;
@property (nonatomic, weak, nullable) id<MHComputedShapeSourceDataSource> dataSource;
@property (nonatomic, nullable) mbgl::style::CustomGeometrySource *rawSource;

- (instancetype)initForSource:(MHComputedShapeSource*)source tile:(const mbgl::CanonicalTileID&)tileId;

@end

@implementation MHComputedShapeSourceFetchOperation

- (instancetype)initForSource:(MHComputedShapeSource*)source tile:(const mbgl::CanonicalTileID&)tileID {
    self = [super init];
    _z = tileID.z;
    _x = tileID.x;
    _y = tileID.y;
    _dataSourceImplementsFeaturesForTile = source.dataSourceImplementsFeaturesForTile;
    _dataSourceImplementsFeaturesForBounds = source.dataSourceImplementsFeaturesForBounds;
    _dataSource = source.dataSource;
    mbgl::style::CustomGeometrySource *rawSource = static_cast<mbgl::style::CustomGeometrySource *>(source.rawSource);
    _rawSource = rawSource;
    return self;
}

- (void)main {
    if ([self isCancelled]) {
        return;
    }

    NSArray<MHShape <MHFeature> *> *data;
    if(!self.dataSource) {
        data = nil;
    } else if(self.dataSourceImplementsFeaturesForTile) {
        data = [self.dataSource featuresInTileAtX:self.x
                                                y:self.y
                                        zoomLevel:self.z];
    } else {
        mbgl::CanonicalTileID tileID = mbgl::CanonicalTileID(self.z, self.x, self.y);
        mbgl::LatLngBounds tileBounds = mbgl::LatLngBounds(tileID);
        data = [self.dataSource featuresInCoordinateBounds:MHCoordinateBoundsFromLatLngBounds(tileBounds)
                                                 zoomLevel:self.z];
    }

    if(![self isCancelled]) {
        mbgl::FeatureCollection featureCollection;
        featureCollection.reserve(data.count);
        for (MHShape <MHFeature> * feature in data) {
            if ([feature isMemberOfClass:[MHShapeCollection class]]) {
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    NSLog(@"MHShapeCollection initialized with MHFeatures will not retain attributes."
                          @"Use MHShapeCollectionFeature to retain attributes instead."
                          @"This will be logged only once.");
                });
            }
            mbgl::GeoJSONFeature geoJsonObject = [feature geoJSONObject].get<mbgl::GeoJSONFeature>();
            featureCollection.push_back(geoJsonObject);
        }
        const auto geojson = mbgl::GeoJSON{featureCollection};

        // Note: potential race condition with `cancel`
        if(![self isCancelled]) {
            if (auto *rawSource = self.rawSource) {
                rawSource->setTileData(mbgl::CanonicalTileID(self.z, self.x, self.y), geojson);
            }
        }
    }
}

- (void)cancel {
    [super cancel];
    self.rawSource = NULL;
}

@end

@implementation MHComputedShapeSource

- (instancetype)initWithIdentifier:(NSString *)identifier options:(NSDictionary<MHShapeSourceOption, id> *)options {
    NSOperationQueue *requestQueue = [[NSOperationQueue alloc] init];
    requestQueue.name = [NSString stringWithFormat:@"mgl.MHComputedShapeSource.%@", identifier];
    requestQueue.qualityOfService = NSQualityOfServiceUtility;
    requestQueue.maxConcurrentOperationCount = 4;

    auto sourceOptions  = MBGLCustomGeometrySourceOptionsFromDictionary(options);
    sourceOptions.fetchTileFunction = ^void(const mbgl::CanonicalTileID& tileID) {
        NSOperation *operation = [[MHComputedShapeSourceFetchOperation alloc] initForSource:self tile:tileID];
        [requestQueue addOperation:operation];
    };
    
    sourceOptions.cancelTileFunction = ^void(const mbgl::CanonicalTileID& tileID) {
        for (MHComputedShapeSourceFetchOperation *operation in requestQueue.operations) {
            if (operation.x == tileID.x && operation.y == tileID.y && operation.z == tileID.z) {
                [operation cancel];
            }
        }
    };

    auto source = std::make_unique<mbgl::style::CustomGeometrySource>(identifier.UTF8String, sourceOptions);

    if (self = [super initWithPendingSource:std::move(source)]) {
        _requestQueue = requestQueue;
    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier dataSource:(id<MHComputedShapeSourceDataSource>)dataSource options:(NSDictionary<MHShapeSourceOption, id> *)options {
    if (self = [self initWithIdentifier:identifier options:options]) {
        [self setDataSource:dataSource];
    }
    return self;
}

- (void)dealloc {
    [self.requestQueue cancelAllOperations];
}

- (void)setFeatures:(NSArray<MHShape <MHFeature> *>*)features inTileAtX:(NSUInteger)x y:(NSUInteger)y zoomLevel:(NSUInteger)zoomLevel {
    MHAssertStyleSourceIsValid();
    mbgl::CanonicalTileID tileID = mbgl::CanonicalTileID((uint8_t)zoomLevel, (uint32_t)x, (uint32_t)y);
    mbgl::FeatureCollection featureCollection;
    featureCollection.reserve(features.count);
    for (MHShape <MHFeature> * feature in features) {
        mbgl::GeoJSONFeature geoJsonObject = [feature geoJSONObject].get<mbgl::GeoJSONFeature>();
        featureCollection.push_back(geoJsonObject);
        if ([feature isMemberOfClass:[MHShapeCollection class]]) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                NSLog(@"MHShapeCollection initialized with MHFeatures will not retain attributes."
                      @"Use MHShapeCollectionFeature to retain attributes instead."
                      @"This will be logged only once.");
            });
        }
    }
    const auto geojson = mbgl::GeoJSON{featureCollection};
    static_cast<mbgl::style::CustomGeometrySource *>(self.rawSource)->setTileData(tileID, geojson);
}

- (void)setDataSource:(id<MHComputedShapeSourceDataSource>)dataSource {
    [self.requestQueue cancelAllOperations];
    // Check which method the datasource implements, to avoid having to check for each tile
    self.dataSourceImplementsFeaturesForTile = [dataSource respondsToSelector:@selector(featuresInTileAtX:y:zoomLevel:)];
    self.dataSourceImplementsFeaturesForBounds = [dataSource respondsToSelector:@selector(featuresInCoordinateBounds:zoomLevel:)];

    if (!self.dataSourceImplementsFeaturesForBounds && !self.dataSourceImplementsFeaturesForTile) {
        [NSException raise:MHInvalidDatasourceException
                    format:@"Datasource does not implement any MHComputedShapeSourceDataSource methods"];
    } else if (self.dataSourceImplementsFeaturesForBounds && self.dataSourceImplementsFeaturesForTile) {
        [NSException raise:MHInvalidDatasourceException
                    format:@"Datasource implements multiple MHComputedShapeSourceDataSource methods"];
    }

    _dataSource = dataSource;
}

- (void) invalidateBounds:(MHCoordinateBounds)bounds {
    MHAssertStyleSourceIsValid();
    ((mbgl::style::CustomGeometrySource *)self.rawSource)->invalidateRegion(MHLatLngBoundsFromCoordinateBounds(bounds));
}

- (void) invalidateTileAtX:(NSUInteger)x y:(NSUInteger)y zoomLevel:(NSUInteger)z {
    MHAssertStyleSourceIsValid();
    ((mbgl::style::CustomGeometrySource *)self.rawSource)->invalidateTile(mbgl::CanonicalTileID(z, (unsigned int)x, (unsigned int)y));
}

@end
