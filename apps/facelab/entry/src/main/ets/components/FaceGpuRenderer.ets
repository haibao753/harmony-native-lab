import nativeRenderer from 'libfacelab_renderer.so';

class FaceLabGpuSurfaceController extends XComponentController {
  onSurfaceCreated(surfaceId: string): void {
    nativeRenderer.SetSurfaceId(BigInt(surfaceId));
  }

  onSurfaceChanged(surfaceId: string, rect: SurfaceRect): void {
    nativeRenderer.ChangeSurface(BigInt(surfaceId), rect.surfaceWidth, rect.surfaceHeight);
  }

  onSurfaceDestroyed(surfaceId: string): void {
    nativeRenderer.DestroySurface(BigInt(surfaceId));
  }
}

@Component
export struct FaceGpuRenderer {
  @Prop @Watch('syncMode') mode: string = 'surface';
  @Prop @Watch('resetView') resetKey: number = 0;

  private controller: FaceLabGpuSurfaceController = new FaceLabGpuSurfaceController();
  private lastTouchX: number = -1;
  private lastTouchY: number = -1;
  private lastPinchDistance: number = 0;
  private viewYaw: number = 0;
  private viewPitch: number = 0;
  private zoom: number = 1;

  private modeIndex(): number {
    if (this.mode === 'wireframe') return 0;
    if (this.mode === 'deformation') return 2;
    if (this.mode === 'regions') return 3;
    return 1;
  }

  syncMode(): void {
    nativeRenderer.SetMode(this.modeIndex());
  }

  resetView(): void {
    this.viewYaw = 0;
    this.viewPitch = 0;
    this.zoom = 1;
    this.lastTouchX = -1;
    this.lastTouchY = -1;
    this.lastPinchDistance = 0;
    nativeRenderer.SetViewTransform(0, 0, 1);
  }

  aboutToAppear(): void {
    nativeRenderer.SetMode(this.modeIndex());
  }

  private handleTouch(event: TouchEvent): void {
    const touches = event.touches;
    if (touches.length === 1) {
      const point = touches[0];
      if (this.lastTouchX >= 0) {
        this.viewYaw += (point.x - this.lastTouchX) * 0.008;
        this.viewPitch += (point.y - this.lastTouchY) * 0.008;
        this.viewPitch = Math.max(-1.35, Math.min(1.35, this.viewPitch));
        nativeRenderer.SetViewTransform(this.viewYaw, this.viewPitch, this.zoom);
      }
      this.lastTouchX = point.x;
      this.lastTouchY = point.y;
      this.lastPinchDistance = 0;
      return;
    }
    if (touches.length >= 2) {
      const first = touches[0];
      const second = touches[1];
      const dx = second.x - first.x;
      const dy = second.y - first.y;
      const distance = Math.sqrt(dx * dx + dy * dy);
      if (this.lastPinchDistance > 0 && distance > 0) {
        this.zoom = this.zoom * distance / this.lastPinchDistance;
        this.zoom = Math.max(0.65, Math.min(2.8, this.zoom));
        nativeRenderer.SetViewTransform(this.viewYaw, this.viewPitch, this.zoom);
      }
      this.lastPinchDistance = distance;
      this.lastTouchX = -1;
      this.lastTouchY = -1;
      return;
    }
    this.lastTouchX = -1;
    this.lastTouchY = -1;
    this.lastPinchDistance = 0;
  }

  build() {
    Column() {
      XComponent({
        id: 'facelab-gpu-renderer',
        type: XComponentType.SURFACE,
        controller: this.controller
      })
        .width('100%')
        .height(340)
        .onTouch((event: TouchEvent) => {
          this.handleTouch(event);
        })
    }
    .width('100%')
    .height(340)
    .backgroundColor('#0B1422')
    .borderRadius(12)
  }
}
