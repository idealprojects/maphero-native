if(TARGET mbgl-vendor-supercluster)
    return()
endif()

add_library(mbgl-vendor-supercluster INTERFACE)

target_include_directories(
    mbgl-vendor-supercluster SYSTEM
    INTERFACE ${CMAKE_CURRENT_LIST_DIR}/supercluster/include
)

set_target_properties(
    mbgl-vendor-supercluster
    PROPERTIES
        INTERFACE_MAPHERO_NAME "supercluster.hpp"
        INTERFACE_MAPHERO_URL "https://github.com/mapbox/supercluster.hpp"
        INTERFACE_MAPHERO_AUTHOR "Mapbox"
        INTERFACE_MAPHERO_LICENSE ${CMAKE_CURRENT_LIST_DIR}/supercluster/LICENSE
)
