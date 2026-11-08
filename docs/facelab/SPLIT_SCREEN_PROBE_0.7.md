# FaceLab 0.7 Split-Screen Camera Continuity Experiment

## Research question

Does the AR Engine face-tracking callback continue to receive frames when FaceLab is still visible in a MatePad split-screen window but the other app owns window focus?

This experiment distinguishes four independent signals:

1. Window mode: `SPLIT_SCREEN`.
2. Visibility / stage lifecycle: visible and not `HIDDEN`.
3. Focus: `INACTIVE` while the other split-screen app is being used.
4. AR delivery: new `ARViewCallback.onFrameUpdate()` callbacks continue arriving and a face remains tracked.

A live process, visible preview, or a stale face count alone is not proof of continuing AR frame delivery.

## Instrumentation

- `windowStageLifecycleEvent` records SHOWN / RESUMED / PAUSED / HIDDEN.
- Main-window `windowEvent` records WINDOW_ACTIVE / WINDOW_INACTIVE / WINDOW_SHOWN / WINDOW_HIDDEN.
- `windowStatusDidChange` records SPLIT_SCREEN / FLOATING / FULL_SCREEN and other modes.
- `windowVisibilityChange` records the system visibility boolean.
- AR callback telemetry counts every active `onFrameUpdate` invocation before the existing gesture and mesh throttles.
- The UI computes the age of the last callback locally; no camera frame or face mesh is stored.

## MatePad test procedure

1. Build and install `apps/facelab` with HarmonyOS SDK 26.
2. Open FaceLab, grant camera permission, start tracking, and keep one face visible. Confirm the face count is greater than zero.
3. Put FaceLab and Huawei Notes into split-screen.
4. Tap inside Huawei Notes so FaceLab loses focus. Do not hide or close the FaceLab window.
5. Confirm the panel shows `SPLIT_SCREEN`, `INACTIVE`, and visible = yes.
6. Keep the state unchanged for at least 10 seconds.
7. Record callback count, estimated callback rate, latest frame age, maximum gap, face count, and the recent window event log.
8. Tap FaceLab again and confirm the focus returns to ACTIVE.
9. Separately send FaceLab fully to the background and confirm HIDDEN cleanup; returning to FaceLab should require a manual restart of AR tracking if the session was released.

## Preliminary pass criteria

The panel shows “初步通过” only if all conditions are met:

- `SPLIT_SCREEN` + `INACTIVE` + visible.
- AR session active and face count greater than zero.
- At least 10 seconds in the inactive state.
- At least 50 AR callback invocations counted during that inactive interval.
- Estimated callback rate at least 5 Hz.
- Last callback age less than 1.5 seconds.

If the callback count stops, the last-frame age grows, or the AR session reports an error, record the failure rather than inferring that the camera is still running.

## Interpretation

- PASS: evidence that AR Engine callbacks continue while the app window is visible but unfocused in split-screen on this exact device / OS build.
- FAIL: evidence that the callback stream stops or becomes unusable in that condition.
- INCONCLUSIVE: window mode/focus/visibility is not correctly reported, face tracking is lost, or the observation is interrupted.

A pass does not establish background camera permission, arbitrary floating-window behavior, or system-wide control of other apps. Repeat the experiment after OS updates and for floating windows separately.

## Privacy and safety

The experiment stores only transient counters and window-state labels in process memory. It does not persist or upload camera frames, face geometry, or facial action data. It does not use keep-alive tricks or inject system input.
