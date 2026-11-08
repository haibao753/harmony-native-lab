# FaceLab 0.6.0-alpha.1 — FacePen Prototype

Date: 2026-11-08

## Goal

Connect the existing 0.5.2 unilateral-wink event pipeline to a local M-Pencil drawing surface without changing the stable GPU face visualizer or AR session lifecycle.

## Implemented

## Stroke Transaction

The active stroke color is snapshotted at pointer DOWN. Palette changes received while the pen is down remain pending and are applied only after pointer UP or CANCEL.

- Added a dedicated ArkUI Canvas drawing component using CanvasRenderingContext2D.
- Accept only `TouchEvent.sourceTool === SourceTool.Pen`; finger input does not create strokes.
- Process `Down`, `Move`, `Up`, and `Cancel`; consume stylus events to prevent them from bubbling into the outer Scroll or the 3D face surface.
- Draw historical touch points before the current point to reduce gaps between samples.
- Use the optional API 15+ pressure value for line-width variation, with a fixed-width fallback when pressure is absent or zero.
- Add six manual colors: ink black, vermilion, cobalt blue, pine green, amber, and wisteria.
- Route left wink to the previous palette color and right wink to the next palette color.
- Reuse the existing 0.5.2 wink event detector, including its unilateral closure confirmation and 650 ms cooldown; no second wink detector is introduced.
- Freeze the active stroke color at DOWN. Face and manual color changes received during a stroke are queued and applied only after UP or CANCEL.
- Keep face control opt-in, mutually exclusive with the A/B/C gesture demo, and automatically pause it when face tracking is lost.
- Keep the FacePen canvas in its own card, separate from the GPU XComponent surface.

## Deliberate limitations

- FacePen controls only its own drawing surface. It does not change the pen color in Huawei Notes or another application.
- StylusFrameBoost is not used in this alpha because its exact public SDK signature and availability were not confirmed for this project; standard Canvas rendering remains the fallback and baseline.
- The prototype does not yet implement undo, stroke persistence, export, palm rejection policy, or a full pressure/tilt brush engine.
- Canvas contents may be cleared when the Canvas is recreated or resized; persistence is not part of this alpha.

## Validation status

- GitHub source-contract checks are added for FacePen event routing, color freezing, pending-color commit, palette wiring, and version metadata.
- ArkTS / DevEco SDK 26.0.0 compilation: **not yet run in this environment**.
- MatePad Pro 13.2 (2023) M-Pencil hardware validation: **pending**.
- Pressure range and SourceTool.Pen behavior must be confirmed on the target tablet.
- No runtime accuracy, latency, or sustained-performance claims are made before device testing.

## Privacy

Face tracking and wink values remain local to the application. The drawing component does not save or upload face data or handwriting.
