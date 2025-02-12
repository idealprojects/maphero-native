#import "MHPointCollection_Private.h"
#import "MHGeometry_Private.h"
#import "NSArray+MHAdditions.h"
#import "MHLoggingConfiguration_Private.h"

#import <mbgl/util/geojson.hpp>
#import <mbgl/util/geometry.hpp>

NS_ASSUME_NONNULL_BEGIN

@implementation MHPointCollection
{
    std::optional<mbgl::LatLngBounds> _bounds;
    std::vector<CLLocationCoordinate2D> _coordinates;
}

+ (instancetype)pointCollectionWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count
{
    return [[self alloc] initWithCoordinates:coords count:count];
}

- (instancetype)initWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count
{
    MHLogDebug(@"Initializing with %lu coordinates.", (unsigned long)count);
    self = [super init];
    if (self)
    {
        _coordinates = { coords, coords + count };
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
    MHLogInfo(@"Initializing with coder.O");
    if (self = [super initWithCoder:decoder]) {
        NSArray *coordinates = [decoder decodeObjectOfClass:[NSArray class] forKey:@"coordinates"];
        _coordinates = [coordinates mgl_coordinates];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:[NSArray mgl_coordinatesFromCoordinates:_coordinates] forKey:@"coordinates"];
}

- (BOOL)isEqual:(id)other {
    if (self == other) return YES;
    if (![other isKindOfClass:[MHPointCollection class]]) return NO;

    MHPointCollection *otherCollection = (MHPointCollection *)other;
    return ([super isEqual:other]
            && ((![self geoJSONDictionary] && ![otherCollection geoJSONDictionary]) || [[self geoJSONDictionary] isEqualToDictionary:[otherCollection geoJSONDictionary]]));
}

- (MHCoordinateBounds)overlayBounds {
    if (!_bounds) {
        mbgl::LatLngBounds bounds = mbgl::LatLngBounds::empty();
        for (auto coordinate : _coordinates) {
            if (!MHLocationCoordinate2DIsValid(coordinate)) {
                bounds = mbgl::LatLngBounds::empty();
                break;
            }
            bounds.extend(MHLatLngFromLocationCoordinate2D(coordinate));
        }
        _bounds = bounds;
    }
    return MHCoordinateBoundsFromLatLngBounds(*_bounds);
}

- (NSUInteger)pointCount
{
    return _coordinates.size();
}

- (CLLocationCoordinate2D *)coordinates
{
    return _coordinates.data();
}

- (CLLocationCoordinate2D)coordinate
{
    MHAssert([self pointCount] > 0, @"A multipoint must have coordinates");
    return _coordinates.at(0);
}

- (void)getCoordinates:(CLLocationCoordinate2D *)coords range:(NSRange)range
{
    if (range.location + range.length > [self pointCount])
    {
        [NSException raise:NSRangeException
                    format:@"Invalid coordinate range %@ extends beyond current coordinate count of %ld",
         NSStringFromRange(range), (unsigned long)[self pointCount]];
    }

    std::copy(_coordinates.begin() + range.location, _coordinates.begin() + NSMaxRange(range), coords);
}

- (BOOL)intersectsOverlayBounds:(MHCoordinateBounds)overlayBounds
{
    return MHCoordinateBoundsIntersectsCoordinateBounds(self.overlayBounds, overlayBounds);
}

- (mbgl::Geometry<double>)geometryObject
{
    mbgl::MultiPoint<double> multiPoint;
    multiPoint.reserve(self.pointCount);
    for (NSUInteger i = 0; i < self.pointCount; i++)
    {
        multiPoint.push_back(mbgl::Point<double>(self.coordinates[i].longitude, self.coordinates[i].latitude));
    }
    return multiPoint;
}

- (NSDictionary *)geoJSONDictionary
{
    NSMutableArray *coordinates = [[NSMutableArray alloc] initWithCapacity:self.pointCount];
    for (NSUInteger index = 0; index < self.pointCount; index++) {
        CLLocationCoordinate2D coordinate = self.coordinates[index];
        [coordinates addObject:@[@(coordinate.longitude), @(coordinate.latitude)]];
    }

    return @{@"type": @"MultiPoint",
             @"coordinates": coordinates};
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; count = %lu; bounds = %@>",
            NSStringFromClass([self class]), (void *)self, (unsigned long)[self pointCount],
            MHStringFromCoordinateBounds(self.overlayBounds)];
}

@end

NS_ASSUME_NONNULL_END
