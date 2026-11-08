import { arEngine, arViewController } from '@kit.AREngine';
import { Node } from '@kit.ArkGraphics3D';
import { BusinessError } from '@kit.BasicServicesKit';

export interface FaceMetrics {
  faceCount: number;
  meshSummary: string;
  poseSummary: string;
  blendSummary: string;
  leftBlink: string;
  rightBlink: string;
  jawOpen: string;
  rotationX: string;
  rotationY: string;
  rotationZ: string;
  quaternionSummary: string;
  translationSummary: string;
  meshMotionSummary: string;
  poseCalibrated: boolean;
}

interface QuaternionValues {
  x: number;
  y: number;
  z: number;
  w: number;
}

interface VectorValues {
  x: number;
  y: number;
  z: number;
}

interface EulerValues {
  x: number;
  y: number;
  z: number;
}

function describeError(error: Object): string {
  const err = error as BusinessError;
  if (err.code !== undefined) {
    return '错误码 ' + err.code.toString() + '：' + err.message;
  }
  return String(error);
}

function formatWeight(values: Float32Array, index: number): string {
  if (index < 0 || index >= values.length) {
    return '—';
  }
  return values[index].toFixed(2);
}

function normalizeQuaternion(value: QuaternionValues): QuaternionValues {
  const length = Math.sqrt(
    value.x * value.x + value.y * value.y + value.z * value.z + value.w * value.w
  );
  if (length < 0.000001 || length > 1000000) {
    return { x: 0, y: 0, z: 0, w: 1 };
  }
  return {
    x: value.x / length,
    y: value.y / length,
    z: value.z / length,
    w: value.w / length
  };
}

function multiplyQuaternion(a: QuaternionValues, b: QuaternionValues): QuaternionValues {
  return normalizeQuaternion({
    x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
    y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
    z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
    w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
  });
}

function quaternionToEulerDegrees(q: QuaternionValues): EulerValues {
  // Standard XYZ Tait-Bryan decomposition. Device-axis labels are intentionally
  // kept as X/Y/Z until the user validates physical directions on the target tablet.
  const sinX = 2 * (q.w * q.x + q.y * q.z);
  const cosX = 1 - 2 * (q.x * q.x + q.y * q.y);
  const x = Math.atan2(sinX, cosX);

  const sinY = 2 * (q.w * q.y - q.z * q.x);
  const clampedY = Math.max(-1, Math.min(1, sinY));
  const y = Math.asin(clampedY);

  const sinZ = 2 * (q.w * q.z + q.x * q.y);
  const cosZ = 1 - 2 * (q.y * q.y + q.z * q.z);
  const z = Math.atan2(sinZ, cosZ);

  const radiansToDegrees = 180 / Math.PI;
  return {
    x: x * radiansToDegrees,
    y: y * radiansToDegrees,
    z: z * radiansToDegrees
  };
}

function shortestAngleDelta(from: number, to: number): number {
  let delta = (to - from) % 360;
  if (delta > 180) {
    delta -= 360;
  } else if (delta < -180) {
    delta += 360;
  }
  return delta;
}

function smoothAngle(previous: number | undefined, next: number, alpha: number): number {
  if (previous === undefined) {
    return next;
  }
  return previous + shortestAngleDelta(previous, next) * alpha;
}

function formatSigned(value: number, digits: number): string {
  const prefix = value > 0 ? '+' : '';
  return prefix + value.toFixed(digits);
}

/**
 * Reads AR Engine face data and computes relative pose / per-frame mesh movement.
 * UI updates are throttled to approximately 5 Hz; ARView rendering remains independent.
 */
export class FaceTrackingCallback extends arViewController.ARViewCallback {
  private active: boolean = true;
  private lastPublishedTimestamp: number = 0;
  private lastErrorMessage: string = '';
  private onMetrics: (metrics: FaceMetrics) => void;
  private onError: (message: string) => void;

