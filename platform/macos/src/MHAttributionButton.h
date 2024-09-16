#import <Cocoa/Cocoa.h>

#import "MHFoundation.h"
#import "MHTypes.h"

NS_ASSUME_NONNULL_BEGIN

@class MHAttributionInfo;

/// Button that looks like a hyperlink and opens a URL.
MH_EXPORT
@interface MHAttributionButton : NSButton

/// Returns an ``MHAttributionButton`` instance with the given info.
- (instancetype)initWithAttributionInfo:(MHAttributionInfo *)info;

/// The URL to open and display as a tooltip.
@property (nonatomic, readonly, nullable) NSURL *URL;

/// Opens the URL.
- (IBAction)openURL:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
