#import <UIKit/UIKit.h>
#import "MHUserLocationAnnotationView.h"

extern const CGFloat MHUserLocationAnnotationDotSize;
extern const CGFloat MHUserLocationAnnotationHaloSize;

extern const CGFloat MHUserLocationAnnotationPuckSize;
extern const CGFloat MHUserLocationAnnotationArrowSize;

// Threshold in radians between heading indicator rotation updates.
extern const CGFloat MHUserLocationHeadingUpdateThreshold;

@interface MHFaux3DUserLocationAnnotationView : MHUserLocationAnnotationView

@end
