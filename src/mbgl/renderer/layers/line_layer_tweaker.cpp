#include <mbgl/renderer/layers/line_layer_tweaker.hpp>

#include <mbgl/gfx/context.hpp>
#include <mbgl/gfx/drawable.hpp>
#include <mbgl/gfx/line_drawable_data.hpp>
#include <mbgl/geometry/line_atlas.hpp>
#include <mbgl/programs/line_program.hpp>
#include <mbgl/renderer/image_atlas.hpp>
#include <mbgl/renderer/layer_group.hpp>
#include <mbgl/renderer/paint_parameters.hpp>
#include <mbgl/renderer/render_tile.hpp>
#include <mbgl/shaders/line_layer_ubo.hpp>
#include <mbgl/shaders/shader_program_base.hpp>
#include <mbgl/style/layers/line_layer_properties.hpp>
#include <mbgl/util/logging.hpp>
#include <mbgl/util/math.hpp>

#if MH_RENDER_BACKEND_METAL
#include <mbgl/shaders/mtl/line.hpp>
#endif // MH_RENDER_BACKEND_METAL

namespace mbgl {

using namespace style;
using namespace shaders;

#if MH_RENDER_BACKEND_METAL && !defined(NDEBUG)
constexpr bool diff(float actual, float expected, float e = 1.0e-6) {
    return actual != expected && (expected == 0 || std::fabs((actual - expected) / expected) > e);
}
constexpr bool diff(Color actual, Color expected, float e = 1.0e-6) {
    return diff(actual.r, expected.r, e) || diff(actual.g, expected.g, e) || diff(actual.b, expected.b, e) ||
           diff(actual.a, expected.a, e);
}
#endif // MH_RENDER_BACKEND_METAL

#if MH_RENDER_BACKEND_METAL && !defined(NDEBUG)
template <typename Result>
std::optional<Result> LineLayerTweaker::gpuEvaluate(
    [[maybe_unused]] const LinePaintProperties::PossiblyEvaluated& evaluated,
    const PaintParameters& parameters,
    const std::size_t index) const {
    if (const auto& gpu = gpuExpressions[index]) {
        const float effectiveZoom = (gpu->options & gfx::GPUOptions::IntegerZoom)
                                        ? parameters.state.getIntegerZoom()
                                        : static_cast<float>(parameters.state.getZoom());
        return gpu->template evaluate<Result>(effectiveZoom);
    }
    return {};
}
#endif // MH_RENDER_BACKEND_METAL

template <typename Property>
auto LineLayerTweaker::evaluate([[maybe_unused]] const PaintParameters& parameters) const {
    const auto& evaluated = static_cast<const LineLayerProperties&>(*evaluatedProperties).evaluated;

#if MH_RENDER_BACKEND_METAL && !defined(NDEBUG)
    constexpr auto index = propertyIndex<Property>();
    if (auto gpuValue = gpuEvaluate<typename Property::Type>(evaluated, parameters, index)) {
        assert(!diff(*gpuValue, evaluated.get<Property>().constantOr(Property::defaultValue())));
        return *gpuValue;
    }
#endif // MH_RENDER_BACKEND_METAL

    return evaluated.get<Property>().constantOr(Property::defaultValue());
}

void LineLayerTweaker::execute(LayerGroupBase& layerGroup, const PaintParameters& parameters) {
    auto& context = parameters.context;
    const auto& evaluated = static_cast<const LineLayerProperties&>(*evaluatedProperties).evaluated;
    const auto& crossfade = static_cast<const LineLayerProperties&>(*evaluatedProperties).crossfade;

    const auto& linePatternValue = evaluated.get<LinePattern>().constantOr(Faded<expression::Image>{"", ""});

    const auto zoom = static_cast<float>(parameters.state.getZoom());
    const auto intZoom = parameters.state.getIntegerZoom();

#if MH_RENDER_BACKEND_METAL
    const auto getExpressionBuffer = [&]() {
        const bool enableEval = gfx::Backend::getEnableGPUExpressionEval();
        if (!expressionUniformBuffer || (gpuExpressionsUpdated && enableEval)) {
            LineExpressionUBO exprUBO = {
                /* color = */ enableEval ? gpuExpressions[propertyIndex<LineColor>()].get() : nullptr,
                /* blur = */ enableEval ? gpuExpressions[propertyIndex<LineBlur>()].get() : nullptr,
                /* opacity = */ enableEval ? gpuExpressions[propertyIndex<LineOpacity>()].get() : nullptr,
                /* gapwidth = */ enableEval ? gpuExpressions[propertyIndex<LineGapWidth>()].get() : nullptr,
                /* offset = */ enableEval ? gpuExpressions[propertyIndex<LineOffset>()].get() : nullptr,
                /* width = */ enableEval ? gpuExpressions[propertyIndex<LineWidth>()].get() : nullptr,
                /* floorWidth = */ enableEval ? gpuExpressions[propertyIndex<LineFloorWidth>()].get() : nullptr,
            };
            context.emplaceOrUpdateUniformBuffer(expressionUniformBuffer, &exprUBO);
            gpuExpressionsUpdated = false;
        }
        return expressionUniformBuffer;
    };
#endif // MH_RENDER_BACKEND_METAL

    if (!evaluatedPropsUniformBuffer || propertiesUpdated) {
#if MH_RENDER_BACKEND_METAL
        expressionMask =
            !gfx::Backend::getEnableGPUExpressionEval()
                ? LineExpressionMask::None
                : ((gpuExpressions[propertyIndex<LineColor>()] ? LineExpressionMask::Color : LineExpressionMask::None) |
                   (gpuExpressions[propertyIndex<LineBlur>()] ? LineExpressionMask::Blur : LineExpressionMask::None) |
                   (gpuExpressions[propertyIndex<LineOpacity>()] ? LineExpressionMask::Opacity
                                                                 : LineExpressionMask::None) |
                   (gpuExpressions[propertyIndex<LineGapWidth>()] ? LineExpressionMask::GapWidth
                                                                  : LineExpressionMask::None) |
                   (gpuExpressions[propertyIndex<LineOffset>()] ? LineExpressionMask::Offset
                                                                : LineExpressionMask::None) |
                   (gpuExpressions[propertyIndex<LineWidth>()] ? LineExpressionMask::Width : LineExpressionMask::None) |
                   (gpuExpressions[propertyIndex<LineFloorWidth>()] ? LineExpressionMask::FloorWidth
                                                                    : LineExpressionMask::None));
        const LineEvaluatedPropsUBO propsUBO{
            /*color =*/(expressionMask & LineExpressionMask::Color) ? LineColor::defaultValue()
                                                                    : evaluate<LineColor>(parameters),
            /*blur =*/
            (expressionMask & LineExpressionMask::Blur) ? LineBlur::defaultValue() : evaluate<LineBlur>(parameters),
            /*opacity =*/
            (expressionMask & LineExpressionMask::Opacity) ? LineOpacity::defaultValue()
                                                           : evaluate<LineOpacity>(parameters),
            /*gapwidth =*/
            (expressionMask & LineExpressionMask::GapWidth) ? LineGapWidth::defaultValue()
                                                            : evaluate<LineGapWidth>(parameters),
            /*offset =*/
            (expressionMask & LineExpressionMask::Offset) ? LineOffset::defaultValue()
                                                          : evaluate<LineOffset>(parameters),
            /*width =*/
            (expressionMask & LineExpressionMask::Width) ? LineWidth::defaultValue() : evaluate<LineWidth>(parameters),
            /*floorwidth =*/
            (expressionMask & LineExpressionMask::FloorWidth) ? LineFloorWidth::defaultValue()
                                                              : evaluate<LineFloorWidth>(parameters),
            expressionMask,
            0};
#else
        const LineEvaluatedPropsUBO propsUBO{/*color =*/evaluate<LineColor>(parameters),
                                             /*blur =*/evaluate<LineBlur>(parameters),
                                             /*opacity =*/evaluate<LineOpacity>(parameters),
                                             /*gapwidth =*/evaluate<LineGapWidth>(parameters),
                                             /*offset =*/evaluate<LineOffset>(parameters),
                                             /*width =*/evaluate<LineWidth>(parameters),
                                             /*floorwidth =*/evaluate<LineFloorWidth>(parameters),
                                             LineExpressionMask::None,
                                             0};
#endif // MH_RENDER_BACKEND_METAL

        context.emplaceOrUpdateUniformBuffer(evaluatedPropsUniformBuffer, &propsUBO);
        propertiesUpdated = false;
    }
    auto& layerUniforms = layerGroup.mutableUniformBuffers();

    layerUniforms.set(idLineEvaluatedPropsUBO, evaluatedPropsUniformBuffer);

#if MH_RENDER_BACKEND_METAL
    // GPU Expressions
    layerUniforms.set(idLineExpressionUBO, getExpressionBuffer());
#endif // MH_RENDER_BACKEND_METAL

    visitLayerGroupDrawables(layerGroup, [&](gfx::Drawable& drawable) {
        const auto shader = drawable.getShader();
        if (!drawable.getTileID() || !shader || !checkTweakDrawable(drawable)) {
            return;
        }

        const UnwrappedTileID tileID = drawable.getTileID()->toUnwrapped();

        auto* binders = static_cast<LineProgram::Binders*>(drawable.getBinders());
        const auto* tile = drawable.getRenderTile();
        if (!binders || !tile) {
            assert(false);
            return;
        }

        const auto patternPosA = tile->getPattern(linePatternValue.from.id());
        const auto patternPosB = tile->getPattern(linePatternValue.to.id());
        binders->setPatternParameters(patternPosA, patternPosB, crossfade);

        const auto& translation = evaluated.get<LineTranslate>();
        const auto anchor = evaluated.get<LineTranslateAnchor>();
        constexpr bool nearClipped = false;
        constexpr bool inViewportPixelUnits = false; // from RenderTile::translatedMatrix
        const auto matrix = getTileMatrix(
            tileID, parameters, translation, anchor, nearClipped, inViewportPixelUnits, drawable);

        auto& drawableUniforms = drawable.mutableUniformBuffers();
        switch (static_cast<LineType>(drawable.getType())) {
            case LineType::Simple: {
                const LineDrawableUBO drawableUBO = {
                    /*matrix = */ util::cast<float>(matrix),
                    /*ratio = */ 1.0f / tileID.pixelsToTileUnits(1.0f, static_cast<float>(zoom)),
                    0,
                    0,
                    0};
                drawableUniforms.createOrUpdate(idLineDrawableUBO, &drawableUBO, context);

                const auto lineInterpolationUBO = LineInterpolationUBO{
                    /*color_t =*/std::get<0>(binders->get<LineColor>()->interpolationFactor(zoom)),
                    /*blur_t =*/std::get<0>(binders->get<LineBlur>()->interpolationFactor(zoom)),
                    /*opacity_t =*/std::get<0>(binders->get<LineOpacity>()->interpolationFactor(zoom)),
                    /*gapwidth_t =*/std::get<0>(binders->get<LineGapWidth>()->interpolationFactor(zoom)),
                    /*offset_t =*/std::get<0>(binders->get<LineOffset>()->interpolationFactor(zoom)),
                    /*width_t =*/std::get<0>(binders->get<LineWidth>()->interpolationFactor(zoom)),
                    0,
                    0};
                drawableUniforms.createOrUpdate(idLineInterpolationUBO, &lineInterpolationUBO, context);
            } break;

            case LineType::Gradient: {
                const LineGradientDrawableUBO drawableUBO = {
                    /*matrix = */ util::cast<float>(matrix),
                    /*ratio = */ 1.0f / tileID.pixelsToTileUnits(1.0f, static_cast<float>(zoom)),
                    0,
                    0,
                    0};
                drawableUniforms.createOrUpdate(idLineDrawableUBO, &drawableUBO, context);

                const auto lineGradientInterpolationUBO = LineGradientInterpolationUBO{
                    /*blur_t =*/std::get<0>(binders->get<LineBlur>()->interpolationFactor(zoom)),
                    /*opacity_t =*/std::get<0>(binders->get<LineOpacity>()->interpolationFactor(zoom)),
                    /*gapwidth_t =*/std::get<0>(binders->get<LineGapWidth>()->interpolationFactor(zoom)),
                    /*offset_t =*/std::get<0>(binders->get<LineOffset>()->interpolationFactor(zoom)),
                    /*width_t =*/std::get<0>(binders->get<LineWidth>()->interpolationFactor(zoom)),
                    0,
                    0,
                    0};
                drawableUniforms.createOrUpdate(idLineInterpolationUBO, &lineGradientInterpolationUBO, context);
            } break;

            case LineType::Pattern: {
                Size textureSize{0, 0};
                if (const auto& texture = drawable.getTexture(idLineImageTexture)) {
                    textureSize = texture->getSize();
                }
                const LinePatternDrawableUBO drawableUBO = {
                    /*matrix =*/util::cast<float>(matrix),
                    /*scale =*/
                    {parameters.pixelRatio,
                     1 / tileID.pixelsToTileUnits(1, intZoom),
                     crossfade.fromScale,
                     crossfade.toScale},
                    /*texsize =*/{static_cast<float>(textureSize.width), static_cast<float>(textureSize.height)},
                    /*ratio =*/1.0f / tileID.pixelsToTileUnits(1.0f, static_cast<float>(zoom)),
                    /*fade =*/crossfade.t};
                drawableUniforms.createOrUpdate(idLineDrawableUBO, &drawableUBO, context);

                const auto linePatternInterpolationUBO = LinePatternInterpolationUBO{
                    /*blur_t =*/std::get<0>(binders->get<LineBlur>()->interpolationFactor(zoom)),
                    /*opacity_t =*/std::get<0>(binders->get<LineOpacity>()->interpolationFactor(zoom)),
                    /*offset_t =*/std::get<0>(binders->get<LineOffset>()->interpolationFactor(zoom)),
                    /*gapwidth_t =*/std::get<0>(binders->get<LineGapWidth>()->interpolationFactor(zoom)),
                    /*width_t =*/std::get<0>(binders->get<LineWidth>()->interpolationFactor(zoom)),
                    /*pattern_from_t =*/std::get<0>(binders->get<LinePattern>()->interpolationFactor(zoom)),
                    /*pattern_to_t =*/std::get<1>(binders->get<LinePattern>()->interpolationFactor(zoom)),
                    0};
                drawableUniforms.createOrUpdate(idLineInterpolationUBO, &linePatternInterpolationUBO, context);

                const auto linePatternTilePropertiesUBO = LinePatternTilePropertiesUBO{
                    /*pattern_from =*/patternPosA ? util::cast<float>(patternPosA->tlbr()) : std::array<float, 4>{0},
                    /*pattern_to =*/patternPosB ? util::cast<float>(patternPosB->tlbr()) : std::array<float, 4>{0}};
                drawableUniforms.createOrUpdate(idLineTilePropertiesUBO, &linePatternTilePropertiesUBO, context);
            } break;

            case LineType::SDF: {
                if (const auto& data = drawable.getData()) {
                    const gfx::LineDrawableData& lineData = static_cast<const gfx::LineDrawableData&>(*data);
                    const auto& dashPatternTexture = parameters.lineAtlas.getDashPatternTexture(
                        evaluated.get<LineDasharray>().from,
                        evaluated.get<LineDasharray>().to,
                        lineData.linePatternCap);

                    // texture
                    if (!drawable.getTexture(idLineImageTexture)) {
                        const auto& texture = dashPatternTexture.getTexture();
                        drawable.setEnabled(!!texture);
                        if (texture) {
                            drawable.setTexture(texture, idLineImageTexture);
                        }
                    }

                    const LinePatternPos& posA = dashPatternTexture.getFrom();
                    const LinePatternPos& posB = dashPatternTexture.getTo();
                    const float widthA = posA.width * crossfade.fromScale;
                    const float widthB = posB.width * crossfade.toScale;
                    const LineSDFDrawableUBO drawableUBO{
                        /* matrix = */ util::cast<float>(matrix),
                        /* patternscale_a = */
                        {1.0f / tileID.pixelsToTileUnits(widthA, intZoom), -posA.height / 2.0f},
                        /* patternscale_b = */
                        {1.0f / tileID.pixelsToTileUnits(widthB, intZoom), -posB.height / 2.0f},
                        /* ratio = */ 1.0f / tileID.pixelsToTileUnits(1.0f, zoom),
                        /* tex_y_a = */ posA.y,
                        /* tex_y_b = */ posB.y,
                        /* sdfgamma = */ static_cast<float>(dashPatternTexture.getSize().width) /
                            (std::min(widthA, widthB) * 256.0f * parameters.pixelRatio) / 2.0f,
                        /* mix = */ crossfade.t,
                        0,
                        0,
                        0};
                    drawableUniforms.createOrUpdate(idLineDrawableUBO, &drawableUBO, context);

                    const auto lineSDFInterpolationUBO = LineSDFInterpolationUBO{
                        /*color_t =*/std::get<0>(binders->get<LineColor>()->interpolationFactor(zoom)),
                        /*blur_t =*/std::get<0>(binders->get<LineBlur>()->interpolationFactor(zoom)),
                        /*opacity_t =*/std::get<0>(binders->get<LineOpacity>()->interpolationFactor(zoom)),
                        /*gapwidth_t =*/std::get<0>(binders->get<LineGapWidth>()->interpolationFactor(zoom)),
                        /*offset_t =*/std::get<0>(binders->get<LineOffset>()->interpolationFactor(zoom)),
                        /*width_t =*/std::get<0>(binders->get<LineWidth>()->interpolationFactor(zoom)),
                        /*floorwidth_t =*/
                        std::get<0>(binders->get<LineFloorWidth>()->interpolationFactor(zoom)),
                        0};
                    drawableUniforms.createOrUpdate(idLineInterpolationUBO, &lineSDFInterpolationUBO, context);
                }
            } break;

            default: {
                Log::Error(Event::General,
                           "LineLayerTweaker: unknown line type: " + std::to_string(drawable.getType()));
            } break;
        }
    });
}

#if MH_RENDER_BACKEND_METAL
void LineLayerTweaker::updateGPUExpressions(const Unevaluated& unevaluated, TimePoint now) {
    if (gfx::Backend::getEnableGPUExpressionEval()) {
        if (unevaluated.updateGPUExpressions(gpuExpressions, now)) {
            gpuExpressionsUpdated = true;

            // Masks also need to be updated
            propertiesUpdated = true;
        }
    }
}

#endif // MH_RENDER_BACKEND_METAL

} // namespace mbgl
