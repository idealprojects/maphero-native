#import "MHCalloutView.h"
#import "SMCalloutView.h"

/**
 A concrete implementation of ``MHCalloutView`` based on
 <a href="https://github.com/nfarina/calloutview">SMCalloutView</a>. This
 callout view displays the represented annotation’s title, subtitle, and
 accessory views in a compact, two-line layout.
 */
@interface MHCompactCalloutView : MHSMCalloutView <MHCalloutView>

+ (instancetype)platformCalloutView;

@end
