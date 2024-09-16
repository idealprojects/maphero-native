#import <Mapbox.h>
#import <XCTest/XCTest.h>

#import "MHOfflineStorage_Private.h"
#import "NSBundle+MHAdditions.h"
#import "NSDate+MHAdditions.h"
#import "MHTestAssertionHandler.h"

#include <mbgl/storage/resource.hpp>
#include <mbgl/util/run_loop.hpp>

#pragma clang diagnostic ignored "-Wshadow"


@interface MHOfflineStorageTests : XCTestCase <MHOfflineStorageDelegate>
@end

@implementation MHOfflineStorageTests

+ (void)tearDown {
    NSURL *cacheDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                                      inDomain:NSUserDomainMask
                                                             appropriateForURL:nil
                                                                        create:NO
                                                                         error:nil];
    NSString *bundleIdentifier = [NSBundle mgl_applicationBundleIdentifier];
    cacheDirectoryURL = [cacheDirectoryURL URLByAppendingPathComponent:bundleIdentifier];
    cacheDirectoryURL = [cacheDirectoryURL URLByAppendingPathComponent:@".mapbox"];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:cacheDirectoryURL.path], @"Directory containing database should exist.");
    
    NSURL *cacheURL = [cacheDirectoryURL URLByAppendingPathComponent:@"cache.db"];
    XCTAssertEqualObjects(cacheURL, MHOfflineStorage.sharedOfflineStorage.databaseURL);
    
    [[NSFileManager defaultManager] removeItemAtURL:cacheURL error:nil];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:cacheURL.path], @"Database should not exist.");
}

- (void)setUp {
    [super setUp];
    [MHSettings useWellKnownTileServer:MHMapTiler];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        XCTestExpectation *expectation = [self keyValueObservingExpectationForObject:[MHOfflineStorage sharedOfflineStorage] keyPath:@"packs" handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
            const auto changeKind = static_cast<NSKeyValueChange>([change[NSKeyValueChangeKindKey] unsignedLongValue]);
            return changeKind == NSKeyValueChangeSetting;
        }];
        if ([MHOfflineStorage sharedOfflineStorage].packs) {
            [expectation fulfill];
            [self waitForExpectationsWithTimeout:0 handler:nil];
        } else {
            [self waitForExpectationsWithTimeout:10 handler:nil];
        }

        XCTAssertNotNil([MHOfflineStorage sharedOfflineStorage].packs, @"Shared offline storage object should have a non-nil collection of packs by this point.");
    });
}

- (NSURL *)offlineStorage:(MHOfflineStorage *)storage
     URLForResourceOfKind:(MHResourceKind)kind
                  withURL:(NSURL *)url {
    if ([url.scheme isEqual: @"test"] && [url.host isEqual: @"api"]) {
        return [NSURL URLWithString:@"https://api.mapbox.com"];
    } else {
        return url;
    }
}

- (void)testSharedObject {
    XCTAssertEqual([MHOfflineStorage sharedOfflineStorage], [MHOfflineStorage sharedOfflineStorage], @"There should only be one shared offline storage object.");
}

