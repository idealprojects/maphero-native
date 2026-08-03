#import <Mapbox.h>
#import <XCTest/XCTest.h>

@interface MHDistanceFormatterTests : XCTestCase

@end

@implementation MHDistanceFormatterTests

- (void)testAbbreviatedMetricUnits {
    MHDistanceFormatter *formatter = [[MHDistanceFormatter alloc] init];
    formatter.numberFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_CA"];
    for (CLLocationDistance distance=0; distance <= 10000; distance+=5) {
        NSString *unit = [[formatter stringFromDistance:distance] componentsSeparatedByString:@" "][1];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", @[@"mm", @"cm", @"m", @"km"]];
        XCTAssert([predicate evaluateWithObject:unit], @"Should only contain metric units");
    }
}

- (void)testAbbreviatedImperialUnits {
    MHDistanceFormatter *formatter = [[MHDistanceFormatter alloc] init];
    formatter.numberFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    for (CLLocationDistance distance=0; distance <= 10000; distance+=5) {
        NSString *unit = [[formatter stringFromDistance:distance] componentsSeparatedByString:@" "][1];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", @[@"ft", @"mi"]];
        XCTAssert([predicate evaluateWithObject:unit], @"Should only contain imperial units");
    }
}

@end
