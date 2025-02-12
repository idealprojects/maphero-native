#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import "MHAnnotation.h"
#import "MHFoundation.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The MHUserLocation class defines a specific type of annotation that identifies
 the user’s current location. You do not create instances of this class
 directly. Instead, you retrieve an existing ``MHUserLocation`` object from the
 `userLocation` property of the map view displayed in your application.

 #### Related examples
 TODO: Customize the user location annotation,learn how to overide the
 default user location annotation.
 */
MH_EXPORT
@interface MHUserLocation : NSObject <MHAnnotation, NSSecureCoding>

// MARK: Determining the User’s Position

/**
 The current location of the device. (read-only)

 This property returns `nil` if the user’s location has not yet been determined.
 */
@property (nonatomic, readonly, nullable) CLLocation *location;

/**
 A Boolean value indicating whether the user’s location is currently being
 updated. (read-only)
 */
@property (nonatomic, readonly, getter=isUpdating) BOOL updating;

/**
 The heading of the user location. (read-only)

 This property is `nil` if the user location tracking mode is not
 ``MHUserTrackingMode/MHUserTrackingModeFollowWithHeading`` or if
 ``MHMapView/showsUserHeadingIndicator`` is disabled.
 */
@property (nonatomic, readonly, nullable) CLHeading *heading;

// MARK: Accessing the User Annotation Text

/** The title to display for the user location annotation. */
@property (nonatomic, copy) NSString *title;

/** The subtitle to display for the user location annotation. */
@property (nonatomic, copy, nullable) NSString *subtitle;

@end

NS_ASSUME_NONNULL_END
