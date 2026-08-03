#pragma once

#include "MHStyleLayer_Private.h"

#include <mbgl/layermanager/model3d_layer_factory.hpp>

namespace mbgl {

class Model3DStyleLayerPeerFactory : public LayerPeerFactory, public mbgl::Model3DLayerFactory {
    // LayerPeerFactory overrides.
    LayerFactory* getCoreLayerFactory() final { return this; }
    virtual MHStyleLayer* createPeer(style::Layer*) final;
};

} // namespace mbgl
