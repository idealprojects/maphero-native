#include "maplibre.hpp"

namespace mbgl {
namespace android {

jni::Local<jni::Object<AssetManager>> MapHero::getAssetManager(jni::JNIEnv& env) {
    static auto& javaClass = jni::Class<MapHero>::Singleton(env);
    auto method = javaClass.GetStaticMethod<jni::Object<AssetManager>()>(env, "getAssetManager");
    return javaClass.Call(env, method);
}

jboolean MapHero::hasInstance(jni::JNIEnv& env) {
    static auto& javaClass = jni::Class<MapHero>::Singleton(env);
    auto method = javaClass.GetStaticMethod<jboolean()>(env, "hasInstance");
    return javaClass.Call(env, method);
}

void MapHero::registerNative(jni::JNIEnv& env) {
    jni::Class<MapHero>::Singleton(env);
}

} // namespace android
} // namespace mbgl
