#import "MHStyleLayer_Private.h"
#import "MHStyle_Private.h"

#include <mbgl/style/style.hpp>
#include <mbgl/style/layer.hpp>

const MHExceptionName MHInvalidStyleLayerException = @"MHInvalidStyleLayerException";

@interface MHStyleLayer ()

@property (nonatomic, readonly) mbgl::style::Layer *rawLayer;

@end

@implementation MHStyleLayer {
    std::unique_ptr<mbgl::style::Layer> _pendingLayer;
    mapbox::base::WeakPtr<mbgl::style::Layer> _weakLayer;
}

- (instancetype)initWithRawLayer:(mbgl::style::Layer *)rawLayer {
    if (self = [super init]) {
        _identifier = @(rawLayer->getID().c_str());
        _weakLayer = rawLayer->makeWeakPtr();
        rawLayer->peer = LayerWrapper { self };
    }
    return self;
}

- (instancetype)initWithPendingLayer:(std::unique_ptr<mbgl::style::Layer>)pendingLayer {
    if (self = [self initWithRawLayer:pendingLayer.get()]) {
        _pendingLayer = std::move(pendingLayer);
    }
    return self;
}

- (mbgl::style::Layer *)rawLayer
{
    return _weakLayer.get();
}

- (void)addToStyle:(MHStyle *)style belowLayer:(MHStyleLayer *)otherLayer
{
    if (_pendingLayer == nullptr) {
        [NSException raise:MHRedundantLayerException
            format:@"This instance %@ was already added to %@. Adding the same layer instance " \
                    "to the style more than once is invalid.", self, style];
    }

    if (otherLayer) {
        const std::optional<std::string> belowLayerId{otherLayer.identifier.UTF8String};
        style.rawStyle->addLayer(std::move(_pendingLayer), belowLayerId);
    } else {
        style.rawStyle->addLayer(std::move(_pendingLayer));
    }
}

- (void)removeFromStyle:(MHStyle *)style
{
    if (self.rawLayer == style.rawStyle->getLayer(self.identifier.UTF8String)) {
        _pendingLayer = style.rawStyle->removeLayer(self.identifier.UTF8String);
    }
}

- (void)setVisible:(BOOL)visible
{
    MHAssertStyleLayerIsValid();

    mbgl::style::VisibilityType v = visible
    ? mbgl::style::VisibilityType::Visible
    : mbgl::style::VisibilityType::None;
    self.rawLayer->setVisibility(v);
}

- (BOOL)isVisible
{
    MHAssertStyleLayerIsValid();

    mbgl::style::VisibilityType v = self.rawLayer->getVisibility();
    return (v == mbgl::style::VisibilityType::Visible);
}

- (void)setMaximumZoomLevel:(float)maximumZoomLevel
{
    MHAssertStyleLayerIsValid();

    self.rawLayer->setMaxZoom(maximumZoomLevel);
}

- (float)maximumZoomLevel
{
    MHAssertStyleLayerIsValid();

    return self.rawLayer->getMaxZoom();
}

- (void)setMinimumZoomLevel:(float)minimumZoomLevel
{
    MHAssertStyleLayerIsValid();

    self.rawLayer->setMinZoom(minimumZoomLevel);
}

- (float)minimumZoomLevel
{
    MHAssertStyleLayerIsValid();

    return self.rawLayer->getMinZoom();
}

- (NSString *)description
{
    if (self.rawLayer) {
        return [NSString stringWithFormat:@"<%@: %p; identifier = %@; visible = %@>",
                NSStringFromClass([self class]), (void *)self, self.identifier,
                self.visible ? @"YES" : @"NO"];
    }
    else {
        return [NSString stringWithFormat:@"<%@: %p; identifier = %@; visible = NO>",
                NSStringFromClass([self class]), (void *)self, self.identifier];
    }
}

@end
