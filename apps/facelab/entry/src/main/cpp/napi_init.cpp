#include "FaceGpuRenderer.h"

#include <napi/native_api.h>

#include <cstdint>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace {
std::mutex g_renderersMutex;
std::unordered_map<uint64_t, std::shared_ptr<FaceGpuRenderer>> g_renderers;

std::shared_ptr<FaceGpuRenderer> FindRenderer(uint64_t surfaceId)
{
    std::lock_guard<std::mutex> lock(g_renderersMutex);
    auto found = g_renderers.find(surfaceId);
    return found == g_renderers.end() ? nullptr : found->second;
}

bool ReadSurfaceId(napi_env env, napi_value value, uint64_t &surfaceId)
{
    bool lossless = false;
    if (napi_get_value_bigint_uint64(env, value, &surfaceId, &lossless) != napi_ok || !lossless) {
        return false;
    }
    return true;
}

bool ReadFloat32Array(napi_env env, napi_value value, std::vector<float> &output)
{
    napi_typedarray_type type;
    size_t length = 0;
    void *data = nullptr;
    napi_value arrayBuffer = nullptr;
    size_t byteOffset = 0;
    if (napi_get_typedarray_info(env, value, &type, &length, &data, &arrayBuffer, &byteOffset) != napi_ok ||
        type != napi_float32_array || (length > 0 && data == nullptr) || length % sizeof(float) != 0) {
        return false;
    }
    // HarmonyOS napi_get_typedarray_info reports byte length, not element count.
    const size_t elementCount = length / sizeof(float);
    if (elementCount == 0) { output.clear(); return true; }
    const float *source = static_cast<const float *>(data);
    output.assign(source, source + elementCount);
    return true;
}

bool ReadUint32Array(napi_env env, napi_value value, std::vector<uint32_t> &output)
{
    napi_typedarray_type type;
    size_t length = 0;
    void *data = nullptr;
    napi_value arrayBuffer = nullptr;
    size_t byteOffset = 0;
    if (napi_get_typedarray_info(env, value, &type, &length, &data, &arrayBuffer, &byteOffset) != napi_ok ||
        type != napi_uint32_array || (length > 0 && data == nullptr) || length % sizeof(uint32_t) != 0) {
        return false;
    }
    // HarmonyOS napi_get_typedarray_info reports byte length, not element count.
    const size_t elementCount = length / sizeof(uint32_t);
    if (elementCount == 0) { output.clear(); return true; }
    const uint32_t *source = static_cast<const uint32_t *>(data);
    output.assign(source, source + elementCount);
    return true;
}

napi_value SetSurfaceId(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    uint64_t surfaceId = 0;
    if (argc < 1 || !ReadSurfaceId(env, args[0], surfaceId)) {
        napi_throw_type_error(env, nullptr, "SetSurfaceId expects a non-negative BigInt surface id");
        return nullptr;
    }

    std::shared_ptr<FaceGpuRenderer> renderer;
    {
        std::lock_guard<std::mutex> lock(g_renderersMutex);
        auto &slot = g_renderers[surfaceId];
        if (!slot) {
            slot = std::make_shared<FaceGpuRenderer>(surfaceId);
            slot->Start();
        }
        renderer = slot;
    }
    napi_value result = nullptr;
    napi_get_undefined(env, &result);
    return result;
}

