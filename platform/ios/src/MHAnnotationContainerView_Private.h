#import "MHAnnotationContainerView.h"
#import "MHAnnotationView.h"

@class MHAnnotationView;

NS_ASSUME_NONNULL_BEGIN

@interface MHAnnotationContainerView (Private)

@property (nonatomic) NSMutableArray<MHAnnotationView *> *annotationViews;

@end

NS_ASSUME_NONNULL_END
