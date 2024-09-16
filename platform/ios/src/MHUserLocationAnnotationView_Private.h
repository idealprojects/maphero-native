#import "MHUserLocation.h"
#import "MHUserLocationAnnotationView.h"

NS_ASSUME_NONNULL_BEGIN

@class MHMapView;

@interface MHUserLocationAnnotationView (Private)

@property (nonatomic, weak, nullable) MHUserLocation *userLocation;
@property (nonatomic, weak, nullable) MHMapView *mapView;

@end

NS_ASSUME_NONNULL_END
