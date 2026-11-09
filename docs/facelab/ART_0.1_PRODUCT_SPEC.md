# FaceLab Art 0.1 — FORM BEYOND

## Product intent

FORM BEYOND is a face-driven, no-touch sculpture study. The user does not control a character or complete a conventional level. The user changes one evolving liquid-metal form through head pose and deliberate facial gestures.

The first slice prioritizes a coherent art experience over progression systems, scores, or collection mechanics.

## Visual direction

- Material: liquid chrome with high-contrast procedural reflection bands and Fresnel edge light.
- Space: near-black void; no dashboard chrome or persistent diagnostic panels.
- Camera: centered object, restrained perspective, head-pose orbit, direct-touch fallback.
- Form: a continuously deforming organic UV surface. The first prototype uses a single closed surface, not a multi-object sculpture.
- Motion: smooth, damped control response; gestures create distinct, legible events.

## Interaction contract

| Input | Sculpture response |
| --- | --- |
| Head roll (tilt) | Rotates the deformation field's gravity direction |
| Head pitch (nod) | Changes viewing elevation |
| Head yaw (turn) | Changes viewing azimuth |
| Left unilateral wink | Increases growth / volume |
| Right unilateral wink | Adds an erosion field / concavity |
| Sustained jaw-open confirmation | Emits a short deformation pulse |
| Touch drag | Manual camera orbit fallback |
| Two-finger pinch | Manual zoom fallback |

The implementation reuses FaceLab's existing FaceGestureMetrics event stream. It does not add a second blink detector. Wink and jaw confirmation thresholds remain owned by the existing 0.5.2 detector.

## Technical slice

1. SculptureControlMapper filters pitch/yaw/roll and converts roll to a 2D gravity vector.
2. SculptureGpuSurfaceController creates static UV-sphere topology once and updates only vertex positions.
3. The existing XComponent / EGL / OpenGL ES 3.0 renderer receives the generated typed arrays through the existing Node-API UpdateMesh method.
4. Renderer mode 4 applies a procedural chrome shader and a black void clear color. Modes 0–3 retain their previous rendering behavior.
5. The art experience is a separate full-screen branch inside FaceLab; the existing tracking page, FacePen canvas, and diagnostics remain available after exit.

## Performance and validation

- Topology: 28 rings × 44 segments, generated once per controller.
- Geometry updates: driven by the existing lightweight face-gesture callback; no mesh topology regeneration.
- No new native module, camera session, sensor permission, or third-party dependency.
- Static source checks cover the interaction contract and renderer mode.
- DevEco ArkTS/NDK compilation, on-device frame pacing, thermal behavior, gesture false positives, and long-session stability require MatePad Pro 13.2 validation.

## Privacy and boundaries

Face metrics and generated geometry stay in local process memory. No frames, meshes, or gesture history are persisted or uploaded. The feature controls only its own scene and does not inject system input or control Huawei Notes or other applications.
