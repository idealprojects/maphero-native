#import "MHMultiPoint_Private.h"
#import "MHGeometry_Private.h"
#import "MHShape_Private.h"
#import "NSCoder+MHAdditions.h"
#import "MHTypes.h"
#import "MHLoggingConfiguration_Private.h"

@implementation MHMultiPoint
{
    std::optional<mbgl::LatLngBounds> _bounds;
    std::vector<CLLocationCoordinate2D> _coordinates;
}

- (instancetype)initWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count
{
    MHLogDebug(@"Initializing with %lu coordinates.", (unsigned long) count);
    self = [super init];

    if (self)
    {
        if (!count) {
            [NSException raise:NSInvalidArgumentException
                        format:@"A multipoint must have at least one vertex."];
        }
        _coordinates = { coords, coords + count };
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    MHLogInfo(@"Initializing with coder.");
    if (self = [super initWithCoder:decoder]) {
        _coordinates = [decoder mgl_decodeLocationCoordinates2DForKey:@"coordinates"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder mgl_encodeLocationCoordinates2D:_coordinates forKey:@"coordinates"];
}

- (BOOL)isEqual:(id)other
{
    if (self == other) return YES;
    if (![other isKindOfClass:[MHMultiPoint class]]) return NO;

    MHMultiPoint *otherMultipoint = other;
    return ([super isEqual:otherMultipoint]
            && _coordinates == otherMultipoint->_coordinates);
}

- (NSUInteger)hash
{
    NSUInteger hash = [super hash];
    for (auto coord : _coordinates) {
        hash += @(coord.latitude+coord.longitude).hash;
    }
    return hash;
}

- (CLLocationCoordinate2D)coordinate
{
    MHAssert([self pointCount] > 0, @"A multipoint must have coordinates");
    return _coordinates.at(0);
}

- (NSUInteger)pointCount
{
    return _coordinates.size();
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingPointCount
{
    return [NSSet setWithObjects:@"coordinates", nil];
}

- (CLLocationCoordinate2D *)coordinates
{
    return _coordinates.data();
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

- (void)setCoordinates:(CLLocationCoordinate2D *)coords count:(NSUInteger)count {
    MHLogDebug(@"Setting: %lu coordinates.", (unsigned long)count);
    if (!count) {
        [NSException raise:NSInvalidArgumentException
                    format:@"A multipoint must have at least one vertex."];
    }

    [self willChangeValueForKey:@"coordinates"];
    _coordinates = { coords, coords + count };
    _bounds = {};
    [self didChangeValueForKey:@"coordinates"];
}

- (void)insertCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count atIndex:(NSUInteger)index {
    MHLogDebug(@"Inserting %lu coordinates at index %lu.", (unsigned long)count, (unsigned long)index);
    if (!count) {
        return;
    }

    if (index > _coordinates.size()) {
        [NSException raise:NSRangeException
                    format:@"Invalid index %lu for existing coordinate count %ld",
         (unsigned long)index, (unsigned long)[self pointCount]];
    }

    [self willChangeValueForKey:@"coordinates"];
    _coordinates.insert(_coordinates.begin() + index, count, *coords);
    _bounds = {};
    [self didChangeValueForKey:@"coordinates"];
}

- (void)appendCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count
{
    MHLogDebug(@"Appending %lu coordinates.", (unsigned long)count);
    [self insertCoordinates:coords count:count atIndex:_coordinates.size()];
}

- (void)replaceCoordinatesInRange:(NSRange)range withCoordinates:(const CLLocationCoordinate2D *)coords
{
    MHLogDebug(@"Replacing coordinates in range: %@", NSStringFromRange(range));
    [self replaceCoordinatesInRange:range withCoordinates:coords count:range.length];
}

- (void)replaceCoordinatesInRange:(NSRange)range withCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count {
    MHLogDebug(@"Replacing %lu coordinates in range %@.", (unsigned long)count, NSStringFromRange(range));
    if (!count && !range.length) {
        return;
    }

    if (NSMaxRange(range) > _coordinates.size()) {
        [NSException raise:NSRangeException
                    format:@"Invalid range %@ for existing coordinate count %ld",
         NSStringFromRange(range), (unsigned long)[self pointCount]];
    }

    [self willChangeValueForKey:@"coordinates"];
    std::copy(coords, coords + MIN(count, range.length), _coordinates.begin() + range.location);
    if (count >= range.length) {
        _coordinates.insert(_coordinates.begin() + NSMaxRange(range), coords, coords + count - range.length);
    } else {
        _coordinates.erase(_coordinates.begin() + range.location + count, _coordinates.begin() + NSMaxRange(range));
    }
    _bounds = {};
    [self didChangeValueForKey:@"coordinates"];
}

- (void)removeCoordinatesInRange:(NSRange)range {
    MHLogDebug(@"Removing coordinatesInRange: %@", NSStringFromRange(range));
    CLLocationCoordinate2D coords;
    [self replaceCoordinatesInRange:range withCoordinates:&coords count:0];
}

- (MHCoordinateBounds)overlayBounds
{
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

- (BOOL)intersectsOverlayBounds:(MHCoordinateBounds)overlayBounds
{
    return MHCoordinateBoundsIntersectsCoordinateBounds(self.overlayBounds, overlayBounds);
}

- (mbgl::Annotation)annotationObjectWithDelegate:(__unused id <MHMultiPointDelegate>)delegate
{
    MHAssert(NO, @"Cannot add an annotation from an instance of %@", NSStringFromClass([self class]));
    return mbgl::SymbolAnnotation(mbgl::Point<double>());
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; count = %lu; bounds = %@>",
            NSStringFromClass([self class]), (void *)self, (unsigned long)[self pointCount],
            MHStringFromCoordinateBounds(self.overlayBounds)];
}

@end
