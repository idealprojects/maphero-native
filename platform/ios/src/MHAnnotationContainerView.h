#import <UIKit/UIKit.h>

#import "MHTypes.h"

@class MHAnnotationView;

NS_ASSUME_NONNULL_BEGIN

@interface MHAnnotationContainerView : UIView

+ (instancetype)annotationContainerViewWithAnnotationContainerView:
    (MHAnnotationContainerView *)annotationContainerView;

- (void)addSubviews:(NSArray<MHAnnotationView *> *)subviews;

@end

NS_ASSUME_NONNULL_END
