#!/usr/bin/env bash
set -euo pipefail

callback="apps/facelab/entry/src/main/ets/common/FaceTrackingCallback.ets"
page="apps/facelab/entry/src/main/ets/pages/Index.ets"
surface="apps/facelab/entry/src/main/ets/components/FaceGpuSurface.ets"
renderer="apps/facelab/entry/src/main/cpp/FaceGpuRenderer.cpp"
napi="apps/facelab/entry/src/main/cpp/napi_init.cpp"
cmake="apps/facelab/entry/src/main/cpp/CMakeLists.txt"
manifest="apps/facelab/AppScope/app.json5"
readme="apps/facelab/README.md"
spec="docs/facelab/PRODUCT_SPEC.md"
release="docs/facelab/RELEASE_NOTES_0.5.2.md"

for file in "$callback" "$page" "$surface" "$renderer" "$napi" "$cmake" "$manifest" "$readme" "$spec" "$release"; do
  test -s "$file"
done

grep -Fq 'GESTURE_SAMPLE_INTERVAL_US = 33333' "$callback"
grep -Fq 'MESH_PUBLISH_INTERVAL_US = 200000' "$callback"
grep -Fq 'interface FaceGestureMetrics' "$callback"
grep -Fq 'private detectGestureEvents(' "$callback"
grep -Fq 'leftBlink >= 0.72' "$callback"
grep -Fq 'now - this.leftWinkCandidateSince >= 80' "$callback"
grep -Fq 'now - this.rightWinkCandidateSince >= 80' "$callback"
grep -Fq 'rightBlink >= 0.72' "$callback"
grep -Fq 'jawOpen >= 0.72' "$callback"
grep -Fq 'now - this.jawOpenStartedAt >= 350' "$callback"
grep -Fq 'this.onGesture({' "$callback"
grep -Fq 'if (shouldPublishMetrics)' "$callback"

grep -Fq 'gestureLabEnabled: boolean = false' "$page"
grep -Fq 'GESTURE INTERACTION LAB' "$page"
grep -Fq '左眼单眨' "$page"
grep -Fq '右眼单眨' "$page"
grep -Fq '张嘴保持' "$page"
grep -Fq '选项 A' "$page"
grep -Fq '选项 B' "$page"
grep -Fq '选项 C' "$page"
grep -Fq '0.5.2' "$page"

grep -Fq 'XComponentType.SURFACE' "$surface"
grep -Fq 'OH_NativeWindow_CreateNativeWindowFromSurfaceId' "$renderer"
grep -Fq 'eglCreateWindowSurface' "$renderer"
grep -Fq 'glBufferData' "$renderer"
grep -Fq 'glDrawElements' "$renderer"
grep -Fq 'napi_get_typedarray_info' "$napi"
grep -Fq 'GLESv3' "$cmake"

grep -Fq '"versionCode": 10010' "$manifest"
grep -Fq '"versionName": "0.5.2"' "$manifest"
grep -Fq 'Gesture Interaction Lab' "$readme"
grep -Fq '0.5.2' "$spec"
grep -Fq 'FaceLab 0.5.2' "$release"

echo "FaceLab 0.5.2 gesture interaction and GPU baseline source checks passed."
