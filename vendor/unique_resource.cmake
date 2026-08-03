if(TARGET mbgl-vendor-unique_resource)
    return()
endif()

add_library(
    mbgl-vendor-unique_resource INTERFACE
)

target_include_directories(
    mbgl-vendor-unique_resource SYSTEM
    INTERFACE ${CMAKE_CURRENT_LIST_DIR}/unique_resource
)

set_target_properties(
    mbgl-vendor-unique_resource
    PROPERTIES
        INTERFACE_MAPHERO_NAME "unique_resource"
        INTERFACE_MAPHERO_URL "https://github.com/okdshin/unique_resource"
        INTERFACE_MAPHERO_AUTHOR "Shintarou Okada"
        INTERFACE_MAPHERO_LICENSE ${CMAKE_CURRENT_LIST_DIR}/unique_resource/LICENSE.txt
)
