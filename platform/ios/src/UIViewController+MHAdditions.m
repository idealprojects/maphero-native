#import "UIViewController+MHAdditions.h"

@implementation UIViewController (MHAdditions)

- (UIViewController *)mgl_topMostViewController
{
    if ([self isKindOfClass:[UINavigationController class]])
    {
        return [[(UINavigationController *)self visibleViewController] mgl_topMostViewController];
    }
    else if ([self isKindOfClass:[UITabBarController class]])
    {
        return [[(UITabBarController *)self selectedViewController] mgl_topMostViewController];
    }
    else if (self.presentedViewController)
    {
        return [self.presentedViewController mgl_topMostViewController];
    }
    return self;
}

@end
