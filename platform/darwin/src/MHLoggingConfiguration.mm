#include <mbgl/util/logging.hpp>
#include <mbgl/util/enum.hpp>

#import "MHLoggingConfiguration_Private.h"

#ifndef MH_LOGGING_DISABLED
#if __has_builtin(__builtin_os_log_format)
#import <os/log.h>
#endif

namespace mbgl {
    
class MHCoreLoggingObserver : public Log :: Observer {
public:
    //Return true not print messages at core level, and filter at platform level.
    bool onRecord(EventSeverity severity, Event event, int64_t code, const std::string& msg) override{
        
        NSString *message = [NSString stringWithFormat:@"[event]:%s [code]:%lld [message]:%@", Enum<Event>::toString(event), code, [NSString stringWithCString:msg.c_str() encoding:NSUTF8StringEncoding]];
        switch (severity) {
            case EventSeverity::Debug:
                MHLogDebug(message);
                break;
            case EventSeverity::Info:
                MHLogInfo(message);
                break;
            case EventSeverity::Warning:
                MHLogWarning(message);
                break;
            case EventSeverity::Error:
                MHLogError(message);
                break;
            default:
                assert(false);
        }
        return true;
    }
};
}

@implementation MHLoggingConfiguration
{
    std::unique_ptr<mbgl::MHCoreLoggingObserver> _coreLoggingObserver;
}

+ (instancetype)sharedConfiguration {
    static dispatch_once_t once;
    static id sharedConfiguration;
    dispatch_once(&once, ^{
        sharedConfiguration = [[self alloc] init];
        ((MHLoggingConfiguration *)sharedConfiguration).handler = nil;
    });
    return sharedConfiguration;
}

- (id)init{
    if(self = [super init]){
        mbgl::Log::setObserver(std::make_unique<mbgl::MHCoreLoggingObserver>());
    }
    return self;
}

- (void)setHandler:(void (^)(MHLoggingLevel, NSString *, NSUInteger, NSString *))handler {
    
    if (!handler) {
        _handler = [self defaultBlockHandler];
    } else {
        _handler = handler;
    }
}

- (void)logCallingFunction:(const char *)callingFunction functionLine:(NSUInteger)functionLine messageType:(MHLoggingLevel)type format:(id)messageFormat, ... {
    va_list formatList;
    va_start(formatList, messageFormat);
    NSString *formattedMessage = [[NSString alloc] initWithFormat:messageFormat arguments:formatList];
    va_end(formatList);
    
    _handler(type, @(callingFunction), functionLine, formattedMessage);
    
}

- (MHLoggingBlockHandler)defaultBlockHandler {
    MHLoggingBlockHandler maplibreHandler = ^(MHLoggingLevel level, NSString *fileName, NSUInteger line, NSString *message) {
        
        if (@available(iOS 10.0, macOS 10.12.0, *)) {
            static dispatch_once_t once;
            static os_log_t info_log;
#if MH_LOGGING_ENABLE_DEBUG
            static os_log_t debug_log;
#endif
            static os_log_t error_log;
            static os_log_t fault_log;
            static os_log_type_t log_types[] = { OS_LOG_TYPE_DEFAULT,
                                                    OS_LOG_TYPE_INFO,
#if MH_LOGGING_ENABLE_DEBUG
                                                    OS_LOG_TYPE_DEBUG,
#endif
                                                    OS_LOG_TYPE_ERROR,
                                                    OS_LOG_TYPE_FAULT };
            constexpr const char* const subsystem = "org.maplibre.Native";
            dispatch_once(&once, ^ {
                info_log = os_log_create(subsystem, "INFO");
#if MH_LOGGING_ENABLE_DEBUG
                debug_log = os_log_create(subsystem, "DEBUG");
#endif
                error_log = os_log_create(subsystem, "ERROR");
                fault_log = os_log_create(subsystem, "FAULT");
            });
            
            os_log_t maplibre_log;
            switch (level) {
                case MHLoggingLevelInfo:
                case MHLoggingLevelWarning:
                    maplibre_log = info_log;
                    break;
#if MH_LOGGING_ENABLE_DEBUG
                case MHLoggingLevelDebug:
                    maplibre_log = debug_log;
                    break;
#endif
                case MHLoggingLevelError:
                    maplibre_log = error_log;
                    break;
                case MHLoggingLevelFault:
                    maplibre_log = fault_log;
                    break;
                case MHLoggingLevelNone:
                default:
                    break;
            }

            os_log_type_t logType = log_types[level];
            os_log_with_type(maplibre_log, logType, "%@ - %lu: %@", fileName, (unsigned long)line, message);
        } else {
            NSString *category;
            switch (level) {
                case MHLoggingLevelInfo:
                case MHLoggingLevelWarning:
                    category = @"INFO";
                    break;
#if MH_LOGGING_ENABLE_DEBUG
                case MHLoggingLevelDebug:
                    category = @"DEBUG";
                    break;
#endif
                case MHLoggingLevelError:
                    category = @"ERROR";
                    break;
                case MHLoggingLevelFault:
                    category = @"FAULT";
                    break;
                case MHLoggingLevelNone:
                default:
                    break;
            }
            
            NSLog(@"[%@] %@ - %lu: %@", category, fileName, (unsigned long)line, message);
        }
    };
    
    return maplibreHandler;
}

@end
#endif