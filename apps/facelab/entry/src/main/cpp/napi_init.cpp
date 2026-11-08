#include "facelab_renderer.h"

static napi_value Init(napi_env env, napi_value exports)
{
    return RegisterRenderer(env, exports);
}

static napi_module facelabRendererModule = {
    1,
    0,
    nullptr,
    Init,
    "facelab_renderer",
    nullptr,
    { 0 }
};

extern "C" __attribute__((constructor)) void RegisterFaceLabRendererModule()
{
    napi_module_register(&facelabRendererModule);
}
