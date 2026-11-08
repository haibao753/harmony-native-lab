import { XComponentController, XComponentType } from '@kit.ArkUI';
import nativeRender from 'libfacelab_native.so';
import { FaceMetrics } from '../common/FaceTrackingCallback';

export class FaceGpuSurfaceController extends XComponentController {
  private surfaceId: bigint | undefined = undefined;
  private latestMetrics: FaceMetrics | undefined = undefined;
  private latestMode: string = 'wireframe';

  onSurfaceCreated(surfaceId: string): void {
    const id = BigInt(surfaceId);
    this.surfaceId = id;
    nativeRender.SetSurfaceId(id);
    this.publishLatest();
  }

  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    nativeRender.ResizeSurface(BigInt(surfaceId), rect.surfaceWidth, rect.surfaceHeight);
  }

  onSurfaceDestroyed(surfaceId: string): void {
    const id = BigInt(surfaceId);
    nativeRender.DestroySurface(id);
    if (this.surfaceId === id) {
      this.surfaceId = undefined;
    }
  }

  update(metrics: FaceMetrics, mode: string): void {
    this.latestMetrics = metrics;
    this.latestMode = mode;
    this.publishLatest();
  }

  clear(): void {
    this.latestMetrics = undefined;
    if (this.surfaceId !== undefined) {
      nativeRender.ClearMesh(this.surfaceId);
    }
  }

  private modeCode(mode: string): number {
    if (mode === 'surface') {
      return 1;
    }
    if (mode === 'deformation') {
      return 2;
    }
    return 0;
  }

  private publishLatest(): void {
    const id = this.surfaceId;
    const metrics = this.latestMetrics;
    if (id === undefined || metrics === undefined) {
      return;
    }
    nativeRender.UpdateMesh(
      id,
      metrics.meshVertices,
      metrics.meshTriangles,
      metrics.meshEdges,
      metrics.meshDeformation,
      metrics.posePitch,
      metrics.poseYaw,
      metrics.poseRoll,
      metrics.meshTopologyRevision,
      this.modeCode(this.latestMode),
      metrics.meshFrameAvailable
    );
  }
}

@Component
export struct FaceGpuSurface {
  controller: FaceGpuSurfaceController = new FaceGpuSurfaceController();

  build() {
    XComponent({
      id: 'facelab-gpu-face-surface',
      type: XComponentType.SURFACE,
      controller: this.controller
    })
      .width('100%')
      .height(340)
      .backgroundColor('#0B1422')
      .borderRadius(12)
  }
}
