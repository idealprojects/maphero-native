#import "MHComputedShapeSource.h"
#import "MHFoundation.h"
#import "MHTypes.h"

#include <mbgl/style/sources/custom_geometry_source.hpp>

NS_ASSUME_NONNULL_BEGIN

MH_EXPORT
mbgl::style::CustomGeometrySource::Options MBGLCustomGeometrySourceOptionsFromDictionary(
    NSDictionary<MHShapeSourceOption, id> *options);

NS_ASSUME_NONNULL_END
