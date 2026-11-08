# FaceLab 0.5.2 — Gesture Interaction Lab

Date: 2026-11-08

## Goal
Turn the existing AR Engine face-pose and BlendShapes measurements into an opt-in, locally processed interaction prototype while preserving the smooth 0.5.1 GPU visualizer.

## Changes
- Sample lightweight pose / BlendShapes data at an approximately 30 Hz target cadence.
- Keep mesh geometry publication and GPU updates at approximately 5 Hz; high-rate gesture sampling does not increase mesh-copy or render-update cadence.
- Detect unilateral left / right winks with 0.72 close and 0.35 release thresholds, edge-triggering and a 650 ms cooldown.
- Treat simultaneous bilateral eye closure as a natural blink, not a wink command.
- Detect sustained jaw opening at weight >= 0.72 for at least 350 ms; re-arm at <= 0.40 and apply a 1000 ms cooldown.
- Add an opt-in in-app demo: left / right wink changes focus among A / B / C; sustained jaw opening confirms the selected option.
- Keep direct touch and M-Pencil selection available.
- Default gesture input to off. The demo does not inject system-level input or control other applications.

## Validation
- GitHub Actions source-contract checks cover sampling cadence, gesture thresholds, UI wiring, version metadata and preservation of the native GPU renderer.
- DevEco Studio / HarmonyOS SDK 26.0.0 build is pending.
- MatePad Pro 13.2 (2023) hardware acceptance is pending.
- No runtime gesture accuracy or latency claim is made before device testing.

## Privacy
All face geometry and gesture values remain in local memory. No face data is saved or uploaded.
