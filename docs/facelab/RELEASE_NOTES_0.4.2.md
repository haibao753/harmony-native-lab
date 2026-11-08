# FaceLab 0.4.2 — Performance & Geometry Visualization

Date: 2026-11-08

## Why this release exists

After running 0.4.1 on the MatePad Pro 13.2 (2023), the user reported two issues:

- Real-time face tracking and mesh display felt noticeably laggy.
- Wireframe, solid surface, and deformation heatmap looked too similar; semantic face-region coloring was the only mode with a clearly distinct appearance.

## Changes

### Performance

- Raise the face-mesh publication target from 5 Hz to approximately 10 Hz.
- Add an async processing guard so a slow frame cannot overlap the next frame callback.
- Reuse geometry and previous-frame typed buffers in the AR callback.
- Reuse ordinary JavaScript arrays at the ArkUI boundary instead of allocating five new arrays on every update.
- Refresh triangle indices, unique edges, and semantic labels only when the mesh topology revision changes.
- Reuse projected-point objects and face-index buckets in the Canvas renderer.
- Reduce text-only diagnostics to approximately 2 Hz while keeping mesh updates on the faster path.

### Geometry modes

- **Wireframe:** edge-only rendering; no triangle fill.
- **Solid surface:** triangle fill shaded by the rotated face normal and a fixed directional light.
- **Deformation heatmap:** eight high-contrast displacement bands, from cool colors to warm colors, without the full wireframe overlay.
- **Face regions:** retain the semantic triangle labels returned by AR Engine.

### Diagnostics

The Canvas overlay shows draw-call frequency and JavaScript draw-submission time. These are application-side diagnostics, not system compositor or GPU presentation FPS.

## Important limitations

- The renderer is still an ArkUI Canvas 3D projection, not a GPU-native mesh scene.
- 10 Hz is the target publication interval, not a guaranteed render rate and not a 60 FPS claim.
- The optimization is source-level until DevEco compilation and MatePad device testing pass.
- If the tablet still feels laggy, capture the overlay values and compare them across modes. The next step should be evidence-led profiling and, if Canvas is the bottleneck, an ArkGraphics3D/GPU-native renderer evaluation.

## MatePad acceptance checklist

1. Build with DevEco Studio and HarmonyOS SDK 26.0.0.
2. Install on MatePad Pro 13.2 (2023) and start face tracking.
3. Confirm the mesh updates continuously without worsening camera preview responsiveness.
4. Compare the four modes side by side:
   - wireframe: thin cyan edges only;
   - solid: opaque shaded surface with visible 3D lighting;
   - deformation: distinct blue-to-red heatmap and legend, no edge overlay;
   - regions: semantic feature colors.
5. Capture the draw-call frequency and JS draw-submission time while still and while moving.
6. Test blink, jaw-open, and head-turn deformation after capturing a neutral baseline.
7. Test drag rotation, pinch zoom, reset view, stop, and restart.
8. Report any mode that appears blank, too similar, or slower than the others.

## Release status

Source changes and source-contract checks are prepared. DevEco build and MatePad hardware acceptance are pending; this release must not be treated as device-verified until those tests are completed.
