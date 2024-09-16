#import "NSProcessInfo+MHAdditions.h"

@implementation NSProcessInfo (MHAdditions)

- (BOOL)mgl_isInterfaceBuilderDesignablesAgent {
    NSString *processName = self.processName;
    return [processName hasPrefix:@"IBAgent"] || [processName hasPrefix:@"IBDesignablesAgent"];
}

@end
