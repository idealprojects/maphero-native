#import "MHOfflineStorage.h"

#import "MHOfflinePack.h"

#include <mbgl/storage/database_file_source.hpp>
#include <mbgl/storage/online_file_source.hpp>

#include "MHSettings_Private.h"

#include <memory>

NS_ASSUME_NONNULL_BEGIN

@interface MHOfflineStorage (Private)

/**
 The shared database file source object owned by the shared offline storage object.
 */
@property (nonatomic) std::shared_ptr<mbgl::DatabaseFileSource> mbglDatabaseFileSource;

/**
 The shared online file source object owned by the shared offline storage object.
 */
@property (nonatomic) std::shared_ptr<mbgl::FileSource> mbglOnlineFileSource;

/**
 The shared resource loader file source object owned by the shared offline storage object.
 */
@property (nonatomic) std::shared_ptr<mbgl::FileSource> mbglFileSource;

- (void)getPacksWithCompletionHandler:(void (^)(NSArray<MHOfflinePack *> *packs,
                                                NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
