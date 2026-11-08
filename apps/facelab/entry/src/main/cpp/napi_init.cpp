#include "facelab_renderer.h"

static napi_value Init(napi_env env, napi_value exports)
{
    return RegisterRenderer(env, exports);
}

static napi_module facelabRendererModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "facelab_renderer",
    .nm_priv = nullptr,
    .reserved = { 0 }
};

extern "C" __attribute__((constructor)) void RegisterFaceLabRendererModule()
{
    napi_module_register(&facelabRendererModule);
}
