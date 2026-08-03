#import <Foundation/Foundation.h>

#include <mbgl/util/chrono.hpp>
#import "MHFoundation.h"

NS_ASSUME_NONNULL_BEGIN

/// Converts from a duration in seconds to a duration object usable in mbgl.
MH_EXPORT
mbgl::Duration MHDurationFromTimeInterval(NSTimeInterval duration);

/// Converts from an mbgl duration object to a duration in seconds.
MH_EXPORT
NSTimeInterval MHTimeIntervalFromDuration(mbgl::Duration duration);

NS_ASSUME_NONNULL_END
