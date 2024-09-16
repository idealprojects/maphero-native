#import "MHPolyline_Private.h"

#import "MHMultiPoint_Private.h"
#import "MHGeometry_Private.h"

#import "MHFeature.h"
#import "MHLoggingConfiguration_Private.h"

#import <mbgl/util/geojson.hpp>
#import <mapbox/polylabel.hpp>

@implementation MHPolyline

@dynamic overlayBounds;

+ (instancetype)polylineWithCoordinates:(const CLLocationCoordinate2D *)coords
                                  count:(NSUInteger)count
{
    return [[self alloc] initWithCoordinates:coords count:count];
}

- (mbgl::LineString<double>)lineString {
    NSUInteger count = self.pointCount;
    CLLocationCoordinate2D *coordinates = self.coordinates;

    mbgl::LineString<double> geometry;
    geometry.reserve(self.pointCount);
    for (NSUInteger i = 0; i < count; i++) {
        geometry.push_back(mbgl::Point<double>(coordinates[i].longitude, coordinates[i].latitude));
    }

    return geometry;
}

- (mbgl::Annotation)annotationObjectWithDelegate:(id <MHMultiPointDelegate>)delegate {
    mbgl::LineAnnotation annotation { [self lineString] };
    annotation.opacity = { static_cast<float>([delegate alphaForShapeAnnotation:self]) };
    annotation.color = { [delegate strokeColorForShapeAnnotation:self] };
    annotation.width = { static_cast<float>([delegate lineWidthForPolylineAnnotation:self]) };

    return annotation;
}

- (mbgl::Geometry<double>)geometryObject {
    return [self lineString];
}

- (NSDictionary *)geoJSONDictionary {
    return @{@"type": @"LineString",
             @"coordinates": self.mgl_coordinates};
}

- (NSArray<id> *)mgl_coordinates {
    NSMutableArray *coordinates = [[NSMutableArray alloc] initWithCapacity:self.pointCount];
    for (NSUInteger index = 0; index < self.pointCount; index++) {
        CLLocationCoordinate2D coordinate = self.coordinates[index];
        [coordinates addObject:@[@(coordinate.longitude), @(coordinate.latitude)]];
    }
    return [coordinates copy];
}

- (BOOL)isEqual:(id)other {
    return self == other || ([other isKindOfClass:[MHPolyline class]] && [super isEqual:other]);
}

- (CLLocationCoordinate2D)coordinate {
    NSUInteger count = self.pointCount;
    MHAssert(count > 0, @"Polyline must have coordinates");

    CLLocationCoordinate2D *coordinates = self.coordinates;
    CLLocationDistance middle = [self length] / 2.0;
    CLLocationDistance traveled = 0.0;
    
    if (count > 1 || middle > traveled) {
        for (NSUInteger i = 0; i < count; i++) {

            // Avoid a heap buffer overflow when there are only two coordinates.
            NSUInteger nextIndex = (i + 1 == count) ? 0 : 1;

            MHRadianCoordinate2D from = MHRadianCoordinateFromLocationCoordinate(coordinates[i]);
            MHRadianCoordinate2D to = MHRadianCoordinateFromLocationCoordinate(coordinates[i + nextIndex]);
            
            if (traveled >= middle) {
                double overshoot = middle - traveled;
                if (overshoot == 0) {
                    return coordinates[i];
                }
                to = MHRadianCoordinateFromLocationCoordinate(coordinates[i - 1]);
                CLLocationDirection direction = [self direction:from to:to] - 180;
                MHRadianCoordinate2D otherCoordinate = MHRadianCoordinateAtDistanceFacingDirection(from,
                                                                                                     overshoot/mbgl::util::EARTH_RADIUS_M,
                                                                                                     MHRadiansFromDegrees(direction));
                return CLLocationCoordinate2DMake(MHDegreesFromRadians(otherCoordinate.latitude),
                                                  MHDegreesFromRadians(otherCoordinate.longitude));
            }
            
            traveled += (MHDistanceBetweenRadianCoordinates(from, to) * mbgl::util::EARTH_RADIUS_M);
        }
    }

    return coordinates[count - 1];
}

