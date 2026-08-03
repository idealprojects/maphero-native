#include <mbgl/style/layers/model3d_layer.hpp>
#include <mbgl/style/layers/model3d_layer_impl.hpp>
#include <mbgl/style/conversion/geojson.hpp>
#include <mbgl/style/conversion/json.hpp>
#include <mbgl/style/conversion_impl.hpp>
#include <mbgl/style/layer_observer.hpp>
#include <mbgl/util/geojson.hpp>
#include <mbgl/util/logging.hpp>

namespace mbgl {
namespace style {

namespace {

const LayerTypeInfo typeInfoModel3D{"model3d",
                                    LayerTypeInfo::Source::NotRequired,
                                    LayerTypeInfo::Pass3D::NotRequired,
                                    LayerTypeInfo::Layout::NotRequired,
                                    LayerTypeInfo::FadingTiles::NotRequired,
                                    LayerTypeInfo::CrossTileIndex::NotRequired,
                                    LayerTypeInfo::TileKind::NotRequired};

double numericProperty(const mapbox::feature::property_map& properties, const char* key, double fallback) {
    auto it = properties.find(key);
    if (it == properties.end()) return fallback;
    const auto& v = it->second;
    if (v.is<double>()) return v.get<double>();
    if (v.is<std::int64_t>()) return static_cast<double>(v.get<std::int64_t>());
    if (v.is<std::uint64_t>()) return static_cast<double>(v.get<std::uint64_t>());
    return fallback;
}

void appendEntriesFromFeature(const mapbox::feature::feature<double>& feature, std::vector<Model3DEntry>& out) {
    if (!feature.geometry.is<mapbox::geometry::point<double>>()) {
        Log::Warning(Event::Style, "model3d: skipping feature with non-Point geometry");
        return;
    }
    auto pathIt = feature.properties.find("path");
    if (pathIt == feature.properties.end() || !pathIt->second.is<std::string>()) {
        Log::Warning(Event::Style, "model3d: skipping feature without a string \"path\" property");
        return;
    }
    const auto& point = feature.geometry.get<mapbox::geometry::point<double>>();
    Model3DEntry entry;
    entry.longitude = point.x;
    entry.latitude = point.y;
    entry.path = pathIt->second.get<std::string>();
    entry.headingDegrees = numericProperty(feature.properties, "heading", 0.0);
    entry.sizeMeters = numericProperty(feature.properties, "size", 0.0);
    // The renderer reads plain filesystem paths; accept file:// URIs for convenience.
    static const std::string fileScheme = "file://";
    if (entry.path.compare(0, fileScheme.size(), fileScheme) == 0) {
        entry.path = entry.path.substr(fileScheme.size());
    }
    out.push_back(std::move(entry));
}

std::vector<Model3DEntry> entriesFromGeoJSON(const GeoJSON& geoJSON) {
    std::vector<Model3DEntry> entries;
    if (geoJSON.is<mapbox::feature::feature_collection<double>>()) {
        for (const auto& feature : geoJSON.get<mapbox::feature::feature_collection<double>>()) {
            appendEntriesFromFeature(feature, entries);
        }
    } else if (geoJSON.is<mapbox::feature::feature<double>>()) {
        appendEntriesFromFeature(geoJSON.get<mapbox::feature::feature<double>>(), entries);
    } else {
        Log::Warning(Event::Style, "model3d: data must be a FeatureCollection (or a single Feature)");
    }
    return entries;
}

} // namespace

Model3DLayer::Model3DLayer(const std::string& layerID)
    : Layer(makeMutable<Impl>(layerID)) {}

Model3DLayer::Model3DLayer(Immutable<Impl> impl_)
    : Layer(std::move(impl_)) {}

Model3DLayer::~Model3DLayer() = default;

const Model3DLayer::Impl& Model3DLayer::impl() const {
    return static_cast<const Impl&>(*baseImpl);
}

Mutable<Model3DLayer::Impl> Model3DLayer::mutableImpl() const {
    return makeMutable<Impl>(impl());
}

std::unique_ptr<Layer> Model3DLayer::cloneRef(const std::string& id_) const {
    auto impl_ = mutableImpl();
    impl_->id = id_;
    return std::make_unique<Model3DLayer>(std::move(impl_));
}

const std::vector<Model3DEntry>& Model3DLayer::getModels() const {
    return impl().models;
}

std::optional<conversion::Error> Model3DLayer::setData(const std::string& geoJSON) {
    conversion::Error error;
    std::optional<GeoJSON> converted = conversion::convertJSON<GeoJSON>(geoJSON, error);
    if (!converted) {
        return error;
    }
    auto impl_ = mutableImpl();
    impl_->models = entriesFromGeoJSON(*converted);
    impl_->revision++;
    baseImpl = std::move(impl_);
    observer->onLayerChanged(*this);
    return std::nullopt;
}

using namespace conversion;

std::optional<Error> Model3DLayer::setPropertyInternal(const std::string& name, const Convertible& value) {
    if (name == "data") {
        Error error;
        std::optional<GeoJSON> converted = convert<GeoJSON>(value, error);
        if (!converted) {
            return error;
        }
        auto impl_ = mutableImpl();
        impl_->models = entriesFromGeoJSON(*converted);
        impl_->revision++;
        baseImpl = std::move(impl_);
        observer->onLayerChanged(*this);
        return std::nullopt;
    }
    return Error{"layer doesn't support this property"};
}

StyleProperty Model3DLayer::getProperty(const std::string&) const {
    return {};
}

Mutable<Layer::Impl> Model3DLayer::mutableBaseImpl() const {
    return staticMutableCast<Layer::Impl>(mutableImpl());
}

// static
const LayerTypeInfo* Model3DLayer::Impl::staticTypeInfo() noexcept {
    return &typeInfoModel3D;
}

} // namespace style
} // namespace mbgl
