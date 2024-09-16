#include <mbgl/interface/native_apple_interface.h>
#import "MHNetworkConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class MHNetworkConfiguration;
@protocol MHNetworkConfigurationMetricsDelegate <NSObject>

- (void)networkConfiguration:(MHNetworkConfiguration *)networkConfiguration
      didGenerateMetricEvent:(NSDictionary *)metricEvent;

@end

extern NSString *const kMHDownloadPerformanceEvent;

@interface MHNetworkConfiguration (Private)

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *events;
@property (nonatomic, weak) id<MHNetworkConfigurationMetricsDelegate> metricsDelegate;

- (void)resetNativeNetworkManagerDelegate;
- (void)startDownloadEvent:(NSString *)urlString type:(NSString *)resourceType;
- (void)stopDownloadEventForResponse:(NSURLResponse *)response;
- (void)cancelDownloadEventForResponse:(NSURLResponse *)response;
@end

NS_ASSUME_NONNULL_END
