# FaceLab 0.5.0 — GPU Native Face Renderer

Date: 2026-11-08

## User feedback driving this release

After 0.4.3, the user confirmed that the deformation heatmap was now visible, but the app remained noticeably laggy. The default viewer still used ArkUI Canvas projection and per-triangle drawing.

## Main changes

- Replace the default Canvas viewer with an ArkTS XComponent SURFACE.
- Add a C++ NAPI module backed by EGL and OpenGL ES 3.2.
- Pass AR Engine Float32Array / Uint32Array / Int32Array geometry buffers directly to native code.
- Keep a thread-safe native mesh snapshot and a dedicated render thread.
- Upload dynamic vertex attributes to a GPU VBO; reuse triangle and edge EBOs while topology is unchanged.
- Render wireframe, lit surface, per-vertex deformation heatmap, and face-region colors with GPU shaders.
- Preserve one-finger rotation, two-finger zoom, AR camera preview, head pose, BlendShapes, neutral baseline capture, and in-memory-only face data handling.

## Version metadata

- app version: 0.5.0
- versionCode: 10008

## Validation status

- GitHub source-contract checks: pending CI run.
- DevEco Studio / HarmonyOS SDK 26.0.0 C++ and ArkTS build: pending user build.
- MatePad Pro 13.2 (2023) EGL / OpenGL ES runtime: pending.
- Render FPS, AR mesh update frequency, motion latency, sustained thermal behavior and memory: pending device measurement.

The renderer loop targets approximately 30 FPS while AR mesh snapshots continue to arrive at approximately 5 Hz. This is an architectural target, not a measured performance claim. The app must be tested on the target device before the release can be considered accepted.
