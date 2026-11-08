# FaceLab 0.4.3 — Live Deformation Heatmap & Lite Rendering

Date: 2026-11-08

## User feedback addressed

After testing 0.4.2 on MatePad Pro 13.2 (2023), the user reported that the solid mesh was visible, the app remained noticeably laggy, and the deformation heatmap showed no useful content.

## Changes

- Reduce the mesh callback publication rate from approximately 10 Hz to approximately 5 Hz to reduce sustained JavaScript and Canvas work.
- Make deformation heatmap useful before neutral calibration:
  - With a captured neutral-expression baseline, display per-vertex displacement from that neutral mesh.
  - Without a neutral baseline, display per-vertex displacement from the previous frame as a live motion heatmap.
- Label the legend clearly as `NEUTRAL Δ` or `LIVE MOTION Δ`.
- Add a one-tap neutral-baseline capture action beside the visualizer title.
- Keep the 0.4.2 array reuse, topology caching, and distinct wireframe / surface / heatmap / region modes.

## Important interpretation

The live-motion fallback is frame-to-frame geometry movement, not expression magnitude. The neutral-baseline view measures displacement from a captured neutral mesh, but can also be affected by head pose. These metrics are not medical or identity signals.

## Performance boundary

The 5 Hz callback target is a conservative workload reduction, not a guarantee of smooth rendering. ARView rendering remains driven by AR Engine. The standalone mesh viewer is still an ArkUI Canvas projection, not a GPU-native mesh scene. If the MatePad still feels laggy, the next engineering step is to profile the measured DRAW CALL / JS costs and evaluate ArkGraphics3D GPU-native rendering rather than adding more Canvas micro-optimizations.

## MatePad acceptance checklist

1. Build with DevEco Studio and HarmonyOS SDK 26.0.0.
2. Start tracking and switch to deformation heatmap without capturing a neutral baseline. The mesh should remain visible in cool colors; moving the head or changing expression should create a live-motion heatmap.
3. Capture a relaxed neutral expression using the shortcut beside the visualizer title.
4. Blink and open the jaw. The legend should change to `NEUTRAL Δ` and visible hot regions should follow mesh displacement.
5. Compare camera preview responsiveness and mesh update cadence against 0.4.2.
6. Record DRAW CALL frequency and JS draw-submission time.
7. Verify wireframe, solid surface, face regions, rotation, zoom, stop, and restart.

## Release status

Source changes and source-contract checks are prepared. DevEco build and MatePad hardware acceptance are pending.
