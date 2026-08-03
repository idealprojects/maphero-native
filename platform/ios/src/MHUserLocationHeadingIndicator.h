#import <QuartzCore/QuartzCore.h>
#import "MHUserLocationAnnotationView.h"

@protocol MHUserLocationHeadingIndicator <NSObject>

- (instancetype)initWithUserLocationAnnotationView:
    (MHUserLocationAnnotationView *)userLocationView;
- (void)updateHeadingAccuracy:(CLLocationDirection)accuracy;
- (void)updateTintColor:(CGColorRef)color;

@end
