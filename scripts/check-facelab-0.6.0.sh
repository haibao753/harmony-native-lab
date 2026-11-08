#!/usr/bin/env bash
set -euo pipefail

page="apps/facelab/entry/src/main/ets/pages/Index.ets"
canvas="apps/facelab/entry/src/main/ets/components/FacePenCanvas.ets"
manifest="apps/facelab/AppScope/app.json5"
readme="apps/facelab/README.md"
release="docs/facelab/RELEASE_NOTES_0.6.0-alpha.1.md"

for file in "$page" "$canvas" "$manifest" "$readme" "$release"; do
  test -s "$file"
done

grep -Fq "FACE PEN · 0.1" "$page"
grep -Fq "facePenControlEnabled: boolean = false" "$page"
grep -Fq "this.requestFacePenColorStep(-1, '左眼单眨')" "$page"
grep -Fq "this.requestFacePenColorStep(1, '右眼单眨')" "$page"
grep -Fq "this.facePenControlEnabled = false" "$page"
grep -Fq "this.facePenPendingColorIndex" "$page"
grep -Fq "this.facePenStrokeActive" "$page"
grep -Fq "FacePenCanvas({" "$page"

grep -Fq "SourceTool.Pen" "$canvas"
grep -Fq "TouchType.Down" "$canvas"
grep -Fq "TouchType.Move" "$canvas"
grep -Fq "TouchType.Up" "$canvas"
grep -Fq "TouchType.Cancel" "$canvas"
grep -Fq "event.stopPropagation()" "$canvas"
grep -Fq "this.activeStrokeColor = this.selectedColor" "$canvas"
grep -Fq "event.getHistoricalPoints()" "$canvas"
grep -Fq "point.pressure" "$canvas"
grep -Fq "this.context.clearRect" "$canvas"

grep -Fq '"versionCode": 10011' "$manifest"
grep -Fq '"versionName": "0.6.0-alpha.1"' "$manifest"
grep -Fq "FacePen" "$readme"
grep -Fq "Stroke Transaction" "$release"
grep -Fq "真机" "$release"

echo "FaceLab 0.6.0-alpha.1 FacePen source checks passed."
