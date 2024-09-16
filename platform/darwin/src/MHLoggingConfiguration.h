#import <Foundation/Foundation.h>

#import "MHFoundation.h"

#ifndef MH_LOGGING_DISABLED
#ifndef MH_LOGGING_ENABLE_DEBUG
#ifndef NDEBUG
#define MH_LOGGING_ENABLE_DEBUG 1
#endif
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 Constants indicating the message's logging level.
 */
typedef NS_ENUM(NSInteger, MHLoggingLevel) {
  /**
   None-level won't print any messages.
   */
  MHLoggingLevelNone = 0,
  /**
   Fault-level messages contain system-level error information.
   */
  MHLoggingLevelFault,
  /**
   Error-level messages contain information that is intended to aid in process-level
   errors.
  */
  MHLoggingLevelError,
  /**
   Warning-level messages contain warning information for potential risks.
   */
  MHLoggingLevelWarning,
  /**
   Info-level messages contain information that may be helpful for flow tracing
   but is not essential.
   */
  MHLoggingLevelInfo,
/**
 Debug-level messages contain information that may be helpful for troubleshooting
 specific problems.
 */
#if MH_LOGGING_ENABLE_DEBUG
  MHLoggingLevelDebug,
#endif
  /**
   Verbose-level will print all messages.
   */
  MHLoggingLevelVerbose,
};

/**
 A block to be called once `loggingLevel` is set to a higher value than
 ``MHLoggingLevel/MHLoggingLevelNone``.

 @param loggingLevel The message logging level.
 @param filePath The description of the file and method for the calling message.
 @param line The line where the message is logged.
 @param message The logging message.
 */
typedef void (^MHLoggingBlockHandler)(MHLoggingLevel loggingLevel, NSString *filePath,
                                       NSUInteger line, NSString *message);

/**
 The ``MHLoggingConfiguration`` object provides a global way to set this SDK logging levels
 and logging handler.
 */
MH_EXPORT
@interface MHLoggingConfiguration : NSObject

/**
 The handler this SDK uses to log messages.

 If this property is set to nil or if no custom handler is provided this property
 is set to the default handler.

 The default handler uses `os_log` and `NSLog` for iOS 10+ and iOS < 10 respectively.
 */
@property (nonatomic, copy, null_resettable) MHLoggingBlockHandler handler;

/**
 The logging level.

 The default value is ``MHLoggingLevel/MHLoggingLevelNone``.

 Setting this property includes logging levels less than or equal to the setted value.
 */
@property (assign, nonatomic) MHLoggingLevel loggingLevel;

/**
 Returns the shared logging object.
 */
@property (class, nonatomic, readonly) MHLoggingConfiguration *sharedConfiguration;

- (MHLoggingBlockHandler)handler UNAVAILABLE_ATTRIBUTE;

@end

NS_ASSUME_NONNULL_END
#endif
