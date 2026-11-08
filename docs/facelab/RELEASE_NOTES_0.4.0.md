# FaceLab 0.4.0 — Face Visualizer

## Changes

- Render the real AR Engine face mesh as a rotatable 3D projection using ArkUI Canvas.
- Add wireframe, translucent surface, deformation heatmap, and face-region color modes.
- Apply live relative head pose to the mesh; combine it with user inspection rotation.
- Add one-finger drag rotation, two-finger pinch zoom, and view reset.
- Read optional ARGeometry triangle labels for lips, eyes, brows, brow center, and nose.
- Cache unique triangle edges and retain the existing approximately 5 Hz UI update cadence.
- Keep all face geometry, labels, and deformation data in memory only.

## Important limitations

- This version uses a 3D-to-2D Canvas projection, not an ArkGraphics3D GPU-native mesh scene.
- Triangle labels are optional and may be unavailable on some devices.
- Face-region colors use Huawei's documented triangle-label values only; no facial region is guessed from vertex position.
- Mesh deformation remains in raw coordinate units and may include head-pose effects.

## Verification

GitHub source-contract checks are included. DevEco Studio compilation and MatePad Pro 13.2 (2023) hardware acceptance remain required.
