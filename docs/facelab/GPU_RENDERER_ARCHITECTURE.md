# FaceLab 0.5.0 — GPU Native Renderer Architecture

## 1. Why this migration

FaceLab 0.4.3 proved that the AR Engine mesh and deformation heatmap data are available on the target MatePad. The user confirmed the heatmap appeared, but the application still felt laggy. The remaining bottleneck was not the heatmap formula alone: the standalone viewer still projected and painted thousands of mesh elements through ArkUI Canvas.

FaceLab 0.5.0 therefore replaces the default Canvas drawing path with a native rendering surface.

## 2. Selected platform path

- ArkUI declaration XComponent with SURFACE type.
- XComponentController forwards Surface lifecycle events and SurfaceId.
- C++ NAPI module: libfacelab_renderer.so.
- OH_NativeWindow_CreateNativeWindowFromSurfaceId obtains the native window.
- EGL creates the window surface and OpenGL ES 3.2 context.
- A native render thread owns the EGL context and draws independently from ArkTS UI updates.

This path is documented by Huawei for custom rendering, game graphics, and 3D rendering. OpenGL ES 3.2 and EGL are documented platform capabilities. Target-device runtime support still requires a real build and device test.

## 3. Data path

\`\`\`text
AR Engine FACE callback (ArkTS)
  ├─ Float32Array vertices
  ├─ Uint32Array triangle indices
  ├─ Uint32Array unique edge indices
  ├─ Float32Array per-vertex deformation
  ├─ Int32Array per-triangle face labels
  └─ relative pose + topology revision
          │
          ▼
NAPI UpdateMesh (synchronous typed-array copy)
          │
          ▼
thread-safe native mesh snapshot
          │
          ▼
native render thread (~30 FPS target)
  ├─ compute normalized positions / vertex normals / region attribute on mesh update
  ├─ update GPU VBO
  ├─ update EBO only when topology revision changes
  ├─ vertex shader: transforms / passes deformation and region attributes
  └─ fragment shader: surface / heatmap / region colors
          │
          ▼
EGL swap → XComponent Surface
\`\`\`

AR geometry publication remains throttled to approximately 5 Hz in 0.4.3. The renderer's approximately 30 FPS loop redraws the most recently received mesh; it does not create new face-capture samples. UI diagnostics must report render FPS and AR mesh update rate separately.

## 4. GPU buffers and modes

| Mode | GPU path |
|---|---|
| Wireframe | Unique edge EBO + GL_LINES |
| Surface | Triangle EBO + per-vertex normal lighting |
| Deformation heatmap | Per-vertex displacement attribute + fragment color ramp |
| Face regions | Per-triangle labels aggregated to vertex region attributes + fragment palette |

The vertex buffer stores position, normal, deformation and region attributes. Triangle and edge index buffers are retained and only re-uploaded when the mesh topology revision changes or buffer capacity must grow.

The heatmap is normalized against the largest displacement in the current snapshot. It is a visualization of the current geometric displacement field, not a calibrated expression-strength score. Neutral-reference displacement may still include head-pose effects.

## 5. Threading and lifecycle

- ArkTS / NAPI only copies new typed-array data into a native snapshot and updates low-frequency controls. HarmonyOS Node-API reports TypedArray length in bytes, so the native boundary converts byte length to 32-bit element count before copying.
- The render thread creates, owns and destroys its EGL context.
- Surface creation starts the native renderer; resize updates viewport dimensions; Surface destruction stops and joins the render thread before destroying the NativeWindow reference.
- AR tracking stop clears the current mesh but does not implicitly destroy the XComponent Surface.
- Page teardown and XComponent Surface destruction must both be safe and idempotent.

## 6. Performance goals (not yet measured)

| Metric | Goal / interpretation |
|---|---|
| GPU render loop | Approximately 30 FPS target |
| AR mesh updates | Approximately 5 Hz inherited from 0.4.3 |
| Vertex upload | Only when a new mesh snapshot arrives |
| Index upload | Only when topology revision changes |
| ArkTS per-frame vertex conversion | Removed from the default viewer path |
| Face data persistence | None; in-memory only |

No frame-rate or latency claim is accepted until measured on MatePad Pro 13.2 (2023). Record sustained render FPS, AR mesh update frequency, CPU utilization, GPU utilization if available, end-to-end motion latency, memory, and thermal behavior.

## 7. Known limitations in this first vertical slice

- The native renderer is implemented against documented XComponent, NativeWindow, EGL, OpenGL ES 3.2 and Node-API interfaces, but it has not yet been built with the user's local DevEco toolchain.
- EGL surface creation, shader compilation and the GLES 3.2 driver must be verified on the target tablet.
- The first implementation computes vertex normals and region aggregation on CPU when a new mesh snapshot arrives. This work is native C++, not ArkTS Canvas drawing, but may still be optimized after measurement.
- Region labels are averaged at shared vertices. Region boundaries can therefore be softer than a per-face flat-shaded implementation.
- The AR mesh callback is still approximately 5 Hz. Smooth 30 FPS display means redraw of the latest sample, not 30 Hz capture.
- The old Canvas component remains in the repository as historical code but is no longer the default viewer in the 0.5.0 page.

## 8. Official references

- [Custom Rendering (XComponent)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/napi-xcomponent-guidelines/)
- [OpenGL ES](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/opengles/)
- [EGL](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/egl/)
- [NativeWindow](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-external-window-h/)
- [Hvigor C++ configuration](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-hmos-hvigor-cpp/)
- [ArkGraphics 3D CustomGeometry](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-scene-types/)
- [ArkGraphics 3D createMesh](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-scene/)
