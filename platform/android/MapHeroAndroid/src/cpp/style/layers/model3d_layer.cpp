#include "model3d_layer.hpp"

#include <mbgl/util/logging.hpp>

#include <string>

namespace mbgl {
namespace android {

Model3DLayer::Model3DLayer(jni::JNIEnv& env, const jni::String& layerId)
    : Layer(std::make_unique<mbgl::style::Model3DLayer>(jni::Make<std::string>(env, layerId))) {}

Model3DLayer::Model3DLayer(mbgl::style::Model3DLayer& coreLayer)
    : Layer(coreLayer) {}

Model3DLayer::Model3DLayer(std::unique_ptr<mbgl::style::Model3DLayer> coreLayer)
    : Layer(std::move(coreLayer)) {}

Model3DLayer::~Model3DLayer() = default;

void Model3DLayer::setData(jni::JNIEnv& env, const jni::String& json) {
    auto& coreLayer = static_cast<mbgl::style::Model3DLayer&>(get());
    if (auto error = coreLayer.setData(jni::Make<std::string>(env, json))) {
        mbgl::Log::Error(mbgl::Event::JNI, "Model3DLayer.setData failed: " + error->message);
    }
}

namespace {
jni::Local<jni::Object<Layer>> createJavaPeer(jni::JNIEnv& env, Layer* layer) {
    static auto& javaClass = jni::Class<Model3DLayer>::Singleton(env);
    static auto constructor = javaClass.GetConstructor<jni::jlong>(env);
    return javaClass.New(env, constructor, reinterpret_cast<jni::jlong>(layer));
}
} // namespace

Model3DJavaLayerPeerFactory::~Model3DJavaLayerPeerFactory() = default;

jni::Local<jni::Object<Layer>> Model3DJavaLayerPeerFactory::createJavaLayerPeer(jni::JNIEnv& env,
                                                                                mbgl::style::Layer& layer) {
    return createJavaPeer(env, new Model3DLayer(static_cast<mbgl::style::Model3DLayer&>(layer)));
}

jni::Local<jni::Object<Layer>> Model3DJavaLayerPeerFactory::createJavaLayerPeer(
    jni::JNIEnv& env, std::unique_ptr<mbgl::style::Layer> layer) {
    return createJavaPeer(env,
                          new Model3DLayer(std::unique_ptr<mbgl::style::Model3DLayer>(
                              static_cast<mbgl::style::Model3DLayer*>(layer.release()))));
}

void Model3DJavaLayerPeerFactory::registerNative(jni::JNIEnv& env) {
    // Lookup the class
    static auto& javaClass = jni::Class<Model3DLayer>::Singleton(env);

#define METHOD(MethodPtr, name) jni::MakeNativePeerMethod<decltype(MethodPtr), (MethodPtr)>(name)

    // Register the peer
    jni::RegisterNativePeer<Model3DLayer>(env,
                                          javaClass,
                                          "nativePtr",
                                          jni::MakePeer<Model3DLayer, const jni::String&>,
                                          "initialize",
                                          "finalize",
                                          METHOD(&Model3DLayer::setData, "nativeSetData"));
}

} // namespace android
} // namespace mbgl