- (CLLocationDistance)length
{
    CLLocationDistance length = 0.0;
    
    NSUInteger count = self.pointCount;
    CLLocationCoordinate2D *coordinates = self.coordinates;
    
    for (NSUInteger i = 0; i < count - 1; i++) {        
        length += (MHDistanceBetweenRadianCoordinates(MHRadianCoordinateFromLocationCoordinate(coordinates[i]),                                                  MHRadianCoordinateFromLocationCoordinate(coordinates[i + 1])) * mbgl::util::EARTH_RADIUS_M);
    }
    
    return length;
}

- (CLLocationDirection)direction:(MHRadianCoordinate2D)from to:(MHRadianCoordinate2D)to
{
    return MHDegreesFromRadians(MHRadianCoordinatesDirection(from, to));
}

@end

@interface MHMultiPolyline ()

@property (nonatomic, copy, readwrite) NSArray<MHPolyline *> *polylines;

@end

@implementation MHMultiPolyline {
    MHCoordinateBounds _overlayBounds;
}

@synthesize overlayBounds = _overlayBounds;

+ (instancetype)multiPolylineWithPolylines:(NSArray<MHPolyline *> *)polylines {
    return [[self alloc] initWithPolylines:polylines];
}

- (instancetype)initWithPolylines:(NSArray<MHPolyline *> *)polylines {
    MHLogDebug(@"Initializing with %lu polylines.", (unsigned long)polylines.count);
    if (self = [super init]) {
        _polylines = polylines;

        mbgl::LatLngBounds bounds = mbgl::LatLngBounds::empty();

        for (MHPolyline *polyline in _polylines) {
            bounds.extend(MHLatLngBoundsFromCoordinateBounds(polyline.overlayBounds));
        }
        _overlayBounds = MHCoordinateBoundsFromLatLngBounds(bounds);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    MHLogInfo(@"Initializing with coder.");
    if (self = [super initWithCoder:decoder]) {
        _polylines = [decoder decodeObjectOfClass:[NSArray class] forKey:@"polylines"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:_polylines forKey:@"polylines"];
}

- (BOOL)isEqual:(id)other
{
    if (self == other) return YES;
    if (![other isKindOfClass:[MHMultiPolyline class]]) return NO;

    MHMultiPolyline *otherMultipoline = other;
    return ([super isEqual:otherMultipoline]
            && [self.polylines isEqualToArray:otherMultipoline.polylines]);
}

- (NSUInteger)hash {
    NSUInteger hash = [super hash];
    for (MHPolyline *polyline in self.polylines) {
        hash += [polyline hash];
    }
    return hash;
}

- (CLLocationCoordinate2D)coordinate {
    MHPolyline *polyline = self.polylines.firstObject;
    CLLocationCoordinate2D *coordinates = polyline.coordinates;
    MHAssert([polyline pointCount] > 0, @"Polyline must have coordinates");
    CLLocationCoordinate2D firstCoordinate = coordinates[0];

    return firstCoordinate;
}

- (BOOL)intersectsOverlayBounds:(MHCoordinateBounds)overlayBounds {
    return MHCoordinateBoundsIntersectsCoordinateBounds(_overlayBounds, overlayBounds);
}

- (mbgl::Geometry<double>)geometryObject {
    mbgl::MultiLineString<double> multiLineString;
    multiLineString.reserve(self.polylines.count);
    for (MHPolyline *polyline in self.polylines) {
        multiLineString.push_back([polyline lineString]);
    }
    return multiLineString;
}

- (NSDictionary *)geoJSONDictionary {
    NSMutableArray *coordinates = [NSMutableArray array];
    for (MHPolylineFeature *feature in self.polylines) {
        [coordinates addObject: feature.mgl_coordinates];
    }
    return @{@"type": @"MultiLineString",
             @"coordinates": coordinates};
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; title = %@, subtitle: = %@, count = %lu; bounds = %@>",
            NSStringFromClass([self class]), (void *)self,
            self.title ? [NSString stringWithFormat:@"\"%@\"", self.title] : self.title,
            self.subtitle ? [NSString stringWithFormat:@"\"%@\"", self.subtitle] : self.subtitle,
            (unsigned long)self.polylines.count,
            MHStringFromCoordinateBounds(self.overlayBounds)];
}

@end
