#include <mbgl/style/image.hpp>
#include <mbgl/style/image_impl.hpp>
#include <mbgl/style/layer.hpp>
#include <mbgl/style/light.hpp>
#include <mbgl/style/source.hpp>
#include <mbgl/style/style.hpp>
#include <mbgl/style/style_impl.hpp>
#include <mbgl/util/instrumentation.hpp>

namespace mbgl {
namespace style {

Style::Style(std::shared_ptr<FileSource> fileSource, float pixelRatio, const TaggedScheduler& threadPool_)
    : impl(std::make_unique<Impl>(std::move(fileSource), pixelRatio, threadPool_)) {}

Style::~Style() = default;

void Style::loadJSON(const std::string& json) {
    MH_TRACE_FUNC();

    impl->loadJSON(json);
}

void Style::loadURL(const std::string& url) {
    MH_TRACE_FUNC();

    impl->loadURL(url);
}

std::string Style::getJSON() const {
    MH_TRACE_FUNC();

    return impl->getJSON();
}

std::string Style::getURL() const {
    MH_TRACE_FUNC();

    return impl->getURL();
}

std::string Style::getName() const {
    return impl->getName();
}

CameraOptions Style::getDefaultCamera() const {
    MH_TRACE_FUNC();

    return impl->getDefaultCamera();
}

TransitionOptions Style::getTransitionOptions() const {
    MH_TRACE_FUNC();

    return impl->getTransitionOptions();
}

void Style::setTransitionOptions(const TransitionOptions& options) {
    MH_TRACE_FUNC();

    impl->mutated = true;
    impl->setTransitionOptions(options);
}

void Style::setLight(std::unique_ptr<Light> light) {
    impl->setLight(std::move(light));
}

Light* Style::getLight() {
    impl->mutated = true;
    return impl->getLight();
}

const Light* Style::getLight() const {
    return impl->getLight();
}

std::optional<Image> Style::getImage(const std::string& name) const {
    MH_TRACE_FUNC();

    auto image = impl->getImage(name);
    if (!image) return std::nullopt;
    return style::Image(std::move(*image));
}

void Style::addImage(std::unique_ptr<Image> image) {
    MH_TRACE_FUNC();

    impl->mutated = true;
    impl->addImage(std::move(image));
}

void Style::removeImage(const std::string& name) {
    MH_TRACE_FUNC();

    impl->mutated = true;
    impl->removeImage(name);
}

std::vector<Source*> Style::getSources() {
    MH_TRACE_FUNC();

    impl->mutated = true;
    return impl->getSources();
}

std::vector<const Source*> Style::getSources() const {
    MH_TRACE_FUNC();

    return const_cast<const Impl&>(*impl).getSources();
}

Source* Style::getSource(const std::string& id) {
    MH_TRACE_FUNC();

    impl->mutated = true;
    return impl->getSource(id);
}

const Source* Style::getSource(const std::string& id) const {
    MH_TRACE_FUNC();

    return impl->getSource(id);
}

void Style::addSource(std::unique_ptr<Source> source) {
    MH_TRACE_FUNC();

    impl->mutated = true;
    impl->addSource(std::move(source));
}

std::unique_ptr<Source> Style::removeSource(const std::string& sourceID) {
    MH_TRACE_FUNC();

    impl->mutated = true;
    return impl->removeSource(sourceID);
}

std::vector<Layer*> Style::getLayers() {
    MH_TRACE_FUNC();

    impl->mutated = true;
    return impl->getLayers();
}

std::vector<const Layer*> Style::getLayers() const {
    MH_TRACE_FUNC();

    return const_cast<const Impl&>(*impl).getLayers();
}

Layer* Style::getLayer(const std::string& layerID) {
    MH_TRACE_FUNC();

    impl->mutated = true;
    return impl->getLayer(layerID);
}

const Layer* Style::getLayer(const std::string& layerID) const {
    MH_TRACE_FUNC();

    return impl->getLayer(layerID);
}

void Style::addLayer(std::unique_ptr<Layer> layer, const std::optional<std::string>& before) {
    MH_TRACE_FUNC();

    impl->mutated = true;
    impl->addLayer(std::move(layer), before);
}

std::unique_ptr<Layer> Style::removeLayer(const std::string& id) {
    MH_TRACE_FUNC();

    impl->mutated = true;
    return impl->removeLayer(id);
}

} // namespace style
} // namespace mbgl
