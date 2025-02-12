#pragma once

#include <mbgl/renderer/render_layer.hpp>
#include <mbgl/style/layers/circle_layer_impl.hpp>
#include <mbgl/style/layers/circle_layer_properties.hpp>

namespace mbgl {

#if MH_LEGACY_RENDERER
class CircleProgram;
#endif // MH_LEGACY_RENDERER

#if MH_DRAWABLE_RENDERER
class CircleLayerTweaker;
using CircleLayerTweakerPtr = std::shared_ptr<CircleLayerTweaker>;
#endif // MH_DRAWABLE_RENDERER

class RenderCircleLayer final : public RenderLayer {
public:
    explicit RenderCircleLayer(Immutable<style::CircleLayer::Impl>);
    ~RenderCircleLayer() final = default;

#if MH_DRAWABLE_RENDERER
    /// Generate any changes needed by the layer
    void update(gfx::ShaderRegistry&,
                gfx::Context&,
                const TransformState&,
                const std::shared_ptr<UpdateParameters>&,
                const RenderTree&,
                UniqueChangeRequestVec&) override;
#endif

private:
    void transition(const TransitionParameters&) override;
    void evaluate(const PropertyEvaluationParameters&) override;
    bool hasTransition() const override;
    bool hasCrossfade() const override;

    bool queryIntersectsFeature(const GeometryCoordinates&,
                                const GeometryTileFeature&,
                                float,
                                const TransformState&,
                                float,
                                const mat4&,
                                const FeatureState&) const override;

#if MH_LEGACY_RENDERER
    void render(PaintParameters&) override;
#endif // MH_LEGACY_RENDERER

private:
    // Paint properties
    style::CirclePaintProperties::Unevaluated unevaluated;

#if MH_LEGACY_RENDERER
    // Programs
    std::shared_ptr<CircleProgram> circleProgram;
#endif

#if MH_DRAWABLE_RENDERER
    gfx::ShaderGroupPtr circleShaderGroup;
#endif
};

} // namespace mbgl
