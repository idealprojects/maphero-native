if(TARGET mbgl-vendor-pmtiles)
    return()
endif()

add_library(
    mbgl-vendor-pmtiles INTERFACE
)

target_include_directories(
    mbgl-vendor-pmtiles SYSTEM
    INTERFACE ${CMAKE_CURRENT_LIST_DIR}/PMTiles/cpp
)

set_target_properties(
    mbgl-vendor-pmtiles
    PROPERTIES
        INTERFACE_MAPHERO_NAME "pmtiles"
        INTERFACE_MAPHERO_URL "https://github.com/protomaps/PMTiles"
        INTERFACE_MAPHERO_AUTHOR "Protomaps LLC"
        INTERFACE_MAPHERO_LICENSE ${CMAKE_CURRENT_LIST_DIR}/PMTiles/LICENSE
)
