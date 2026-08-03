#import "NSCoder+MHAdditions.h"

#import "NSArray+MHAdditions.h"
#import "NSValue+MHAdditions.h"

@implementation NSCoder (MHAdditions)

- (void)mgl_encodeLocationCoordinates2D:(std::vector<CLLocationCoordinate2D>)coordinates forKey:(NSString *)key {
    [self encodeObject:[NSArray mgl_coordinatesFromCoordinates:coordinates] forKey:key];
}

- (std::vector<CLLocationCoordinate2D>)mgl_decodeLocationCoordinates2DForKey:(NSString *)key {
    NSArray *coordinates = [self decodeObjectOfClass:[NSArray class] forKey:key];
    return [coordinates mgl_coordinates];
}

- (void)encodeMHCoordinate:(CLLocationCoordinate2D)coordinate forKey:(NSString *)key {
    [self encodeObject:@{@"latitude": @(coordinate.latitude), @"longitude": @(coordinate.longitude)} forKey:key];
}

- (CLLocationCoordinate2D)decodeMHCoordinateForKey:(NSString *)key {
    NSDictionary *coordinate = [self decodeObjectForKey:key];
    return CLLocationCoordinate2DMake([coordinate[@"latitude"] doubleValue], [coordinate[@"longitude"] doubleValue]);
}

@end
