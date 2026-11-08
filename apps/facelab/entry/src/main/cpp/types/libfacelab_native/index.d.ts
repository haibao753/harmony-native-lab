interface FaceLabNativeRender {
  SetSurfaceId(surfaceId: bigint): void;
  SetViewTransform(surfaceId: bigint, pitch: number, yaw: number, zoom: number): void;
  ResizeSurface(surfaceId: bigint, width: number, height: number): void;
  UpdateMesh(
    surfaceId: bigint,
    vertices: Float32Array,
    triangles: Uint32Array,
    edges: Uint32Array,
    deformation: Float32Array,
    labels: Int32Array,
    pitch: number,
    yaw: number,
    roll: number,
    topologyRevision: number,
    mode: number,
    hasMesh: boolean
  ): void;
  ClearMesh(surfaceId: bigint): void;
  DestroySurface(surfaceId: bigint): void;
}

declare const nativeRender: FaceLabNativeRender;
export default nativeRender;
