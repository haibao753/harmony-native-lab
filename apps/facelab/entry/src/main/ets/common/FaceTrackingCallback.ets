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

/**
 * Reads face tracking data from AR Engine.
 * UI updates are throttled to approximately 5 Hz; ARView rendering remains independent.
 */
export class FaceTrackingCallback extends arViewController.ARViewCallback {
  private active: boolean = true;
  private lastPublishedTimestamp: number = 0;
  private lastErrorMessage: string = '';
  private onMetrics: (metrics: FaceMetrics) => void;
  private onError: (message: string) => void;

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
        this.onMetrics({
          faceCount: 0,
          meshSummary: '未检测到人脸',
          poseSummary: '—',
          blendSummary: '—',
          leftBlink: '—',
          rightBlink: '—',
          jawOpen: '—'
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

      try {
        pose = firstFace.getPose();
        const matrix = pose.getMatrix();
        poseSummary = '已获取 · ' + matrix.length.toString() + ' 项矩阵';
      } catch (error) {
        poseSummary = describeError(error as Object);
      }

      try {
        geometry = firstFace.getGeometry();
        const vertices = geometry.getVertices();
        const indices = geometry.getIndices();
        const vertexCount = Math.floor(vertices.byteLength / 12);
        const indexCount = Math.floor(indices.byteLength / 4);
        const triangleCount = Math.floor(indexCount / 3);
        meshSummary = vertexCount.toString() + ' 顶点 · ' + triangleCount.toString() + ' 三角面';
      } catch (error) {
        meshSummary = describeError(error as Object);
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
        jawOpen: jawOpen
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
