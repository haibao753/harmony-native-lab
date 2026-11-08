#!/usr/bin/env bash
set -euo pipefail

cpp="apps/facelab/entry/src/main/cpp"
gpu="apps/facelab/entry/src/main/ets/components/FaceGpuSurface.ets"
page="apps/facelab/entry/src/main/ets/pages/Index.ets"
types="apps/facelab/entry/src/main/cpp/types/libfacelab_native/index.d.ts"
typepkg="apps/facelab/entry/src/main/cpp/types/libfacelab_native/oh-package.json5"
build="apps/facelab/entry/build-profile.json5"
manifest="apps/facelab/AppScope/app.json5"
readme="apps/facelab/README.md"
release="docs/facelab/RELEASE_NOTES_0.5.0.md"

for file in \
  "$cpp/CMakeLists.txt" "$cpp/FaceGpuRenderer.h" "$cpp/FaceGpuRenderer.cpp" \
  "$cpp/napi_init.cpp" "$gpu" "$page" "$types" "$typepkg" "$build" "$manifest" "$readme" "$release"; do
  test -s "$file"
done

grep -Fq 'libGLESv3.so' "$cpp/CMakeLists.txt"
grep -Fq 'libEGL.so' "$cpp/CMakeLists.txt"
grep -Fq 'libnative_window.so' "$cpp/CMakeLists.txt"
grep -Fq 'eglCreateContext' "$cpp/FaceGpuRenderer.cpp"
grep -Fq 'eglBindAPI(EGL_OPENGL_ES_API)' "$cpp/FaceGpuRenderer.cpp"
grep -Fq 'EGL_CONTEXT_CLIENT_VERSION, 3' "$cpp/FaceGpuRenderer.cpp"
grep -Fq 'glBufferData(GL_ARRAY_BUFFER' "$cpp/FaceGpuRenderer.cpp"
grep -Fq 'glDrawElements(GL_TRIANGLES' "$cpp/FaceGpuRenderer.cpp"
grep -Fq 'glDrawElements(GL_LINES' "$cpp/FaceGpuRenderer.cpp"
grep -Fq 'std::chrono::milliseconds(33)' "$cpp/FaceGpuRenderer.cpp"
grep -Fq 'OH_NativeWindow_CreateNativeWindowFromSurfaceId' "$cpp/FaceGpuRenderer.cpp"
grep -Fq 'OH_NativeWindow_DestroyNativeWindow' "$cpp/FaceGpuRenderer.cpp"
grep -Fq 'napi/native_api.h' "$cpp/napi_init.cpp"
if grep -Fq 'napi/native_node_api.h' "$cpp/napi_init.cpp"; then
  echo "Do not include native_node_api.h; SDK Node-API surface is provided by napi/native_api.h." >&2
  exit 1
fi
grep -Fq 'napi_get_typedarray_info' "$cpp/napi_init.cpp"
grep -Fq 'length / sizeof(float)' "$cpp/napi_init.cpp"
grep -Fq 'length / sizeof(uint32_t)' "$cpp/napi_init.cpp"
grep -Fq 'napi_get_value_bigint_uint64' "$cpp/napi_init.cpp"
grep -Fq 'nativeRender.UpdateMesh' "$gpu"
if grep -Fq "from '@kit.ArkUI'" "$gpu" && grep -Fq 'XComponentController' "$gpu"; then
  echo "XComponentController / XComponentType are ArkUI global declarations, not @kit.ArkUI named exports." >&2
  exit 1
fi
grep -Fq 'XComponentType.SURFACE' "$gpu"
grep -Fq 'controller: this.controller' "$gpu"
grep -Fq '"version": "1.0.0"' apps/facelab/entry/oh-package.json5
grep -Fq '"libfacelab_native.so": "file:./src/main/cpp/types/libfacelab_native"' apps/facelab/entry/oh-package.json5
grep -Fq '"name": "libfacelab_native.so"' "$typepkg"
grep -Fq '"types": "./index.d.ts"' "$typepkg"
grep -Fq 'export default nativeRender;' "$types"
test ! -e apps/facelab/entry/src/main/ets/types/libfacelab_native.d.ts
grep -Fq '"packages": ["libfacelab_native.so"]' "$build"
grep -Fq 'nativeRender.SetViewTransform' "$gpu"
grep -Fq 'this.publishViewTransform();' "$gpu"
grep -Fq "this.meshViewMode === 'regions'" "$page"
grep -Fq 'FaceGpuSurface({ controller: this.gpuSurfaceController })' "$page"
grep -Fq 'externalNativeOptions' "$build"
grep -Fq '"versionCode": 10008' "$manifest"
grep -Fq '"versionName": "0.5.0"' "$manifest"
grep -Fq '0.5.0' "$readme"
grep -Fq 'FaceLab 0.5.0' "$release"

if grep -Fq '@Prop vertices: Float32Array' apps/facelab/entry/src/main/ets/components/FaceMeshViewer.ets; then
  echo "TypedArray must not cross the ArkUI @Prop boundary." >&2
  exit 1
fi

echo "FaceLab 0.5.0 native GPU source contracts passed."