  private poseBaseline: QuaternionValues | undefined = undefined;
  private translationBaseline: VectorValues | undefined = undefined;
  private calibrationRequested: boolean = false;
  private smoothedX: number | undefined = undefined;
  private smoothedY: number | undefined = undefined;
  private smoothedZ: number | undefined = undefined;
  private smoothedTranslationX: number | undefined = undefined;
  private smoothedTranslationY: number | undefined = undefined;
  private smoothedTranslationZ: number | undefined = undefined;
  private previousVertices: Float32Array | undefined = undefined;

  constructor(
    onMetrics: (metrics: FaceMetrics) => void,
    onError: (message: string) => void
  ) {
    super();
    this.onMetrics = onMetrics;
    this.onError = onError;
  }

  stop(): void {
    this.active = false;
    this.previousVertices = undefined;
    this.poseBaseline = undefined;
    this.translationBaseline = undefined;
  }

  /** Capture the next valid face pose as the relative zero point. */
  calibratePose(): void {
    this.calibrationRequested = true;
  }

  /** Drop the previous mesh sample; the next frame becomes a fresh comparison baseline. */
  resetMeshBaseline(): void {
    this.previousVertices = undefined;
  }

  onAnchorAdd(ctx: arViewController.ARViewContext, node: Node, anchor: arEngine.ARAnchor): void {
    // Face tracking does not require plane anchors.
  }

  onAnchorUpdate(ctx: arViewController.ARViewContext, node: Node, anchor: arEngine.ARAnchor): void {
    // Face tracking does not require plane anchors.
  }

