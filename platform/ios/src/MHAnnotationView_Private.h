#import "MHAnnotation.h"
#import "MHAnnotationView.h"

NS_ASSUME_NONNULL_BEGIN

@class MHMapView;

@interface MHAnnotationView (Private)

@property (nonatomic, readwrite, nullable) NSString *reuseIdentifier;
@property (nonatomic, weak) MHMapView *mapView;

@end

NS_ASSUME_NONNULL_END
