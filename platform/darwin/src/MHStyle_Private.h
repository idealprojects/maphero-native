#import "MHStyle.h"

#import "MHFillStyleLayer.h"
#import "MHStyleLayer.h"

NS_ASSUME_NONNULL_BEGIN

namespace mbgl {
namespace style {
class Style;
}
}  // namespace mbgl

@class MHAttributionInfo;
@class MHMapView;
@class MHCustomStyleLayer;
@class MHVectorTileSource;
@class MHVectorStyleLayer;

@interface MHStyle (Private)

- (instancetype)initWithRawStyle:(mbgl::style::Style *)rawStyle stylable:(id<MHStylable>)stylable;

@property (nonatomic, readonly, weak) id<MHStylable> stylable;
@property (nonatomic, readonly) mbgl::style::Style *rawStyle;

- (nullable NSArray<MHAttributionInfo *> *)attributionInfosWithFontSize:(CGFloat)fontSize
                                                               linkColor:
                                                                   (nullable MHColor *)linkColor;
@property (nonatomic, readonly, strong)
    NSMutableDictionary<NSString *, MHCustomStyleLayer *> *customLayers;
- (void)setStyleClasses:(NSArray<NSString *> *)appliedClasses
     transitionDuration:(NSTimeInterval)transitionDuration;

@end

@interface MHStyle (MHStreetsAdditions)

@property (nonatomic, readonly, copy) NSArray<MHVectorStyleLayer *> *placeStyleLayers;
@property (nonatomic, readonly, copy) NSArray<MHVectorStyleLayer *> *roadStyleLayers;

@end

NS_ASSUME_NONNULL_END