  async onFrameUpdate(ctx: arViewController.ARViewContext, sysBootTs: number): Promise<void> {
    if (!this.active || sysBootTs - this.lastPublishedTimestamp < 200000) {
      return;
    }
    this.lastPublishedTimestamp = sysBootTs;

    const session = ctx.session;
    if (session === undefined) {
      this.reportError('AR 会话尚未就绪。');
      return;
    }

    let frame: arEngine.ARFrame | undefined = undefined;
    let geometry: arEngine.ARGeometry | undefined = undefined;
    let blendShapes: arEngine.ARBlendShapes | undefined = undefined;
    let pose: arEngine.ARPose | undefined = undefined;

    try {
      frame = session.getFrame();
      const trackables: arEngine.ARTrackable[] =
        session.getAllTrackables(arEngine.ARTrackableType.FACE);

      let faceCount = 0;
      let firstFace: arEngine.ARFace | undefined = undefined;
      for (let i = 0; i < trackables.length; i++) {
        if (trackables[i].state === arEngine.ARTrackingState.TRACKING) {
          faceCount++;
          if (firstFace === undefined) {
            firstFace = trackables[i] as arEngine.ARFace;
          }
        }
      }

      if (firstFace === undefined) {
        this.previousVertices = undefined;
        this.poseBaseline = undefined;
        this.translationBaseline = undefined;
        this.smoothedX = undefined;
        this.smoothedY = undefined;
        this.smoothedZ = undefined;
        this.smoothedTranslationX = undefined;
        this.smoothedTranslationY = undefined;
        this.smoothedTranslationZ = undefined;
        this.onMetrics({
          faceCount: 0,
          meshSummary: '未检测到人脸',
          poseSummary: '—',
          blendSummary: '—',
          leftBlink: '—',
          rightBlink: '—',
          jawOpen: '—',
          rotationX: '—',
          rotationY: '—',
          rotationZ: '—',
          quaternionSummary: '—',
          translationSummary: '—',
          meshMotionSummary: '等待人脸',
          poseCalibrated: false
        });
        this.lastErrorMessage = '';
        return;
      }

      let meshSummary = '读取失败';
      let poseSummary = '读取失败';
      let blendSummary = '读取失败';
      let leftBlink = '—';
      let rightBlink = '—';
      let jawOpen = '—';
      let rotationX = '—';
      let rotationY = '—';
      let rotationZ = '—';
      let quaternionSummary = '—';
      let translationSummary = '—';
      let meshMotionSummary = '等待网格数据';
      let poseCalibrated = this.poseBaseline !== undefined;

      try {
        pose = firstFace.getPose();
        const rotation = normalizeQuaternion({
          x: pose.rotation.x,
          y: pose.rotation.y,
          z: pose.rotation.z,
          w: pose.rotation.w
        });
        const translation: VectorValues = {
          x: pose.translation.x,
          y: pose.translation.y,
          z: pose.translation.z
        };

        if (this.poseBaseline === undefined || this.translationBaseline === undefined ||
          this.calibrationRequested) {
          this.poseBaseline = rotation;
          this.translationBaseline = translation;
          this.calibrationRequested = false;
          this.smoothedX = undefined;
          this.smoothedY = undefined;
          this.smoothedZ = undefined;
          this.smoothedTranslationX = undefined;
          this.smoothedTranslationY = undefined;
          this.smoothedTranslationZ = undefined;
        }

        const baseline = this.poseBaseline;
        const translationBase = this.translationBaseline;
        if (baseline !== undefined && translationBase !== undefined) {
          const inverseBaseline: QuaternionValues = {
            x: -baseline.x,
            y: -baseline.y,
            z: -baseline.z,
            w: baseline.w
          };
          const relativeRotation = multiplyQuaternion(inverseBaseline, rotation);
          const euler = quaternionToEulerDegrees(relativeRotation);
          const alpha = 0.35;

          const filteredX = smoothAngle(this.smoothedX, euler.x, alpha);
          const filteredY = smoothAngle(this.smoothedY, euler.y, alpha);
          const filteredZ = smoothAngle(this.smoothedZ, euler.z, alpha);
          this.smoothedX = filteredX;
          this.smoothedY = filteredY;
          this.smoothedZ = filteredZ;

          const deltaX = translation.x - translationBase.x;
          const deltaY = translation.y - translationBase.y;
          const deltaZ = translation.z - translationBase.z;
          const filteredTranslationX = this.smoothedTranslationX === undefined ?
            deltaX : this.smoothedTranslationX + (deltaX - this.smoothedTranslationX) * alpha;
          const filteredTranslationY = this.smoothedTranslationY === undefined ?
            deltaY : this.smoothedTranslationY + (deltaY - this.smoothedTranslationY) * alpha;
          const filteredTranslationZ = this.smoothedTranslationZ === undefined ?
            deltaZ : this.smoothedTranslationZ + (deltaZ - this.smoothedTranslationZ) * alpha;
          this.smoothedTranslationX = filteredTranslationX;
          this.smoothedTranslationY = filteredTranslationY;
          this.smoothedTranslationZ = filteredTranslationZ;

          rotationX = formatSigned(filteredX, 1) + '°';
          rotationY = formatSigned(filteredY, 1) + '°';
          rotationZ = formatSigned(filteredZ, 1) + '°';
          translationSummary = 'ΔX ' + formatSigned(filteredTranslationX, 3) +
            ' · ΔY ' + formatSigned(filteredTranslationY, 3) +
            ' · ΔZ ' + formatSigned(filteredTranslationZ, 3);
          quaternionSummary = 'x ' + rotation.x.toFixed(3) + ' · y ' +
            rotation.y.toFixed(3) + ' · z ' + rotation.z.toFixed(3) + ' · w ' +
            rotation.w.toFixed(3);
          poseSummary = '四元数 + 平移 · ' + (this.calibrationRequested ? '待校准' : '相对姿态');
          poseCalibrated = true;
        }
      } catch (error) {
        poseSummary = describeError(error as Object);
      }

      try {
        geometry = firstFace.getGeometry();
        const verticesBuffer = geometry.getVertices();
        const indicesBuffer = geometry.getIndices();
        // The target device's observed buffer layout is XYZ Float32 per vertex.
        // Keep a strict length guard instead of silently interpreting unknown layouts.
        if (verticesBuffer.byteLength % 12 !== 0) {
          throw new Error('顶点缓冲区长度不是 12 字节的整数倍，无法按 XYZ Float32 解析。');
        }
        const currentVertices = new Float32Array(verticesBuffer);
        const vertexCount = Math.floor(currentVertices.length / 3);
        const indexCount = Math.floor(indicesBuffer.byteLength / 4);
        const triangleCount = Math.floor(indexCount / 3);
        meshSummary = vertexCount.toString() + ' 顶点 · ' + triangleCount.toString() + ' 三角面';

        if (this.previousVertices === undefined ||
          this.previousVertices.length !== currentVertices.length) {
          meshMotionSummary = '已建立基准，等待下一帧';
        } else {
          let sumSquaredDisplacement = 0;
          let maxDisplacement = 0;
          for (let i = 0; i + 2 < currentVertices.length; i += 3) {
            const dx = currentVertices[i] - this.previousVertices[i];
            const dy = currentVertices[i + 1] - this.previousVertices[i + 1];
            const dz = currentVertices[i + 2] - this.previousVertices[i + 2];
            const displacement = Math.sqrt(dx * dx + dy * dy + dz * dz);
            sumSquaredDisplacement += displacement * displacement;
            if (displacement > maxDisplacement) {
              maxDisplacement = displacement;
            }
          }
          const rms = vertexCount > 0 ? Math.sqrt(sumSquaredDisplacement / vertexCount) : 0;
          meshMotionSummary = 'RMS ' + rms.toFixed(5) + ' · MAX ' + maxDisplacement.toFixed(5);
        }

        const snapshot = new Float32Array(currentVertices.length);
        snapshot.set(currentVertices);
        this.previousVertices = snapshot;
      } catch (error) {
        this.previousVertices = undefined;
        meshSummary = describeError(error as Object);
        meshMotionSummary = '无法计算网格位移';
      }

      try {
        blendShapes = firstFace.getBlendShapes();
        const types = blendShapes.getTypes();
        const values = new Float32Array(blendShapes.getData());
        blendSummary = blendShapes.count.toString() + ' 个参数 · ' +
          values.length.toString() + ' 个数值';

        const leftIndex = types.indexOf(arEngine.ARBlendShapeType.EYE_BLINK_LEFT);
        const rightIndex = types.indexOf(arEngine.ARBlendShapeType.EYE_BLINK_RIGHT);
        const jawIndex = types.indexOf(arEngine.ARBlendShapeType.JAW_OPEN);

        leftBlink = formatWeight(values, leftIndex);
        rightBlink = formatWeight(values, rightIndex);
        jawOpen = formatWeight(values, jawIndex);
      } catch (error) {
        blendSummary = describeError(error as Object);
      }

      this.onMetrics({
        faceCount: faceCount,
        meshSummary: meshSummary,
        poseSummary: poseSummary,
        blendSummary: blendSummary,
        leftBlink: leftBlink,
        rightBlink: rightBlink,
        jawOpen: jawOpen,
        rotationX: rotationX,
        rotationY: rotationY,
        rotationZ: rotationZ,
        quaternionSummary: quaternionSummary,
        translationSummary: translationSummary,
        meshMotionSummary: meshMotionSummary,
        poseCalibrated: poseCalibrated
      });
      this.lastErrorMessage = '';
    } catch (error) {
      this.reportError('读取人脸帧失败：' + describeError(error as Object));
    } finally {
      if (pose !== undefined) {
        try {
          await pose.release();
        } catch (_) {
          // Ignore cleanup errors while the AR session is stopping.
        }
      }
      if (blendShapes !== undefined) {
        try {
          await blendShapes.release();
        } catch (_) {
          // Ignore cleanup errors while the AR session is stopping.
        }
      }
      if (geometry !== undefined) {
        try {
          await geometry.release();
        } catch (_) {
          // Ignore cleanup errors while the AR session is stopping.
        }
      }
      if (frame !== undefined) {
        try {
          await frame.release();
        } catch (_) {
          // Ignore cleanup errors while the AR session is stopping.
        }
      }
    }
  }

  private reportError(message: string): void {
    if (message !== this.lastErrorMessage) {
      this.lastErrorMessage = message;
      this.onError(message);
    }
  }
}
