cmake_minimum_required(VERSION 3.4.1)
project(facelab_renderer)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_definitions(-DOHOS_PLATFORM)

add_library(facelab_renderer SHARED
    facelab_renderer.cpp
    napi_init.cpp
)

find_library(EGL_LIB EGL)
find_library(GLES_LIB GLESv3)
find_library(NATIVE_WINDOW_LIB native_window)
find_library(ACE_NDK_LIB ace_ndk.z)
find_library(ACE_NAPI_LIB ace_napi.z)

target_link_libraries(facelab_renderer PUBLIC
    ${EGL_LIB}
    ${GLES_LIB}
    ${NATIVE_WINDOW_LIB}
    ${ACE_NDK_LIB}
    ${ACE_NAPI_LIB}
)
