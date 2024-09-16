#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MHNativeNetworkManager;

@protocol MHNativeNetworkDelegate <NSObject>

@optional

- (NSURLSession *)sessionForNetworkManager:(MHNativeNetworkManager *)networkManager;

@required

- (NSURLSessionConfiguration *)sessionConfiguration;

- (void)startDownloadEvent:(NSString *)event type:(NSString *)type;

- (void)cancelDownloadEventForResponse:(NSURLResponse *)response;

- (void)stopDownloadEventForResponse:(NSURLResponse *)response;

- (void)debugLog:(NSString *)message;

- (void)errorLog:(NSString *)message;

@end

#define MH_APPLE_EXPORT __attribute__((visibility("default")))

@interface MHNativeNetworkManager : NSObject

+ (MHNativeNetworkManager *)sharedManager;

@property (nonatomic, weak) id<MHNativeNetworkDelegate> delegate;

@property (nonatomic, readonly) NSURLSessionConfiguration *sessionConfiguration;

- (void)startDownloadEvent:(NSString *)event type:(NSString *)type;

- (void)cancelDownloadEventForResponse:(NSURLResponse *)response;

- (void)stopDownloadEventForResponse:(NSURLResponse *)response;

- (void)debugLog:(NSString *)format, ...;

- (void)errorLog:(NSString *)format, ...;

@end

NS_ASSUME_NONNULL_END
