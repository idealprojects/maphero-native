#import <XCTest/XCTest.h>
#import <Mapbox.h>

#if TARGET_OS_IPHONE
    #import "UIImage+MHAdditions.h"
    #define MHImageResizingModeTile UIImageResizingModeTile
    #define MHImageResizingModeStretch UIImageResizingModeStretch
#else
    #import "NSImage+MHAdditions.h"
    #define MHImageResizingModeTile NSImageResizingModeTile
    #define MHImageResizingModeStretch NSImageResizingModeStretch
#endif

@interface MHImageTests : XCTestCase

@end

@implementation MHImageTests

- (void)testStretching {
#if TARGET_OS_IPHONE
    CGRect rect = CGRectMake(0, 0, 24, 24);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, UIScreen.mainScreen.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, UIColor.blackColor.CGColor);
    CGContextStrokeRectWithWidth(context, rect, 2);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
#else
    NSImage *image = [NSImage imageWithSize:NSMakeSize(24, 24) flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        // A little more fanciful than the iOS version, but we aren’t testing the actual contents of the image anyways.
        NSRectEdge allSides[] = {NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge, NSMaxXEdge};
        CGFloat grays[] = {NSBlack, NSBlack, NSWhite, NSWhite, NSDarkGray, NSDarkGray};
        dstRect = NSDrawTiledRects(dstRect, dstRect, allSides, grays, sizeof(grays) / sizeof(grays[0]));
        [NSColor.grayColor set];
        NSRectFill(dstRect);
        return YES;
    }];
    image.resizingMode = NSImageResizingModeTile;
#endif
    
    {
        auto styleImage = [image mgl_styleImageWithIdentifier:@"box"];
        XCTAssert(styleImage);
        if (styleImage) {
            XCTAssert(!styleImage->getContent());
            XCTAssertFalse(styleImage->isSdf());
            XCTAssertTrue(styleImage->getStretchX().empty());
            XCTAssertTrue(styleImage->getStretchY().empty());
            
            MHImage *imageAfter = [[MHImage alloc] initWithMHStyleImage:*styleImage];
            XCTAssertEqual(imageAfter.resizingMode, MHImageResizingModeTile);
            XCTAssertEqual(imageAfter.capInsets.top, 0);
            XCTAssertEqual(imageAfter.capInsets.left, 0);
            XCTAssertEqual(imageAfter.capInsets.bottom, 0);
            XCTAssertEqual(imageAfter.capInsets.right, 0);
        }
    }
    
#if TARGET_OS_IPHONE
    image = [image resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch];
#else
    image.resizingMode = NSImageResizingModeStretch;
    image.capInsets = NSEdgeInsetsZero;
#endif
    {
        auto styleImage = [image mgl_styleImageWithIdentifier:@"box"];
        XCTAssert(styleImage);
        if (styleImage) {
            auto scale = styleImage->getPixelRatio();
            XCTAssert(!styleImage->getContent());
            
            auto stretchX = styleImage->getStretchX();
            XCTAssertEqual(stretchX.size(), 1UL);
            if (!stretchX.empty()) {
                XCTAssertEqual(stretchX.front(), mbgl::style::ImageStretch(0, 24 * scale));
            }
            auto stretchY = styleImage->getStretchY();
            XCTAssertEqual(stretchY.size(), 1UL);
            if (!stretchY.empty()) {
                XCTAssertEqual(stretchY.front(), mbgl::style::ImageStretch(0, 24 * scale));
            }
            
            MHImage *imageAfter = [[MHImage alloc] initWithMHStyleImage:*styleImage];
            XCTAssertEqual(imageAfter.resizingMode, MHImageResizingModeStretch);
            XCTAssertEqual(imageAfter.capInsets.top, 0);
            XCTAssertEqual(imageAfter.capInsets.left, 0);
            XCTAssertEqual(imageAfter.capInsets.bottom, 0);
            XCTAssertEqual(imageAfter.capInsets.right, 0);
        }
    }
    
#if TARGET_OS_IPHONE
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(1, 2, 3, 4)];
#else
    image.capInsets = NSEdgeInsetsMake(1, 2, 3, 4);
#endif
    {
        auto styleImage = [image mgl_styleImageWithIdentifier:@"box"];
        XCTAssert(styleImage);
        if (styleImage) {
            auto scale = styleImage->getPixelRatio();
            auto content = styleImage->getContent();
            XCTAssert(content);
            if (content) {
                XCTAssertEqual(content->top, 1 * scale);
                XCTAssertEqual(content->left, 2 * scale);
                XCTAssertEqual(content->bottom, 21 * scale);
                XCTAssertEqual(content->right, 20 * scale);
            }
            
            auto stretchX = styleImage->getStretchX();
            XCTAssertEqual(stretchX.size(), 1UL);
            if (!stretchX.empty()) {
                XCTAssertEqual(stretchX.front(), mbgl::style::ImageStretch(2 * scale, 20 * scale));
            }
            auto stretchY = styleImage->getStretchY();
            XCTAssertEqual(stretchY.size(), 1UL);
            if (!stretchY.empty()) {
                XCTAssertEqual(stretchY.front(), mbgl::style::ImageStretch(1 * scale, 21 * scale));
            }
            
            MHImage *imageAfter = [[MHImage alloc] initWithMHStyleImage:*styleImage];
            XCTAssertEqual(imageAfter.resizingMode, MHImageResizingModeStretch);
            XCTAssertEqual(imageAfter.capInsets.top, 1);
            XCTAssertEqual(imageAfter.capInsets.left, 2);
            XCTAssertEqual(imageAfter.capInsets.bottom, 3);
            XCTAssertEqual(imageAfter.capInsets.right, 4);
        }
    }
}

@end
