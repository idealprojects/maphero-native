#import "PluginLayerExample.h"

@implementation PluginLayerExample


// This is the layer type in the style that is used
+(MHPluginLayerCapabilities *)layerCapabilities {

    MHPluginLayerCapabilities *tempResult = [[MHPluginLayerCapabilities alloc] init];
    tempResult.layerID = @"plugin-layer-test";
    tempResult.requiresPass3D = YES;
    return tempResult;

}

// The overrides
-(void)onRenderLayer {
    NSLog(@"PluginLayerExample: On Render Layer");

}

-(void)onUpdateLayer {

}

-(void)onUpdateLayerProperties:(NSDictionary *)layerProperties {
    // NSLog(@"Layer Properties: %@", layerProperties);
}

@end
