import nativeRender from 'libfacelab_native.so';
import { FaceGestureMetrics } from '../common/FaceTrackingCallback';
import { SculptureControlFrame, SculptureControlMapper } from '../common/SculptureControlMapper';

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, value));
}

/**
 * Generates a small, deterministic UV sculpture mesh and feeds the existing
 * native GPU renderer. Topology is created once; only vertex positions change.
 */
export class SculptureGpuSurfaceController extends XComponentController {
  private readonly rings: number = 28;
  private readonly segments: number = 44;
  private readonly mapper: SculptureControlMapper = new SculptureControlMapper();

  private surfaceId: bigint | undefined = undefined;
  private vertices: Float32Array = new Float32Array(0);
  private triangles: Uint32Array = new Uint32Array(0);
  private edges: Uint32Array = new Uint32Array(0);
  private deformation: Float32Array = new Float32Array(0);
  private labels: Int32Array = new Int32Array(0);

  private phase: number = 0;
  private growth: number = 1.0;
  private erosion: number = 0;
  private pulse: number = 0;
  private facePitch: number = 0;
  private faceYaw: number = 0;
  private touchPitch: number = 0;
  private touchYaw: number = 0;
  private viewZoom: number = 0.92;
  private lastTouchX: number = -1;
  private lastTouchY: number = -1;
  private lastPinchDistance: number = 0;
  private controls: SculptureControlFrame = {
    pitch: 0,
    yaw: 0,
    roll: 0,
    gravityX: 0,
    gravityY: -1,
    leftWink: false,
    rightWink: false,
    jawPulse: false
  };

  constructor() {
    super();
    this.createTopology();
    this.rebuildMesh();
  }

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

  update(metrics: FaceGestureMetrics): void {
    if (!metrics.faceDetected) {
      return;
    }

    this.controls = this.mapper.map(metrics);
    // Face pose is neutral-relative and expressed in degrees; amplify it so movement is legible.
    this.facePitch = this.controls.pitch * 0.88;
    this.faceYaw = this.controls.yaw * 0.88;

    if (this.controls.leftWink) {
      this.growth = clamp(this.growth + 0.085, 1.0, 1.34);
    }
    if (this.controls.rightWink) {
      this.erosion = clamp(this.erosion + 0.34, 0, 1.0);
    }
    if (this.controls.jawPulse) {
      this.pulse = 1.0;
    }

    this.growth += (1.0 - this.growth) * 0.002;
    this.erosion *= 0.992;
    this.pulse *= 0.88;
    this.phase += 0.038;

    this.rebuildMesh();
    this.publishViewTransform();
    this.publishLatest();
  }

  pauseFaceInput(): void {
    this.mapper.reset();
    this.facePitch = 0;
    this.faceYaw = 0;
    this.publishViewTransform();
  }

  reset(): void {
    this.mapper.reset();
    this.phase = 0;
    this.growth = 1.0;
    this.erosion = 0;
    this.pulse = 0;
    this.facePitch = 0;
    this.faceYaw = 0;
    this.touchPitch = 0;
    this.touchYaw = 0;
    this.viewZoom = 0.92;
    this.lastTouchX = -1;
    this.lastTouchY = -1;
    this.lastPinchDistance = 0;
    this.controls = {
      pitch: 0,
      yaw: 0,
      roll: 0,
      gravityX: 0,
      gravityY: -1,
      leftWink: false,
      rightWink: false,
      jawPulse: false
    };
    this.rebuildMesh();
    this.publishViewTransform();
    this.publishLatest();
  }

