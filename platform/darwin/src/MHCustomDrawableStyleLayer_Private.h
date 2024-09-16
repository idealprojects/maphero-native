#pragma once

#include "MHStyleLayer_Private.h"

#include <mbgl/layermanager/custom_drawable_layer_factory.hpp>

namespace mbgl {

class CustomDrawableStyleLayerPeerFactory : public LayerPeerFactory, public mbgl::CustomDrawableLayerFactory {
    // LayerPeerFactory overrides.
    LayerFactory* getCoreLayerFactory() final { return this; }
    virtual MHStyleLayer* createPeer(style::Layer*) final;
};

} // namespace mbgl
