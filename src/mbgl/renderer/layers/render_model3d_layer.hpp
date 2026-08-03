#pragma once

#include <mbgl/renderer/render_layer.hpp>
#include <mbgl/style/layers/custom_layer.hpp>
#include <mbgl/style/layers/model3d_layer_impl.hpp>

namespace mbgl {

class Model3DHost;

class RenderModel3DLayer final : public RenderLayer {
public:
    explicit RenderModel3DLayer(Immutable<style::Model3DLayer::Impl>);
    ~RenderModel3DLayer() override;

    void update(gfx::ShaderRegistry&,
                gfx::Context&,
                const TransformState&,
                const std::shared_ptr<UpdateParameters>&,
                const RenderTree&,
                UniqueChangeRequestVec&) override;

private:
    void transition(const TransitionParameters&) override {}
    void evaluate(const PropertyEvaluationParameters&) override;
    bool hasTransition() const override;
    bool hasCrossfade() const override;
    void markContextDestroyed() override;
    void prepare(const LayerPrepareParameters&) override;

    bool contextDestroyed = false;
    // Revision of the style impl the current host was built from.
    uint64_t builtRevision = 0;
    std::shared_ptr<style::CustomLayerHost> host;
};

} // namespace mbgl
