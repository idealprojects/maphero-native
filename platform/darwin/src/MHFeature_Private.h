#import "MHFeature.h"
#import "MHFoundation.h"
#import "MHShape.h"

#import <mbgl/style/conversion/geojson.hpp>
#import <mbgl/util/feature.hpp>
#import <mbgl/util/geo.hpp>

NS_ASSUME_NONNULL_BEGIN

/**
 Returns an array of ``MHFeature`` objects converted from the given vector of
 vector tile features.
 */
MH_EXPORT
NSArray<MHShape<MHFeature> *> *MHFeaturesFromMBGLFeatures(
    const std::vector<mbgl::Feature> &features);

/**
 Returns an array of ``MHFeature`` objects converted from the given vector of
 vector tile features.
 */
MH_EXPORT
NSArray<MHShape<MHFeature> *> *MHFeaturesFromMBGLFeatures(
    const std::vector<mbgl::GeoJSONFeature> &features);

/**
 Returns an ``MHFeature`` object converted from the given mbgl::GeoJSONFeature
 */
MH_EXPORT
id<MHFeature> MHFeatureFromMBGLFeature(const mbgl::GeoJSONFeature &feature);

/**
 Returns an ``MHShape`` representing the given geojson. The shape can be
 a feature, a collection of features, or a geometry.
 */
MHShape *MHShapeFromGeoJSON(const mapbox::geojson::geojson &geojson);

/**
 Takes an `mbgl::GeoJSONFeature` object, an identifer, and attributes dictionary and
 returns the feature object with converted `mbgl::FeatureIdentifier` and
 `mbgl::PropertyMap` properties.
 */
mbgl::GeoJSONFeature mbglFeature(mbgl::GeoJSONFeature feature, id identifier,
                                 NSDictionary *attributes);

/**
 Returns an `NSDictionary` representation of an ``MHFeature``.
 */
NSDictionary<NSString *, id> *NSDictionaryFeatureForGeometry(NSDictionary *geometry,
                                                             NSDictionary *attributes,
                                                             id identifier);

NS_ASSUME_NONNULL_END

#define MH_DEFINE_FEATURE_INIT_WITH_CODER()                                                 \
  -(instancetype)initWithCoder : (NSCoder *)decoder {                                        \
    if (self = [super initWithCoder:decoder]) {                                              \
      NSSet<Class> *identifierClasses =                                                      \
          [NSSet setWithArray:@[ [NSString class], [NSNumber class] ]];                      \
      identifier = [decoder decodeObjectOfClasses:identifierClasses forKey:@"identifier"];   \
      _attributes = [decoder decodeObjectOfClass:[NSDictionary class] forKey:@"attributes"]; \
    }                                                                                        \
    return self;                                                                             \
  }

#define MH_DEFINE_FEATURE_ENCODE()                        \
  -(void)encodeWithCoder : (NSCoder *)coder {              \
    [super encodeWithCoder:coder];                         \
    [coder encodeObject:identifier forKey:@"identifier"];  \
    [coder encodeObject:_attributes forKey:@"attributes"]; \
  }

#define MH_DEFINE_FEATURE_IS_EQUAL()                                                     \
  -(BOOL)isEqual : (id)other {                                                            \
    if (other == self) return YES;                                                        \
    if (![other isKindOfClass:[self class]]) return NO;                                   \
    __typeof(self) otherFeature = other;                                                  \
    return [super isEqual:other] && [self geoJSONObject] == [otherFeature geoJSONObject]; \
  }                                                                                       \
  -(NSUInteger)hash {                                                                     \
    return [super hash] + [[self geoJSONDictionary] hash];                                \
  }

#define MH_DEFINE_FEATURE_ATTRIBUTES_GETTER() \
  -(NSDictionary *)attributes {                \
    if (!_attributes) {                        \
      return @{};                              \
    }                                          \
    return _attributes;                        \
  }
