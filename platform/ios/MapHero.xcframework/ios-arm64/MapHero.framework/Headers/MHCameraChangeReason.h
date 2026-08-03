#import "MHFoundation.h"

/**
 Bitmask values that describe why a camera move occurred.

 Values of this type are passed to the ``MHMapView``'s delegate in the following methods:

 - ``MHMapViewDelegate/mapView:shouldChangeFromCamera:toCamera:reason:``
 - ``MHMapViewDelegate/mapView:regionWillChangeWithReason:animated:``
 - ``MHMapViewDelegate/mapView:regionIsChangingWithReason:``
 - ``MHMapViewDelegate/mapView:regionDidChangeWithReason:animated:``

 It's important to note that it's almost impossible to perform a rotate without zooming (in or out),
 so if you'll often find ``MHCameraChangeReasonGesturePinch`` set alongside
 ``MHCameraChangeReasonGestureRotate``.

 Since there are several reasons why a zoom or rotation has occurred, it is worth considering
 creating a combined constant, for example:

 ```objc
 static const MHCameraChangeReason anyZoom = MHCameraChangeReasonGesturePinch |
                                                MHCameraChangeReasonGestureZoomIn |
                                                MHCameraChangeReasonGestureZoomOut |
                                                MHCameraChangeReasonGestureOneFingerZoom;

 static const MHCameraChangeReason anyRotation = MHCameraChangeReasonResetNorth |
 MHCameraChangeReasonGestureRotate;
 ```
 */
typedef NS_OPTIONS(NSUInteger, MHCameraChangeReason) {
  /// The reason for the camera change has not be specified.
  MHCameraChangeReasonNone = 0,

  /// Set when a public API that moves the camera is called. This may be set for some
  /// gestures, for example MHCameraChangeReasonResetNorth.
  MHCameraChangeReasonProgrammatic = 1 << 0,

  /// The user tapped the compass to reset the map orientation so North is up.
  MHCameraChangeReasonResetNorth = 1 << 1,

  /// The user panned the map.
  MHCameraChangeReasonGesturePan = 1 << 2,

  /// The user pinched to zoom in/out.
  MHCameraChangeReasonGesturePinch = 1 << 3,

  // :nodoc: The user rotated the map.
  MHCameraChangeReasonGestureRotate = 1 << 4,

  /// The user zoomed the map in (one finger double tap).
  MHCameraChangeReasonGestureZoomIn = 1 << 5,

  /// The user zoomed the map out (two finger single tap).
  MHCameraChangeReasonGestureZoomOut = 1 << 6,

  /// The user long pressed on the map for a quick zoom (single tap, then long press and
  /// drag up/down).
  MHCameraChangeReasonGestureOneFingerZoom = 1 << 7,

  // The user panned with two fingers to tilt the map (two finger drag).
  MHCameraChangeReasonGestureTilt = 1 << 8,

  // Cancelled
  MHCameraChangeReasonTransitionCancelled = 1 << 16

};
