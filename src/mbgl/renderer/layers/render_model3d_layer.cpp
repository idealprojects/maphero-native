#include <mbgl/renderer/layers/render_model3d_layer.hpp>

#include <mbgl/gfx/backend_scope.hpp>
#include <mbgl/gfx/context.hpp>
#include <mbgl/gfx/drawable_builder.hpp>
#include <mbgl/gfx/drawable_custom_layer_host_tweaker.hpp>
#include <mbgl/renderer/layer_group.hpp>
#include <mbgl/renderer/layers/model3d_host.hpp>
#include <mbgl/renderer/paint_parameters.hpp>

namespace mbgl {

using namespace style;

namespace {

inline const Model3DLayer::Impl& impl(const Immutable<style::Layer::Impl>& impl) {
    assert(impl->getTypeInfo() == Model3DLayer::Impl::staticTypeInfo());
    return static_cast<const Model3DLayer::Impl&>(*impl);
}

} // namespace

RenderModel3DLayer::RenderModel3DLayer(Immutable<style::Model3DLayer::Impl> _impl)
    : RenderLayer(makeMutable<Model3DLayerProperties>(std::move(_impl))) {
    assert(gfx::BackendScope::exists());
    builtRevision = impl(baseImpl).revision;
    host = std::make_shared<Model3DHost>(impl(baseImpl).models);
    host->initialize();
}

RenderModel3DLayer::~RenderModel3DLayer() {
    assert(gfx::BackendScope::exists());
    if (host) {
        if (contextDestroyed) {
            host->contextLost();
        } else {
            host->deinitialize();
        }
    }
}

void RenderModel3DLayer::evaluate(const PropertyEvaluationParameters&) {
    passes = RenderPass::Translucent;
}

bool RenderModel3DLayer::hasTransition() const {
    return false;
}
bool RenderModel3DLayer::hasCrossfade() const {
    return false;
}

void RenderModel3DLayer::markContextDestroyed() {
    contextDestroyed = true;
}

void RenderModel3DLayer::prepare(const LayerPrepareParameters&) {}

void RenderModel3DLayer::update([[maybe_unused]] gfx::ShaderRegistry& shaders,
                                gfx::Context& context,
                                [[maybe_unused]] const TransformState& state,
                                const std::shared_ptr<UpdateParameters>&,
                                [[maybe_unused]] const RenderTree& renderTree,
                                [[maybe_unused]] UniqueChangeRequestVec& changes) {
    if (!layerGroup) {
        if (auto layerGroup_ = context.createLayerGroup(layerIndex, /*initialCapacity=*/1, getID())) {
            setLayerGroup(std::move(layerGroup_), changes);
        }
    }

    auto* localLayerGroup = static_cast<LayerGroup*>(layerGroup.get());

    // Rebuild the host when the layer's model list changed (setData bumps the revision).
    const bool modelsChanged = (builtRevision != impl(baseImpl).revision) || !host;
    if (modelsChanged) {
        if (host && !contextDestroyed) {
            host->deinitialize();
        }
        builtRevision = impl(baseImpl).revision;
        host = std::make_shared<Model3DHost>(impl(baseImpl).models);
        host->initialize();
    }

    if (localLayerGroup->getDrawableCount() == 0 || modelsChanged) {
        localLayerGroup->clearDrawables();

        auto tweaker = std::make_shared<gfx::DrawableCustomLayerHostTweaker>(host);

        std::unique_ptr<gfx::DrawableBuilder> builder = context.createDrawableBuilder(getID());
        auto& drawable = builder->getCurrentDrawable(true);
        drawable->setIsCustom(true);
        drawable->setRenderPass(RenderPass::Translucent);
        drawable->addTweaker(tweaker);

        localLayerGroup->addDrawable(std::move(drawable));
        ++stats.drawablesAdded;
    }
}

} // namespace mbgl