napi_value ResizeSurface(napi_env env, napi_callback_info info)
{
    size_t argc = 3;
    napi_value args[3] = {nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    uint64_t surfaceId = 0;
    int32_t width = 0;
    int32_t height = 0;
    if (argc < 3 || !ReadSurfaceId(env, args[0], surfaceId) ||
        napi_get_value_int32(env, args[1], &width) != napi_ok ||
        napi_get_value_int32(env, args[2], &height) != napi_ok) {
        napi_throw_type_error(env, nullptr, "ResizeSurface expects (BigInt, number, number)");
        return nullptr;
    }
    auto renderer = FindRenderer(surfaceId);
    if (renderer) {
        renderer->Resize(width, height);
    }
    napi_value result = nullptr;
    napi_get_undefined(env, &result);
    return result;
}

napi_value SetViewTransform(napi_env env, napi_callback_info info)
{
    size_t argc = 4;
    napi_value args[4] = {nullptr, nullptr, nullptr, nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    uint64_t surfaceId = 0;
    double pitch = 0.0;
    double yaw = 0.0;
    double zoom = 1.0;
    if (argc < 4 || !ReadSurfaceId(env, args[0], surfaceId) ||
        napi_get_value_double(env, args[1], &pitch) != napi_ok ||
        napi_get_value_double(env, args[2], &yaw) != napi_ok ||
        napi_get_value_double(env, args[3], &zoom) != napi_ok) {
        napi_throw_type_error(env, nullptr, "SetViewTransform expects (BigInt, pitch, yaw, zoom)");
        return nullptr;
    }
    auto renderer = FindRenderer(surfaceId);
    if (renderer) {
        renderer->SetViewTransform(static_cast<float>(pitch), static_cast<float>(yaw), static_cast<float>(zoom));
    }
    napi_value result = nullptr;
    napi_get_undefined(env, &result);
    return result;
}

napi_value UpdateMesh(napi_env env, napi_callback_info info)
{
    size_t argc = 11;
    napi_value args[11] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    uint64_t surfaceId = 0;
    if (argc < 11 || !ReadSurfaceId(env, args[0], surfaceId)) {
        napi_throw_type_error(env, nullptr, "UpdateMesh received invalid arguments");
        return nullptr;
    }

    std::vector<float> vertices;
    std::vector<uint32_t> triangles;
    std::vector<uint32_t> edges;
    std::vector<float> deformation;
    double pitch = 0.0;
    double yaw = 0.0;
    double roll = 0.0;
    uint32_t topologyRevision = 0;
    int32_t mode = 0;

    if (!ReadFloat32Array(env, args[1], vertices) ||
        !ReadUint32Array(env, args[2], triangles) ||
        !ReadUint32Array(env, args[3], edges) ||
        !ReadFloat32Array(env, args[4], deformation) ||
        napi_get_value_double(env, args[5], &pitch) != napi_ok ||
        napi_get_value_double(env, args[6], &yaw) != napi_ok ||
        napi_get_value_double(env, args[7], &roll) != napi_ok ||
        napi_get_value_uint32(env, args[8], &topologyRevision) != napi_ok ||
        napi_get_value_int32(env, args[9], &mode) != napi_ok) {
        napi_throw_type_error(env, nullptr, "UpdateMesh expects Float32Array / Uint32Array geometry buffers");
        return nullptr;
    }

    bool hasMesh = false;
    if (napi_get_value_bool(env, args[10], &hasMesh) != napi_ok) {
        napi_throw_type_error(env, nullptr, "UpdateMesh expects a boolean hasMesh flag");
        return nullptr;
    }

    auto renderer = FindRenderer(surfaceId);
    if (renderer) {
        if (hasMesh) {
            renderer->UpdateMesh(vertices.data(), vertices.size(),
                                 triangles.data(), triangles.size(),
                                 edges.data(), edges.size(),
                                 deformation.data(), deformation.size(),
                                 static_cast<float>(pitch), static_cast<float>(yaw), static_cast<float>(roll),
                                 topologyRevision, mode);
        } else {
            renderer->ClearMesh();
        }
    }

    napi_value result = nullptr;
    napi_get_undefined(env, &result);
    return result;
}

napi_value ClearMesh(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    uint64_t surfaceId = 0;
    if (argc < 1 || !ReadSurfaceId(env, args[0], surfaceId)) {
        napi_throw_type_error(env, nullptr, "ClearMesh expects a BigInt surface id");
        return nullptr;
    }
    auto renderer = FindRenderer(surfaceId);
    if (renderer) {
        renderer->ClearMesh();
    }
    napi_value result = nullptr;
    napi_get_undefined(env, &result);
    return result;
}

napi_value DestroySurface(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    uint64_t surfaceId = 0;
    if (argc < 1 || !ReadSurfaceId(env, args[0], surfaceId)) {
        napi_throw_type_error(env, nullptr, "DestroySurface expects a BigInt surface id");
        return nullptr;
    }

    std::shared_ptr<FaceGpuRenderer> renderer;
    {
        std::lock_guard<std::mutex> lock(g_renderersMutex);
        auto found = g_renderers.find(surfaceId);
        if (found != g_renderers.end()) {
            renderer = found->second;
            g_renderers.erase(found);
        }
    }
    if (renderer) {
        renderer->Stop();
    }
    napi_value result = nullptr;
    napi_get_undefined(env, &result);
    return result;
}

napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor descriptors[] = {
        {"SetSurfaceId", nullptr, SetSurfaceId, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"ResizeSurface", nullptr, ResizeSurface, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"SetViewTransform", nullptr, SetViewTransform, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"UpdateMesh", nullptr, UpdateMesh, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"ClearMesh", nullptr, ClearMesh, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"DestroySurface", nullptr, DestroySurface, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    return exports;
}

napi_module g_module = {
    1,
    0,
    nullptr,
    Init,
    "facelab_native",
    nullptr,
    {nullptr, nullptr, nullptr, nullptr}
};
} // namespace

extern "C" __attribute__((constructor)) void RegisterFaceLabNativeModule()
{
    napi_module_register(&g_module);
}
