#import "MHPointAnnotation.h"

#import "MHShape_Private.h"
#import "NSCoder+MHAdditions.h"
#import "MHLoggingConfiguration_Private.h"

#import <mbgl/util/geometry.hpp>


@implementation MHPointAnnotation

@synthesize coordinate;

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    MHLogInfo(@"Initializing with coder.");
    if (self = [super initWithCoder:coder]) {
        self.coordinate = [coder decodeMHCoordinateForKey:@"coordinate"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeMHCoordinate:coordinate forKey:@"coordinate"];
}

- (BOOL)isEqual:(id)other
{
    if (other == self) return YES;
    if (![other isKindOfClass:[MHPointAnnotation class]]) return NO;

    MHPointAnnotation *otherAnnotation = other;
    return ([super isEqual:other]
            && self.coordinate.latitude == otherAnnotation.coordinate.latitude
            && self.coordinate.longitude == otherAnnotation.coordinate.longitude);
}

- (NSUInteger)hash
{
    return [super hash] + @(self.coordinate.latitude).hash + @(self.coordinate.longitude).hash;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; title = %@; subtitle = %@; coordinate = %f, %f>",
            NSStringFromClass([self class]), (void *)self,
            self.title ? [NSString stringWithFormat:@"\"%@\"", self.title] : self.title,
            self.subtitle ? [NSString stringWithFormat:@"\"%@\"", self.subtitle] : self.subtitle,
            coordinate.latitude, coordinate.longitude];
}

- (NSDictionary *)geoJSONDictionary
{
    return @{@"type": @"Point",
             @"coordinates": @[@(self.coordinate.longitude), @(self.coordinate.latitude)]};
}

- (mbgl::Geometry<double>)geometryObject
{
    mbgl::Point<double> point = { self.coordinate.longitude, self.coordinate.latitude };
    return point;
}

@end

