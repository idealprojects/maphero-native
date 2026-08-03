add_library(maplibre-native-base INTERFACE)
add_library(MapHeroNative::Base ALIAS maplibre-native-base)

target_include_directories(maplibre-native-base SYSTEM INTERFACE
    "${PROJECT_SOURCE_DIR}/include"
)
