#import "MHShape.h"

#import <mbgl/util/geo.hpp>
#import <mbgl/util/geojson.hpp>
#import <mbgl/util/geometry.hpp>

bool operator==(const CLLocationCoordinate2D lhs, const CLLocationCoordinate2D rhs);

@interface MHShape (Private)

/**
 Returns an `mbgl::GeoJSON` representation of the ``MHShape``.
 */
- (mbgl::GeoJSON)geoJSONObject;

/**
 Returns an `mbgl::Geometry<double>` representation of the ``MHShape``.
 */
- (mbgl::Geometry<double>)geometryObject;

/**
 Returns a dictionary with the GeoJSON geometry member object.
 */
- (NSDictionary *)geoJSONDictionary;

@end
