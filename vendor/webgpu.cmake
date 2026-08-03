# WebGPU implementation configuration
# This file handles the integration of either Dawn or wgpu

set(MH_WEBGPU_IMPL_DAWN OFF CACHE STRING "WebGPU with Dawn implementation")
set(MH_WEBGPU_IMPL_WGPU OFF CACHE STRING "WebGPU with wgpu implementation")

if(MH_WITH_WEBGPU)
    if(MH_WEBGPU_IMPL_DAWN)
        message(STATUS "Using Dawn as WebGPU backend")
        add_compile_definitions(MH_WEBGPU_IMPL_DAWN)

    elseif(MH_WEBGPU_IMPL_WGPU)
        message(STATUS "Using wgpu as WebGPU backend")
        add_compile_definitions(MH_WEBGPU_IMPL_WGPU)

    else()
        message(FATAL_ERROR "MH_WEBGPU_IMPL_DAWN or MH_WEBGPU_IMPL_WGPU must be set")

    endif()
endif()
