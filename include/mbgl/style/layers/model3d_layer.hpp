#pragma once

#include <mbgl/style/layer.hpp>

#include <string>
#include <vector>

namespace mbgl {
namespace style {

/**
 * One glTF (.glb) building model anchored to a map coordinate.
 *
 * Produced from a GeoJSON FeatureCollection of Point features:
 *  - geometry:   the anchor (lng, lat)
 *  - properties: "path"    (string, required) absolute filesystem path or file:// URI of the .glb
 *                "heading" (number, optional) rotation around the up axis, degrees
 *                "size"    (number, optional) largest horizontal extent the model is
 *                          auto-fitted to, in meters (default 180)
 */
struct Model3DEntry {
    double latitude = 0;
    double longitude = 0;
    double headingDegrees = 0;
    double sizeMeters = 0; // 0 -> renderer default
    std::string path;
};

/**
 * A style layer that renders glTF (.glb) models inside the map's own render pass
 * (fill-extrusion-like). The models are true map geometry: depth-tested against
 * 3D layers, hidden by the standard minzoom/maxzoom/visibility mechanisms.
 *
 * Style JSON:
 *   { "id": "models", "type": "model3d",
 *     "maxzoom": 16.5,
 *     "data": { "type": "FeatureCollection", "features": [
 *        { "type": "Feature",
 *          "properties": { "path": "file:///.../mall.glb", "heading": 132, "size": 180 },
 *          "geometry": { "type": "Point", "coordinates": [35.19267, 31.93617] } } ] } }
 *
 * Runtime: construct with an id, then setData() with the FeatureCollection JSON.
 */
class Model3DLayer final : public Layer {
public:
    explicit Model3DLayer(const std::string& layerID);
    ~Model3DLayer() override;

    /// Replaces the rendered models with the Point features of the given
    /// GeoJSON FeatureCollection (see Model3DEntry for the recognized properties).
    /// Returns an error description if the JSON could not be parsed.
    std::optional<conversion::Error> setData(const std::string& geoJSON);

    const std::vector<Model3DEntry>& getModels() const;

    class Impl;
    const Impl& impl() const;
    Mutable<Impl> mutableImpl() const;

    Model3DLayer(Immutable<Impl>);
    std::unique_ptr<Layer> cloneRef(const std::string& id) const final;

protected:
    // Supports the "data" property so the layer is fully definable from JSON.
    std::optional<conversion::Error> setPropertyInternal(const std::string& name,
                                                         const conversion::Convertible& value) final;
    StyleProperty getProperty(const std::string&) const final;
    Mutable<Layer::Impl> mutableBaseImpl() const final;
};

} // namespace style
} // namespace mbgl
