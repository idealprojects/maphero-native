#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "MHFoundation.h"

NS_ASSUME_NONNULL_BEGIN

/**
 ``MHDistanceFormatter`` implements a formatter object meant to be used for
 geographic distances. The user’s current locale will be used by default
 but it can be overriden by changing the locale property of the numberFormatter.
 */
MH_EXPORT
@interface MHDistanceFormatter : NSLengthFormatter

/**
 Returns a localized formatted string for the provided distance.

 @param distance The distance, measured in meters.
 @return A localized formatted distance string including units.
 */
- (NSString *)stringFromDistance:(CLLocationDistance)distance;

@end

NS_ASSUME_NONNULL_END
