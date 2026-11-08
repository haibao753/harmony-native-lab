# FaceLab 0.5.1 — GPU Region Rendering

Date: 2026-11-08

## User feedback driving this patch

FaceLab 0.5.0 was successfully deployed on MatePad Pro 13.2 (2023). The user confirmed wireframe, shaded surface, and deformation heatmap now run very smoothly, while Regions mode remained as laggy as before. Source inspection confirmed Regions was the only mode still using the legacy ArkUI Canvas viewer and copying geometry into ordinary `number[]` arrays.

## What changed

- Route all four visualizer modes through the same XComponent native GPU surface.
- Forward AR Engine's per-triangle semantic labels as an `Int32Array` through Node-API.
- Expand indexed triangles into three GPU vertices only for region mode. Each triangle's three vertices receive the same region ID, preserving hard region boundaries even where neighboring triangles share mesh vertices.
- Use a GLSL ES flat varying to choose the matching semantic color.
- Preserve the previous ten-color mapping:
  - -1: non-face
  - 0: face-other
  - 1: lower lip
  - 2: upper lip
  - 3: left eye
  - 4: right eye
  - 5: left brow
  - 6: right brow
  - 7: brow center
  - 8: nose
- Remove the Regions-only Canvas branch and per-frame ArkTS `number[]` conversion.
- Keep other GPU modes on their existing indexed VBO/EBO path.

## Validation status

- FaceLab 0.5.0: user-confirmed smooth behavior for wireframe, surface and deformation heatmap.
- FaceLab 0.5.1 source implementation: committed to the feature branch.
- Static source-contract CI: pending for this commit.
- DevEco Studio / HarmonyOS SDK 26.0.0 build: pending.
- MatePad region colors, semantic label correctness, frame pacing, CPU load, temperature and battery impact: pending user validation.

No claim is made that region-mode performance is fixed until the new build is installed and tested on the target tablet.

## Privacy

Face geometry, triangle labels and region colors are processed in local memory only. No face data is saved or uploaded.
