declare module 'libfacelab_native.so' {
  const nativeRender: {
    SetSurfaceId(surfaceId: bigint): void;
    ResizeSurface(surfaceId: bigint, width: number, height: number): void;
    UpdateMesh(
      surfaceId: bigint,
      vertices: Float32Array,
      triangles: Uint32Array,
      edges: Uint32Array,
      deformation: Float32Array,
      pitch: number,
      yaw: number,
      roll: number,
      topologyRevision: number,
      mode: number,
      hasMesh: boolean
    ): void;
    ClearMesh(surfaceId: bigint): void;
    DestroySurface(surfaceId: bigint): void;
  };
  export default nativeRender;
}
