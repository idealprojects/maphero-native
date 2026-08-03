#import <mbgl/gfx/rendering_stats.hpp>
#import "MHRenderingStats.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHRenderingStats (Private)

- (void)setCoreData:(const mbgl::gfx::RenderingStats&)stats;

@end

NS_ASSUME_NONNULL_END
