#import "MHNetworkConfiguration_Private.h"
#import "MHLoggingConfiguration_Private.h"
#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
#import "MHSettings_Private.h"
#endif

#import "MHReachability.h"

static NSString * const MHStartTime = @"start_time";
static NSString * const MHResourceType = @"resource_type";
NSString * const kMHDownloadPerformanceEvent = @"mobile.performance_trace";

@interface MHNetworkConfiguration () <MHNativeNetworkDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary*> *events;
@property (nonatomic, weak) id<MHNetworkConfigurationMetricsDelegate> metricsDelegate;
@property (nonatomic) dispatch_queue_t eventsQueue;
@property (nonatomic, strong, readwrite, nullable) NSString *token;

@end

@implementation MHNetworkConfiguration
{
    NSURLSessionConfiguration *_sessionConfig;
}

- (instancetype)init {
    if (self = [super init]) {
        self.sessionConfiguration = nil;
        _events = [NSMutableDictionary dictionary];
        _eventsQueue = dispatch_queue_create("org.maplibre.network-configuration", DISPATCH_QUEUE_CONCURRENT);
        _token = nil;
    }

    return self;
}

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static MHNetworkConfiguration *_sharedManager;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });

    // Notice, this is reset for each call. This is primarily for testing purposes.
    // TODO: Consider only calling this for testing?
    [_sharedManager resetNativeNetworkManagerDelegate];

    return _sharedManager;
}

- (void)resetNativeNetworkManagerDelegate {
    // Tell core about our network integration. `delegate` here is not (yet)
    // intended to be set to nil, except for testing.
    [MHNativeNetworkManager sharedManager].delegate = self;
}

+ (NSURLSessionConfiguration *)defaultSessionConfiguration {
    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    sessionConfiguration.timeoutIntervalForResource = 30;
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 8;
    sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    sessionConfiguration.URLCache = nil;

    return sessionConfiguration;
}

// MARK: - MHNativeNetworkDelegate

- (NSURLSession *)sessionForNetworkManager:(MHNativeNetworkManager *)networkManager {
    // Note: this method is NOT called on the main thread.
    NSURLSession *session;
    if ([self.delegate respondsToSelector:@selector(sessionForNetworkConfiguration:)]) {
        session = [self.delegate sessionForNetworkConfiguration:self];
    }

    // Check for a background session; string checking is fragile, but this is not
    // a deal breaker as we're only doing this to provide more clarity to the
    // developer
    NSAssert(![session isKindOfClass:NSClassFromString(@"__NSURLBackgroundSession")],
             @"Background NSURLSessions are not yet supported");

    if (session.delegate) {
        NSAssert(![session.delegate conformsToProtocol:@protocol(NSURLSessionDataDelegate)],
                 @"Session delegates conforming to NSURLSessionDataDelegate are not yet supported");
    }

    return session;
}

- (NSURLSessionConfiguration *)sessionConfiguration {
    NSURLSessionConfiguration *sessionConfig = nil;
    @synchronized (self) {
        sessionConfig = _sessionConfig;
    }
    return sessionConfig;
}

- (void)setSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration {
    @synchronized (self) {
        if (sessionConfiguration == nil) {
            _sessionConfig = [MHNetworkConfiguration defaultSessionConfiguration];
        } else {
            _sessionConfig = sessionConfiguration;
        }
        [self updateSessionHeaders];
    }
}

- (void)setToken:(NSString *)token {
    _token = token;
    [self updateSessionHeaders];
}

/**
 Every header this SDK adds to a MapHero request.

 The credential travels in `X-API-Key` and in the legacy `map-token` BOTH. The server picks its
 authentication path from the credential's own prefix (`mh_pk_` / `mh_sk_` or neither) rather than
 from the header it arrived in, so one value works in either — but `map-token` cannot simply be
 dropped, because nginx in front of the tile and asset host reads it *by name*
 (`proxy_set_header X-Map-Token $http_map_token`). Without it a tile request arrives with no token
 and is refused for anything not served from a maphero.io page. A request carrying both is resolved
 by a documented precedence, not rejected.

 `X-MapHero-Ios-Bundle` is what an API key restricted to named iOS applications is checked against;
 no iOS SDK sent it before, so that restriction could only ever refuse this SDK.
 `X-MapHero-Client` says which SDK is calling, for attribution and support.

 Both of those are **claims, not proof** — an application chooses every header it sends, so they
 raise the cost of casual key theft and establish nothing against a determined attacker. Real proof
 needs App Attest. They are worth sending and are not worth trusting, and nothing should be granted
 on the strength of them.

 A secret `mh_sk_` key is not duplicated into the legacy header: it is never a legacy map token, and
 an account's full API access does not belong in a second place a log might pick it up.

 Each header is set only when absent, keeping the existing contract that a value an application put
 on the session configuration itself wins. The assignment back to `HTTPAdditionalHeaders` now
 happens unconditionally: it used to sit inside the `map-token` check, so once that header existed
 nothing else could ever be added to the session.
 */
