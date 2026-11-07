#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_ROOT="${1:-$ROOT_DIR/dist}"
STAGE_DIR="$OUTPUT_ROOT/AlgoLab-Stage"
ARTIFACT_DIR="$OUTPUT_ROOT/artifacts"

if ! command -v devecocli >/dev/null 2>&1; then
  echo "devecocli is required. Configure Huawei Command Line Tools and DevEco CLI first." >&2
  exit 127
fi

if [[ -e "$STAGE_DIR" ]]; then
  echo "Stage output already exists; refusing to overwrite: $STAGE_DIR" >&2
  exit 3
fi

mkdir -p "$OUTPUT_ROOT"
bash "$ROOT_DIR/scripts/bootstrap-algolab-stage.sh" "$STAGE_DIR"

echo "Building entry HAP with the official DevEco CLI..."
(
  cd "$STAGE_DIR"
  devecocli build --modules entry --build-mode debug
)

mkdir -p "$ARTIFACT_DIR"
mapfile -t HAP_FILES < <(find "$STAGE_DIR/entry/build" -type f -name '*.hap' -print 2>/dev/null | sort)

if [[ "${#HAP_FILES[@]}" -eq 0 ]]; then
  echo "Build command returned, but no HAP file was found under entry/build." >&2
  exit 5
fi

for hap in "${HAP_FILES[@]}"; do
  cp "$hap" "$ARTIFACT_DIR/"
  echo "HAP_ARTIFACT=$ARTIFACT_DIR/$(basename "$hap")"
done

echo "Build completed. Review the CLI output to determine signing status before device installation."
