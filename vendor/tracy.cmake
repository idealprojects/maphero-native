if (MH_USE_TRACY)
    add_definitions(-DTRACY_ENABLE)
    add_definitions(-DMH_TRACY_ENABLE)
else()
    return()
endif()

include(FetchContent)

FetchContent_Declare(
    tracy
    GIT_REPOSITORY "https://github.com/wolfpld/tracy.git"
    GIT_TAG master
    GIT_SHALLOW TRUE
    GIT_PROGRESS TRUE
)

FetchContent_MakeAvailable(tracy)

set_target_properties(
    TracyClient
    PROPERTIES
        INTERFACE_MAPHERO_NAME "Tracy profiler"
        INTERFACE_MAPHERO_URL "https://github.com/wolfpld/tracy.git"
        INTERFACE_MAPHERO_AUTHOR "Bartosz Taudul"
        INTERFACE_MAPHERO_LICENSE ${CMAKE_CURRENT_LIST_DIR}/tracy/LICENSE
)
