# FaceLab 0.4.1 — Runtime stability hotfix

## Why this release exists

The first MatePad Pro run of the 0.4.0 visualizer crashed on the first mesh frame. The JSCrash identified:

- FaceMeshViewer.ets:158:40.
- TypeError: This value does not have a [[TypedArrayName]] internal slot.

The failure occurred when ArkUI observed TypedArray values passed through @Prop. TypedArray accessors such as .length require a genuine TypedArray receiver; an observed proxy does not satisfy that internal-slot requirement.

## Fix

- Keep Float32Array, Uint32Array, and Int32Array in the AR callback for geometry processing.
- Convert vertices, triangle indices, unique edges, deformation values, and optional triangle labels to ordinary number[] in Index.ets before passing them to FaceMeshViewer.
- Keep the visualizer's @Prop contract limited to ordinary arrays and scalar values.
- Preserve the four existing modes: wireframe, surface, deformation heatmap, and semantic regions.
- Keep mesh data in memory only; no face data is persisted or uploaded.

## Version

- versionName: 0.4.1
- versionCode: 10005

## Verification

- GitHub Actions source-contract checks validate all five typed-buffer conversions, all five plain-array props, and the absence of TypedArray types in the viewer.
- This is a source-level fix. It does not claim that DevEco Studio compilation or MatePad hardware acceptance has passed.

## MatePad acceptance checklist

1. Build the apps/facelab project with DevEco Studio and HarmonyOS SDK 26.0.0.
2. Install 0.4.1 and tap 开始追踪; confirm the camera preview and first mesh frame appear without a crash.
3. Verify wireframe, surface, deformation heatmap, and region modes.
4. Verify one-finger rotation, two-finger zoom, and view reset.
5. Move the head and change facial expression; confirm the mesh updates.
6. Stop tracking, confirm camera and mesh data clear, then start tracking again.
7. Record whether triangle-region labels are available on this device. Their absence must not break the other three modes.
