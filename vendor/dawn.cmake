# Dawn WebGPU Implementation Configuration

if(TARGET mbgl-vendor-dawn)
    return()
endif()

if(NOT MH_WITH_WEBGPU)
    return()
endif()

if(POLICY CMP0169)
    cmake_policy(SET CMP0169 OLD)
endif()

set(MH_DAWN_GIT_VERSION "v20251014.163906" CACHE STRING "Git ref (branch, tag, or commit) used when fetching Dawn")

message(STATUS "Configuring Dawn WebGPU implementation (${MH_DAWN_GIT_VERSION})")

set(_mln_dawn_source_dir "${PROJECT_SOURCE_DIR}/vendor/dawn")
set(_mln_dawn_binary_dir "${CMAKE_BINARY_DIR}/vendor/dawn/build")


if(EXISTS "${_mln_dawn_source_dir}/CMakeLists.txt")
    set(FETCHCONTENT_SOURCE_DIR_MAPHERO_DAWN ${_mln_dawn_source_dir})
endif()

include(FetchContent)

FetchContent_Declare(MAPHERO_dawn
    GIT_REPOSITORY https://github.com/google/dawn.git
    GIT_TAG ${MH_DAWN_GIT_VERSION}
    GIT_SUBMODULES ""
)

FetchContent_GetProperties(MAPHERO_dawn)
if(NOT MAPHERO_dawn_POPULATED)
    message(STATUS "Fetching Dawn sources into ${_mln_dawn_source_dir}")
    FetchContent_Populate(MAPHERO_dawn)

    if(NOT EXISTS "${_mln_dawn_source_dir}/CMakeLists.txt")
        file(REMOVE_RECURSE "${_mln_dawn_source_dir}")
        file(RENAME "${MAPHERO_dawn_SOURCE_DIR}" "${_mln_dawn_source_dir}")
        # Make future configure runs reuse the relocated checkout.
        set(FETCHCONTENT_SOURCE_DIR_MAPHERO_DAWN "${_mln_dawn_source_dir}" CACHE PATH "" FORCE)
    endif()
endif()

set(MAPHERO_dawn_SOURCE_DIR "${_mln_dawn_source_dir}")

set(DAWN_DIR "${_mln_dawn_source_dir}")
set(DAWN_BUILD_DIR "${_mln_dawn_binary_dir}")

# Configure Dawn the same way as the quickstart recommends.
set(DAWN_FETCH_DEPENDENCIES ON CACHE BOOL "Use Dawn's dependency bootstrapper" FORCE)
set(DAWN_ENABLE_INSTALL ON CACHE BOOL "Generate install targets for Dawn" FORCE)
set(DAWN_BUILD_SAMPLES OFF CACHE BOOL "Disable Dawn samples" FORCE)
set(DAWN_BUILD_TESTS OFF CACHE BOOL "Disable Dawn tests" FORCE)
set(DAWN_BUILD_BENCHMARKS OFF CACHE BOOL "Disable Dawn benchmarks" FORCE)
set(DAWN_BUILD_NODE_BINDINGS OFF CACHE BOOL "Disable Dawn Node bindings" FORCE)
set(DAWN_WERROR OFF CACHE BOOL "Disable -Werror in Dawn" FORCE)

if(NOT TARGET dawn::webgpu_dawn)
    if(APPLE)
        enable_language(OBJC OBJCXX)
    endif()
    add_subdirectory(${DAWN_DIR} ${DAWN_BUILD_DIR})
endif()

add_library(mbgl-vendor-dawn INTERFACE)

target_link_libraries(mbgl-vendor-dawn INTERFACE dawn::webgpu_dawn)

target_include_directories(mbgl-vendor-dawn
    SYSTEM INTERFACE
        ${DAWN_DIR}/include
        ${DAWN_BUILD_DIR}/gen/include
)

if(APPLE)
    target_compile_definitions(mbgl-vendor-dawn INTERFACE DAWN_ENABLE_BACKEND_METAL=1)
else()
    target_compile_definitions(mbgl-vendor-dawn INTERFACE DAWN_ENABLE_BACKEND_VULKAN=1)
endif()

target_compile_options(mbgl-vendor-dawn INTERFACE -Wno-strict-aliasing -Wno-error=strict-aliasing)

set_target_properties(
    mbgl-vendor-dawn
    PROPERTIES
        INTERFACE_MAPHERO_NAME "dawn"
        INTERFACE_MAPHERO_URL "https://dawn.googlesource.com/dawn"
        INTERFACE_MAPHERO_AUTHOR "Chromium Dawn Team"
        INTERFACE_MAPHERO_LICENSE "${PROJECT_SOURCE_DIR}/vendor/dawn/LICENSE"
)
