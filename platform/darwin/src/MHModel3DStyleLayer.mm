#import "MHModel3DStyleLayer.h"
#import "MHModel3DStyleLayer_Private.h"

#import "MHStyleLayer_Private.h"

#include <mbgl/style/layers/model3d_layer.hpp>

#include <string>

@interface MHModel3DStyleLayer ()

@property (nonatomic, readonly) mbgl::style::Model3DLayer *rawLayer;

@end

@implementation MHModel3DStyleLayer

- (instancetype)initWithIdentifier:(NSString *)identifier {
    auto layer = std::make_unique<mbgl::style::Model3DLayer>(identifier.UTF8String);
    return self = [super initWithPendingLayer:std::move(layer)];
}

- (mbgl::style::Model3DLayer *)rawLayer {
    return (mbgl::style::Model3DLayer *)super.rawLayer;
}

- (void)setData:(NSString *)featureCollectionJSON {
    if (auto error = self.rawLayer->setData(std::string(featureCollectionJSON.UTF8String))) {
        NSLog(@"MHModel3DStyleLayer setData failed: %s", error->message.c_str());
    }
}

@end

namespace mbgl {

MHStyleLayer* Model3DStyleLayerPeerFactory::createPeer(style::Layer* rawLayer) {
    return [[MHModel3DStyleLayer alloc] initWithRawLayer:rawLayer];
}

} // namespace mbgl
