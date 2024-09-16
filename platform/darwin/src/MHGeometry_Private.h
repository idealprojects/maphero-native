#import "MHGeometry.h"

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import <mbgl/util/geo.hpp>
#import <mbgl/util/geometry.hpp>

#import <array>
typedef double MHLocationRadians;
typedef double MHRadianDistance;
typedef double MHRadianDirection;

/** Defines the coordinate by a `MHRadianCoordinate2D`. */
typedef struct MHRadianCoordinate2D {
  MHLocationRadians latitude;
  MHLocationRadians longitude;
} MHRadianCoordinate2D;

/**
 Creates a new `MHRadianCoordinate2D` from the given latitudinal and longitudinal.
 */
NS_INLINE MHRadianCoordinate2D MHRadianCoordinate2DMake(MHLocationRadians latitude,
                                                          MHLocationRadians longitude) {
  MHRadianCoordinate2D radianCoordinate;
  radianCoordinate.latitude = latitude;
  radianCoordinate.longitude = longitude;
  return radianCoordinate;
}

/// Returns the smallest rectangle that contains both the given rectangle and
/// the given point.
CGRect MHExtendRect(CGRect rect, CGPoint point);

#if TARGET_OS_IPHONE
NS_INLINE NSString *MHStringFromSize(CGSize size) { return NSStringFromCGSize(size); }
#else
NS_INLINE NSString *MHStringFromSize(NSSize size) { return NSStringFromSize(size); }
#endif

NS_INLINE NSString *MHStringFromCLLocationCoordinate2D(CLLocationCoordinate2D coordinate) {
  return
      [NSString stringWithFormat:@"(lat: %f, lon: %f)", coordinate.latitude, coordinate.longitude];
}

mbgl::LatLng MHLatLngFromLocationCoordinate2D(CLLocationCoordinate2D coordinate);

NS_INLINE mbgl::Point<double> MHPointFeatureClusterFromLocationCoordinate2D(CLLocationCoordinate2D coordinate) {
  return mbgl::Point<double>(coordinate.longitude, coordinate.latitude);
}

NS_INLINE CLLocationCoordinate2D MHLocationCoordinate2DFromPoint(mbgl::Point<double> point) {
  return CLLocationCoordinate2DMake(point.y, point.x);
}

NS_INLINE CLLocationCoordinate2D MHLocationCoordinate2DFromLatLng(mbgl::LatLng latLng) {
  return CLLocationCoordinate2DMake(latLng.latitude(), latLng.longitude());
}

NS_INLINE MHCoordinateBounds MHCoordinateBoundsFromLatLngBounds(mbgl::LatLngBounds latLngBounds) {
  return MHCoordinateBoundsMake(MHLocationCoordinate2DFromLatLng(latLngBounds.southwest()),
                                 MHLocationCoordinate2DFromLatLng(latLngBounds.northeast()));
}

NS_INLINE mbgl::LatLngBounds MHLatLngBoundsFromCoordinateBounds(
    MHCoordinateBounds coordinateBounds) {
  return mbgl::LatLngBounds::hull(MHLatLngFromLocationCoordinate2D(coordinateBounds.sw),
                                  MHLatLngFromLocationCoordinate2D(coordinateBounds.ne));
}

NS_INLINE std::array<mbgl::LatLng, 4> MHLatLngArrayFromCoordinateQuad(MHCoordinateQuad quad) {
  return {MHLatLngFromLocationCoordinate2D(quad.topLeft),
          MHLatLngFromLocationCoordinate2D(quad.topRight),
          MHLatLngFromLocationCoordinate2D(quad.bottomRight),
          MHLatLngFromLocationCoordinate2D(quad.bottomLeft)};
}

NS_INLINE MHCoordinateQuad MHCoordinateQuadFromLatLngArray(std::array<mbgl::LatLng, 4> quad) {
  return {MHLocationCoordinate2DFromLatLng(quad[0]), MHLocationCoordinate2DFromLatLng(quad[3]),
          MHLocationCoordinate2DFromLatLng(quad[2]), MHLocationCoordinate2DFromLatLng(quad[1])};
}

/**
 YES if the coordinate is valid or NO if it is not.
 Considers extended coordinates.
 */
NS_INLINE BOOL MHLocationCoordinate2DIsValid(CLLocationCoordinate2D coordinate) {
  return (coordinate.latitude <= 90.0 && coordinate.latitude >= -90.0 &&
          coordinate.longitude <= 360.0 && coordinate.longitude >= -360.0);
}

#if TARGET_OS_IPHONE
#define MHEdgeInsets UIEdgeInsets
#define MHEdgeInsetsMake UIEdgeInsetsMake
#else
#define MHEdgeInsets NSEdgeInsets
#define MHEdgeInsetsMake NSEdgeInsetsMake
#endif

NS_INLINE mbgl::EdgeInsets MHEdgeInsetsFromNSEdgeInsets(MHEdgeInsets insets) {
  return {insets.top, insets.left, insets.bottom, insets.right};
}

NS_INLINE MHEdgeInsets NSEdgeInsetsFromMHEdgeInsets(const mbgl::EdgeInsets &insets) {
  return MHEdgeInsetsMake(insets.top(), insets.left(), insets.bottom(), insets.right());
}

/// Returns the combination of two edge insets.
NS_INLINE MHEdgeInsets MHEdgeInsetsInsetEdgeInset(MHEdgeInsets base, MHEdgeInsets inset) {
  return MHEdgeInsetsMake(base.top + inset.top, base.left + inset.left, base.bottom + inset.bottom,
                           base.right + inset.right);
}

/** Returns MHRadianCoordinate2D, converted from CLLocationCoordinate2D. */
NS_INLINE MHRadianCoordinate2D
MHRadianCoordinateFromLocationCoordinate(CLLocationCoordinate2D locationCoordinate) {
  return MHRadianCoordinate2DMake(MHRadiansFromDegrees(locationCoordinate.latitude),
                                   MHRadiansFromDegrees(locationCoordinate.longitude));
}

/**
 Returns the distance in radians given two coordinates.
 */
MHRadianDistance MHDistanceBetweenRadianCoordinates(MHRadianCoordinate2D from,
                                                      MHRadianCoordinate2D to);

/**
 Returns direction in radians given two coordinates.
 */
MHRadianDirection MHRadianCoordinatesDirection(MHRadianCoordinate2D from,
                                                 MHRadianCoordinate2D to);

/**
 Returns a coordinate at a given distance and direction away from coordinate.
 */
MHRadianCoordinate2D MHRadianCoordinateAtDistanceFacingDirection(MHRadianCoordinate2D coordinate,
                                                                   MHRadianDistance distance,
                                                                   MHRadianDirection direction);

/**
 Returns the direction from one coordinate to another.
 */
CLLocationDirection MHDirectionBetweenCoordinates(CLLocationCoordinate2D firstCoordinate,
                                                   CLLocationCoordinate2D secondCoordinate);

/**
 Returns a point with coordinates rounded to the nearest logical pixel.
 */
CGPoint MHPointFeatureClusterRounded(CGPoint point);

MHMatrix4 MHMatrix4Make(std::array<double, 16> mat);
