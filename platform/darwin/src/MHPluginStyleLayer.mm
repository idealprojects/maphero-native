#import "MHPluginStyleLayer.h"
#import "MHPluginStyleLayer_Private.h"
#import <mbgl/plugin/plugin_layer.hpp>
#import <mbgl/plugin/plugin_layer_impl.hpp>
#import "MHPluginLayer.h"

@implementation MHPluginStyleLayer

-(void)getStats {

    mbgl::style::PluginLayer *l = (mbgl::style::PluginLayer *)self.rawLayer;
    auto pl = l->impl();

}

-(MHPluginLayer *)pluginLayer {

    mbgl::style::PluginLayer *l = (mbgl::style::PluginLayer *)self.rawLayer;
    if (l->_platformReference) {
        MHPluginLayer *pl = (__bridge MHPluginLayer *)l->_platformReference;
        return pl;
    }

    return nil;

}


@end


MHStyleLayer* mbgl::PluginLayerPeerFactory::createPeer(style::Layer *rawLayer) {
    return [[MHPluginStyleLayer alloc] initWithRawLayer:rawLayer];

}
