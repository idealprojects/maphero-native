#import "MHShapeCollection.h"

#import "MHShape_Private.h"
#import "MHFeature.h"
#import "MHLoggingConfiguration_Private.h"

#import <mbgl/style/conversion/geojson.hpp>

@implementation MHShapeCollection

+ (instancetype)shapeCollectionWithShapes:(NSArray<MHShape *> *)shapes {
    return [[self alloc] initWithShapes:shapes];
}

- (instancetype)initWithShapes:(NSArray<MHShape *> *)shapes {
    MHLogDebug(@"Initializing with %lu shapes.", (unsigned long)shapes.count);
    if (self = [super init]) {
        _shapes = shapes.copy;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    MHLogInfo(@"Initializing with coder.");
    if (self = [super initWithCoder:decoder]) {
        _shapes = [decoder decodeObjectOfClass:[NSArray class] forKey:@"shapes"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:_shapes forKey:@"shapes"];
}

- (BOOL)isEqual:(id)other {
    if (self == other) return YES;
    if (![other isKindOfClass:[MHShapeCollection class]]) return NO;

    MHShapeCollection *otherShapeCollection = other;
    return [super isEqual:otherShapeCollection]
    && [_shapes isEqualToArray:otherShapeCollection.shapes];
}

- (NSUInteger)hash {
    NSUInteger hash = [super hash];
    for (MHShape *shape in _shapes) {
        hash += [shape hash];
    }
    return hash;
}

- (CLLocationCoordinate2D)coordinate {
    return _shapes.firstObject.coordinate;
}

- (NSDictionary *)geoJSONDictionary {
    return @{@"type": @"GeometryCollection",
             @"geometries": [self geometryCollection]};
}

- (NSArray *)geometryCollection {
    NSMutableArray *geometries = [[NSMutableArray alloc] initWithCapacity:self.shapes.count];
    for (id shape in self.shapes) {
        NSDictionary *geometry = [shape geoJSONDictionary];
        [geometries addObject:geometry];
    }
    return [geometries copy];
}

- (mbgl::Geometry<double>)geometryObject {
    mapbox::geojson::geometry_collection collection;
    collection.reserve(self.shapes.count);
    for (MHShape *shape in self.shapes) {
        collection.push_back([shape geometryObject]);
    }
    return collection;
}

@end
