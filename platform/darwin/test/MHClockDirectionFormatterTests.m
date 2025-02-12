#import <Mapbox.h>
#import <XCTest/XCTest.h>

@interface MHClockDirectionFormatterTests : XCTestCase

@end

@implementation MHClockDirectionFormatterTests

- (void)testClockDirections {
    MHClockDirectionFormatter *shortFormatter = [[MHClockDirectionFormatter alloc] init];
    shortFormatter.unitStyle = NSFormattingUnitStyleShort;

    MHClockDirectionFormatter *mediumFormatter = [[MHClockDirectionFormatter alloc] init];

    MHClockDirectionFormatter *longFormatter = [[MHClockDirectionFormatter alloc] init];
    longFormatter.unitStyle = NSFormattingUnitStyleLong;

    CLLocationDirection direction;

    direction = -90;
    XCTAssertEqualObjects(@"9:00", [shortFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"9 o’clock", [mediumFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"9 o’clock", [longFormatter stringFromDirection:direction]);

    direction = 0;
    XCTAssertEqualObjects(@"12:00", [shortFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"12 o’clock", [mediumFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"12 o’clock", [longFormatter stringFromDirection:direction]);

    direction = 45;
    XCTAssertEqualObjects(@"2:00", [shortFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"2 o’clock", [mediumFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"2 o’clock", [longFormatter stringFromDirection:direction]);

    direction = 90;
    XCTAssertEqualObjects(@"3:00", [shortFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"3 o’clock", [mediumFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"3 o’clock", [longFormatter stringFromDirection:direction]);

    direction = 180;
    XCTAssertEqualObjects(@"6:00", [shortFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"6 o’clock", [mediumFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"6 o’clock", [longFormatter stringFromDirection:direction]);

    direction = 270;
    XCTAssertEqualObjects(@"9:00", [shortFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"9 o’clock", [mediumFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"9 o’clock", [longFormatter stringFromDirection:direction]);

    direction = 359.34951805867024;
    XCTAssertEqualObjects(@"12:00", [shortFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"12 o’clock", [mediumFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"12 o’clock", [longFormatter stringFromDirection:direction]);

    direction = 360;
    XCTAssertEqualObjects(@"12:00", [shortFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"12 o’clock", [mediumFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"12 o’clock", [longFormatter stringFromDirection:direction]);

    direction = 360.1;
    XCTAssertEqualObjects(@"12:00", [shortFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"12 o’clock", [mediumFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"12 o’clock", [longFormatter stringFromDirection:direction]);

    direction = 720;
    XCTAssertEqualObjects(@"12:00", [shortFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"12 o’clock", [mediumFormatter stringFromDirection:direction]);
    XCTAssertEqualObjects(@"12 o’clock", [longFormatter stringFromDirection:direction]);
}

@end
