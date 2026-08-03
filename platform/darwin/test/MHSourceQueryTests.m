#import <Mapbox.h>
#import <XCTest/XCTest.h>

@interface MHSourceQueryTests : XCTestCase <MHMapViewDelegate>

@end

@implementation MHSourceQueryTests

- (void) testQueryVectorTileSource {
    MHVectorTileSource *source = [[MHVectorTileSource alloc] initWithIdentifier:@"vector" tileURLTemplates:@[@"fake"] options:nil];
    NSSet *sourceLayers = [NSSet setWithObjects:@"buildings", @"water", nil];
    NSArray* features = [source featuresInSourceLayersWithIdentifiers:sourceLayers predicate:nil];
    // Source not added yet, so features is 0
    XCTAssertEqual([features count], 0);
}

- (void) testQueryShapeSource {
    MHShapeSource *source = [[MHShapeSource alloc] initWithIdentifier:@"shape" shape:[MHShapeCollection shapeCollectionWithShapes:@[]] options:nil];
    NSArray* features = [source featuresMatchingPredicate:nil];
    // Source not added yet, so features is 0
    XCTAssertEqual([features count], 0);
}

@end