- (void)testAddPackForBounds {
    NSUInteger countOfPacks = [MHOfflineStorage sharedOfflineStorage].packs.count;

    NSURL *styleURL = [[MHStyle predefinedStyle:@"Bright"] url];
    /// Somewhere near Grape Grove, Ohio, United States.
    MHCoordinateBounds bounds = {
        { .latitude = 39.70358155855172, .longitude = -83.69506472545841 },
        { .latitude = 39.703818870225376, .longitude = -83.69420641857361 },
    };
    double zoomLevel = 20;
    MHTilePyramidOfflineRegion *region = [[MHTilePyramidOfflineRegion alloc] initWithStyleURL:styleURL bounds:bounds fromZoomLevel:zoomLevel toZoomLevel:zoomLevel];

    NSString *nameKey = @"Name";
    NSString *name = @"🍇 Grape Grove";

    NSData *context = [NSKeyedArchiver archivedDataWithRootObject:@{
        nameKey: name,
    }];

    __block MHOfflinePack *pack;
    [self keyValueObservingExpectationForObject:[MHOfflineStorage sharedOfflineStorage] keyPath:@"packs" handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
        const auto changeKind = static_cast<NSKeyValueChange>([change[NSKeyValueChangeKindKey] unsignedLongValue]);
        NSIndexSet *indices = change[NSKeyValueChangeIndexesKey];
        return changeKind == NSKeyValueChangeInsertion && indices.count == 1;
    }];
    XCTestExpectation *additionCompletionHandlerExpectation = [self expectationWithDescription:@"add pack completion handler"];
    [[MHOfflineStorage sharedOfflineStorage] addPackForRegion:region withContext:context completionHandler:^(MHOfflinePack * _Nullable completionHandlerPack, NSError * _Nullable error) {
        XCTAssertNotNil(completionHandlerPack, @"Added pack should exist.");
        XCTAssertEqual(completionHandlerPack.state, MHOfflinePackStateInactive, @"New pack should initially have inactive state.");
        pack = completionHandlerPack;
        [additionCompletionHandlerExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];

    XCTAssertEqual([MHOfflineStorage sharedOfflineStorage].packs.count, countOfPacks + 1, @"Added pack should have been added to the canonical collection of packs owned by the shared offline storage object. This assertion can fail if this test is run before -testAAALoadPacks.");

    XCTAssertEqual(pack, [MHOfflineStorage sharedOfflineStorage].packs.lastObject, @"Pack should be appended to end of packs array.");

    XCTAssertEqualObjects(pack.region, region, @"Added pack’s region has changed.");

    NSDictionary *userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:pack.context];
    XCTAssert([userInfo isKindOfClass:[NSDictionary class]], @"Context of offline pack isn’t a dictionary.");
    XCTAssert([userInfo[nameKey] isKindOfClass:[NSString class]], @"Name of offline pack isn’t a string.");
    XCTAssertEqualObjects(userInfo[nameKey], name, @"Name of offline pack has changed.");

    XCTAssertEqual(pack.state, MHOfflinePackStateInactive, @"New pack should initially have inactive state.");

    [self keyValueObservingExpectationForObject:pack keyPath:@"state" handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
        const auto changeKind = static_cast<NSKeyValueChange>([change[NSKeyValueChangeKindKey] unsignedLongValue]);
        const auto state = static_cast<MHOfflinePackState>([change[NSKeyValueChangeNewKey] longValue]);
        return changeKind == NSKeyValueChangeSetting && state == MHOfflinePackStateInactive;
    }];
    [self expectationForNotification:MHOfflinePackProgressChangedNotification object:pack handler:^BOOL(NSNotification * _Nonnull notification) {
        MHOfflinePack *notificationPack = notification.object;
        XCTAssert([notificationPack isKindOfClass:[MHOfflinePack class]], @"Object of notification should be an MHOfflinePack.");

        NSDictionary *userInfo = notification.userInfo;
        XCTAssertNotNil(userInfo, @"Progress change notification should have a userInfo dictionary.");

        NSNumber *stateNumber = userInfo[MHOfflinePackUserInfoKeyState];
        XCTAssert([stateNumber isKindOfClass:[NSNumber class]], @"Progress change notification’s state should be an NSNumber.");
        XCTAssertEqual(stateNumber.integerValue, pack.state, @"State in a progress change notification should match the pack’s state.");

        NSValue *progressValue = userInfo[MHOfflinePackUserInfoKeyProgress];
        XCTAssert([progressValue isKindOfClass:[NSValue class]], @"Progress change notification’s progress should be an NSValue.");
        XCTAssertEqualObjects(progressValue, [NSValue valueWithMHOfflinePackProgress:pack.progress], @"Progress change notification’s progress should match pack’s progress.");

        return notificationPack == pack && pack.state == MHOfflinePackStateInactive;
    }];
    [pack requestProgress];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    
    XCTAssertEqualObjects(pack.context, context, @"Offline pack context should match the context specified by the application.");
    NSString *newName = @"🍑 Peach Grove";
    NSData *newContext = [NSKeyedArchiver archivedDataWithRootObject:@{
        nameKey: newName,
    }];
    
    XCTestExpectation *contextCompletionHandlerExpectation = [self expectationWithDescription:@"set pack completion context handler"];
    __weak MHOfflinePack *weakPack = pack;
    [pack setContext:newContext completionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(weakPack);
        XCTAssertEqualObjects(weakPack.context, newContext, @"Offline pack context should match the updated context specified by the application.");
        [contextCompletionHandlerExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testAddPackForGeometry {
    NSUInteger countOfPacks = [MHOfflineStorage sharedOfflineStorage].packs.count;

    NSURL *styleURL = [[MHStyle predefinedStyle:@"Bright"] url];
    double zoomLevel = 20;
    NSString *geojson = @"{ \"type\": \"Polygon\", \"coordinates\": [ [ [ 5.1299285888671875, 52.10365839097971 ], [ 5.103063583374023, 52.110037078604236 ], [ 5.080232620239258, 52.09548601177304 ], [ 5.106925964355469, 52.07987524347506 ], [ 5.1299285888671875, 52.10365839097971 ] ] ]}";
    NSError *error;
    MHShape *shape = [MHShape shapeWithData: [geojson dataUsingEncoding:NSUTF8StringEncoding] encoding: NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    MHShapeOfflineRegion *region = [[MHShapeOfflineRegion alloc] initWithStyleURL:styleURL shape:shape fromZoomLevel:zoomLevel toZoomLevel:zoomLevel];
    region.includesIdeographicGlyphs = NO;

    NSString *nameKey = @"Name";
    NSString *name = @"Utrecht centrum";

    NSData *context = [NSKeyedArchiver archivedDataWithRootObject:@{nameKey: name}];

    __block MHOfflinePack *pack;
    [self keyValueObservingExpectationForObject:[MHOfflineStorage sharedOfflineStorage] keyPath:@"packs" handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
        const auto changeKind = static_cast<NSKeyValueChange>([change[NSKeyValueChangeKindKey] unsignedLongValue]);
        NSIndexSet *indices = change[NSKeyValueChangeIndexesKey];
        return changeKind == NSKeyValueChangeInsertion && indices.count == 1;
    }];
    XCTestExpectation *additionCompletionHandlerExpectation = [self expectationWithDescription:@"add pack completion handler"];
    [[MHOfflineStorage sharedOfflineStorage] addPackForRegion:region withContext:context completionHandler:^(MHOfflinePack * _Nullable completionHandlerPack, NSError * _Nullable error) {
        XCTAssertNotNil(completionHandlerPack, @"Added pack should exist.");
        XCTAssertEqual(completionHandlerPack.state, MHOfflinePackStateInactive, @"New pack should initially have inactive state.");
        pack = completionHandlerPack;
        [additionCompletionHandlerExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];

    XCTAssertEqual([MHOfflineStorage sharedOfflineStorage].packs.count, countOfPacks + 1, @"Added pack should have been added to the canonical collection of packs owned by the shared offline storage object. This assertion can fail if this test is run before -testAAALoadPacks.");

    XCTAssertEqual(pack, [MHOfflineStorage sharedOfflineStorage].packs.lastObject, @"Pack should be appended to end of packs array.");

    XCTAssertEqualObjects(pack.region, region, @"Added pack’s region has changed.");

    NSDictionary *userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:pack.context];
    XCTAssert([userInfo isKindOfClass:[NSDictionary class]], @"Context of offline pack isn’t a dictionary.");
    XCTAssert([userInfo[nameKey] isKindOfClass:[NSString class]], @"Name of offline pack isn’t a string.");
    XCTAssertEqualObjects(userInfo[nameKey], name, @"Name of offline pack has changed.");

    XCTAssertEqual(pack.state, MHOfflinePackStateInactive, @"New pack should initially have inactive state.");

    [self keyValueObservingExpectationForObject:pack keyPath:@"state" handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
        const auto changeKind = static_cast<NSKeyValueChange>([change[NSKeyValueChangeKindKey] unsignedLongValue]);
        const auto state = static_cast<MHOfflinePackState>([change[NSKeyValueChangeNewKey] longValue]);
        return changeKind == NSKeyValueChangeSetting && state == MHOfflinePackStateInactive;
    }];
    [self expectationForNotification:MHOfflinePackProgressChangedNotification object:pack handler:^BOOL(NSNotification * _Nonnull notification) {
        MHOfflinePack *notificationPack = notification.object;
        XCTAssert([notificationPack isKindOfClass:[MHOfflinePack class]], @"Object of notification should be an MHOfflinePack.");

        NSDictionary *userInfo = notification.userInfo;
        XCTAssertNotNil(userInfo, @"Progress change notification should have a userInfo dictionary.");

        NSNumber *stateNumber = userInfo[MHOfflinePackUserInfoKeyState];
        XCTAssert([stateNumber isKindOfClass:[NSNumber class]], @"Progress change notification’s state should be an NSNumber.");
        XCTAssertEqual(stateNumber.integerValue, pack.state, @"State in a progress change notification should match the pack’s state.");

        NSValue *progressValue = userInfo[MHOfflinePackUserInfoKeyProgress];
        XCTAssert([progressValue isKindOfClass:[NSValue class]], @"Progress change notification’s progress should be an NSValue.");
        XCTAssertEqualObjects(progressValue, [NSValue valueWithMHOfflinePackProgress:pack.progress], @"Progress change notification’s progress should match pack’s progress.");

        return notificationPack == pack && pack.state == MHOfflinePackStateInactive;
    }];
    [pack requestProgress];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    pack = nil;
}

- (void)testInvalidatePack {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect offline pack to be invalidated without an error."];
    MHCoordinateBounds bounds = {
        { .latitude = 48.8660, .longitude = 2.3306 },
        { .latitude = 48.8603, .longitude = 2.3213 },
    };

    NSURL *styleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"one-liner" withExtension:@"json"];
    MHTilePyramidOfflineRegion *region = [[MHTilePyramidOfflineRegion alloc] initWithStyleURL:styleURL bounds:bounds fromZoomLevel:10 toZoomLevel:11];

    NSString *nameKey = @"Name";
    NSString *name = @"Paris square";

    NSData *context = [NSKeyedArchiver archivedDataWithRootObject:@{nameKey: name}];
    [[MHOfflineStorage sharedOfflineStorage] addPackForRegion:region withContext:context completionHandler:^(MHOfflinePack * _Nullable pack, NSError * _Nullable error) {
        XCTAssertNotNil(pack);
        [[MHOfflineStorage sharedOfflineStorage] invalidatePack:pack withCompletionHandler:^(NSError * _Nullable) {
            XCTAssertNotNil(pack);
            XCTAssertNil(error);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testRemovePack {
    NSUInteger countOfPacks = [MHOfflineStorage sharedOfflineStorage].packs.count;

    MHOfflinePack *pack = [MHOfflineStorage sharedOfflineStorage].packs.lastObject;
    XCTAssertNotNil(pack, @"Added pack should still exist.");

    [self keyValueObservingExpectationForObject:[MHOfflineStorage sharedOfflineStorage] keyPath:@"packs" handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
        const auto changeKind = static_cast<NSKeyValueChange>([change[NSKeyValueChangeKindKey] unsignedLongValue]);
        NSIndexSet *indices = change[NSKeyValueChangeIndexesKey];
        return changeKind == NSKeyValueChangeRemoval && indices.count == 1;
    }];
    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"remove pack completion handler"];
    [[MHOfflineStorage sharedOfflineStorage] removePack:pack withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertEqual(pack.state, MHOfflinePackStateInvalid, @"Removed pack should be invalid in the completion handler.");
        [completionHandlerExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];

    XCTAssertEqual(pack.state, MHOfflinePackStateInvalid, @"Removed pack should have been invalidated synchronously.");

    XCTAssertEqual([MHOfflineStorage sharedOfflineStorage].packs.count, countOfPacks - 1, @"Removed pack should have been removed from the canonical collection of packs owned by the shared offline storage object. This assertion can fail if this test is run before -testAAALoadPacks or -testAddPack.");
}

- (void)testBackupExclusion {
    NSURL *cacheDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                                      inDomain:NSUserDomainMask
                                                             appropriateForURL:nil
                                                                        create:NO
                                                                         error:nil];
    // As of iOS SDK 12.2 unit tests now have a bundle id: com.apple.dt.xctest.tool
    NSString *bundleIdentifier = [NSBundle mgl_applicationBundleIdentifier];
    cacheDirectoryURL = [cacheDirectoryURL URLByAppendingPathComponent:bundleIdentifier];
    cacheDirectoryURL = [cacheDirectoryURL URLByAppendingPathComponent:@".mapbox"];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:cacheDirectoryURL.path], @"Cache subdirectory should exist.");

    NSURL *cacheURL = [cacheDirectoryURL URLByAppendingPathComponent:@"cache.db"];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:cacheURL.path], @"Cache database should exist.");

    NSError *error = nil;
    NSNumber *exclusionFlag = nil;
    [cacheDirectoryURL getResourceValue:&exclusionFlag
                                 forKey:NSURLIsExcludedFromBackupKey
                                  error:&error];
    XCTAssertTrue(exclusionFlag && [exclusionFlag boolValue], @"Backup exclusion flag should be set for the directory containing the cache database.");
    XCTAssertNil(error, @"No errors should be returned when checking backup exclusion flag.");
}

