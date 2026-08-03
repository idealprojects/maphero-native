if(TARGET mbgl-vendor-kdbush)
    return()
endif()

add_library(
    mbgl-vendor-kdbush INTERFACE
)

target_include_directories(
    mbgl-vendor-kdbush SYSTEM
    INTERFACE ${CMAKE_CURRENT_LIST_DIR}/kdbush.hpp/include
)

set_target_properties(
    mbgl-vendor-kdbush
    PROPERTIES
        INTERFACE_MAPHERO_NAME "kdbush.hpp"
        INTERFACE_MAPHERO_URL "https://github.com/mourner/kdbush.hpp"
        INTERFACE_MAPHERO_AUTHOR "Vladimir Agafonkin"
        INTERFACE_MAPHERO_LICENSE ${CMAKE_CURRENT_LIST_DIR}/kdbush.hpp/LICENSE
)
