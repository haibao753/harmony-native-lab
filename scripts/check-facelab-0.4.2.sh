#!/usr/bin/env bash
set -euo pipefail

callback="apps/facelab/entry/src/main/ets/common/FaceTrackingCallback.ets"
page="apps/facelab/entry/src/main/ets/pages/Index.ets"
viewer="apps/facelab/entry/src/main/ets/components/FaceMeshViewer.ets"
manifest="apps/facelab/AppScope/app.json5"
readme="apps/facelab/README.md"
release="docs/facelab/RELEASE_NOTES_0.4.2.md"

for file in "$callback" "$page" "$viewer" "$manifest" "$readme" "$release"; do
  test -s "$file"
done

# Typed buffers stay in the AR processing layer.
grep -Fq 'meshVertices: Float32Array' "$callback"
grep -Fq 'meshTriangles: Uint32Array' "$callback"
grep -Fq 'meshEdges: Uint32Array' "$callback"
grep -Fq 'meshDeformation: Float32Array' "$callback"
grep -Fq 'meshLabels: Int32Array' "$callback"

# Callback is throttled and cannot process overlapping async frames.
grep -Fq 'sysBootTs - this.lastPublishedTimestamp < 100000' "$callback"
grep -Fq 'this.processing ||' "$callback"
grep -Fq 'this.processing = true' "$callback"
grep -Fq 'this.processing = false' "$callback"

# Stable typed buffers and previous-frame snapshots are reused.
grep -Fq 'this.cachedMeshVertices.set(currentVertices)' "$callback"
grep -Fq 'this.cachedMeshDeformation' "$callback"
grep -Fq 'this.previousVertices.set(currentVertices)' "$callback"
grep -Fq 'meshTopologyRevision: this.meshTopologyRevision' "$callback"

# ArkUI receives ordinary arrays; no TypedArray crosses @Prop boundary.
grep -Fq '@Prop vertices: number[] = []' "$viewer"
grep -Fq '@Prop triangles: number[] = []' "$viewer"
grep -Fq '@Prop edges: number[] = []' "$viewer"
grep -Fq '@Prop deformation: number[] = []' "$viewer"
grep -Fq '@Prop labels: number[] = []' "$viewer"
if grep -Eq 'Float32Array|Uint32Array|Int32Array' "$viewer"; then
  echo "TypedArray leaked into FaceMeshViewer." >&2
  exit 1
fi

# Reuse plain arrays at the UI boundary; static topology changes only by revision.
grep -Fq 'private copyNumericData' "$page"
grep -Fq 'this.copyNumericData(this.meshVertices, metrics.meshVertices)' "$page"
grep -Fq 'this.copyNumericData(this.meshDeformation, metrics.meshDeformation)' "$page"
grep -Fq 'this.meshTopologyRevision !== metrics.meshTopologyRevision' "$page"
grep -Fq 'this.copyNumericData(this.meshTriangles, metrics.meshTriangles)' "$page"
grep -Fq 'this.copyNumericData(this.meshEdges, metrics.meshEdges)' "$page"
grep -Fq 'this.copyNumericData(this.meshLabels, metrics.meshLabels)' "$page"
if grep -Fq 'Array.from(metrics.' "$page"; then
  echo "Per-frame Array.from allocation regressed in Index.ets." >&2
  exit 1
fi
grep -Fq 'now - this.lastTextMetricsUpdate >= 500' "$page"

# Four modes have materially different render paths.
grep -Fq "this.mode === 'surface'" "$viewer"
grep -Fq "this.mode === 'regions'" "$viewer"
grep -Fq "this.mode === 'deformation'" "$viewer"
grep -Fq "this.mode === 'wireframe'" "$viewer"
grep -Fq 'this.surfaceColors[bucket]' "$viewer"
grep -Fq 'this.deformationColors[bucket]' "$viewer"
grep -Fq 'this.drawEdges(1, ' "$viewer"
grep -Fq 'this.projectedPoints' "$viewer"
grep -Fq 'this.rebuildRegionBins()' "$viewer"
grep -Fq 'DRAW CALL ' "$viewer"
grep -Fq 'lastDrawCostMs' "$viewer"
grep -Fq 'Canvas(this.context)' "$viewer"

# Version metadata and user-facing identity agree.
grep -Fq '"versionCode": 10006' "$manifest"
grep -Fq '"versionName": "0.4.2"' "$manifest"
grep -Fq 'AR Face Tracking Lab · 0.4.2' "$page"
grep -Fq 'FaceLab 0.4.2' "$release"

echo "FaceLab 0.4.2 source checks passed."