- (void)addPacks:(NSInteger)count {

    XCTestExpectation *expectation = [self expectationWithDescription:@"added packs"];

    NSURL *styleURL = [[MHStyle predefinedStyle:@"Bright"] url];

    MHCoordinateBounds bounds[] = {
        {{51.5, -0.2},   {51.6, -0.1}},     // London
        {{60.1, 24.8},   {60.3, 25.1}},     // Helsinki
        {{38.9, -77.1},  {38.9, -77.0}},    // DC
        {{37.7, -122.5}, {37.9, -122.4}}    // SF
    };

    int arraySize = sizeof(bounds)/sizeof(bounds[0]);

    count = MIN(count, arraySize);

    dispatch_group_t group = dispatch_group_create();

    for (int i = 0; i < count; i++) {

        dispatch_group_enter(group);
        MHTilePyramidOfflineRegion *region = [[MHTilePyramidOfflineRegion alloc] initWithStyleURL:styleURL bounds:bounds[i] fromZoomLevel:20 toZoomLevel:20];
        NSData *context = [NSKeyedArchiver archivedDataWithRootObject:@{
            @"index": @(i)
        }];

        [[MHOfflineStorage sharedOfflineStorage] addPackForRegion:region
                                                       withContext:context
                                                 completionHandler:^(MHOfflinePack * _Nullable pack, NSError * _Nullable error) {
            XCTAssertNotNil(pack);
            XCTAssertNil(error);

            dispatch_group_leave(group);
        }];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout:1.0];
}

