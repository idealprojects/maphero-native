#import <mbgl/util/action_journal_options.hpp>
#import "MHActionJournalOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHActionJournalOptions (Private)

- (mbgl::util::ActionJournalOptions)getCoreOptions;

@end

NS_ASSUME_NONNULL_END
