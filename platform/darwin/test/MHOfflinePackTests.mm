#import <Mapbox.h>
#import <XCTest/XCTest.h>
#import "MHOfflinePack_Private.h"
#import "MHTestAssertionHandler.h"

@interface MHOfflinePackTests : XCTestCase

@end

@implementation MHOfflinePackTests

- (void)testInvalidation {
    MHOfflinePack *invalidPack = [[MHOfflinePack alloc] init];

    XCTAssertEqual(invalidPack.state, MHOfflinePackStateInvalid, @"Offline pack should be invalid when initialized independently of MHOfflineStorage.");

    XCTAssertThrowsSpecificNamed(invalidPack.region, NSException, MHInvalidOfflinePackException, @"Invalid offline pack should raise an exception when accessing its region.");
    XCTAssertThrowsSpecificNamed(invalidPack.context, NSException, MHInvalidOfflinePackException, @"Invalid offline pack should raise an exception when accessing its context.");
    XCTAssertThrowsSpecificNamed([invalidPack resume], NSException, MHInvalidOfflinePackException, @"Invalid offline pack should raise an exception when being resumed.");
    XCTAssertThrowsSpecificNamed([invalidPack suspend], NSException, MHInvalidOfflinePackException, @"Invalid offline pack should raise an exception when being suspended.");
}

- (void)testInvalidatingAnInvalidPack {
    MHOfflinePack *invalidPack = [[MHOfflinePack alloc] init];

    XCTAssertThrowsSpecificNamed([invalidPack invalidate], NSException, NSInternalInconsistencyException, @"Invalid offline pack should raise an exception when being invalidated.");

    // Now try again, without asserts
    NSAssertionHandler *oldHandler = [NSAssertionHandler currentHandler];
    MHTestAssertionHandler *newHandler = [[MHTestAssertionHandler alloc] initWithTestCase:self];
    [[[NSThread currentThread] threadDictionary] setValue:newHandler forKey:NSAssertionHandlerKey];

    // Make sure this doesn't crash without asserts
    [invalidPack invalidate];
    
    [[[NSThread currentThread] threadDictionary] setValue:oldHandler forKey:NSAssertionHandlerKey];
}

- (void)testProgressBoxing {
    MHOfflinePackProgress progress = {
        .countOfResourcesCompleted = 3,
        .countOfResourcesExpected = 2,
        .countOfBytesCompleted = 7,
        .countOfTilesCompleted = 1,
        .countOfTileBytesCompleted = 6,
        .maximumResourcesExpected = UINT64_MAX,
    };
    MHOfflinePackProgress roundTrippedProgress = [NSValue valueWithMHOfflinePackProgress:progress].MHOfflinePackProgressValue;

    XCTAssertEqual(progress.countOfResourcesCompleted, roundTrippedProgress.countOfResourcesCompleted, @"Completed resources should round-trip.");
    XCTAssertEqual(progress.countOfResourcesExpected, roundTrippedProgress.countOfResourcesExpected, @"Expected resources should round-trip.");
    XCTAssertEqual(progress.countOfBytesCompleted, roundTrippedProgress.countOfBytesCompleted, @"Completed bytes should round-trip.");
    XCTAssertEqual(progress.countOfTilesCompleted, roundTrippedProgress.countOfTilesCompleted, @"Completed tiles should round-trip.");
    XCTAssertEqual(progress.countOfTileBytesCompleted, roundTrippedProgress.countOfTileBytesCompleted, @"Completed tile bytes should round-trip.");
    XCTAssertEqual(progress.maximumResourcesExpected, roundTrippedProgress.maximumResourcesExpected, @"Maximum expected resources should round-trip.");
}

@end
