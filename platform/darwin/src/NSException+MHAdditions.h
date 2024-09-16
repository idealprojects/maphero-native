#import <Foundation/Foundation.h>
#import "MHLoggingConfiguration_Private.h"

#define MHAssertIsMainThread()                                                     \
  MHAssert([[NSThread currentThread] isMainThread],                                \
            @"%s must be accessed on the main thread, not %@", __PRETTY_FUNCTION__, \
            [NSThread currentThread])
