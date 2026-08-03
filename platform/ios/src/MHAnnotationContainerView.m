#import "MHAnnotationContainerView.h"
#import "MHAnnotationView.h"

@interface MHAnnotationContainerView ()

@property (nonatomic) NSMutableArray<MHAnnotationView *> *annotationViews;

@end

@implementation MHAnnotationContainerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _annotationViews = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)annotationContainerViewWithAnnotationContainerView:(nonnull MHAnnotationContainerView *)annotationContainerView
{
    MHAnnotationContainerView *newAnnotationContainerView = [[MHAnnotationContainerView alloc] initWithFrame:annotationContainerView.frame];
    [newAnnotationContainerView addSubviews:annotationContainerView.subviews];
    return newAnnotationContainerView;
}

- (void)addSubviews:(NSArray<MHAnnotationView *> *)subviews
{
    for (MHAnnotationView *view in subviews)
    {
        [self addSubview:view];
        [self.annotationViews addObject:view];
    }
}

// MARK: UIAccessibility methods

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitAdjustable;
}

- (void)accessibilityIncrement {
    [self.superview.superview accessibilityIncrement];
}

- (void)accessibilityDecrement {
    [self.superview.superview accessibilityDecrement];
}

@end
