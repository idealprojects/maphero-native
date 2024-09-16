#import "NSDate+MHAdditions.h"
#import <ratio>

mbgl::Duration MHDurationFromTimeInterval(NSTimeInterval duration)
{
    return std::chrono::duration_cast<mbgl::Duration>(std::chrono::duration<NSTimeInterval>(duration));
}

NSTimeInterval MHTimeIntervalFromDuration(mbgl::Duration duration)
{
    return std::chrono::duration<NSTimeInterval, std::ratio<1>>(duration).count();
}
