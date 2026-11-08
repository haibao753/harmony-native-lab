#!/usr/bin/env bash
set -Eeuo pipefail

# Generate a real Stage project from Huawei's installed API 26 toolchain,
# then overlay the AlgoLab ArkTS source. No project metadata is fabricated here.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="${ALGOLAB_APP_NAME:-AlgoLab}"
BUNDLE_NAME="${ALGOLAB_BUNDLE_NAME:-com.haibao.algolab}"
API_LEVEL="${HARMONYOS_API_LEVEL:-26}"
OUTPUT_DIR="${1:-$ROOT_DIR/dist/AlgoLab-Stage}"

if [[ "$API_LEVEL" != "26" ]]; then
  echo "This bootstrap is pinned to API 26 for the confirmed HarmonyOS 7.0.0 device." >&2
  echo "Refusing API level: $API_LEVEL" >&2
  exit 2
fi

if ! command -v devecocli >/dev/null 2>&1; then
  cat >&2 <<'EOF'
devecocli was not found.

Install Huawei Command Line Tools 26.0.0 Release (which includes HarmonyOS SDK),
configure its environment as documented by Huawei, and install the official
DevEco CLI package. Then verify with:

  devecocli help

This script does not download proprietary toolchains or invent Stage metadata.
EOF
  exit 127
fi

if [[ -e "$OUTPUT_DIR" ]]; then
  echo "Output already exists; refusing to overwrite: $OUTPUT_DIR" >&2
  exit 3
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

PROJECT_DIR="$TMP_DIR/$APP_NAME"

echo "Creating a Stage project with API $API_LEVEL..."
devecocli create \
  --project-path "$PROJECT_DIR" \
  --app-name "$APP_NAME" \
  --bundle-name "$BUNDLE_NAME" \
  --api-level "$API_LEVEL"

required_files=(
  "AppScope/app.json5"
  "entry/src/main/module.json5"
  "entry/src/main/ets/pages/Index.ets"
  "build-profile.json5"
)
for relative_path in "${required_files[@]}"; do
  if [[ ! -f "$PROJECT_DIR/$relative_path" ]]; then
    echo "The official CLI template did not produce expected file: $relative_path" >&2
    echo "No source overlay was applied. Inspect the generated template before proceeding." >&2
    exit 4
  fi
done

ETS_ROOT="$PROJECT_DIR/entry/src/main/ets"
mkdir -p "$ETS_ROOT/domain" "$ETS_ROOT/codegen"

cp "$ROOT_DIR/apps/algolab/entry/src/main/ets/domain/LinkedListModel.ets" \
  "$ETS_ROOT/domain/LinkedListModel.ets"
cp "$ROOT_DIR/apps/algolab/entry/src/main/ets/codegen/CppLinkedListGenerator.ets" \
  "$ETS_ROOT/codegen/CppLinkedListGenerator.ets"
cp "$ROOT_DIR/apps/algolab/entry/src/main/ets/pages/Index.ets" \
  "$ETS_ROOT/pages/Index.ets"

mkdir -p "$(dirname "$OUTPUT_DIR")"
cp -a "$PROJECT_DIR" "$OUTPUT_DIR"

cat <<EOF
Stage project generated:
  $OUTPUT_DIR

Target:
  HarmonyOS 7.0.0 / API 26
  $BUNDLE_NAME

Next:
  cd "$OUTPUT_DIR"
  devecocli build --modules entry --build-mode debug

The HAP build has NOT been run by this bootstrap script.
EOF
