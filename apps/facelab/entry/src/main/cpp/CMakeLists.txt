cmake_minimum_required(VERSION 3.16)
project(facelab_native)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

add_library(facelab_native SHARED
    napi_init.cpp
    FaceGpuRenderer.cpp
)

target_include_directories(facelab_native PRIVATE
    ${NATIVERENDER_ROOT_PATH}
)

target_compile_features(facelab_native PRIVATE cxx_std_17)
target_compile_options(facelab_native PRIVATE -O2 -Wall -Wextra)

target_link_libraries(facelab_native PUBLIC
    libace_napi.z.so
    libace_ndk.z.so
    libnative_window.so
    libEGL.so
    libGLESv3.so
    libhilog_ndk.z.so
)
