#!/usr/bin/env bash
set -euo pipefail

callback="apps/facelab/entry/src/main/ets/common/FaceTrackingCallback.ets"
page="apps/facelab/entry/src/main/ets/pages/Index.ets"
viewer="apps/facelab/entry/src/main/ets/components/FaceMeshViewer.ets"
manifest="apps/facelab/AppScope/app.json5"
release="docs/facelab/RELEASE_NOTES_0.4.1.md"

for file in "$callback" "$page" "$viewer" "$manifest" "$release"; do
  test -s "$file"
done

# Typed buffers remain in the AR processing layer.
grep -Fq 'meshVertices: Float32Array' "$callback"
grep -Fq 'meshTriangles: Uint32Array' "$callback"
grep -Fq 'meshEdges: Uint32Array' "$callback"
grep -Fq 'meshDeformation: Float32Array' "$callback"
grep -Fq 'meshLabels: Int32Array' "$callback"

# Every typed buffer is converted before crossing into ArkUI component props.
grep -Fq 'this.meshVertices = Array.from(metrics.meshVertices)' "$page"
grep -Fq 'this.meshTriangles = Array.from(metrics.meshTriangles)' "$page"
grep -Fq 'this.meshEdges = Array.from(metrics.meshEdges)' "$page"
grep -Fq 'this.meshDeformation = Array.from(metrics.meshDeformation)' "$page"
grep -Fq 'this.meshLabels = Array.from(metrics.meshLabels)' "$page"

# The viewer accepts ordinary arrays only; no TypedArray is allowed in this layer.
grep -Fq '@Prop vertices: number[] = []' "$viewer"
grep -Fq '@Prop triangles: number[] = []' "$viewer"
grep -Fq '@Prop edges: number[] = []' "$viewer"
grep -Fq '@Prop deformation: number[] = []' "$viewer"
grep -Fq '@Prop labels: number[] = []' "$viewer"
if grep -Eq 'Float32Array|Uint32Array|Int32Array' "$viewer"; then
  echo "TypedArray leaked into FaceMeshViewer; ArkUI @Prop boundary is unsafe." >&2
  exit 1
fi

# Verify that each converted array is actually wired into the viewer.
grep -Fq 'vertices: this.meshVertices' "$page"
grep -Fq 'triangles: this.meshTriangles' "$page"
grep -Fq 'edges: this.meshEdges' "$page"
grep -Fq 'deformation: this.meshDeformation' "$page"
grep -Fq 'labels: this.meshLabels' "$page"

# Preserve all four visualizer modes and the event-driven Canvas renderer.
grep -Fq "this.meshViewMode = 'regions'" "$page"
grep -Fq "this.meshViewMode = 'deformation'" "$page"
grep -Fq 'meshRevision++' "$page"
grep -Fq 'Canvas(this.context)' "$viewer"
grep -Fq "this.mode === 'wireframe'" "$viewer"
grep -Fq "this.mode === 'surface'" "$viewer"
grep -Fq "this.mode === 'deformation'" "$viewer"
grep -Fq "this.mode === 'regions'" "$viewer"
grep -Fq '.onTouch((event: TouchEvent)' "$viewer"
grep -Fq 'this.poseYaw * Math.PI / 180' "$viewer"

# Version and user-facing release identity must agree.
grep -Fq '"versionCode": 10005' "$manifest"
grep -Fq '"versionName": "0.4.1"' "$manifest"
grep -Fq 'AR Face Tracking Lab · 0.4.1' "$page"
grep -Fq 'FaceLab 0.4.1' "$release"

echo "FaceLab 0.4.1 source checks passed."
