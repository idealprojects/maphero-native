#import <Foundation/Foundation.h>

#import "MHFoundation.h"

NS_ASSUME_NONNULL_BEGIN

@class MHNetworkConfiguration;

@protocol MHNetworkConfigurationDelegate <NSObject>
@optional

/**
 :nodoc:
 Provides an `NSURLSession` object for the specified ``MHNetworkConfiguration``.
 This API should be considered experimental, likely to be removed or changed in
 future releases.

 This method is called from background threads, i.e. it is not called on the main
 thread.

 > Note: Background sessions (i.e. created with
 `-[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:]`)
 and sessions created with a delegate that conforms to `NSURLSessionDataDelegate`
 are not supported at this time.
 */
- (NSURLSession *)sessionForNetworkConfiguration:(MHNetworkConfiguration *)configuration;
@end

/**
 The ``MHNetworkConfiguration`` object provides a global way to set a base
 `NSURLSessionConfiguration`, and other resources.
 */
MH_EXPORT
@interface MHNetworkConfiguration : NSObject

/**
 :nodoc:
 Delegate for the ``MHNetworkConfiguration`` class.
 */
@property (nonatomic, weak) id<MHNetworkConfigurationDelegate> delegate;

/**
 Set Authentication token.
 */
@property (nonatomic, strong, nullable, readonly) NSString *token;

/**
 Returns the shared instance of the ``MHNetworkConfiguration`` class.
 */
@property (class, nonatomic, readonly) MHNetworkConfiguration *sharedManager;

/**
 The session configuration object that is used by the `NSURLSession` objects
 in this SDK.

 If this property is set to nil or if no session configuration is provided this property
 is set to the default session configuration.

 Assign this object before instantiating any ``MHMapView`` object, or using
 ``MHOfflineStorage``

 > Note: `NSURLSession` objects store a copy of this configuration. Any further changes
 to mutable properties on this configuration object passed to a session’s initializer
 will not affect the behavior of that session.

 > Note: Background sessions are not currently supported.
 */
@property (atomic, strong, null_resettable) NSURLSessionConfiguration *sessionConfiguration;

- (void)setToken:(nullable NSString *)token;

@end

NS_ASSUME_NONNULL_END
