#import "MHCompactCalloutView.h"

#import "MHAnnotation.h"

@implementation MHCompactCalloutView
{
    id <MHAnnotation> _representedObject;
}

@synthesize representedObject = _representedObject;

+ (instancetype)platformCalloutView
{
    return [[self alloc] init];
}

- (BOOL)isAnchoredToAnnotation {
    return YES;
}

- (BOOL)dismissesAutomatically {
    return NO;
}

- (void)setRepresentedObject:(id <MHAnnotation>)representedObject
{
    _representedObject = representedObject;

    if ([representedObject respondsToSelector:@selector(title)])
    {
        self.title = representedObject.title;
    }
    if ([representedObject respondsToSelector:@selector(subtitle)])
    {
        self.subtitle = representedObject.subtitle;
    }
}

@end
