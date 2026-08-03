#include <mbgl/layermanager/model3d_layer_factory.hpp>

#include <mbgl/renderer/layers/render_model3d_layer.hpp>
#include <mbgl/style/conversion_impl.hpp>
#include <mbgl/style/layers/model3d_layer.hpp>
#include <mbgl/style/layers/model3d_layer_impl.hpp>

namespace mbgl {

const style::LayerTypeInfo* Model3DLayerFactory::getTypeInfo() const noexcept {
    return style::Model3DLayer::Impl::staticTypeInfo();
}

std::unique_ptr<style::Layer> Model3DLayerFactory::createLayer(
    const std::string& id, const style::conversion::Convertible& value) noexcept {
    auto layer = std::make_unique<style::Model3DLayer>(id);
    // "data" is a top-level member of the layer JSON (this layer has no source);
    // the generic layer conversion only routes layout/paint members, so parse it here.
    if (auto dataValue = objectMember(value, "data")) {
        layer->setProperty("data", *dataValue);
    }
    return layer;
}

std::unique_ptr<RenderLayer> Model3DLayerFactory::createRenderLayer(Immutable<style::Layer::Impl> impl) noexcept {
    return std::make_unique<RenderModel3DLayer>(staticImmutableCast<style::Model3DLayer::Impl>(impl));
}

} // namespace mbgl
