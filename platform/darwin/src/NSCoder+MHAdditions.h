#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import <mbgl/util/feature.hpp>

@interface NSCoder (MHAdditions)

- (void)encodeMHCoordinate:(CLLocationCoordinate2D)coordinate forKey:(NSString *)key;

- (CLLocationCoordinate2D)decodeMHCoordinateForKey:(NSString *)key;

- (void)mgl_encodeLocationCoordinates2D:(std::vector<CLLocationCoordinate2D>)coordinates
                                 forKey:(NSString *)key;

- (std::vector<CLLocationCoordinate2D>)mgl_decodeLocationCoordinates2DForKey:(NSString *)key;

@end
