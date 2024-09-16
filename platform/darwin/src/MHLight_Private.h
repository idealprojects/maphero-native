#import <Foundation/Foundation.h>

#import "MHLight.h"

namespace mbgl {
namespace style {
class Light;
}
}  // namespace mbgl

@interface MHLight (Private)

/**
 Initializes and returns a ``MHLight`` associated with a style's light.
 */
- (instancetype)initWithMBGLLight:(const mbgl::style::Light *)mbglLight;

/**
 Returns an `mbgl::style::Light` representation of the ``MHLight``.
 */
- (mbgl::style::Light)mbglLight;

@end
