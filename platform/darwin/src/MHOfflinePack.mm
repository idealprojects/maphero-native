#import "MHOfflinePack_Private.h"

#import "MHOfflineStorage_Private.h"
#import "MHOfflineRegion_Private.h"
#import "MHTilePyramidOfflineRegion.h"
#import "MHTilePyramidOfflineRegion_Private.h"
#import "MHShapeOfflineRegion.h"
#import "MHShapeOfflineRegion_Private.h"
#import "MHLoggingConfiguration_Private.h"

#import "NSValue+MHAdditions.h"

#include <mbgl/map/map_options.hpp>
#include <mbgl/storage/database_file_source.hpp>
#include <mbgl/util/variant.hpp>

const MHExceptionName MHInvalidOfflinePackException = @"MHInvalidOfflinePackException";

/**
 Assert that the current offline pack is valid.

 This macro should be used at the beginning of any public-facing instance method
 of ``MHOfflinePack``. For private methods, an assertion is more appropriate.
 */
#define MHAssertOfflinePackIsValid() \
    do { \
        if (_state == MHOfflinePackStateInvalid) { \
            [NSException raise:MHInvalidOfflinePackException \
                        format: \
             @"-[MHOfflineStorage removePack:withCompletionHandler:] has been called " \
             @"on this instance of MHOfflinePack, rendering it invalid. It is an " \
             @"error to send any message to this pack."]; \
        } \
    } while (NO);

@interface MHTilePyramidOfflineRegion () <MHOfflineRegion_Private, MHTilePyramidOfflineRegion_Private>
@end

@interface MHShapeOfflineRegion () <MHOfflineRegion_Private, MHShapeOfflineRegion_Private>
@end

class MBGLOfflineRegionObserver : public mbgl::OfflineRegionObserver {
public:
    MBGLOfflineRegionObserver(MHOfflinePack *pack_) : pack(pack_) {}

    void statusChanged(mbgl::OfflineRegionStatus status) override;
    void responseError(mbgl::Response::Error error) override;
    void mapboxTileCountLimitExceeded(uint64_t limit) override;

private:
    __weak MHOfflinePack *pack = nullptr;
};

@interface MHOfflinePack ()

@property (nonatomic, nullable, readwrite) mbgl::OfflineRegion *mbglOfflineRegion;
@property (nonatomic, readwrite) MHOfflinePackProgress progress;

@end

@implementation MHOfflinePack {
    BOOL _isSuspending;
    std::shared_ptr<mbgl::DatabaseFileSource> _mbglDatabaseFileSource;
}

- (instancetype)init {
    MHLogInfo(@"Calling this initializer is not allowed.");
    if (self = [super init]) {
        _state = MHOfflinePackStateInvalid;
        NSLog(@"%s called; did you mean to call +[MHOfflineStorage addPackForRegion:withContext:completionHandler:] instead?", __PRETTY_FUNCTION__);
    }
    return self;
}

- (instancetype)initWithMBGLRegion:(mbgl::OfflineRegion *)region {
    if (self = [super init]) {
        _mbglOfflineRegion = region;
        _state = MHOfflinePackStateUnknown;

        _mbglDatabaseFileSource = [[MHOfflineStorage sharedOfflineStorage] mbglDatabaseFileSource];
        _mbglDatabaseFileSource->setOfflineRegionObserver(*_mbglOfflineRegion, std::make_unique<MBGLOfflineRegionObserver>(self));
    }
    return self;
}

- (void)dealloc {
    MHAssert(_state == MHOfflinePackStateInvalid, @"MHOfflinePack was not invalided prior to deallocation.");
}

- (id <MHOfflineRegion>)region {
    MHAssertOfflinePackIsValid();

    const mbgl::OfflineRegionDefinition &regionDefinition = _mbglOfflineRegion->getDefinition();
    MHAssert([MHTilePyramidOfflineRegion conformsToProtocol:@protocol(MHOfflineRegion_Private)], @"MHTilePyramidOfflineRegion should conform to MHOfflineRegion_Private.");
    MHAssert([MHShapeOfflineRegion conformsToProtocol:@protocol(MHOfflineRegion_Private)], @"MHShapeOfflineRegion should conform to MHOfflineRegion_Private.");
    
    return  std::visit(mbgl::overloaded{
                                   [&] (const mbgl::OfflineTilePyramidRegionDefinition def){
                                       return (id <MHOfflineRegion>)[[MHTilePyramidOfflineRegion alloc] initWithOfflineRegionDefinition:def];
                                   },
                                   [&] (const mbgl::OfflineGeometryRegionDefinition& def){
                                       return (id <MHOfflineRegion>)[[MHShapeOfflineRegion alloc] initWithOfflineRegionDefinition:def];
                                   }
    }, regionDefinition);
}

