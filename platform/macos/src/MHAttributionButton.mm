#import "MHAttributionButton.h"
#import "MHAttributionInfo.h"

#import "NSBundle+MHAdditions.h"
#import "NSString+MHAdditions.h"

@implementation MHAttributionButton

- (instancetype)initWithAttributionInfo:(MHAttributionInfo *)info {
    if (self = [super initWithFrame:NSZeroRect]) {
        self.bordered = NO;
        self.bezelStyle = NSBezelStyleBadge;

        // Extract any prefix consisting of intellectual property symbols.
        NSScanner *scanner = [NSScanner scannerWithString:info.title.string];
        NSCharacterSet *symbolSet = [NSCharacterSet characterSetWithCharactersInString:@"©℗®℠™ &"];
        NSString *symbol;
        [scanner scanCharactersFromSet:symbolSet intoString:&symbol];

        // Remove the underline from the symbol for aesthetic reasons.
        NSMutableAttributedString *title = info.title.mutableCopy;
        [title removeAttribute:NSUnderlineStyleAttributeName range:NSMakeRange(0, symbol.length)];

        self.attributedTitle = title;
        [self sizeToFit];

        _URL = info.URL;
        if (_URL) {
            self.toolTip = _URL.absoluteString;
        }

        self.target = self;
        self.action = @selector(openURL:);
    }
    return self;
}

- (BOOL)wantsLayer {
    return YES;
}

- (void)resetCursorRects {
    if (self.URL) {
        // The whole button gets a pointing hand cursor, just like a hyperlink.
        [self addCursorRect:self.bounds cursor:[NSCursor pointingHandCursor]];
    }
}

- (IBAction)openURL:(__unused id)sender {
    if (self.URL) {
        [[NSWorkspace sharedWorkspace] openURL:self.URL];
    }
}

@end
