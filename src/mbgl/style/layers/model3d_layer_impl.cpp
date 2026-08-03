#include <mbgl/style/layers/model3d_layer_impl.hpp>

namespace mbgl {
namespace style {

Model3DLayer::Impl::Impl(const std::string& id_)
    : Layer::Impl(id_, std::string()) {}

bool Model3DLayer::Impl::hasLayoutDifference(const Layer::Impl& other) const {
    assert(other.getTypeInfo() == getTypeInfo());
    const auto& otherImpl = static_cast<const Model3DLayer::Impl&>(other);
    return revision != otherImpl.revision;
}

void Model3DLayer::Impl::stringifyLayout(rapidjson::Writer<rapidjson::StringBuffer>&) const {}

} // namespace style
} // namespace mbgl
