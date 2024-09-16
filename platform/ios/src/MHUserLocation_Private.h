#import "MHUserLocation.h"

#import <CoreLocation/CoreLocation.h>

@class MHMapView;

NS_ASSUME_NONNULL_BEGIN

@interface MHUserLocation (Private)

@property (nonatomic, weak) MHMapView *mapView;
@property (nonatomic, readwrite, nullable) CLLocation *location;
@property (nonatomic, readwrite, nullable) CLHeading *heading;

- (instancetype)initWithMapView:(MHMapView *)mapView;

@end

NS_ASSUME_NONNULL_END