- (NSData *)context {
    MHAssertOfflinePackIsValid();

    const mbgl::OfflineRegionMetadata &metadata = _mbglOfflineRegion->getMetadata();
    return [NSData dataWithBytes:&metadata[0] length:metadata.size()];
}

- (void)setContext:(NSData *)context completionHandler:(void (^_Nullable)(NSError * _Nullable error))completion {
    MHAssertOfflinePackIsValid();
    
    mbgl::OfflineRegionMetadata metadata(context.length);
    [context getBytes:&metadata[0] length:metadata.size()];
    
    [self willChangeValueForKey:@"context"];
    __weak MHOfflinePack *weakSelf = self;
    _mbglDatabaseFileSource->updateOfflineMetadata(_mbglOfflineRegion->getID(), metadata, [&, completion, weakSelf](mbgl::expected<mbgl::OfflineRegionMetadata, std::exception_ptr> mbglOfflineRegionMetadata) {
        NSError *error;
        if (!mbglOfflineRegionMetadata) {
            NSString *errorDescription = @(mbgl::util::toString(mbglOfflineRegionMetadata.error()).c_str());
            error = [NSError errorWithDomain:MHErrorDomain code:MHErrorCodeModifyingOfflineStorageFailed userInfo:errorDescription ? @{
                NSLocalizedDescriptionKey: errorDescription,
            } : nil];
        }
        dispatch_async(dispatch_get_main_queue(), [&, completion, weakSelf, error](void) {
            [weakSelf reloadWithCompletionHandler:^(NSError * _Nullable reloadingError) {
                MHOfflinePack *strongSelf = weakSelf;
                [strongSelf didChangeValueForKey:@"context"];
                if (completion) {
                    completion(error ?: reloadingError);
                }
            }];
        });
    });
}

- (void)reloadWithCompletionHandler:(void (^)(NSError * _Nullable error))completion {
    auto regionID = _mbglOfflineRegion->getID();
    MHOfflineStorage *sharedOfflineStorage = [MHOfflineStorage sharedOfflineStorage];
    __weak MHOfflinePack *weakSelf = self;
    [sharedOfflineStorage getPacksWithCompletionHandler:^(NSArray<MHOfflinePack *> *packs, __unused NSError * _Nullable error) {
        MHOfflinePack *strongSelf = weakSelf;
        for (MHOfflinePack *pack in packs) {
            if (pack.mbglOfflineRegion->getID() == regionID) {
                strongSelf.mbglOfflineRegion = pack.mbglOfflineRegion;
            }
            [pack invalidate];
        }
        completion(error);
    }];
}

- (void)resume {
    MHLogInfo(@"Resuming pack download.");
    MHAssertOfflinePackIsValid();

    self.state = MHOfflinePackStateActive;

    _mbglDatabaseFileSource->setOfflineRegionDownloadState(*_mbglOfflineRegion, mbgl::OfflineRegionDownloadState::Active);
}

- (void)suspend {
    MHLogInfo(@"Suspending pack download.");
    MHAssertOfflinePackIsValid();

    if (self.state == MHOfflinePackStateActive) {
        self.state = MHOfflinePackStateInactive;
        _isSuspending = YES;
    }

    _mbglDatabaseFileSource->setOfflineRegionDownloadState(*_mbglOfflineRegion, mbgl::OfflineRegionDownloadState::Inactive);
}

- (void)invalidate {
    MHLogInfo(@"Invalidating pack.");
    MHAssert(_state != MHOfflinePackStateInvalid, @"Cannot invalidate an already invalid offline pack.");
    MHAssert(self.mbglOfflineRegion, @"Should have a valid region");

    @synchronized (self) {
        self.state = MHOfflinePackStateInvalid;
        if (self.mbglOfflineRegion) {
            _mbglDatabaseFileSource->setOfflineRegionObserver(*self.mbglOfflineRegion, nullptr);
        }
        self.mbglOfflineRegion = nil;
    }
}

- (void)setState:(MHOfflinePackState)state {
    MHLogDebug(@"Setting state: %ld", (long)state);
    if (!self.mbglOfflineRegion) {
        // A progress update has arrived after the call to
        // -[MHOfflineStorage removePack:withCompletionHandler:] but before the
        // removal is complete and the completion handler is called.
        MHAssert(_state == MHOfflinePackStateInvalid, @"A valid MHOfflinePack has no mbgl::OfflineRegion.");
        return;
    }

    MHAssert(_state != MHOfflinePackStateInvalid, @"Cannot change the state of an invalid offline pack.");

    if (!_isSuspending || state != MHOfflinePackStateActive) {
        _isSuspending = NO;
        _state = state;
    }
}