- (void)updateSessionHeaders {
    if (_token) {
        // Ensure session config exists
        if (!_sessionConfig) {
            _sessionConfig = [MHNetworkConfiguration defaultSessionConfiguration];
        }

        // Get existing headers (if any)
        NSMutableDictionary *headers =
            [(_sessionConfig.HTTPAdditionalHeaders ?: @{}) mutableCopy];

        if (!headers[@"X-API-Key"]) {
            headers[@"X-API-Key"] = _token;
        }
        if (![_token hasPrefix:@"mh_sk_"] && !headers[@"map-token"]) {
            headers[@"map-token"] = _token;
        }
        if (!headers[@"X-MapHero-Client"]) {
            headers[@"X-MapHero-Client"] = @"ios";
        }
        // Fixed for an installed application. Left out rather than sent empty when there is none:
        // an empty claim is one the server has to consider and refuse, where its absence lets the
        // key's other restrictions decide.
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        if (bundleIdentifier.length > 0 && !headers[@"X-MapHero-Ios-Bundle"]) {
            headers[@"X-MapHero-Ios-Bundle"] = bundleIdentifier;
        }

        _sessionConfig.HTTPAdditionalHeaders = headers;
    }
}

- (void)startDownloadEvent:(NSString *)urlString type:(NSString *)resourceType {
    if (urlString && resourceType && ![self eventDictionaryForKey:urlString]) {
        NSDate *startDate = [NSDate date];
        [self setEventDictionary:@{ MHStartTime: startDate, MHResourceType: resourceType }
                          forKey:urlString];
    }
}

- (void)stopDownloadEventForResponse:(NSURLResponse *)response {
    [self sendEventForURLResponse:response withAction:nil];
}

- (void)cancelDownloadEventForResponse:(NSURLResponse *)response {
    [self sendEventForURLResponse:response withAction:@"cancel"];
}

- (void)debugLog:(NSString *)message {
    MHLogDebug(message);
}

- (void)errorLog:(NSString *)message {
    MHLogError(message);
}

// MARK: - Event management

- (void)sendEventForURLResponse:(NSURLResponse *)response withAction:(NSString *)action
{
    if ([response isKindOfClass:[NSURLResponse class]]) {
        NSString *urlString = response.URL.relativePath;
        if (urlString && [self eventDictionaryForKey:urlString]) {
            NSDictionary *eventAttributes = [self eventAttributesForURL:response withAction:action];
            [self removeEventDictionaryForKey:urlString];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.metricsDelegate networkConfiguration:self didGenerateMetricEvent:eventAttributes];
            });
        }
    }
}

- (NSDictionary *)eventAttributesForURL:(NSURLResponse *)response withAction:(NSString *)action
{
    NSString *urlString = response.URL.relativePath;
    NSDictionary *parameters = [self eventDictionaryForKey:urlString];
    NSDate *startDate = [parameters objectForKey:MHStartTime];
    NSDate *endDate = [NSDate date];
    NSTimeInterval elapsedTime = [endDate timeIntervalSinceDate:startDate];
    NSDateFormatter* iso8601Formatter = [[NSDateFormatter alloc] init];
    iso8601Formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    NSString *createdDate = [iso8601Formatter stringFromDate:[NSDate date]];

    NSMutableArray *attributes = [NSMutableArray array];
    [attributes addObject:@{ @"name" : @"requestUrl" , @"value" : urlString }];
    [attributes addObject:@{ @"name" : MHResourceType , @"value" : [parameters objectForKey:MHResourceType] }];

    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
        [attributes addObject:@{ @"name" : @"responseCode", @"value" : @(responseCode)}];
    }

    BOOL isWIFIOn = [[MHReachability reachabilityWithHostName:response.URL.host] isReachableViaWiFi];
    [attributes addObject:@{ @"name" : @"wifiOn", @"value" : @(isWIFIOn)}];

    if (action) {
        [attributes addObject:@{ @"name" : @"action" , @"value" : action }];
    }

    double elapsedTimeInMS = elapsedTime * 1000.0;

    return @{
             @"event" : kMHDownloadPerformanceEvent,
             @"created" : createdDate,
             @"sessionId" : [NSUUID UUID].UUIDString,
             @"counters" : @[ @{ @"name" : @"elapsedMS" , @"value" : @(elapsedTimeInMS) } ],
             @"attributes" : attributes
             };
}

// MARK: - Events dictionary access

- (nullable NSDictionary*)eventDictionaryForKey:(nonnull NSString*)key {
    __block NSDictionary *dictionary;

    dispatch_sync(self.eventsQueue, ^{
        dictionary = [self.events objectForKey:key];
    });

    return dictionary;
}

- (void)setEventDictionary:(nonnull NSDictionary*)dictionary forKey:(nonnull NSString*)key {
    dispatch_barrier_async(self.eventsQueue, ^{
        [self.events setObject:dictionary forKey:key];
    });
}

- (void)removeEventDictionaryForKey:(nonnull NSString*)key {
    dispatch_barrier_async(self.eventsQueue, ^{
        [self.events removeObjectForKey:key];
    });
}

@end

@implementation MHNetworkConfiguration (ForTesting)

+ (void)testing_clearNativeNetworkManagerDelegate {
    [MHNativeNetworkManager sharedManager].delegate = nil;
}

+ (id)testing_nativeNetworkManagerDelegate {
    return [MHNativeNetworkManager sharedManager].delegate;
}

@end