  handleTouch(event: TouchEvent): void {
    const touches = event.touches;
    if (touches.length === 1) {
      const point = touches[0];
      if (this.lastTouchX >= 0) {
        this.touchYaw += (point.x - this.lastTouchX) * 0.42;
        this.touchPitch += (point.y - this.lastTouchY) * 0.42;
        this.touchPitch = clamp(this.touchPitch, -72, 72);
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
        this.viewZoom = clamp(this.viewZoom * distance / this.lastPinchDistance, 0.72, 2.4);
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

  private createTopology(): void {
    const triangleIndices: number[] = [];
    const edgeIndices: number[] = [];
    const rowSize = this.segments + 1;

    for (let ring = 0; ring < this.rings; ring++) {
      for (let segment = 0; segment < this.segments; segment++) {
        const a = ring * rowSize + segment;
        const b = (ring + 1) * rowSize + segment;
        const c = b + 1;
        const d = a + 1;
        triangleIndices.push(a, b, d, b, c, d);
        edgeIndices.push(a, b, a, d);
      }
    }

    this.vertices = new Float32Array((this.rings + 1) * rowSize * 3);
    this.deformation = new Float32Array((this.rings + 1) * rowSize);
    this.triangles = new Uint32Array(triangleIndices);
    this.edges = new Uint32Array(edgeIndices);
    this.labels = new Int32Array(triangleIndices.length / 3);
  }

  private rebuildMesh(): void {
    const rowSize = this.segments + 1;
    for (let ring = 0; ring <= this.rings; ring++) {
      const latitude = -Math.PI * 0.5 + Math.PI * ring / this.rings;
      const cosLatitude = Math.cos(latitude);
      const sinLatitude = Math.sin(latitude);

      for (let segment = 0; segment <= this.segments; segment++) {
        const theta = Math.PI * 2 * segment / this.segments;
        const sphereX = cosLatitude * Math.cos(theta);
        const sphereY = sinLatitude;
        const sphereZ = cosLatitude * Math.sin(theta);

        const waveA = Math.sin(theta * 3.0 + this.phase + this.controls.yaw * 0.024) *
          Math.cos(latitude * 2.4 - this.controls.pitch * 0.022);
        const waveB = Math.sin(theta * 5.0 - latitude * 3.2 + this.phase * 0.72);
        const gravity = sphereX * this.controls.gravityX + sphereY * this.controls.gravityY;
        const crater = Math.pow(Math.max(0, Math.cos(theta * 2.0 + latitude * 2.8 + this.phase * 0.55)), 9);
        const pulseWave = Math.sin(theta * 4.0 + latitude * 4.2 - this.phase);
        const radial = clamp(
          this.growth + waveA * 0.16 + waveB * 0.075 + gravity * 0.18 -
            crater * this.erosion * 0.16 + pulseWave * this.pulse * 0.10,
          0.70,
          1.48
        );

        const vertexIndex = ring * rowSize + segment;
        const offset = vertexIndex * 3;
        this.vertices[offset] = sphereX * radial;
        this.vertices[offset + 1] = sphereY * radial;
        this.vertices[offset + 2] = sphereZ * radial;
        this.deformation[vertexIndex] = Math.abs(radial - 1.0);
      }
    }
  }

  private publishViewTransform(): void {
    if (this.surfaceId !== undefined) {
      nativeRender.SetViewTransform(
        this.surfaceId,
        clamp(this.facePitch + this.touchPitch, -78, 78),
        this.faceYaw + this.touchYaw,
        this.viewZoom
      );
    }
  }

  private publishLatest(): void {
    if (this.surfaceId === undefined) {
      return;
    }
    nativeRender.UpdateMesh(
      this.surfaceId,
      this.vertices,
      this.triangles,
      this.edges,
      this.deformation,
      this.labels,
      0,
      0,
      0,
      1,
      4,
      true
    );
  }
}

@Component
export struct SculptureExperience {
  controller: SculptureGpuSurfaceController = new SculptureGpuSurfaceController();
  @Prop trackingActive: boolean = false;
  @Prop faceDetected: boolean = false;
  @Prop controlSummary: string = '等待面部姿态数据';
  @Prop gestureStatus: string = 'NO GESTURE';
  onExit: () => void = () => {};

  build() {
    Column({ space: 0 }) {
      Row() {
        Column({ space: 3 }) {
          Text('FORM BEYOND')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F1F5F7')
            .letterSpacing(2)
          Text('LIQUID STUDY 001  /  FACE-DRIVEN SCULPTURE')
            .fontSize(9)
            .fontColor('#788692')
            .letterSpacing(1)
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Button('EXIT')
          .height(34)
          .fontSize(11)
          .backgroundColor('#1C252D')
          .fontColor('#DDE6EB')
          .onClick(() => {
            this.onExit();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 16, top: 18, bottom: 12 })

      Row() {
        Text(this.faceDetected ? 'FACE LINK  /  LIVE' :
          (this.trackingActive ? 'FACE LINK  /  SEARCHING' : 'FACE LINK  /  OFFLINE'))
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.faceDetected ? '#A7D8DE' : '#77838D')
        Blank()
        Text(this.gestureStatus)
          .fontSize(9)
          .fontColor(this.faceDetected ? '#A7D8DE' : '#77838D')
          .letterSpacing(1)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 6, bottom: 6 })

      XComponent({
        type: XComponentType.SURFACE,
        controller: this.controller
      })
        .onTouch((event: TouchEvent) => {
          this.controller.handleTouch(event);
        })
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#050609')

      Column({ space: 5 }) {
        Text('LEFT WINK  /  GROW     RIGHT WINK  /  ERODE     JAW  /  PULSE')
          .fontSize(9)
          .fontColor('#B9C8CF')
          .letterSpacing(0.5)
          .textAlign(TextAlign.Center)
          .width('100%')
        Text(this.controlSummary)
          .fontSize(10)
          .fontColor('#A7D8DE')
          .textAlign(TextAlign.Center)
          .width('100%')
        Text('头部动作控制雕塑；单眨眼生长 / 侵蚀，张嘴触发脉冲。可拖动与双指缩放。')
          .fontSize(10)
          .fontColor('#71808B')
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 10, bottom: 18 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#050609')
  }
}