- (void)testRemovePackTwiceInSuccession {

    [self addPacks:1];

    NSUInteger countOfPacks = [MHOfflineStorage sharedOfflineStorage].packs.count;

    MHOfflinePack *pack = [MHOfflineStorage sharedOfflineStorage].packs.lastObject;
    XCTAssertNotNil(pack, @"Added pack should still exist.");

    [self keyValueObservingExpectationForObject:[MHOfflineStorage sharedOfflineStorage] keyPath:@"packs" handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
        const auto changeKind = static_cast<NSKeyValueChange>([change[NSKeyValueChangeKindKey] unsignedLongValue]);
        NSIndexSet *indices = change[NSKeyValueChangeIndexesKey];
        return changeKind == NSKeyValueChangeRemoval && indices.count == 1;
    }];

    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"remove pack completion handler"];

    [[MHOfflineStorage sharedOfflineStorage] removePack:pack withCompletionHandler:nil];

    NSAssertionHandler *oldHandler = [NSAssertionHandler currentHandler];
    MHTestAssertionHandler *newHandler = [[MHTestAssertionHandler alloc] initWithTestCase:self];

    [[[NSThread currentThread] threadDictionary] setValue:newHandler forKey:NSAssertionHandlerKey];

    [[MHOfflineStorage sharedOfflineStorage] removePack:pack withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertEqual(pack.state, MHOfflinePackStateInvalid, @"Removed pack should be invalid in the completion handler.");
        [completionHandlerExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];

    [[[NSThread currentThread] threadDictionary] setValue:oldHandler forKey:NSAssertionHandlerKey];

    XCTAssertEqual(pack.state, MHOfflinePackStateInvalid, @"Removed pack should have been invalidated synchronously.");

    XCTAssertEqual([MHOfflineStorage sharedOfflineStorage].packs.count, countOfPacks - 1, @"Removed pack should have been removed from the canonical collection of packs owned by the shared offline storage object. This assertion can fail if this test is run before -testAAALoadPacks or -testAddPack.");

    NSLog(@"Test `%@` complete", NSStringFromSelector(_cmd));
}

