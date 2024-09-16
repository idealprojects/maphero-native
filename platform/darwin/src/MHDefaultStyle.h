#import <Foundation/Foundation.h>

#import "MHFoundation.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The ``MHDefaultStyle`` defines the predefined vendor style
 */
MH_EXPORT
@interface MHDefaultStyle : NSObject

/**
The style URL
 */
@property (nonatomic, retain) NSURL* url;

/**
The style name
 */
@property (nonatomic, retain) NSString* name;

/**
The style version
 */
@property (nonatomic) int version;

@end

NS_ASSUME_NONNULL_END
