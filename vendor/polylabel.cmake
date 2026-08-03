if(TARGET mbgl-vendor-polylabel)
    return()
endif()

add_library(
    mbgl-vendor-polylabel INTERFACE
)

target_include_directories(
    mbgl-vendor-polylabel SYSTEM
    INTERFACE ${CMAKE_CURRENT_LIST_DIR}/polylabel/include
)

set_target_properties(
    mbgl-vendor-polylabel
    PROPERTIES
        INTERFACE_MAPHERO_NAME "polylabel"
        INTERFACE_MAPHERO_URL "https://github.com/mapbox/polylabel"
        INTERFACE_MAPHERO_AUTHOR "Mapbox"
        INTERFACE_MAPHERO_LICENSE ${CMAKE_CURRENT_LIST_DIR}/polylabel/LICENSE
)
