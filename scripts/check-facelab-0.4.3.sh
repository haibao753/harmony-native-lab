#!/usr/bin/env bash
set -euo pipefail

callback="apps/facelab/entry/src/main/ets/common/FaceTrackingCallback.ets"
page="apps/facelab/entry/src/main/ets/pages/Index.ets"
viewer="apps/facelab/entry/src/main/ets/components/FaceMeshViewer.ets"
manifest="apps/facelab/AppScope/app.json5"
readme="apps/facelab/README.md"
release="docs/facelab/RELEASE_NOTES_0.4.3.md"

for file in "$callback" "$page" "$viewer" "$manifest" "$readme" "$release"; do
  test -s "$file"
done

grep -Fq 'sysBootTs - this.lastPublishedTimestamp < 200000' "$callback"
grep -Fq 'this.processing ||' "$callback"
grep -Fq 'meshDeformation[Math.floor(i / 3)] = displacement' "$callback"
grep -Fq "neutralDeformationSummary = '动态位移 RMS ' + rms.toFixed(5)" "$callback"
grep -Fq '@Prop vertices: number[] = []' "$viewer"
grep -Fq 'if (this.deformation.length === vertexCount)' "$viewer"
grep -Fq "this.hasNeutral ? 'NEUTRAL Δ' : 'LIVE MOTION Δ'" "$viewer"
grep -Fq "Button('采集基准')" "$page"
grep -Fq 'AR Face Tracking Lab · 0.4.3' "$page"
grep -Fq '"versionCode": 10007' "$manifest"
grep -Fq '"versionName": "0.4.3"' "$manifest"
grep -Fq 'FaceLab 0.4.3' "$release"

echo "FaceLab 0.4.3 source checks passed."
