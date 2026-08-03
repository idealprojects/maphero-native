#import "MHMapOptions.h"

@interface MHMapOptions ()

@end

@implementation MHMapOptions

-(instancetype _Nonnull)init
{
    self = [super init];
    if (self)
    {
        _styleURL = nil;
        _styleJSON = nil;
        _pluginLayers = nil;

        _actionJournalOptions = [[MHActionJournalOptions alloc] init];
    }

    return self;
}

@end
