#import "MHLoggingConfiguration.h"

NS_INLINE NSString *MHStringFromBOOL(BOOL value) { return value ? @"YES" : @"NO"; }

#if TARGET_OS_OSX
NS_INLINE NSString *MHStringFromNSEdgeInsets(NSEdgeInsets insets) {
  return [NSString stringWithFormat:@"{ top: %f, left: %f, bottom: %f, right: %f", insets.top,
                                    insets.left, insets.bottom, insets.right];
}
#endif

#ifdef MH_LOGGING_DISABLED

#define MHLogInfo(...)
#define MHLogDebug(...)
#define MHLogWarning(...)
#define MHLogError(...)
#define MHLogFault(...)

#else

#if MH_LOGGING_ENABLE_DEBUG
#define MHLogDebug(message, ...) \
  MHLogWithType(MHLoggingLevelDebug, __PRETTY_FUNCTION__, __LINE__, message, ##__VA_ARGS__)
#else
#define MHLogDebug(...)
#endif

#define MHLogInfo(message, ...) \
  MHLogWithType(MHLoggingLevelInfo, __PRETTY_FUNCTION__, __LINE__, message, ##__VA_ARGS__)
#define MHLogWarning(message, ...) \
  MHLogWithType(MHLoggingLevelWarning, __PRETTY_FUNCTION__, __LINE__, message, ##__VA_ARGS__)
#define MHLogError(message, ...) \
  MHLogWithType(MHLoggingLevelError, __PRETTY_FUNCTION__, __LINE__, message, ##__VA_ARGS__)
#define MHLogFault(message, ...) \
  MHLogWithType(MHLoggingLevelFault, __PRETTY_FUNCTION__, __LINE__, message, ##__VA_ARGS__)

#endif

#define MHAssert(expression, message, ...)       \
  __extension__({                                 \
    if (__builtin_expect(!(expression), 0)) {     \
      MHLogFault(message, ##__VA_ARGS__);        \
    }                                             \
    NSAssert(expression, message, ##__VA_ARGS__); \
  })
#define MHCAssert(expression, message, ...)       \
  __extension__({                                  \
    if (__builtin_expect(!(expression), 0)) {      \
      MHLogFault(message, ##__VA_ARGS__);         \
    }                                              \
    NSCAssert(expression, message, ##__VA_ARGS__); \
  })

#ifndef MH_LOGGING_DISABLED

#define MHLogWithType(type, function, line, message, ...)                                         \
  {                                                                                                \
    if ([MHLoggingConfiguration sharedConfiguration].loggingLevel != MHLoggingLevelNone &&       \
        type <= [MHLoggingConfiguration sharedConfiguration].loggingLevel) {                      \
      [[MHLoggingConfiguration sharedConfiguration] logCallingFunction:function                   \
                                                           functionLine:line                       \
                                                            messageType:type                       \
                                                                 format:(message), ##__VA_ARGS__]; \
    }                                                                                              \
  }

@interface MHLoggingConfiguration (Private)

- (void)logCallingFunction:(const char *)callingFunction
              functionLine:(NSUInteger)functionLine
               messageType:(MHLoggingLevel)type
                    format:(id)messageFormat, ...;

@end
#endif