- (void)test15536RemovePacksWhileReloading {

    // This test triggers
    //
    // throw std::runtime_error("Malformed offline region definition");
    //
    // in offline.cpp
    //
    // Reloading packs, while trying to remove them is currently problematic.

    [self addPacks:4];

    NSInteger countOfPacks = [MHOfflineStorage sharedOfflineStorage].packs.count;
    XCTAssert(countOfPacks > 0);

    // Now delete packs one by one
    XCTestExpectation *expectation = [self expectationWithDescription:@"All packs removed"];
    expectation.expectedFulfillmentCount = countOfPacks;

    MHOfflineStorage *storage = [MHOfflineStorage sharedOfflineStorage];
    NSArray *packs = [storage.packs copy];

    // Simulate what happens the first time sharedOfflineStorage is accessed
    [storage reloadPacks];

    NSArray *validPacks = [packs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        MHOfflinePack *pack = (MHOfflinePack*)evaluatedObject;
        return pack.state != MHOfflinePackStateInvalid;
    }]];

    NSAssertionHandler *oldHandler = [NSAssertionHandler currentHandler];
    MHTestAssertionHandler *newHandler = [[MHTestAssertionHandler alloc] initWithTestCase:self];

    [[[NSThread currentThread] threadDictionary] setValue:newHandler forKey:NSAssertionHandlerKey];

    for (MHOfflinePack *pack in validPacks) {
        [storage removePack:pack withCompletionHandler:^(NSError * _Nullable error) {
            [expectation fulfill];
        }];
    }

    [[[NSThread currentThread] threadDictionary] setValue:oldHandler forKey:NSAssertionHandlerKey];

    [self waitForExpectations:@[expectation] timeout:10.0];

    // TODO: What should we expect here? All packs removed?

    NSLog(@"Test `%@` complete", NSStringFromSelector(_cmd));
}

