if(TARGET mbgl-harfbuzz)
    return()
endif()
if (MH_TEXT_SHAPING_HARFBUZZ)
    add_library(mbgl-harfbuzz STATIC
        ${CMAKE_CURRENT_LIST_DIR}/harfbuzz/src/harfbuzz.cc
    )

    target_include_directories(mbgl-harfbuzz
        PUBLIC
            ${CMAKE_CURRENT_LIST_DIR}/harfbuzz/src
    )

    target_link_libraries(mbgl-harfbuzz PRIVATE mbgl-freetype)
    target_include_directories(mbgl-harfbuzz PRIVATE ${CMAKE_CURRENT_LIST_DIR}/freetype/include)
    target_compile_definitions(mbgl-harfbuzz PRIVATE -DHAVE_FREETYPE)

    set_target_properties(
        mbgl-harfbuzz
        PROPERTIES
            INTERFACE_MAPHERO_NAME "harfbuzz"
            INTERFACE_MAPHERO_URL "https://github.com/harfbuzz/harfbuzz"
            INTERFACE_MAPHERO_AUTHOR ${CMAKE_CURRENT_LIST_DIR}/harfbuzz/AUTHORS
            INTERFACE_MAPHERO_LICENSE ${CMAKE_CURRENT_LIST_DIR}/harfbuzz/COPYING
    )
endif()
