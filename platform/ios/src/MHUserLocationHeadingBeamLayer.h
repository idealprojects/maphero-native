#import <QuartzCore/QuartzCore.h>
#import "MHUserLocationAnnotationView.h"
#import "MHUserLocationHeadingIndicator.h"

@interface MHUserLocationHeadingBeamLayer : CALayer <MHUserLocationHeadingIndicator>

- (MHUserLocationHeadingBeamLayer *)initWithUserLocationAnnotationView:
    (MHUserLocationAnnotationView *)userLocationView;
- (void)updateHeadingAccuracy:(CLLocationDirection)accuracy;
- (void)updateTintColor:(CGColorRef)color;

@end
