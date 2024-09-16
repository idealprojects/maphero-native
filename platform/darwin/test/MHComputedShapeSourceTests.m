#import <XCTest/XCTest.h>

#import <Mapbox.h>


@interface MHComputedShapeSourceTests : XCTestCase
@end

@implementation MHComputedShapeSourceTests

- (void)testInitializer {
    MHComputedShapeSource *source = [[MHComputedShapeSource alloc] initWithIdentifier:@"id" options:@{}];
    XCTAssertNotNil(source);
    XCTAssertNotNil(source.requestQueue);
    XCTAssertNil(source.dataSource);
}

- (void)testNilOptions {
    MHComputedShapeSource *source = [[MHComputedShapeSource alloc] initWithIdentifier:@"id" options:nil];
    XCTAssertNotNil(source);
}


@end
