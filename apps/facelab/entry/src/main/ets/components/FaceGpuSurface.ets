import { XComponentController, XComponentType } from '@kit.ArkUI';
import nativeRender from 'libfacelab_native.so';
import { FaceMetrics } from '../common/FaceTrackingCallback';

export class FaceGpuSurfaceController extends XComponentController {
  private surfaceId: bigint | undefined = undefined;
  private latestMetrics: FaceMetrics | undefined = undefined;
  private latestMode: string = 'wireframe';
  private lastTouchX: number = -1;
  private lastTouchY: number = -1;
  private lastPinchDistance: number = 0;
  private viewPitch: number = 0;
  private viewYaw: number = 0;
  private viewZoom: number = 1;

  onSurfaceCreated(surfaceId: string): void {
    const id = BigInt(surfaceId);
    this.surfaceId = id;
    nativeRender.SetSurfaceId(id);
    this.publishViewTransform();
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

  handleTouch(event: TouchEvent): void {
    const touches = event.touches;
    if (touches.length === 1) {
      const point = touches[0];
      if (this.lastTouchX >= 0) {
        this.viewYaw += (point.x - this.lastTouchX) * 0.42;
        this.viewPitch += (point.y - this.lastTouchY) * 0.42;
        this.viewPitch = Math.max(-78, Math.min(78, this.viewPitch));
      }
      this.lastTouchX = point.x;
      this.lastTouchY = point.y;
      this.lastPinchDistance = 0;
      this.publishViewTransform();
      return;
    }
    if (touches.length >= 2) {
      const dx = touches[1].x - touches[0].x;
      const dy = touches[1].y - touches[0].y;
      const distance = Math.sqrt(dx * dx + dy * dy);
      if (this.lastPinchDistance > 0 && distance > 0) {
        this.viewZoom = Math.max(0.65, Math.min(2.8, this.viewZoom * distance / this.lastPinchDistance));
      }
      this.lastPinchDistance = distance;
      this.lastTouchX = -1;
      this.lastTouchY = -1;
      this.publishViewTransform();
      return;
    }
    this.lastTouchX = -1;
    this.lastTouchY = -1;
    this.lastPinchDistance = 0;
  }

  resetView(): void {
    this.viewPitch = 0;
    this.viewYaw = 0;
    this.viewZoom = 1;
    this.publishViewTransform();
  }

  private publishViewTransform(): void {
    if (this.surfaceId !== undefined) {
      nativeRender.SetViewTransform(this.surfaceId, this.viewPitch, this.viewYaw, this.viewZoom);
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
      type: XComponentType.SURFACE,
      controller: this.controller
    })
      .onTouch((event: TouchEvent) => {
        this.controller.handleTouch(event);
      })
      .width('100%')
      .height(340)
      .backgroundColor('#0B1422')
      .borderRadius(12)
  }
}
