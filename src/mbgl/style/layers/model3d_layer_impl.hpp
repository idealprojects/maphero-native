#pragma once

#include <mbgl/style/layers/model3d_layer.hpp>
#include <mbgl/style/layer_impl.hpp>
#include <mbgl/style/layer_properties.hpp>

#include <cstdint>
#include <vector>

namespace mbgl {
namespace style {

class Model3DLayer::Impl : public Layer::Impl {
public:
    Impl(const std::string& id);
    Impl(const Impl&) = default;

    bool hasLayoutDifference(const Layer::Impl&) const override;
    void stringifyLayout(rapidjson::Writer<rapidjson::StringBuffer>&) const override;

    std::vector<Model3DEntry> models;
    // Bumped on every setData; the render layer rebuilds its GPU resources
    // when the revision it built from no longer matches.
    uint64_t revision = 0;

    DECLARE_LAYER_TYPE_INFO;
};

class Model3DLayerProperties final : public LayerProperties {
public:
    explicit Model3DLayerProperties(Immutable<Model3DLayer::Impl> impl)
        : LayerProperties(std::move(impl)) {}

    expression::Dependency getDependencies() const noexcept override { return expression::Dependency::None; }
};

} // namespace style
} // namespace mbgl
