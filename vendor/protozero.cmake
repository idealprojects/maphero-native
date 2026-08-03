if(TARGET mbgl-vendor-protozero)
    return()
endif()

add_library(
    mbgl-vendor-protozero INTERFACE
)

target_include_directories(
    mbgl-vendor-protozero SYSTEM
    INTERFACE ${CMAKE_CURRENT_LIST_DIR}/protozero/include
)

set_target_properties(
    mbgl-vendor-protozero
    PROPERTIES
        INTERFACE_MAPHERO_NAME "protozero"
        INTERFACE_MAPHERO_URL "https://github.com/mapbox/protozero"
        INTERFACE_MAPHERO_AUTHOR "Mapbox"
        INTERFACE_MAPHERO_LICENSE ${CMAKE_CURRENT_LIST_DIR}/protozero/LICENSE.md
)
