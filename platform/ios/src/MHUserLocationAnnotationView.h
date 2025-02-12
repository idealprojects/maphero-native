#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

#import "MHAnnotationView.h"
#import "MHFoundation.h"

NS_ASSUME_NONNULL_BEGIN

@class MHMapView;
@class MHUserLocation;

/** View representing an ``MHUserLocation`` on screen. */
MH_EXPORT
@interface MHUserLocationAnnotationView : MHAnnotationView

/**
 Returns the associated map view.

 The value of this property is nil during initialization.
 */
@property (nonatomic, readonly, weak, nullable) MHMapView *mapView;

/**
 Returns the annotation object indicating the user’s current location.

 The value of this property is nil during initialization and while user tracking
 is inactive.

 #### Related examples
 TODO: Customize the user location annotation, learn how to customize
 the default user location annotation object.
 */
@property (nonatomic, readonly, weak, nullable) MHUserLocation *userLocation;

/**
 Returns the layer that should be used for annotation selection hit testing.

 The default value of this property is the presentation layer of the view’s Core
 Animation layer. When subclassing, you may override this property to specify a
 different layer to be used for hit testing. This can be useful when you wish to
 limit the interactive area of the annotation to a specific sublayer.
 */
@property (nonatomic, readonly, weak) CALayer *hitTestLayer;

/**
 Updates the user location annotation.

 Use this method to update the appearance of the user location annotation. This
 method is called by the associated map view when it has determined that the
 user location annotation needs to be updated. This can happen in response to
 user interaction, a change in the user’s location, when the user tracking mode
 changes, or when the viewport changes.

 > Note: During user interaction with the map, this method may be called many
 times to update the user location annotation. Therefore, your implementation of
 this method should be as lightweight as possible to avoid negatively affecting
 performance.
 */
- (void)update;

@end

NS_ASSUME_NONNULL_END
