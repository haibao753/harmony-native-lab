# FaceLab 0.3.1 — Motion Intelligence

## Changes

- Map the device-verified pose axes to human-readable semantics: X / Pitch (nodding), Y / Yaw (left-right turn), Z / Roll (side tilt).
- Capture a user-selected neutral-expression face mesh as an in-memory reference.
- Display current-vs-neutral mesh displacement separately from adjacent-frame mesh movement.
- Add a rolling pose-continuity heuristic with qualitative feedback.
- Preserve the existing AR session, camera preview, BlendShapes, pose calibration, and resource cleanup.

## Important interpretation notes

- Mesh RMS / MAX values use raw coordinate units, not millimeters.
- Current-vs-neutral mesh displacement may include both expression and head-pose effects; it is not a pure expression coefficient.
- Pose continuity is a local heuristic derived from consecutive pose samples, not an AR Engine confidence score.
- Face data remains in memory only and is not persisted or uploaded.

## Verification

Source-level checks are included in GitHub Actions. DevEco Studio compilation, HAP packaging, and MatePad Pro 13.2 hardware acceptance remain required before treating 0.3.1 as device-verified.
