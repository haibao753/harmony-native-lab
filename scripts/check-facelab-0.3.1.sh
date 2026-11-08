#!/usr/bin/env bash
set -euo pipefail

callback="apps/facelab/entry/src/main/ets/common/FaceTrackingCallback.ets"
page="apps/facelab/entry/src/main/ets/pages/Index.ets"
manifest="apps/facelab/AppScope/app.json5"

test -s "$callback"
test -s "$page"
test -s "$manifest"

grep -Fq 'captureNeutralBaseline(): void' "$callback"
grep -Fq 'this.neutralVertices = neutralSnapshot' "$callback"
grep -Fq "neutralDeformationSummary = 'RMS '" "$callback"
grep -Fq 'this.poseStepSamples.length > 8' "$callback"
grep -Fq 'trackingStabilitySummary' "$callback"

grep -Fq 'PITCH · 上下点头 (X)' "$page"
grep -Fq 'YAW · 左右转头 (Y)' "$page"
grep -Fq 'ROLL · 左右歪头 (Z)' "$page"
grep -Fq '采集 / 重新采集中性表情' "$page"
grep -Fq '相邻帧网格变化' "$page"

grep -Fq '"versionCode": 10003' "$manifest"
grep -Fq '"versionName": "0.3.1"' "$manifest"

echo "FaceLab 0.3.1 source checks passed."
