enable_language(OBJC OBJCXX Swift)

target_link_libraries(
    mbgl-core
    PRIVATE
        "-framework CoreGraphics"
        "-framework CoreLocation"
        "-framework CoreImage"
        "-framework SystemConfiguration"
        mbgl-vendor-icu
        sqlite3
        z
)

if(TARGET mbgl-vendor-dawn)
    target_link_libraries(
        mbgl-vendor-dawn
        INTERFACE
            "-framework Metal"
            "-framework QuartzCore"
            "-framework IOKit"
            "-framework IOSurface"
            "-framework CoreGraphics"
    )
endif()

if(MH_DARWIN_USE_LIBUV)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(LIBUV REQUIRED IMPORTED_TARGET libuv)

    target_link_libraries(mbgl-core
        PRIVATE
            PkgConfig::LIBUV
    )
endif()

target_sources(
    mbgl-core
    PRIVATE
        $<$<BOOL:${MH_DARWIN_USE_LIBUV}>:
            ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/async_task.cpp
            ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/run_loop.cpp
            ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/timer.cpp
        >

        $<$<NOT:$<BOOL:${MH_DARWIN_USE_LIBUV}>>:
            ${PROJECT_SOURCE_DIR}/platform/darwin/core/async_task.cpp
            ${PROJECT_SOURCE_DIR}/platform/darwin/core/run_loop.cpp
            ${PROJECT_SOURCE_DIR}/platform/darwin/core/timer.cpp
        >

        ${PROJECT_SOURCE_DIR}/platform/darwin/core/collator.mm
        ${PROJECT_SOURCE_DIR}/platform/darwin/core/http_file_source.mm
        ${PROJECT_SOURCE_DIR}/platform/darwin/core/image.mm
        ${PROJECT_SOURCE_DIR}/platform/darwin/core/local_glyph_rasterizer.mm
        ${PROJECT_SOURCE_DIR}/platform/darwin/core/logging_nslog.mm
        ${PROJECT_SOURCE_DIR}/platform/darwin/core/native_apple_interface.m
        ${PROJECT_SOURCE_DIR}/platform/darwin/core/nsthread.mm
        ${PROJECT_SOURCE_DIR}/platform/darwin/core/number_format.mm
        ${PROJECT_SOURCE_DIR}/platform/darwin/core/string_nsstring.mm
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/gfx/headless_backend.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/gfx/headless_frontend.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/layermanager/layer_manager.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/map/map_snapshotter.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/platform/time.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/asset_file_source.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/mbtiles_file_source.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/database_file_source.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/file_source_manager.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/file_source_request.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/local_file_request.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/local_file_source.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/main_resource_loader.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/offline.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/offline_database.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/offline_download.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/online_file_source.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/$<IF:$<BOOL:${MH_WITH_PMTILES}>,pmtiles_file_source.cpp,pmtiles_file_source_stub.cpp>
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/storage/sqlite3.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/text/bidi.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/compression.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/filesystem.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/monotonic_timer.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/png_writer.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/thread_local.cpp
        ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/util/utf.cpp
)

target_include_directories(
    mbgl-core
    PUBLIC
        ${PROJECT_SOURCE_DIR}/platform/darwin/include
        ${PROJECT_SOURCE_DIR}/platform/default/include
    PRIVATE
        ${PROJECT_SOURCE_DIR}/platform/darwin/src ${PROJECT_SOURCE_DIR}/platform/macos/src
)

if(MH_WITH_METAL)
    target_sources(
        mbgl-core
        PRIVATE
            ${PROJECT_SOURCE_DIR}/platform/default/src/mbgl/mtl/headless_backend.cpp
    )
endif()

include(${PROJECT_SOURCE_DIR}/vendor/icu.cmake)

set(CMAKE_OBJC_FLAGS "-fobjc-arc")
set(CMAKE_OBJCXX_FLAGS "-fobjc-arc")

set(MH_GENERATED_DARWIN_CODE_DIR
    ${CMAKE_BINARY_DIR}/generated-darwin-code/src
)

set(MH_GENERATED_DARWIN_STYLE_SOURCE
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHLight.mm"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHBackgroundStyleLayer.mm"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHCircleStyleLayer.mm"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHFillExtrusionStyleLayer.mm"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHFillStyleLayer.mm"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHHeatmapStyleLayer.mm"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHHillshadeStyleLayer.mm"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHLineStyleLayer.mm"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHRasterStyleLayer.mm"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHSymbolStyleLayer.mm"
)

set(MH_GENERATED_DARWIN_STYLE_PUBLIC_HEADERS
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHBackgroundStyleLayer.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHFillExtrusionStyleLayer.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHHeatmapStyleLayer.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHLight.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHLineStyleLayer.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHSymbolStyleLayer.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHCircleStyleLayer.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHFillStyleLayer.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHHillshadeStyleLayer.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHRasterStyleLayer.h"
)

set(MH_GENERATED_DARWIN_STYLE_HEADERS
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHRasterStyleLayer_Private.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHBackgroundStyleLayer_Private.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHFillExtrusionStyleLayer_Private.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHHeatmapStyleLayer_Private.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHLineStyleLayer_Private.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHSymbolStyleLayer_Private.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHCircleStyleLayer_Private.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHFillStyleLayer_Private.h"
    "${MH_GENERATED_DARWIN_CODE_DIR}/MHHillshadeStyleLayer_Private.h"
    ${MH_GENERATED_DARWIN_STYLE_PUBLIC_HEADERS}
)

find_program(BAZEL bazel REQUIRED)

add_custom_command(
    OUTPUT ${MH_GENERATED_DARWIN_STYLE_SOURCE} ${MH_GENERATED_DARWIN_STYLE_HEADERS}
    COMMAND ${CMAKE_COMMAND} -E rm -Rf
        "${PROJECT_SOURCE_DIR}/bazel-bin/platform/darwin/src"
    COMMAND ${BAZEL} build //platform/darwin:generated_code
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${PROJECT_SOURCE_DIR}/bazel-bin/platform/darwin/src"
        ${MH_GENERATED_DARWIN_CODE_DIR}
    COMMENT "Generating Darwin style source and header files"
    VERBATIM
)

add_custom_target(mbgl-darwin-style-code
    DEPENDS ${MH_GENERATED_DARWIN_STYLE_SOURCE} ${MH_GENERATED_DARWIN_STYLE_HEADERS}
)

add_library(
    custom-layer-examples
    EXCLUDE_FROM_ALL
    "${CMAKE_CURRENT_LIST_DIR}/app/ExampleCustomDrawableStyleLayer.mm"
    "${CMAKE_CURRENT_LIST_DIR}/app/CustomStyleLayerExample.m"
    "${CMAKE_CURRENT_LIST_DIR}/app/PluginLayerExample.mm"
    "${CMAKE_CURRENT_LIST_DIR}/app/PluginLayerExampleMetalRendering.mm"
)

target_link_libraries(
    custom-layer-examples
    PUBLIC ios-sdk-static
    PRIVATE mbgl-compiler-options mbgl-core
)

target_include_directories(
    custom-layer-examples
    PUBLIC
        "${CMAKE_CURRENT_LIST_DIR}/app"
    PRIVATE
        "${PROJECT_SOURCE_DIR}/src" # FIXME: should not use private headers
)
