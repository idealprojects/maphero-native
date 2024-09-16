#import <UIKit/UIKit.h>

#import "MHCompassButton.h"

@class MHMapView;

NS_ASSUME_NONNULL_BEGIN

@interface MHCompassButton (Private)

+ (instancetype)compassButtonWithMapView:(MHMapView *)mapView;

@property (nonatomic, weak) MHMapView *mapView;

- (void)updateCompass;

@end

NS_ASSUME_NONNULL_END
