#pragma once

#include <jni/jni.hpp>
#include <mbgl/style/layers/model3d_layer.hpp>
#include <mbgl/layermanager/model3d_layer_factory.hpp>
#include "layer.hpp"

namespace mbgl {
namespace android {

class Model3DLayer : public Layer {
public:
    using SuperTag = Layer;
    static constexpr auto Name() { return "org/maphero/android/style/layers/Model3DLayer"; };

    static void registerNative(jni::JNIEnv&);

    Model3DLayer(jni::JNIEnv&, const jni::String&);
    Model3DLayer(mbgl::style::Model3DLayer&);
    Model3DLayer(std::unique_ptr<mbgl::style::Model3DLayer>);
    ~Model3DLayer();

    void setData(jni::JNIEnv&, const jni::String&);

    jni::Local<jni::Object<Layer>> createJavaPeer(jni::JNIEnv&);
}; // class Model3DLayer

class Model3DJavaLayerPeerFactory final : public JavaLayerPeerFactory, public mbgl::Model3DLayerFactory {
public:
    ~Model3DJavaLayerPeerFactory() override;

    // JavaLayerPeerFactory overrides.
    jni::Local<jni::Object<Layer>> createJavaLayerPeer(jni::JNIEnv&, mbgl::style::Layer&) final;
    jni::Local<jni::Object<Layer>> createJavaLayerPeer(jni::JNIEnv& env, std::unique_ptr<mbgl::style::Layer>) final;

    void registerNative(jni::JNIEnv&) final;

    LayerFactory* getLayerFactory() final { return this; }

}; // class Model3DJavaLayerPeerFactory

} // namespace android
} // namespace mbgl