// Test to explore https://github.com/mapbox/mapbox-gl-native/issues/15536
- (void)test15536RemovePacksOnBackgroundQueueWhileReloading {

    [self addPacks:4];

    NSInteger countOfPacks = [MHOfflineStorage sharedOfflineStorage].packs.count;
    XCTAssert(countOfPacks > 0);

    // Now delete packs one by one
    dispatch_queue_t queue = dispatch_queue_create("com.mapbox.testRemovePacks", DISPATCH_QUEUE_SERIAL);

    XCTestExpectation *expectation = [self expectationWithDescription:@"all packs removed"];
    expectation.expectedFulfillmentCount = countOfPacks;

    MHOfflineStorage *storage = [MHOfflineStorage sharedOfflineStorage];

    // Simulate what happens the first time sharedOfflineStorage is accessed
    [storage reloadPacks];

//  NSArray *packs = [storage.packs copy];

    dispatch_async(queue, ^{
        NSArray *packs = storage.packs;
        NSAssertionHandler *oldHandler = [NSAssertionHandler currentHandler];
        MHTestAssertionHandler *newHandler = [[MHTestAssertionHandler alloc] initWithTestCase:self];

        [[[NSThread currentThread] threadDictionary] setValue:newHandler forKey:NSAssertionHandlerKey];

        NSArray *validPacks = [packs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            MHOfflinePack *pack = (MHOfflinePack*)evaluatedObject;
            return pack.state != MHOfflinePackStateInvalid;
        }]];

        for (MHOfflinePack *pack in validPacks) {
            // NOTE: pack can be invalid, as we have two threads potentially
            // modifying the same MHOfflinePack.

            dispatch_group_t group = dispatch_group_create();
            dispatch_group_enter(group);
            [storage removePack:pack withCompletionHandler:^(NSError * _Nullable error) {
                dispatch_group_leave(group);
            }];
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

            [expectation fulfill];
        }

        [[[NSThread currentThread] threadDictionary] setValue:oldHandler forKey:NSAssertionHandlerKey];
    });

    [self waitForExpectations:@[expectation] timeout:60.0];

    // TODO: What should we expect here? All packs removed?

    NSLog(@"Test `%@` complete", NSStringFromSelector(_cmd));
}

- (void)testCountOfBytesCompleted {
    XCTAssertGreaterThan([MHOfflineStorage sharedOfflineStorage].countOfBytesCompleted, 0UL);
}

- (void)testResourceTransform {
    MHOfflineStorage *os = [MHOfflineStorage sharedOfflineStorage];
    [os setDelegate:self];

    auto fs = os.mbglOnlineFileSource;

    // Delegate returns "https://api.mapbox.com" as a replacement URL.
    const mbgl::Resource resource { mbgl::Resource::Unknown, "test://api" };
    std::unique_ptr<mbgl::AsyncRequest> req;
    req = fs->request(resource, [&](mbgl::Response res) {
        req.reset();
        XCTAssertFalse(res.error.get(), @"Request should not return an error");
        XCTAssertTrue(res.data.get(), @"Request should return data");
        XCTAssertEqual("{\"api\":\"mapbox\"}", *res.data, @"Request did not return expected data");
        CFRunLoopStop(CFRunLoopGetCurrent());
    });

    CFRunLoopRun();

    [os setDelegate:nil];
}

