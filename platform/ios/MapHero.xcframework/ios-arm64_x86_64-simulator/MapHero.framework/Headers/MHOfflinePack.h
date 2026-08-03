#import <Foundation/Foundation.h>

#import "MHFoundation.h"
#import "MHOfflineRegion.h"
#import "MHTypes.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN MH_EXPORT MHExceptionName const MHInvalidOfflinePackException;

/**
 The state an offline pack is currently in.
 */
typedef NS_ENUM(NSInteger, MHOfflinePackState) {
  /**
   It is unknown whether the pack is inactive, active, or complete.

   This is the initial state of a pack. The state of a pack becomes known by
   the time the shared ``MHOfflineStorage`` object sends the first
   ``MHOfflinePackProgressChangedNotification`` about the pack. For inactive
   packs, you must explicitly request a progress update using the
   ``MHOfflinePack/requestProgress`` method.

   An invalid pack always has a state of ``MHOfflinePackStateInvalid``, never
   ``MHOfflinePackState/MHOfflinePackStateUnknown``.
   */
  MHOfflinePackStateUnknown = 0,
  /**
   The pack is incomplete and is not currently downloading.

   This is the initial state of a pack that is created using the
   ``MHOfflineStorage/addPackForRegion:withContext:completionHandler:``
   method, as well as after the ``MHOfflinePack/suspend`` method is
   called.
   */
  MHOfflinePackStateInactive = 1,
  /**
   The pack is incomplete and is currently downloading.

   This is the state of a pack after the ``MHOfflinePack/resume`` method is
   called.
   */
  MHOfflinePackStateActive = 2,
  /**
   The pack has downloaded to completion.
   */
  MHOfflinePackStateComplete = 3,
  /**
   The pack has been removed using the
   ``MHOfflineStorage/removePack:withCompletionHandler:`` method. Sending
   any message to the pack will raise an exception.
   */
  MHOfflinePackStateInvalid = 4,
};

/**
 A structure containing information about an offline pack’s current download
 progress.
 */
typedef struct __attribute__((objc_boxable)) MHOfflinePackProgress {
  /**
   The number of resources, including tiles, that have been completely
   downloaded and are ready to use offline.
   */
  uint64_t countOfResourcesCompleted;
  /**
   The cumulative size of the downloaded resources on disk, including tiles,
   measured in bytes.
   */
  uint64_t countOfBytesCompleted;
  /**
   The number of tiles that have been completely downloaded and are ready
   to use offline.
   */
  uint64_t countOfTilesCompleted;
  /**
   The cumulative size of the downloaded tiles on disk, measured in bytes.
   */
  uint64_t countOfTileBytesCompleted;
  /**
   The minimum number of resources that must be downloaded in order to view
   the pack’s full region without any omissions.

   At the beginning of a download, this count is a lower bound; the number of
   expected resources may increase as the download progresses.
   */
  uint64_t countOfResourcesExpected;
  /**
   The maximum number of resources that must be downloaded in order to view
   the pack’s full region without any omissions.

   At the beginning of a download, when the exact number of required resources
   is unknown, this field is set to `UINT64_MAX`. Thus this count is always an
   upper bound.
   */
  uint64_t maximumResourcesExpected;
} MHOfflinePackProgress;

/**
 An ``MHOfflinePack`` represents a collection of resources necessary for viewing
 a region offline to a local database.

 To create an instance of ``MHOfflinePack``, use the
 ``MHOfflineStorage/addPackForRegion:withContext:completionHandler:`` method.
 A pack created using `MHOfflinePack/init` is immediately invalid.

 ### Example
 ```swift
 MHOfflineStorage.shared.addPack(for: region, withContext: context) { (pack, error) in
     guard let pack = pack else {
         // If adding the pack fails, log an error to console.
         print("Error:", error?.localizedDescription ?? "unknown error adding pack at
 \(#file)(\(#line)) in \(#function)") return
     }

     // Start an MHOfflinePack download
     pack.resume()
 }
 ```
 */
MH_EXPORT
@interface MHOfflinePack : NSObject

/**
 The region for which the pack manages resources.
 */
@property (nonatomic, readonly) id<MHOfflineRegion> region;

/**
 Arbitrary data stored alongside the downloaded resources.

 The context typically holds application-specific information for identifying
 the pack, such as a user-selected name.

 To change the value of this property, use the `-setContext:completionHandler:`
 method. If you access this property after calling that method but before its
 completion handler is called, this property’s value may not reflect the new
 value that you specify.
 */
@property (nonatomic, readonly) NSData *context;

/**
 Associates arbitrary contextual data with the offline pack, replacing any
 context that was previously associated with the offline pack.

 Setting the context is asynchronous. The `context` property may not be updated
 until the completion handler is called.

 @param context The new context to associate with the offline pack.
 @param completion The completion handler to call when the context has been
    updated. If there is an error setting the context, the error is passed into
    the completion handler.
 */
- (void)setContext:(NSData *)context
    completionHandler:(void (^_Nullable)(NSError *_Nullable error))completion;

/**
 The pack’s current state.

 The state of an inactive or completed pack is computed lazily and is set to
 ``MHOfflinePackState/MHOfflinePackStateUnknown`` by default. To request the pack’s status, use
 the
 `-requestProgress` method. To get notified when the state becomes known and
 when it changes, observe KVO change notifications on this pack’s `state` key
 path. Alternatively, you can add an observer for
 ``MHOfflinePackProgressChangedNotification``s about this pack that come from the
 default notification center.
 */
@property (nonatomic, readonly) MHOfflinePackState state;

/**
 The pack’s current progress.

 The progress of an inactive or completed pack is computed lazily, and all its
 fields are set to 0 by default. To request the pack’s progress, use the
 `-requestProgress` method. To get notified when the progress becomes
 known and when it changes, observe KVO change notifications on this pack’s
 `state` key path. Alternatively, you can add an observer for
 ``MHOfflinePackProgressChangedNotification``s about this pack that come from the
 default notification center.
 */
@property (nonatomic, readonly) MHOfflinePackProgress progress;

/**
 Resumes downloading if the pack is inactive.

 When a pack resumes after being suspended, it may begin by iterating over the
 already downloaded resources. As a result, the `progress` structure’s
 `countOfResourcesCompleted` field may revert to 0 before rapidly returning to
 the level of progress at the time the pack was suspended.

 To temporarily suspend downloading, call the `-suspend` method.
 */
- (void)resume;

/**
 Temporarily stops downloading if the pack is active.

 A pack suspends asynchronously, so some network requests may be sent after this
 method is called. Regardless, the `progress` property will not be updated until
 `-resume` is called.

 If the pack previously reached a higher level of progress before being
 suspended, it may wait to suspend until it returns to that level.

 To resume downloading, call the `-resume` method.
 */
- (void)suspend;

/**
 Request an asynchronous update to the pack’s `state` and `progress` properties.

 The state and progress of an inactive or completed pack are computed lazily. If
 you need the state or progress of a pack whose `state` property is currently
 set to ``MHOfflinePackState/MHOfflinePackStateUnknown``, observe KVO change notifications on this
 pack’s `state` key path, then call this method. Alternatively, you can add an
 observer for ``MHOfflinePackProgressChangedNotification`` about this pack that
 come from the default notification center.
 */
- (void)requestProgress;

@end

NS_ASSUME_NONNULL_END
