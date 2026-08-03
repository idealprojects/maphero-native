#import <QuartzCore/QuartzCore.h>
#import "MHUserLocationAnnotationView.h"
#import "MHUserLocationHeadingIndicator.h"

@interface MHUserLocationHeadingArrowLayer : CAShapeLayer <MHUserLocationHeadingIndicator>

- (instancetype)initWithUserLocationAnnotationView:
    (MHUserLocationAnnotationView *)userLocationView;
- (void)updateHeadingAccuracy:(CLLocationDirection)accuracy;
- (void)updateTintColor:(CGColorRef)color;

@end
