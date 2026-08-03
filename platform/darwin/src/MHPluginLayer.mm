#import "MHPluginLayer.h"

@implementation MHPluginLayerProperty

+(MHPluginLayerProperty *)propertyWithName:(NSString *)propertyName
                               propertyType:(MHPluginLayerPropertyType)propertyType
                               defaultValue:(id)defaultValue {
    MHPluginLayerProperty *tempResult = [[MHPluginLayerProperty alloc] init];
    tempResult.propertyName = propertyName;
    tempResult.propertyType = propertyType;

    if (propertyType == MHPluginLayerPropertyTypeSingleFloat) {
        if ([defaultValue isKindOfClass:[NSNumber class]]) {
            tempResult.singleFloatDefaultValue = [defaultValue floatValue];
        }
    } else if (propertyType == MHPluginLayerPropertyTypeColor) {
#if TARGET_OS_IPHONE
        if ([defaultValue isKindOfClass:[UIColor class]]) {
#else
        if ([defaultValue isKindOfClass:[NSColor class]]) {
#endif
            tempResult.colorDefaultValue = defaultValue;
        }
    }

    return tempResult;
}


-(id)init {
    // Base class implemenation
    if (self = [super init]) {
        // Default setup
        self.propertyType = MHPluginLayerPropertyTypeUnknown;
        self.propertyName = @"unknown";

        // Default values for the various types
        self.singleFloatDefaultValue = 1.0;
    }
    return self;
}

@end

@implementation MHPluginLayer

// This is the layer type in the style that is used
+(MHPluginLayerCapabilities *)layerCapabilities {

    // Base class returns the class name just to return something
    // TODO: Add an assert/etc or something to notify the developer that this needs to be overridden
    return nil;

}

- (void)onRenderLayer:(MHMapView *)mapView
        renderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder {
    // Base class does nothing
}

- (void)onUpdateLayer:(MHPluginLayerDrawingContext)drawingContext {
    // Base class does nothing
}

-(void)onUpdateLayerProperties:(NSDictionary *)layerProperties {
    // Base class does nothing
}

/// Added to a map view
- (void)didMoveToMapView:(MHMapView *)mapView {
    // Base class does nothing
}


@end



@implementation MHPluginLayerCapabilities
@end
