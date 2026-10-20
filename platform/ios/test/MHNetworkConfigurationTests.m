#import <Mapbox.h>
#import <XCTest/XCTest.h>
#import "MHNetworkConfiguration_Private.h"

@interface MHNetworkConfigurationTests : XCTestCase
@end

@implementation MHNetworkConfigurationTests

// Regression test for https://github.com/mapbox/mapbox-gl-native/issues/14982
- (void)testAccessingEventsFromMultipleThreads {
    MHNetworkConfiguration *configuration = [[MHNetworkConfiguration alloc] init];

    // Concurrent
    dispatch_queue_t queue = dispatch_queue_create("org.maplibre.testAccessingEventsFromMultipleThreads", DISPATCH_QUEUE_CONCURRENT);

    NSUInteger numberOfConcurrentBlocks = 20;

    XCTestExpectation *expectation = [self expectationWithDescription:@"wait-for-threads"];
    expectation.expectedFulfillmentCount = numberOfConcurrentBlocks;

    for (NSUInteger i = 0; i < numberOfConcurrentBlocks; i++) {

        NSString *event = [NSString stringWithFormat:@"test://event-%ld", i];
        NSString *resourceType = @"test";

        dispatch_async(queue, ^{
            [configuration startDownloadEvent:event type:resourceType];

            NSURL *url = [NSURL URLWithString:event];
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:url MIMEType:nil expectedContentLength:0 textEncodingName:nil];

            [configuration stopDownloadEventForResponse:response];

            dispatch_async(dispatch_get_main_queue(), ^{
                [expectation fulfill];
            });
        });
    }

    [self waitForExpectations:@[expectation] timeout:10.0];
}

// Setting the API key is the whole documented setup, so it alone must put the key on requests.
- (void)testSettingApiKeySendsItAsXApiKey {
    NSString *key = @"mh_pk_settings_test_key";
    MHSettings.apiKey = key;

    NSDictionary *headers = MHNetworkConfiguration.sharedManager.sessionConfiguration.HTTPAdditionalHeaders;
    XCTAssertEqualObjects(headers[@"X-API-Key"], key);
    XCTAssertEqualObjects(headers[@"map-token"], key, @"a publishable key also travels as the legacy header");
    XCTAssertEqualObjects(headers[@"X-MapHero-Client"], @"ios");
}

// An app with one key per map changes the key at runtime; the new one must be what is sent.
- (void)testChangingApiKeyReplacesTheHeader {
    MHSettings.apiKey = @"mh_pk_first_key";
    MHSettings.apiKey = @"mh_pk_second_key";

    NSDictionary *headers = MHNetworkConfiguration.sharedManager.sessionConfiguration.HTTPAdditionalHeaders;
    XCTAssertEqualObjects(headers[@"X-API-Key"], @"mh_pk_second_key");
    XCTAssertEqualObjects(headers[@"map-token"], @"mh_pk_second_key");
}

// A secret key never goes into the legacy header, and switching to one removes the old value there.
- (void)testSecretKeyIsNotCopiedIntoTheLegacyHeader {
    MHSettings.apiKey = @"mh_pk_publishable_key";
    MHSettings.apiKey = @"mh_sk_secret_key";

    NSDictionary *headers = MHNetworkConfiguration.sharedManager.sessionConfiguration.HTTPAdditionalHeaders;
    XCTAssertEqualObjects(headers[@"X-API-Key"], @"mh_sk_secret_key");
    XCTAssertNil(headers[@"map-token"]);
}

// A header the application set on the session itself still wins.
- (void)testApplicationSuppliedHeaderIsKept {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPAdditionalHeaders = @{ @"X-API-Key": @"set-by-the-app" };
    MHNetworkConfiguration.sharedManager.sessionConfiguration = config;
    MHSettings.apiKey = @"mh_pk_settings_key";

    NSDictionary *headers = MHNetworkConfiguration.sharedManager.sessionConfiguration.HTTPAdditionalHeaders;
    XCTAssertEqualObjects(headers[@"X-API-Key"], @"set-by-the-app");
    MHNetworkConfiguration.sharedManager.sessionConfiguration = nil;
}
@end
