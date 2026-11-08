# FaceLab 0.5.0 — OpenGL ES Native Face Renderer

Date: 2026-11-08

## Why this version exists

FaceLab 0.4.3 made the heatmap visible and reduced AR mesh publication to approximately 5 Hz, but the user continued to report noticeable lag. The previous viewer used ArkUI Canvas to project and draw thousands of mesh elements. Version 0.5.0 moves the three frequently used geometry modes to a native OpenGL ES 3.0 rendering path.

## Architecture

- ArkTS XComponent SURFACE owns the visible native rendering surface.
- XComponentController forwards surface creation, resize, and destruction events.
- Node-API receives the AR callback's Float32Array / Uint32Array buffers directly.
- C++ obtains OHNativeWindow from SurfaceId, creates EGL, and renders through OpenGL ES 3.0.
- VBO stores interleaved vertex position, normal, and heat value; separate EBOs store triangle and edge indices.
- The native render thread targets approximately 30 Hz while AR mesh data remains updated at approximately 5 Hz.

## Display modes

- Wireframe: GL_LINES draws mesh edges only.
- Surface: GL_TRIANGLES draws the face with per-vertex normal lighting.
- Deformation: per-vertex displacement is mapped to a blue-cyan-green-yellow-red heat scale.
- Regions: retains the 0.4.x Canvas implementation for AR Engine triangle-label semantics.

## Interaction

- One-finger drag rotates the inspection view.
- Two-finger pinch changes zoom.
- Reset View returns the manual inspection transform to its default.

## Privacy and lifecycle

Face images, mesh geometry, and expression metrics remain in local memory. No face data is saved or uploaded. Surface destruction stops the native render thread and releases GL, EGL, and NativeWindow resources.

## SDK 26 ArkTS compile correction

The first user build completed CMake / native C++ compilation and failed in ArkTS because XComponentController and XComponentType were incorrectly imported from @kit.ArkUI. Huawei's ArkUI API declarations define these as global ArkTS declarations. The implementation now references them without named imports and retains the ArkTS XComponentOptions controller lifecycle path. The separate API 19+ NativeXComponentParameters overload is not used.

## Validation status

**Status: Source implementation only**

- GitHub source changes are committed to the 0.5.0 feature branch.
- DevEco Studio / HarmonyOS SDK 26.0.0 compilation has not been run in this environment.
- MatePad Pro 13.2 (2023) runtime validation is pending.
- No FPS or performance improvement is claimed until the device test is completed.

## MatePad acceptance checklist

1. Build the entry module and verify that libfacelab_native.so is packaged for arm64-v8a.
2. Launch FaceLab and start AR face tracking.
3. Confirm the XComponent Surface displays the live face mesh.
4. Compare wireframe, surface lighting, and deformation heatmap.
5. Test one-finger rotation, two-finger pinch, and Reset View.
6. Switch to Regions and verify the Canvas fallback.
7. Stop tracking and leave the page; confirm camera and native rendering resources are released.
8. Compare visible frame pacing, CPU load, temperature, and battery impact against 0.4.3.
