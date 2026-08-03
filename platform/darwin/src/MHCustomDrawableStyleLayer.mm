#import "MHCustomDrawableStyleLayer.h"
#import "MHStyleLayer.h"

#import "MHCustomDrawableStyleLayer_Private.h"
#import "MHStyle_Private.h"
#import "MHStyleLayer_Private.h"
#import "MHGeometry_Private.h"

#include <mbgl/layermanager/custom_drawable_layer_factory.hpp>
#include <mbgl/style/layers/custom_drawable_layer.hpp>

#include <memory>
#include <cmath>

#include <mbgl/style/layer.hpp>

@interface MHCustomDrawableStyleLayer (Internal)
- (instancetype)initWithPendingLayer:(std::unique_ptr<mbgl::style::Layer>)pendingLayer;
@end

@implementation MHCustomDrawableStyleLayer

- (instancetype)initWithRawLayer:(mbgl::style::Layer *)rawLayer {
    return [super initWithRawLayer:rawLayer];
}

- (instancetype)initWithPendingLayer:(std::unique_ptr<mbgl::style::Layer>)pendingLayer {
    return [super initWithPendingLayer:std::move(pendingLayer)];
}

@end

namespace mbgl {

MHStyleLayer* CustomDrawableStyleLayerPeerFactory::createPeer(style::Layer* rawLayer) {
    return [[MHCustomDrawableStyleLayer alloc] initWithRawLayer:rawLayer];
}

}  // namespace mbgl