- (void)testAddFileContent {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // Valid database
    [XCTContext runActivityNamed:@"Valid database" block:^(id<XCTActivity> activity) {
        NSURL *resourceURL = [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"sideload_sat" ofType:@"db"]];

        NSError *error;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:resourceURL.path error:&error];
        XCTAssertNil(error, @"Getting the file's attributes should not return an error. (%@)", resourceURL.path);

        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        long long fileSize = [fileSizeNumber longLongValue];
        long long databaseFileSize = 19218432;
        // Merging databases creates an empty file if the file does not exist at the given path.
        XCTAssertEqual(fileSize, databaseFileSize, @"The database file size must be:%lld actual size:%lld", databaseFileSize, fileSize);

        NSUInteger countOfPacks = [MHOfflineStorage sharedOfflineStorage].packs.count;

        [self keyValueObservingExpectationForObject:[MHOfflineStorage sharedOfflineStorage] keyPath:@"packs" handler:^BOOL(id _Nonnull observedObject, NSDictionary * _Nonnull change) {
            const auto changeKind = static_cast<NSKeyValueChange>([change[NSKeyValueChangeKindKey] unsignedLongValue]);
            NSIndexSet *indices = change[NSKeyValueChangeIndexesKey];
            return changeKind == NSKeyValueChangeInsertion && indices.count == 1;
        }];

        XCTestExpectation *fileAdditionCompletionHandlerExpectation = [self expectationWithDescription:@"add database content completion handler"];
        MHOfflineStorage *os = [MHOfflineStorage sharedOfflineStorage];
        [os addContentsOfURL:resourceURL withCompletionHandler:^(NSURL *fileURL, NSArray<MHOfflinePack *> * _Nullable packs, NSError * _Nullable error) {
            XCTAssertNotNil(fileURL, @"The fileURL should not be nil.");
            XCTAssertNotNil(packs, @"Adding the contents of the sideload_sat.db should update one pack.");
            XCTAssertNil(error, @"Adding contents to a file should not return an error.");
            for (MHOfflinePack *pack in [MHOfflineStorage sharedOfflineStorage].packs) {
                NSLog(@"PACK:%@", pack);
            }
            [fileAdditionCompletionHandlerExpectation fulfill];
        }];
        [self waitForExpectationsWithTimeout:10 handler:nil];
        // Depending on the database it may update or add a pack. For this case specifically the offline database adds one pack.
        XCTAssertEqual([MHOfflineStorage sharedOfflineStorage].packs.count, countOfPacks + 1, @"Adding contents of sideload_sat.db should add one pack.");
    }];

    // Invalid database type
    [XCTContext runActivityNamed:@"Invalid database type" block:^(id<XCTActivity> activity) {
        NSURL *resourceURL = [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"one-liner" ofType:@"json"]];

        XCTestExpectation *invalidFileCompletionHandlerExpectation = [self expectationWithDescription:@"invalid content database completion handler"];
        MHOfflineStorage *os = [MHOfflineStorage sharedOfflineStorage];
        [os addContentsOfFile:resourceURL.path withCompletionHandler:^(NSURL *fileURL, NSArray<MHOfflinePack *> * _Nullable packs, NSError * _Nullable error) {
            XCTAssertNotNil(error, @"Passing an invalid offline database file should return an error.");
            XCTAssertNil(packs, @"Passing an invalid offline database file should not add packs to the offline database.");
            [invalidFileCompletionHandlerExpectation fulfill];
        }];
        [self waitForExpectationsWithTimeout:10 handler:nil];
    }];

    // File does not exist
    [XCTContext runActivityNamed:@"File does not exist" block:^(id<XCTActivity> activity) {
        NSURL *resourceURL = [NSURL URLWithString:@"nonexistent.db"];

        MHOfflineStorage *os = [MHOfflineStorage sharedOfflineStorage];
        XCTAssertThrowsSpecificNamed([os addContentsOfURL:resourceURL withCompletionHandler:nil], NSException, NSInvalidArgumentException, "MHOfflineStorage should rise an exception if an invalid database file is passed.");
    }];

    // URL to a non-file
    [XCTContext runActivityNamed:@"URL to a non-file" block:^(id<XCTActivity> activity) {
        NSURL *resourceURL = [NSURL URLWithString:@"https://www.mapbox.com"];

        MHOfflineStorage *os = [MHOfflineStorage sharedOfflineStorage];
        XCTAssertThrowsSpecificNamed([os addContentsOfURL:resourceURL withCompletionHandler:nil], NSException, NSInvalidArgumentException, "MHOfflineStorage should rise an exception if an invalid URL file is passed.");
    }];
}

