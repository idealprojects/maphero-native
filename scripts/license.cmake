# Generate the license file for the target ${param} at config time

# Reads one of the attribution properties off a target, by our own property name first and the
# upstream one second.
#
# Every vendored library whose .cmake file lives in this repository was renamed with the rest of the
# project, so it carries INTERFACE_MAPHERO_*. A submodule that declares its own attribution did not:
# maplibre-tile-spec sets INTERFACE_MAPLIBRE_LICENSE on mlt-cpp inside its own CMakeLists.txt, a
# file this project does not own and must not rewrite. Reading only the renamed property made the
# generator below declare that library unlicensed and abort every CMake configure with
# "License not found for target: mlt-cpp".
function(mbgl_attribution_property out target suffix)
    get_target_property(value ${target} INTERFACE_MAPHERO_${suffix})
    if(NOT value)
        get_target_property(value ${target} INTERFACE_MAPLIBRE_${suffix})
    endif()
    set(${out} "${value}" PARENT_SCOPE)
endfunction()

function(mbgl_generate_license param)
    # Fake targets or non relevant.
    set(BLACKLIST "mbgl-compiler-options" "mbgl-rustutils")

    get_target_property(LIBRARIES ${param} LINK_LIBRARIES)
    list(INSERT LIBRARIES 0 ${param})

    # cmake-format: off
    foreach(LIBRARY IN LISTS LIBRARIES)
    # cmake-format: on
        if(${LIBRARY} IN_LIST BLACKLIST)
            continue()
        endif()

        if(TARGET ${LIBRARY})
            mbgl_attribution_property(NAME ${LIBRARY} NAME)
            mbgl_attribution_property(URL ${LIBRARY} URL)
            mbgl_attribution_property(AUTHOR ${LIBRARY} AUTHOR)
            mbgl_attribution_property(LICENSE ${LIBRARY} LICENSE)

            if(NOT LICENSE OR NOT EXISTS ${LICENSE})
                message(FATAL_ERROR "License not found for target: ${LIBRARY}")
            endif()

            file(READ ${LICENSE} LICENSE_DATA)

            string(APPEND LICENSE_LIST "### [${NAME}](${URL}) by ${AUTHOR}\n\n")
            string(APPEND LICENSE_LIST "```\n${LICENSE_DATA}\n```\n\n")
            string(APPEND LICENSE_LIST "---\n\n")
        endif()
    endforeach()

    file(WRITE ${CMAKE_BINARY_DIR}/${param}.license ${LICENSE_LIST})

    add_custom_target(${param}-license COMMAND cat ${CMAKE_BINARY_DIR}/${param}.license)
endfunction()

mbgl_generate_license(mbgl-core)
