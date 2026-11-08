# FaceLab 0.8.0-alpha.1 — FaceLab Art 0.1 / FORM BEYOND

## Included

- New full-screen liquid-sculpture art experience.
- Reuses the existing face tracking session and FaceGestureMetrics stream.
- Head roll steers the deformation field; pitch and yaw orbit the camera.
- Left wink grows the form; right wink erodes it; sustained jaw confirmation triggers a pulse.
- Procedural UV surface with a chrome-style reflection shader and black void background.
- Touch orbit and pinch zoom remain available as fallbacks.
- Existing face-mesh modes and FacePen canvas remain separate from the art scene.

## Verification boundary

- GitHub Actions source-contract checks are included.
- DevEco Studio ArkTS / NDK build has not yet been run for this alpha.
- MatePad Pro 13.2 runtime validation is pending.
- No measured FPS, thermal, battery, or gesture false-positive claim is made.

## Privacy

All face metrics and sculpture geometry remain in local memory. No face data is saved or uploaded. The scene does not control other apps or inject system-level input.
