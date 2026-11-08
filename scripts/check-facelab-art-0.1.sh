#!/usr/bin/env bash
set -euo pipefail

mapper="apps/facelab/entry/src/main/ets/common/SculptureControlMapper.ets"
experience="apps/facelab/entry/src/main/ets/components/SculptureExperience.ets"
page="apps/facelab/entry/src/main/ets/pages/Index.ets"
renderer="apps/facelab/entry/src/main/cpp/FaceGpuRenderer.cpp"
manifest="apps/facelab/AppScope/app.json5"

for file in "$mapper" "$experience" "$page" "$renderer" "$manifest"; do
  test -s "$file"
done

grep -Fq "class SculptureControlMapper" "$mapper"
grep -Fq "gravityX: Math.sin(rollRadians)" "$mapper"
grep -Fq "leftWink: metrics.leftWink" "$mapper"
grep -Fq "rightWink: metrics.rightWink" "$mapper"
grep -Fq "jawPulse: metrics.jawConfirm" "$mapper"

grep -Fq "this.controls.leftWink" "$experience"
grep -Fq "this.controls.rightWink" "$experience"
grep -Fq "this.controls.jawPulse" "$experience"
grep -Fq "this.controls.gravityX" "$experience"
grep -Fq "4," "$experience"
grep -Fq "FORM BEYOND" "$experience"

grep -Fq "this.sculptureController.update(metrics)" "$page"
grep -Fq "showSculptureExperience" "$page"
grep -Fq "SculptureExperience" "$page"

grep -Fq "uMode == 4" "$renderer"
grep -Fq "mode == 4" "$renderer"
grep -Fq '"versionCode": 10013' "$manifest"
grep -Fq '"versionName": "0.8.0-alpha.1"' "$manifest"

if grep -Eq "OH_Input_InjectTouchEvent|CONTROL_DEVICE|injectGesture" "$page"; then
  echo "Unexpected system-input injection code found."
  exit 1
fi

echo "FaceLab Art 0.1 source contracts passed."
