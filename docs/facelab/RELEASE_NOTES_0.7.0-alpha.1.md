# FaceLab 0.7.0-alpha.1 — Split-Screen Camera Continuity Probe

## Scope

This alpha adds instrumentation to answer one narrow question on MatePad Pro 13.2 (2023):

> When FaceLab remains visible in split-screen but loses window focus, does AR Engine continue delivering face-tracking frame callbacks?

It does not promise background camera operation and does not attempt to bypass HarmonyOS privacy restrictions.

## Included

- Explicit multi-window support declaration: fullscreen, split, floating.
- WindowStage lifecycle telemetry: SHOWN / RESUMED / PAUSED / HIDDEN.
- Main-window focus telemetry: ACTIVE / INACTIVE.
- Window mode and visibility telemetry.
- ARViewCallback frame callback count, estimated callback rate, last interval and maximum observed interval.
- A 10-second preliminary observation indicator for visible, split-screen, unfocused operation.
- Automatic AR session cleanup after the window is genuinely HIDDEN.

## Preliminary observation threshold

The in-app indicator reports a preliminary pass only when all of the following hold:

- Window mode is SPLIT_SCREEN.
- Window remains visible and focus state is INACTIVE.
- AR session is active and at least one face remains tracked.
- The inactive observation lasts at least 10 seconds.
- At least 50 AR frame callbacks are observed during that interval.
- Estimated callback rate is at least 5 Hz and the most recent callback is less than 1.5 seconds old.

This is a diagnostic threshold, not a camera FPS guarantee or a final product acceptance result.

## Build and device validation

- Static source contract: added to GitHub Actions.
- DevEco Studio / SDK 26 build: pending.
- MatePad Pro 13.2 (2023) split-screen test: pending.
- Full background / HIDDEN cleanup test: pending.

## Privacy and non-goals

- No camera frames, face meshes, or facial action data are persisted or uploaded.
- No background keep-alive, system touch injection, accessibility gesture injection, or third-party app control.
- No claim is made about controlling Huawei Notes.
