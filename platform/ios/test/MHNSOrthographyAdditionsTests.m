#import <XCTest/XCTest.h>

#import "NSOrthography+MHAdditions.h"
#import "MHVectorTileSource_Private.h"

@interface MHNSOrthographyAdditionsTests : XCTestCase

@end

@implementation MHNSOrthographyAdditionsTests

- (void)testStreetsLanguages {
    for (NSString *language in [MHVectorTileSource mapboxStreetsLanguages]) {
        NSString *dominantScript = [NSOrthography mgl_dominantScriptForMapboxStreetsLanguage:language];
        XCTAssertNotEqualObjects(dominantScript, @"Zyyy", @"Mapbox Streets languages should have dominant script");
    }
}

@end
