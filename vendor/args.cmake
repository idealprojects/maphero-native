if(TARGET mbgl-vendor-args)
    return()
endif()

add_library(
    mbgl-vendor-args INTERFACE
)

target_include_directories(
    mbgl-vendor-args SYSTEM
    INTERFACE ${CMAKE_CURRENT_LIST_DIR}/args
)

set_target_properties(
    mbgl-vendor-args
    PROPERTIES
        INTERFACE_MAPHERO_NAME "args"
        INTERFACE_MAPHERO_URL "https://github.com/Taywee/args"
        INTERFACE_MAPHERO_AUTHOR "Taylor C. Richberger"
        INTERFACE_MAPHERO_LICENSE ${CMAKE_CURRENT_LIST_DIR}/args/LICENSE
)
