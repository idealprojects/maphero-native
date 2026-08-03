#import <Foundation/Foundation.h>

#import "MHGeometry.h"
#import "MHLight.h"
#import "MHOfflinePack.h"
#import "MHTypes.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Methods for round-tripping values for Mapbox-defined types.
 */
@interface NSValue (MHAdditions)

// MARK: Working with Geographic Coordinate Values

/**
 Creates a new value object containing the specified Core Location geographic
 coordinate structure.

 @param coordinate The value for the new object.
 @return A new value object that contains the geographic coordinate information.
 */
+ (instancetype)valueWithMHCoordinate:(CLLocationCoordinate2D)coordinate;

/**
 The Core Location geographic coordinate structure representation of the value.
 */
@property (readonly) CLLocationCoordinate2D MHCoordinateValue;

/**
 Creates a new value object containing the specified Mapbox map point structure.

 @param point The value for the new object.
 @return A new value object that contains the coordinate and zoom level information.
 */
+ (instancetype)valueWithMHMapPoint:(MHMapPoint)point;

/**
 The Mapbox map point structure representation of the value.
 */
@property (readonly) MHMapPoint MHMapPointValue;

/**
 Creates a new value object containing the specified Mapbox coordinate span
 structure.

 @param span The value for the new object.
 @return A new value object that contains the coordinate span information.
 */
+ (instancetype)valueWithMHCoordinateSpan:(MHCoordinateSpan)span;

/**
 The Mapbox coordinate span structure representation of the value.
 */
@property (readonly) MHCoordinateSpan MHCoordinateSpanValue;

/**
 Creates a new value object containing the specified Mapbox coordinate bounds
 structure.

 @param bounds The value for the new object.
 @return A new value object that contains the coordinate bounds information.
 */
+ (instancetype)valueWithMHCoordinateBounds:(MHCoordinateBounds)bounds;

/**
 The Mapbox coordinate bounds structure representation of the value.
 */
@property (readonly) MHCoordinateBounds MHCoordinateBoundsValue;

/**
 Creates a new value object containing the specified Mapbox coordinate
 quad structure.

 @param quad The value for the new object.
 @return A new value object that contains the coordinate quad information.
 */
+ (instancetype)valueWithMHCoordinateQuad:(MHCoordinateQuad)quad;

/**
 The Mapbox coordinate quad structure representation of the value.
 */
- (MHCoordinateQuad)MHCoordinateQuadValue;

// MARK: Working with Offline Map Values

/**
 Creates a new value object containing the given ``MHOfflinePackProgress``
 structure.

 @param progress The value for the new object.
 @return A new value object that contains the offline pack progress information.
 */
+ (NSValue *)valueWithMHOfflinePackProgress:(MHOfflinePackProgress)progress;

/**
 The ``MHOfflinePackProgress`` structure representation of the value.
 */
@property (readonly) MHOfflinePackProgress MHOfflinePackProgressValue;

// MARK: Working with Transition Values

/**
 Creates a new value object containing the given ``MHTransition``
 structure.

 @param transition The value for the new object.
 @return A new value object that contains the transition information.
 */
+ (NSValue *)valueWithMHTransition:(MHTransition)transition;

/**
 The ``MHTransition`` structure representation of the value.
 */
@property (readonly) MHTransition MHTransitionValue;

/**
 Creates a new value object containing the given ``MHSphericalPosition``
 structure.

 @param lightPosition The value for the new object.
 @return A new value object that contains the light position information.
 */
+ (instancetype)valueWithMHSphericalPosition:(MHSphericalPosition)lightPosition;

/**
 The ``MHSphericalPosition`` structure representation of the value.
 */
@property (readonly) MHSphericalPosition MHSphericalPositionValue;

/**
 Creates a new value object containing the given ``MHLightAnchor``
 enum.

 @param lightAnchor The value for the new object.
 @return A new value object that contains the light anchor information.
 */
+ (NSValue *)valueWithMHLightAnchor:(MHLightAnchor)lightAnchor;

/**
 The ``MHLightAnchor`` enum representation of the value.
 */
@property (readonly) MHLightAnchor MHLightAnchorValue;

@end

NS_ASSUME_NONNULL_END
