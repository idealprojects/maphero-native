#import "MHUserLocationHeadingArrowLayer.h"

#import "MHFaux3DUserLocationAnnotationView.h"
#import "MHGeometry.h"

const CGFloat MHUserLocationHeadingArrowSize = 8;

@implementation MHUserLocationHeadingArrowLayer

- (instancetype)initWithUserLocationAnnotationView:(MHUserLocationAnnotationView *)userLocationView
{
    CGFloat size = userLocationView.bounds.size.width + MHUserLocationHeadingArrowSize;

    self = [super init];
    self.bounds = CGRectMake(0, 0, size, size);
    self.position = CGPointMake(CGRectGetMidX(userLocationView.bounds), CGRectGetMidY(userLocationView.bounds));
    self.path = [self arrowPath];
    self.fillColor = userLocationView.tintColor.CGColor;
    self.shouldRasterize = YES;
    self.rasterizationScale = UIScreen.mainScreen.scale;
    self.drawsAsynchronously = YES;

    self.strokeColor = UIColor.whiteColor.CGColor;
    self.lineWidth = 1.0;
    self.lineJoin = kCALineJoinRound;

    return self;
}

- (void)updateHeadingAccuracy:(CLLocationDirection)accuracy
{
    // unimplemented
}

- (void)updateTintColor:(CGColorRef)color
{
    self.fillColor = color;
}

- (CGPathRef)arrowPath {
    CGFloat center = roundf(CGRectGetMidX(self.bounds));
    CGFloat size = MHUserLocationHeadingArrowSize;

    CGPoint top =       CGPointMake(center,         0);
    CGPoint left =      CGPointMake(center - size,  size);
    CGPoint right =     CGPointMake(center + size,  size);
    CGPoint middle =    CGPointMake(center,         size / M_PI);

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:top];
    [bezierPath addLineToPoint:left];
    [bezierPath addQuadCurveToPoint:right controlPoint:middle];
    [bezierPath addLineToPoint:top];
    [bezierPath closePath];
    
    return bezierPath.CGPath;
}

@end
