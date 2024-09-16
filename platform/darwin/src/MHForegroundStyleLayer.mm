#import "MHForegroundStyleLayer.h"
#import "MHStyleLayer_Private.h"

@implementation MHForegroundStyleLayer

- (NSString *)sourceIdentifier {
    [NSException raise:MHAbstractClassException
                format:@"MHForegroundStyleLayer is an abstract class"];
    return nil;
}

- (NSString *)description {
    if (self.rawLayer) {
        return [NSString stringWithFormat:
                @"<%@: %p; identifier = %@; sourceIdentifier = %@; visible = %@>",
                NSStringFromClass([self class]), (void *)self, self.identifier,
                self.sourceIdentifier, self.visible ? @"YES" : @"NO"];
    }
    else {
        return [NSString stringWithFormat:
                @"<%@: %p; identifier = %@; sourceIdentifier = <unknown>; visible = NO>",
                NSStringFromClass([self class]), (void *)self, self.identifier];
    }
}

@end
