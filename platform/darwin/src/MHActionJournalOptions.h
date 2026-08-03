#import <Foundation/Foundation.h>

#import "MHFoundation.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The ``MHActionJournalOptions`` defines action journal properties such as path, log size, etc...
 */
MH_EXPORT
@interface MHActionJournalOptions : NSObject

/**
 * Enable/disable journal logging
 */
@property (nonatomic) BOOL enabled;

/**
 * Local file path.
 */
@property (nonatomic, nonnull) NSString* path;

/**
 * Log file size (total journal size is equal to `logFileSize * logFileCount`)
 */
@property (nonatomic) NSInteger logFileSize;

/**
 * Maximum number of log files
 */
@property (nonatomic) NSInteger logFileCount;

/**
 * The wait time (seconds) between rendering reports
 */
@property (nonatomic) NSInteger renderingStatsReportInterval;

@end

NS_ASSUME_NONNULL_END