- (void)testPutResourceForURL {
    NSURL *styleURL = [NSURL URLWithString:@"https://api.mapbox.com/some/thing"];

    MHOfflineStorage *os = [MHOfflineStorage sharedOfflineStorage];
    std::string testData("test data");
    NSData *data = [NSData dataWithBytes:testData.c_str() length:testData.length()];
    __block std::unique_ptr<mbgl::AsyncRequest> req;
    [os preloadData:data forURL:styleURL modificationDate:nil expirationDate:nil eTag:nil mustRevalidate:NO completionHandler:^(NSURL * url, NSError * _Nullable error) {
        XCTAssertFalse(error, @"preloadData should not return an error");
        XCTAssertEqual(styleURL, url, @"Preloaded resource url is invalid");

        auto fs = os.mbglDatabaseFileSource;
        const mbgl::Resource resource { mbgl::Resource::Unknown, "https://api.mapbox.com/some/thing" };
        req = fs->request(resource, [&](mbgl::Response res) {
            XCTAssertFalse(res.error.get(), @"Request should not return an error");
            XCTAssertTrue(res.data.get(), @"Request should return data");
            XCTAssertFalse(res.modified, @"Request should not have a modification timestamp");
            XCTAssertFalse(res.expires, @"Request should not have an expiration timestamp");
            XCTAssertFalse(res.etag, @"Request should not have an entity tag");
            XCTAssertFalse(res.mustRevalidate, @"Request should not require revalidation");
            XCTAssertEqual("test data", *res.data, @"Request did not return expected data");
            CFRunLoopStop(CFRunLoopGetCurrent());
        });
    }];

    CFRunLoopRun();
}

- (void)testPutResourceForURLWithTimestamps {
    NSURL *styleURL = [NSURL URLWithString:@"https://api.mapbox.com/some/thing1"];

    MHOfflineStorage *os = [MHOfflineStorage sharedOfflineStorage];
    std::string testData("test data");
    NSData *data = [NSData dataWithBytes:testData.c_str() length:testData.length()];
    __block NSDate *now = [NSDate date];
    __block NSDate *future = [now dateByAddingTimeInterval:600];
    __block std::unique_ptr<mbgl::AsyncRequest> req;
    [os preloadData:data forURL:styleURL modificationDate:now expirationDate:future eTag:@"some etag" mustRevalidate:YES completionHandler:^(NSURL * url, NSError * _Nullable error){
        XCTAssertFalse(error, @"preloadData should not return an error");
        XCTAssertEqual(styleURL, url, @"Preloaded resource url is invalid");

        auto fs = os.mbglDatabaseFileSource;
        const mbgl::Resource resource { mbgl::Resource::Unknown, "https://api.mapbox.com/some/thing1" };
        req = fs->request(resource, [&, tNow = now.timeIntervalSince1970, tFuture = future.timeIntervalSince1970](mbgl::Response res) {
            XCTAssertFalse(res.error.get(), @"Request should not return an error");
            XCTAssertTrue(res.data.get(), @"Request should return data");
            XCTAssertTrue(res.modified, @"Request should have a modification timestamp");
            XCTAssertEqual(MHTimeIntervalFromDuration(res.modified->time_since_epoch()), floor(tNow), @"Modification timestamp should roundtrip");
            XCTAssertTrue(res.expires, @"Request should have an expiration timestamp");
            XCTAssertEqual(MHTimeIntervalFromDuration(res.expires->time_since_epoch()), floor(tFuture), @"Expiration timestamp should roundtrip");
            XCTAssertTrue(res.etag, @"Request should have an entity tag");
            XCTAssertEqual(*res.etag, "some etag", @"Entity tag should roundtrip");
            XCTAssertTrue(res.mustRevalidate, @"Request should require revalidation");
            XCTAssertEqual("test data", *res.data, @"Request did not return expected data");
            CFRunLoopStop(CFRunLoopGetCurrent());
        });
    }];

    CFRunLoopRun();
}

- (void)testSetMaximumAmbientCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect maximum cache size to be raised without an error."];
    [[MHOfflineStorage sharedOfflineStorage] setMaximumAmbientCacheSize:0 withCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [[MHOfflineStorage sharedOfflineStorage] setMaximumAmbientCacheSize:50*1024*1024 withCompletionHandler:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }];
    }];

    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testInvalidateAmbientCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect cache to be invalidated without an error."];
    [[MHOfflineStorage sharedOfflineStorage] invalidateAmbientCacheWithCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testClearCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect cache to be cleared without an error."];
    [[MHOfflineStorage sharedOfflineStorage] clearAmbientCacheWithCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testResetDatabase {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expect database to be reset without an error."];
    [[MHOfflineStorage sharedOfflineStorage] resetDatabaseWithCompletionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
