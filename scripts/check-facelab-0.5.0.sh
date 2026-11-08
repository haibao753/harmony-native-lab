#!/usr/bin/env bash
set -euo pipefail

cpp="apps/facelab/entry/src/main/cpp/facelab_renderer.cpp"
header="apps/facelab/entry/src/main/cpp/facelab_renderer.h"
napi="apps/facelab/entry/src/main/cpp/napi_init.cpp"
cmake="apps/facelab/entry/src/main/cpp/CMakeLists.txt"
types="apps/facelab/entry/src/main/cpp/types/libfacelab_renderer/index.d.ts"
gpu="apps/facelab/entry/src/main/ets/components/FaceGpuRenderer.ets"
page="apps/facelab/entry/src/main/ets/pages/Index.ets"
profile="apps/facelab/entry/build-profile.json5"
manifest="apps/facelab/AppScope/app.json5"
readme="apps/facelab/README.md"
architecture="docs/facelab/GPU_RENDERER_ARCHITECTURE.md"
release="docs/facelab/RELEASE_NOTES_0.5.0.md"

for file in "$cpp" "$header" "$napi" "$cmake" "$types" "$gpu" "$page" "$profile" "$manifest" "$readme" "$architecture" "$release"; do
  test -s "$file"
done

grep -Fq 'OH_NativeWindow_CreateNativeWindowFromSurfaceId' "$cpp"
grep -Fq 'eglCreateWindowSurface' "$cpp"
grep -Fq 'glBufferSubData' "$cpp"
grep -Fq 'glDrawElements' "$cpp"
grep -Fq 'napi_get_typedarray_info' "$cpp"
grep -Fq 'napi_get_value_bigint_int64' "$cpp"
grep -Fq '*length /= sizeof(uint32_t)' "$cpp"
grep -Fq 'napi_module_register' "$napi"
grep -Fq 'GLESv3' "$cmake"
grep -Fq 'libfacelab_renderer.so' "$gpu"
grep -Fq 'XComponentType.SURFACE' "$gpu"
grep -Fq 'nativeRenderer.UpdateMesh' "$page"
grep -Fq 'nativeRenderer.GetStats' "$page"
grep -Fq 'napi_value GetStats' "$cpp"
grep -Fq 'externalNativeOptions' "$profile"
grep -Fq 'CMakeLists.txt' "$profile"
grep -Fq '"versionCode": 10008' "$manifest"
grep -Fq '"versionName": "0.5.0"' "$manifest"
grep -Fq 'AR Face Tracking Lab · 0.5.0' "$page"
grep -Fq 'GPU Native Face Renderer' "$readme"
grep -Fq 'GPU Native Renderer Architecture' "$architecture"
grep -Fq 'FaceLab 0.5.0' "$release"

if grep -Fq 'FaceMeshViewer(' "$page"; then
  echo "Default 0.5.0 page must not use the Canvas FaceMeshViewer."
  exit 1
fi

echo "FaceLab 0.5.0 native GPU renderer source checks passed."
