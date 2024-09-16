#import <XCTest/XCTest.h>

#include <mbgl/util/chrono.hpp>
#import "../../darwin/src/NSDate+MHAdditions.h"

using namespace std::chrono_literals;

@interface MHNSDateAdditionsTests : XCTestCase
@end

@implementation MHNSDateAdditionsTests

- (void)testDurationToNSTimeInterval {
    
    NSTimeInterval timeInterval = 5;
    mbgl::Duration duration = MHDurationFromTimeInterval(timeInterval);
    NSTimeInterval durationTimeInterval = MHTimeIntervalFromDuration(duration);
    
    mbgl::Duration expectedDuration = 5s;
    mbgl::Duration expectedDurationMiliSeconds = 5000ms;
    mbgl::Duration expectedDurationMicroSeconds = 5000000us;
    mbgl::Duration expectedDurationNanoSeconds = 5000000000ns;
    
    XCTAssertEqual(timeInterval, durationTimeInterval);
    XCTAssertEqual(timeInterval, MHTimeIntervalFromDuration(expectedDuration));
    XCTAssertEqual(timeInterval, MHTimeIntervalFromDuration(expectedDurationMiliSeconds));
    XCTAssertEqual(timeInterval, MHTimeIntervalFromDuration(expectedDurationMicroSeconds));
    XCTAssertEqual(timeInterval, MHTimeIntervalFromDuration(expectedDurationNanoSeconds));
    
    mbgl::Duration durationMiliSeconds = 2500ms;
    mbgl::Duration durationMicroSeconds = 2500000us;
    mbgl::Duration durationNanoSeconds = 2500000000ns;
    
    XCTAssertEqual(NSTimeInterval(2.5), MHTimeIntervalFromDuration(durationMiliSeconds));
    XCTAssertEqual(NSTimeInterval(2.5), MHTimeIntervalFromDuration(durationMicroSeconds));
    XCTAssertEqual(NSTimeInterval(2.5), MHTimeIntervalFromDuration(durationNanoSeconds));
    
}

@end
