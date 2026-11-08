export const SetSurfaceId: (surfaceId: BigInt) => void;
export const ChangeSurface: (surfaceId: BigInt, width: number, height: number) => void;
export const DestroySurface: (surfaceId: BigInt) => void;
export const UpdateMesh: (
  vertices: Float32Array,
  triangles: Uint32Array,
  edges: Uint32Array,
  deformation: Float32Array,
  labels: Int32Array,
  pitch: number,
  yaw: number,
  roll: number,
  topologyRevision: number
) => void;
export const ClearMesh: () => void;
export const SetMode: (mode: number) => void;
export const SetViewTransform: (yawRadians: number, pitchRadians: number, zoom: number) => void;
