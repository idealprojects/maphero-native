#import "MHUserLocationAnnotationViewStyle.h"
#import "MHLoggingConfiguration_Private.h"

@implementation MHUserLocationAnnotationViewStyle

- (instancetype)init {
    if ((self = [super init])) {
        self.puckShadowOpacity = 0.25;
        if (@available(iOS 14, *)) {
            self.approximateHaloBorderWidth = 2.0;
            self.approximateHaloOpacity = 0.15;
        }
    }
    return self;
}

- (void)setPuckFillColor:(UIColor *)puckFillColor {
    MHLogDebug(@"Setting puckFillColor: %@", puckFillColor);
    _puckFillColor = puckFillColor;
}

- (void)setPuckShadowColor:(UIColor *)puckShadowColor {
    MHLogDebug(@"Setting puckShadowColor: %@", puckShadowColor);
    _puckShadowColor = puckShadowColor;
}

- (void)setPuckShadowOpacity:(CGFloat)puckShadowOpacity {
    MHLogDebug(@"Setting puckShadowOpacity: %.2f", puckShadowOpacity);
    _puckShadowOpacity = puckShadowOpacity;
}

- (void)setPuckArrowFillColor:(UIColor *)puckArrowFillColor {
    MHLogDebug(@"Setting puckArrowFillColor: %@", puckArrowFillColor);
    _puckArrowFillColor = puckArrowFillColor;
}

- (void)setHaloFillColor:(UIColor *)haloFillColor {
    MHLogDebug(@"Setting haloFillColor: %@", haloFillColor);
    _haloFillColor = haloFillColor;
}

- (void)setApproximateHaloFillColor:(UIColor *)approximateHaloFillColor {
    MHLogDebug(@"Setting approximateHaloFillColor: %@", approximateHaloFillColor);
    _approximateHaloFillColor = approximateHaloFillColor;
}

- (void)setApproximateHaloBorderColor:(UIColor *)approximateHaloBorderColor {
    MHLogDebug(@"Setting approximateHaloBorderColor: %@", approximateHaloBorderColor);
    _approximateHaloBorderColor = approximateHaloBorderColor;
}

- (void)setApproximateHaloBorderWidth:(CGFloat)approximateHaloBorderWidth {
    MHLogDebug(@"Setting approximateHaloBorderWidth: %.2f", approximateHaloBorderWidth);
    _approximateHaloBorderWidth = approximateHaloBorderWidth;
}

- (void)setApproximateHaloOpacity:(CGFloat)approximateHaloOpacity {
    MHLogDebug(@"Setting approximateHaloOpacity: %.2f", approximateHaloOpacity);
    _approximateHaloOpacity = approximateHaloOpacity;
}

@end
