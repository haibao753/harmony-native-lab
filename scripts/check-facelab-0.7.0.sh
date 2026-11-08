#!/usr/bin/env bash
set -euo pipefail

ability="apps/facelab/entry/src/main/ets/entryability/EntryAbility.ets"
page="apps/facelab/entry/src/main/ets/pages/Index.ets"
callback="apps/facelab/entry/src/main/ets/common/FaceTrackingCallback.ets"
module="apps/facelab/entry/src/main/module.json5"
manifest="apps/facelab/AppScope/app.json5"

for file in "$ability" "$page" "$callback" "$module" "$manifest"; do
  test -s "$file"
done

grep -Fq "windowStageLifecycleEvent" "$ability"
grep -Fq "windowEvent" "$ability"
grep -Fq "windowStatusDidChange" "$ability"
grep -Fq "windowVisibilityChange" "$ability"
grep -Fq "WINDOW_INACTIVE" "$ability"
grep -Fq "SPLIT_SCREEN" "$ability"

grep -Fq "faceLabWindowFocus" "$page"
grep -Fq "framesWhileInactive" "$page"
grep -Fq "frameAgeMs" "$page"
grep -Fq "splitProbeStatus" "$page"
grep -Fq "INACTIVE" "$page"

grep -Fq "FaceFrameDiagnostics" "$callback"
grep -Fq "recordFramePulse(sysBootTs)" "$callback"
grep -Fq "callbackCount: this.frameCallbackCount" "$callback"

grep -Fq '"supportWindowMode": ["fullscreen", "split", "floating"]' "$module"
grep -Fq '"versionCode": 10012' "$manifest"
grep -Fq '"versionName": "0.7.0-alpha.1"' "$manifest"

if grep -Eq "OH_Input_InjectTouchEvent|CONTROL_DEVICE|injectGesture" "$page" "$ability"; then
  echo "Unexpected system-input injection code found."
  exit 1
fi

echo "FaceLab 0.7.0 split-screen probe source checks passed."
