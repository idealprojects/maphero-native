#pragma once

#include <mbgl/style/layers/custom_layer.hpp>
#include <mbgl/style/layers/model3d_layer.hpp>

#include <memory>
#include <vector>

namespace mbgl {

/**
 * The renderer behind the "model3d" style layer: draws glTF (.glb) models inside
 * the map's render pass through the CustomLayerHost mechanism (same plumbing the
 * public custom layers use, so it works identically on the OpenGL and Metal
 * backends).
 *
 * Conventions (identical to the long-verified Doroob implementations):
 *  - glTF node transforms are baked into vertex data at load time.
 *  - The fleet's CAD exports are Z-UP; model space (x-east, y-north, z-up) maps to
 *    map world (x-east px, y-south px, z-up meters), worldSize = 512 * 2^zoom,
 *    and the projection matrix's z column takes meters directly.
 *  - Models are auto-fitted: largest horizontal extent -> sizeMeters, footprint
 *    centered on the anchor, base grounded at z = 0.
 *  - Materials are solid colors (KHR_materials_pbrSpecularGlossiness diffuseFactor
 *    or pbrMetallicRoughness baseColorFactor).
 */
class Model3DHost final : public style::CustomLayerHost {
public:
    explicit Model3DHost(std::vector<style::Model3DEntry> entries);
    ~Model3DHost() override;

    void initialize() override;
    void render(const style::CustomLayerRenderParameters&) override;
    void contextLost() override;
    void deinitialize() override;

private:
    struct BackendState; // per-backend GPU objects, defined in the .cpp
    std::vector<style::Model3DEntry> entries_;
    std::unique_ptr<BackendState> state_;
    bool needSetup_ = true;
    int setupAttempts_ = 0;
};

} // namespace mbgl
