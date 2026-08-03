#include <mbgl/util/immutable.hpp>
#import "MHFoundation.h"
#import "MHShapeSource.h"

NS_ASSUME_NONNULL_BEGIN

namespace mbgl {
namespace style {
struct GeoJSONOptions;
}
}  // namespace mbgl

MH_EXPORT
mbgl::Immutable<mbgl::style::GeoJSONOptions> MHGeoJSONOptionsFromDictionary(
    NSDictionary<MHShapeSourceOption, id> *options);

@interface MHShapeSource (Private)

/**
 :nodoc:
 Debug log showing structure of an ``MHFeature``. This method recurses in the case
 that the feature conforms to ``MHCluster``. This method is used for testing and
 should be considered experimental, likely to be removed or changed in future
 releases.

 @param feature An object that conforms to the ``MHFeature`` protocol.
 @param indent Used during recursion. Specify 0.
 */

- (void)debugRecursiveLogForFeature:(id<MHFeature>)feature indent:(NSUInteger)indent;
@end

NS_ASSUME_NONNULL_END
