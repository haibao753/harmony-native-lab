# FaceLab 0.6.0-alpha.1 — FacePen Prototype

Date: 2026-11-08

## Goal

Connect the existing 0.5.2 unilateral-wink event pipeline to a local M-Pencil drawing surface without changing the stable GPU face visualizer or AR session lifecycle.

## Implemented

- Added a dedicated ArkUI Canvas drawing component using CanvasRenderingContext2D.
- Accept only `TouchEvent.sourceTool === SourceTool.Pen`; finger input does not create strokes. M-Pencil is the target device, but the component does not identify a pen by brand.
- Process `Down`, `Move`, `Up`, and `Cancel`; consume stylus events to prevent them from bubbling into the outer Scroll or the 3D face surface.
- Draw historical touch points before the current point to reduce gaps between samples.
- Use the optional API 15+ pressure value for line-width variation, with a fixed-width fallback when pressure is absent or zero.
- Add six manual colors: ink black, vermilion, cobalt blue, pine green, amber, and wisteria.
- Route left wink to the previous palette color and right wink to the next palette color.
- Reuse the existing 0.5.2 wink event detector, including its unilateral closure confirmation and 650 ms cooldown; no second wink detector is introduced.
- Keep face control opt-in, mutually exclusive with the A/B/C gesture demo, and automatically pause it when face tracking is lost.
- Keep the FacePen canvas in its own card, separate from the GPU XComponent surface.

## Stroke Transaction

The active stroke color is snapshotted at pointer DOWN. Palette changes received while the pen is down remain pending and are applied only after pointer UP or CANCEL. This prevents a single stroke from changing color halfway through.

## Deliberate limitations

- FacePen controls only its own drawing surface. It does not change the pen color in Huawei Notes or another application.
- API 26 `StylusFrameBoost` is a best-effort optimization on stylus DOWN / MOVE / UP / CANCEL. Constructor failure, exceptions, or a non-zero result disable the optimization while leaving normal Canvas drawing available.
- The prototype does not yet implement undo, stroke persistence, export, palm rejection policy, or a full pressure/tilt brush engine.
- Canvas contents may be cleared when the Canvas is recreated or resized; persistence is not part of this alpha.

## Validation status

- GitHub source-contract checks are added for FacePen event routing, color freezing, pending-color commit, palette wiring, and version metadata.
- ArkTS / DevEco SDK 26.0.0 compilation: **not yet run in this environment**.
- MatePad Pro 13.2 (2023) M-Pencil 真机硬件验证：**pending**。
- Pressure range and SourceTool.Pen behavior must be confirmed on the target tablet.
- No runtime accuracy, latency, or sustained-performance claims are made before device testing.

## Privacy

Face tracking and wink values remain local to the application. The drawing component does not save or upload face data or handwriting.
