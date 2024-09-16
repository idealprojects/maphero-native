#import <Mapbox/Mapbox.h>
#import <XCTest/XCTest.h>

#import "MHAttributionButton.h"
#import "MHAttributionInfo.h"

@interface MHAttributionButtonTests : XCTestCase

@end

@implementation MHAttributionButtonTests

- (void)testPlainSymbol {
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"® & ™ Mapbox" attributes:@{
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
    }];
    MHAttributionInfo *info = [[MHAttributionInfo alloc] initWithTitle:title URL:nil];
    MHAttributionButton *button = [[MHAttributionButton alloc] initWithAttributionInfo:info];

    NSRange symbolUnderlineRange;
    NSNumber *symbolUnderline = [button.attributedTitle attribute:NSUnderlineStyleAttributeName atIndex:0 effectiveRange:&symbolUnderlineRange];
    XCTAssertNil(symbolUnderline);
    XCTAssertEqual(symbolUnderlineRange.length, 6);

    NSRange wordUnderlineRange;
    NSNumber *wordUnderline = [button.attributedTitle attribute:NSUnderlineStyleAttributeName atIndex:6 effectiveRange:&wordUnderlineRange];
    XCTAssertEqualObjects(wordUnderline, @(NSUnderlineStyleSingle));
    XCTAssertEqual(wordUnderlineRange.length, 6);
}

@end