- (void)requestProgress {
    MHLogInfo(@"Requesting pack progress.");
    MHAssertOfflinePackIsValid();

    __weak MHOfflinePack *weakSelf = self;
    _mbglDatabaseFileSource->getOfflineRegionStatus(*_mbglOfflineRegion, [&, weakSelf](mbgl::expected<mbgl::OfflineRegionStatus, std::exception_ptr> status) {
        if (status) {
            mbgl::OfflineRegionStatus checkedStatus = *status;
            dispatch_async(dispatch_get_main_queue(), ^{
                MHOfflinePack *strongSelf = weakSelf;
                [strongSelf offlineRegionStatusDidChange:checkedStatus];
            });
        }
    });
}

- (void)offlineRegionStatusDidChange:(mbgl::OfflineRegionStatus)status {
    MHAssert(_state != MHOfflinePackStateInvalid, @"Cannot change update progress of an invalid offline pack.");

    switch (status.downloadState) {
        case mbgl::OfflineRegionDownloadState::Inactive:
            self.state = status.complete() ? MHOfflinePackStateComplete : MHOfflinePackStateInactive;
            break;

        case mbgl::OfflineRegionDownloadState::Active:
            self.state = MHOfflinePackStateActive;
            break;
    }

    if (_isSuspending) {
        return;
    }

    MHOfflinePackProgress progress;
    progress.countOfResourcesCompleted = status.completedResourceCount;
    progress.countOfBytesCompleted = status.completedResourceSize;
    progress.countOfTilesCompleted = status.completedTileCount;
    progress.countOfTileBytesCompleted = status.completedTileSize;
    progress.countOfResourcesExpected = status.requiredResourceCount;
    progress.maximumResourcesExpected = status.requiredResourceCountIsPrecise ? status.requiredResourceCount : UINT64_MAX;
    self.progress = progress;

    NSDictionary *userInfo = @{MHOfflinePackUserInfoKeyState: @(self.state),
                               MHOfflinePackUserInfoKeyProgress: [NSValue valueWithMHOfflinePackProgress:progress]};

    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
    [noteCenter postNotificationName:MHOfflinePackProgressChangedNotification
                              object:self
                            userInfo:userInfo];
}

- (void)didReceiveError:(NSError *)error {
    MHLogError(@"Error: %@", error.localizedDescription);
    MHLogInfo(@"Notifying about pack error.");
    
    NSDictionary *userInfo = @{ MHOfflinePackUserInfoKeyError: error };
    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
    [noteCenter postNotificationName:MHOfflinePackErrorNotification
                              object:self
                            userInfo:userInfo];
}

- (void)didReceiveMaximumAllowedMapboxTiles:(uint64_t)limit {
    MHLogInfo(@"Notifying reached maximum allowed Mapbox tiles: %lu", (unsigned long)limit);
    NSDictionary *userInfo = @{ MHOfflinePackUserInfoKeyMaximumCount: @(limit) };
    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
    [noteCenter postNotificationName:MHOfflinePackMaximumMapboxTilesReachedNotification
                              object:self
                            userInfo:userInfo];
}

NSError *MHErrorFromResponseError(mbgl::Response::Error error) {
    NSInteger errorCode = MHErrorCodeUnknown;
    switch (error.reason) {
        case mbgl::Response::Error::Reason::NotFound:
            errorCode = MHErrorCodeNotFound;
            break;

        case mbgl::Response::Error::Reason::Server:
            errorCode = MHErrorCodeBadServerResponse;
            break;

        case mbgl::Response::Error::Reason::Connection:
            errorCode = MHErrorCodeConnectionFailed;
            break;

        default:
            break;
    }
    return [NSError errorWithDomain:MHErrorDomain code:errorCode userInfo:@{
        NSLocalizedFailureReasonErrorKey: @(error.message.c_str())
    }];
}

@end

void MBGLOfflineRegionObserver::statusChanged(mbgl::OfflineRegionStatus status) {
    __weak MHOfflinePack *weakPack = pack;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakPack offlineRegionStatusDidChange:status];
    });
}

void MBGLOfflineRegionObserver::responseError(mbgl::Response::Error error) {
    __weak MHOfflinePack *weakPack = pack;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakPack didReceiveError:MHErrorFromResponseError(error)];
    });
}

void MBGLOfflineRegionObserver::mapboxTileCountLimitExceeded(uint64_t limit) {
    __weak MHOfflinePack *weakPack = pack;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakPack didReceiveMaximumAllowedMapboxTiles:limit];
    });
}
