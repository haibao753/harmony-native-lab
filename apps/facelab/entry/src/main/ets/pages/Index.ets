import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { ARView, arEngine, arViewController } from '@kit.AREngine';
import { Scene } from '@kit.ArkGraphics3D';
import { BusinessError } from '@kit.BasicServicesKit';
import { FaceFrameDiagnostics, FaceGestureMetrics, FaceMetrics, FaceTrackingCallback } from '../common/FaceTrackingCallback';
import { FaceGpuSurface, FaceGpuSurfaceController } from '../components/FaceGpuSurface';
import { FACE_PEN_PALETTE, FacePenCanvas } from '../components/FacePenCanvas';
import { SculptureExperience, SculptureGpuSurfaceController } from '../components/SculptureExperience';

@Entry
@Component
struct Index {
  @State arContext: arViewController.ARViewContext | undefined = undefined;
  @State isStarting: boolean = false;
  @State status: string = '尚未启动';
  @State faceCount: number = 0;
  @State meshSummary: string = '等待人脸';
  @State poseSummary: string = '等待人脸';
  @State blendSummary: string = '等待人脸';
  @State leftBlink: string = '—';
  @State rightBlink: string = '—';
  @State jawOpen: string = '—';
  @State rotationX: string = '—';
  @State rotationY: string = '—';
  @State rotationZ: string = '—';
  @State quaternionSummary: string = '等待姿态数据';
  @State translationSummary: string = '等待姿态数据';
  @State meshMotionSummary: string = '等待网格数据';
  @State neutralDeformationSummary: string = '尚未采集中性表情';
  @State neutralCalibrated: boolean = false;
  @State trackingStabilityLabel: string = '—';
  @State trackingStabilitySummary: string = '等待姿态数据';
  @State poseCalibrated: boolean = false;
  @State meshViewMode: string = 'wireframe';
  @State meshLabelsAvailable: boolean = false;
  @State errorMessage: string = '';
  @StorageLink('faceLabWindowLifecycle') windowLifecycleState: string = 'UNKNOWN';
  @StorageLink('faceLabWindowFocus') windowFocusState: string = 'UNKNOWN';
  @StorageLink('faceLabWindowMode') windowMode: string = 'UNKNOWN';
  @StorageLink('faceLabWindowVisible') windowVisible: boolean = false;
  @StorageLink('faceLabWindowEventLog') windowEventLog: string = '';
  @State frameCallbackCount: number = 0;
  @State frameRateHz: number = 0;
  @State frameLastIntervalMs: number = 0;
  @State frameMaxGapMs: number = 0;
  @State frameLastSeenAtMs: number = 0;
  @State frameAgeMs: number = -1;
  @State framesWhileInactive: number = 0;
  @State inactiveElapsedMs: number = 0;
  @State gestureLabEnabled: boolean = false;
  @State gestureAxisSummary: string = '等待人脸姿态';
  @State gestureLeftBlink: string = '—';
  @State gestureRightBlink: string = '—';
  @State gestureJawOpen: string = '—';
  @State gestureLastEvent: string = '尚无手势事件';
  @State gestureSelectionIndex: number = 0;
  @State gestureConfirmCount: number = 0;
  @State facePenControlEnabled: boolean = false;
  @State facePenSelectedColorIndex: number = 0;
  @State facePenPendingColorIndex: number = -1;
  @State facePenStrokeActive: boolean = false;
  @State facePenStatus: string = '等待 M-Pencil 输入';
  @State facePenLastCommand: string = '面部控制关闭';
  @State showSculptureExperience: boolean = false;

  private faceCallback: FaceTrackingCallback | undefined = undefined;
  private gpuSurfaceController: FaceGpuSurfaceController = new FaceGpuSurfaceController();
  private sculptureController: SculptureGpuSurfaceController = new SculptureGpuSurfaceController();
  private lastTextMetricsUpdate: number = 0;
  private lastGestureUiUpdate: number = 0;
  private frameAgeTimerId: number = -1;
  private lastWindowFocusState: string = 'UNKNOWN';
  private inactiveStartAtMs: number = 0;
  private inactiveFrameBaseline: number = 0;
  private hiddenStopRequested: boolean = false;

  private onFramePulse(diagnostics: FaceFrameDiagnostics): void {
    this.frameCallbackCount = diagnostics.callbackCount;
    this.frameRateHz = diagnostics.rateHz;
    this.frameLastIntervalMs = diagnostics.lastIntervalMs;
    this.frameMaxGapMs = diagnostics.maxGapMs;
    this.frameLastSeenAtMs = Date.now();
    this.frameAgeMs = 0;
    if (this.windowFocusState === 'INACTIVE' && this.windowVisible &&
      this.windowLifecycleState !== 'HIDDEN') {
      this.framesWhileInactive = Math.max(0, diagnostics.callbackCount - this.inactiveFrameBaseline);
    }
  }

  private splitProbeStatus(): string {
    if (this.windowMode !== 'SPLIT_SCREEN') {
      return '等待进入 SPLIT_SCREEN：请将 FaceLab 与华为笔记并排分屏';
    }
    if (!this.windowVisible || this.windowLifecycleState === 'HIDDEN') {
      return '窗口当前不可见或已进入后台';
    }
    if (this.windowFocusState !== 'INACTIVE') {
      return '等待失焦：点击另一侧应用，使 FaceLab 保持可见但不获焦';
    }
    if (this.arContext === undefined) {
      return '请先启动 AR 追踪';
    }
    if (this.faceCount <= 0) {
      return 'AR 会话已启动，但尚未检测到人脸';
    }
    if (this.frameAgeMs < 0) {
      return '等待 AR 帧回调';
    }
    if (this.frameAgeMs > 1500) {
      return '异常：最近 1.5 秒没有收到 AR 帧回调';
    }
    if (this.inactiveElapsedMs < 10000) {
      return '观察中：请保持分屏失焦状态至少 10 秒';
    }
    if (this.framesWhileInactive >= 50 && this.frameRateHz >= 5) {
      return '初步通过：失焦期间持续收到 AR 帧，且人脸仍被检测';
    }
    return '观察未达阈值：检查回调累计数、帧率和人脸检测状态';
  }

  private splitProbeStatusColor(): string {
    const status = this.splitProbeStatus();
    if (status.indexOf('初步通过') === 0) {
      return '#63D6A5';
    }
    if (status.indexOf('异常') === 0) {
      return '#F2C078';
    }
    return '#D2DCE8';
  }

  private resetSplitProbeCounters(): void {
    this.inactiveFrameBaseline = this.frameCallbackCount;
    this.framesWhileInactive = 0;
    this.inactiveStartAtMs = this.windowFocusState === 'INACTIVE' ? Date.now() : 0;
    this.inactiveElapsedMs = 0;
  }

  private setMeshViewMode(mode: string): void {
    this.meshViewMode = mode;
    this.gpuSurfaceController.setMode(mode);
  }

  private describeError(error: Object): string {
    const err = error as BusinessError;
    if (err.code !== undefined) {
      return '错误码 ' + err.code.toString() + '：' + err.message;
    }
    return String(error);
  }

  private async requestCameraPermission(): Promise<boolean> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const atManager = abilityAccessCtrl.createAtManager();
    const permissions: Permissions[] = ['ohos.permission.CAMERA'];
    try {
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      return result.authResults.length > 0 && result.authResults[0] === 0;
    } catch (error) {
      this.errorMessage = '相机权限申请失败：' + this.describeError(error as Object);
      return false;
    }
  }

  private onFaceMetrics(metrics: FaceMetrics): void {
    this.faceCount = metrics.faceCount;
    this.neutralCalibrated = metrics.neutralCalibrated;
    this.poseCalibrated = metrics.poseCalibrated;
    // All four display modes use the native GPU path. Face labels remain Int32Array
    // buffers and cross the ArkTS/native boundary without Canvas number[] copies.
    this.gpuSurfaceController.update(metrics, this.meshViewMode);
    this.meshLabelsAvailable = metrics.meshLabelsAvailable;

    // The geometry viewer updates at 10 Hz; textual diagnostics only need 2 Hz.
    const now = Date.now();
    if (now - this.lastTextMetricsUpdate >= 500) {
      this.meshSummary = metrics.meshSummary;
      this.poseSummary = metrics.poseSummary;
      this.blendSummary = metrics.blendSummary;
      this.leftBlink = metrics.leftBlink;
      this.rightBlink = metrics.rightBlink;
      this.jawOpen = metrics.jawOpen;
      this.rotationX = metrics.rotationX;
      this.rotationY = metrics.rotationY;
      this.rotationZ = metrics.rotationZ;
      this.quaternionSummary = metrics.quaternionSummary;
      this.translationSummary = metrics.translationSummary;
      this.meshMotionSummary = metrics.meshMotionSummary;
      this.neutralDeformationSummary = metrics.neutralDeformationSummary;
      this.trackingStabilityLabel = metrics.trackingStabilityLabel;
      this.trackingStabilitySummary = metrics.trackingStabilitySummary;
      this.lastTextMetricsUpdate = now;
    }

    const nextStatus = metrics.faceCount > 0 ? '正在追踪人脸' : 'AR 已运行，等待人脸进入画面';
    if (this.status !== nextStatus) {
      this.status = nextStatus;
    }
  }

  private onFaceGesture(metrics: FaceGestureMetrics): void {
    if (!metrics.faceDetected) {
      this.gestureAxisSummary = '等待人脸姿态';
      this.gestureLeftBlink = '—';
      this.gestureRightBlink = '—';
      this.gestureJawOpen = '—';
      if (this.showSculptureExperience) {
        this.sculptureController.pauseFaceInput();
      }
      if (this.facePenControlEnabled) {
        this.facePenControlEnabled = false;
        this.facePenLastCommand = '人脸丢失 · 面部颜色控制已暂停，请重新启用';
      }
      return;
    }

    if (this.showSculptureExperience) {
      this.sculptureController.update(metrics);
    }

    const now = Date.now();
    if (now - this.lastGestureUiUpdate >= 100) {
      this.gestureAxisSummary = 'Pitch X ' + (metrics.pitch >= 0 ? '+' : '') +
        metrics.pitch.toFixed(1) + '° · Yaw Y ' + (metrics.yaw >= 0 ? '+' : '') +
        metrics.yaw.toFixed(1) + '° · Roll Z ' + (metrics.roll >= 0 ? '+' : '') +
        metrics.roll.toFixed(1) + '°';
      this.gestureLeftBlink = metrics.leftBlinkWeight.toFixed(2);
      this.gestureRightBlink = metrics.rightBlinkWeight.toFixed(2);
      this.gestureJawOpen = metrics.jawOpenWeight.toFixed(2);
      this.lastGestureUiUpdate = now;
    }

    // FacePen reuses the 0.5.2 wink edge detector and its existing cooldown.
    // It is mutually exclusive with the A/B/C gesture demo.
    if (this.facePenControlEnabled) {
      if (metrics.leftWink) {
        this.requestFacePenColorStep(-1, '左眼单眨');
      }
      if (metrics.rightWink) {
        this.requestFacePenColorStep(1, '右眼单眨');
      }
      return;
    }
    if (!this.gestureLabEnabled) {
      return;
    }
    if (metrics.leftWink) {
      this.gestureSelectionIndex = (this.gestureSelectionIndex + 2) % 3;
      this.gestureLastEvent = '左眼单眨 · 焦点切换到选项 ' +
        String.fromCharCode(65 + this.gestureSelectionIndex);
    }
    if (metrics.rightWink) {
      this.gestureSelectionIndex = (this.gestureSelectionIndex + 1) % 3;
      this.gestureLastEvent = '右眼单眨 · 焦点切换到选项 ' +
        String.fromCharCode(65 + this.gestureSelectionIndex);
    }
    if (metrics.jawConfirm) {
      this.gestureConfirmCount++;
      this.gestureLastEvent = '张嘴保持 · 已确认选项 ' +
        String.fromCharCode(65 + this.gestureSelectionIndex) +
        '（累计 ' + this.gestureConfirmCount.toString() + ' 次）';
    }
  }

  private toggleGestureLab(): void {
    if (!this.gestureLabEnabled && (this.faceCount === 0 || this.arContext === undefined)) {
      this.errorMessage = '请先启动追踪并检测到人脸，再启用手势输入。';
      return;
    }
    if (!this.gestureLabEnabled) {
      this.facePenControlEnabled = false;
      this.facePenLastCommand = '手势演示已启用 · FacePen 面部控制已暂停';
    }
    this.gestureLabEnabled = !this.gestureLabEnabled;
    this.gestureLastEvent = this.gestureLabEnabled ? '手势输入已启用' : '手势输入已关闭';
  }

  private resetGestureDemo(): void {
    this.gestureSelectionIndex = 0;
    this.gestureConfirmCount = 0;
    this.gestureLastEvent = '演示状态已重置';
  }

  private facePenTargetColorIndex(): number {
    return this.facePenPendingColorIndex >= 0 ?
      this.facePenPendingColorIndex : this.facePenSelectedColorIndex;
  }

  private requestFacePenColor(index: number, source: string): void {
    const paletteSize = FACE_PEN_PALETTE.length;
    const normalizedIndex = (index + paletteSize) % paletteSize;
    const color = FACE_PEN_PALETTE[normalizedIndex];
    if (this.facePenStrokeActive) {
      this.facePenPendingColorIndex = normalizedIndex;
      this.facePenLastCommand = source + ' · 下一笔切换为 ' + color.name;
      return;
    }
    this.facePenSelectedColorIndex = normalizedIndex;
    this.facePenPendingColorIndex = -1;
    this.facePenLastCommand = source + ' · 当前笔色 ' + color.name;
  }

  private requestFacePenColorStep(direction: number, source: string): void {
    const baseIndex = this.facePenPendingColorIndex >= 0 ?
      this.facePenPendingColorIndex : this.facePenSelectedColorIndex;
    this.requestFacePenColor(baseIndex + direction, source);
  }

  private onFacePenStrokeStateChange(active: boolean): void {
    this.facePenStrokeActive = active;
    if (!active && this.facePenPendingColorIndex >= 0) {
      this.facePenSelectedColorIndex = this.facePenPendingColorIndex;
      this.facePenPendingColorIndex = -1;
      this.facePenLastCommand = '笔画结束 · 下一笔使用 ' +
        FACE_PEN_PALETTE[this.facePenSelectedColorIndex].name;
    }
  }

  private toggleFacePenControl(): void {
    if (this.facePenControlEnabled) {
      this.facePenControlEnabled = false;
      this.facePenLastCommand = '面部颜色控制已暂停';
      return;
    }
    if (this.faceCount === 0 || this.arContext === undefined) {
      this.errorMessage = '请先启动人脸追踪并检测到人脸，再启用 FacePen 面部控制。';
      return;
    }
    this.gestureLabEnabled = false;
    this.facePenControlEnabled = true;
    this.facePenLastCommand = '面部控制已启用 · 左眼上一色，右眼下一色';
  }

  private calibratePose(): void {
    if (this.faceCallback === undefined || this.faceCount === 0) {
      this.errorMessage = '请先启动追踪并让摄像头检测到人脸，再进行姿态校准。';
      return;
    }
    this.faceCallback.calibratePose();
    this.status = '正在校准姿态，请保持当前头部位置…';
  }

  private resetMeshBaseline(): void {
    if (this.faceCallback === undefined || this.faceCount === 0) {
      this.errorMessage = '请先启动追踪并检测到人脸，再重置网格位移基准。';
      return;
    }
    this.faceCallback.resetMeshBaseline();
    this.meshMotionSummary = '已重置，等待下一帧建立基准';
  }

  private captureNeutralBaseline(): void {
    if (this.faceCallback === undefined || this.faceCount === 0) {
      this.errorMessage = '请先启动追踪并检测到人脸，再采集中性表情基准。';
      return;
    }
    this.faceCallback.captureNeutralBaseline();
    this.neutralDeformationSummary = '正在采集下一帧，请保持自然放松表情…';
  }

  private enterSculptureExperience(): void {
    if (this.arContext === undefined || this.faceCount <= 0) {
      this.errorMessage = '请先启动人脸追踪并检测到人脸，再进入 FORM BEYOND。';
      return;
    }
    this.gestureLabEnabled = false;
    this.facePenControlEnabled = false;
    this.sculptureController.reset();
    this.showSculptureExperience = true;
  }

  private exitSculptureExperience(): void {
    this.showSculptureExperience = false;
  }

  private async startTracking(): Promise<void> {
    if (this.isStarting || this.arContext !== undefined) {
      return;
    }

    this.isStarting = true;
    this.errorMessage = '';
    this.frameCallbackCount = 0;
    this.frameRateHz = 0;
    this.frameLastIntervalMs = 0;
    this.frameMaxGapMs = 0;
    this.frameLastSeenAtMs = 0;
    this.frameAgeMs = -1;
    this.framesWhileInactive = 0;
    this.inactiveFrameBaseline = 0;
    this.status = '正在申请相机权限…';

    let stage = '申请相机权限';
    let context: arViewController.ARViewContext | undefined = undefined;
    try {
      const granted = await this.requestCameraPermission();
      if (!granted) {
        this.status = '相机权限未授予';
        if (this.errorMessage.length === 0) {
          this.errorMessage = '需要相机权限才能启动前置摄像头人脸追踪。你可以在系统设置中为 FaceLab 授权。';
        }
        return;
      }

      // FaceLab 0.1.0 already confirmed FACE support on this exact device.
      // Skip a second capability probe here: it throws in this 0.2.x runtime path
      // before the AR session can be created. Let context.init() be the definitive test.
      stage = '加载 AR 场景';
      this.status = '正在加载 AR 场景…';
      const scene = await Scene.load();

      context = new arViewController.ARViewContext();
      context.scene = scene;

      stage = '创建人脸追踪回调';
      this.faceCallback = new FaceTrackingCallback(
        (metrics: FaceMetrics) => {
          this.onFaceMetrics(metrics);
        },
        (message: string) => {
          this.errorMessage = message;
        },
        (gesture: FaceGestureMetrics) => {
          this.onFaceGesture(gesture);
        },
        (diagnostics: FaceFrameDiagnostics) => {
          this.onFramePulse(diagnostics);
        }
      );
      context.callback = this.faceCallback;

      stage = '配置 FACE 会话';
      context.config = {
        type: arEngine.ARType.FACE,
        planeFindingMode: arEngine.ARPlaneFindingMode.DISABLED,
        powerMode: arEngine.ARPowerMode.NORMAL,
        focusMode: arEngine.ARFocusMode.AUTO,
        cameraLensFacing: arEngine.ARCameraLensFacing.FRONT,
        multiFaceMode: arEngine.ARMultiFaceMode.MULTIFACE_ENABLE
      };

      stage = '初始化 AR 会话';
      this.status = '正在初始化 AR 会话…';
      await context.init();
      this.arContext = context;
      this.status = 'AR 已启动，等待人脸进入画面';
    } catch (error) {
      this.status = '启动失败 · ' + stage;
      this.errorMessage = '失败阶段：' + stage + '\\n' + this.describeError(error as Object);
      if (this.faceCallback) {
        this.faceCallback.stop();
        this.faceCallback = undefined;
      }
      if (context !== undefined) {
        try {
          await context.destroy();
        } catch (_) {
          // The context may not have completed initialization.
        }
      }
    } finally {
      this.isStarting = false;
    }
  }

  private async stopTracking(): Promise<void> {
    const context = this.arContext;
    if (context === undefined) {
      this.status = '已停止';
      return;
    }

    this.status = '正在停止…';
    if (this.faceCallback) {
      this.faceCallback.stop();
      this.faceCallback = undefined;
    }

    try {
      await context.destroy();
      this.status = '已停止';
    } catch (error) {
      this.status = '停止时发生错误';
      this.errorMessage = this.describeError(error as Object);
    } finally {
      this.arContext = undefined;
      this.faceCount = 0;
      this.meshSummary = '已停止';
      this.poseSummary = '已停止';
      this.blendSummary = '已停止';
      this.leftBlink = '—';
      this.rightBlink = '—';
      this.jawOpen = '—';
      this.rotationX = '—';
      this.rotationY = '—';
      this.rotationZ = '—';
      this.quaternionSummary = '已停止';
      this.translationSummary = '已停止';
      this.meshMotionSummary = '已停止';
      this.neutralDeformationSummary = '尚未采集中性表情';
      this.neutralCalibrated = false;
      this.trackingStabilityLabel = '—';
      this.trackingStabilitySummary = '已停止';
      this.poseCalibrated = false;
      this.meshLabelsAvailable = false;
      this.gestureLabEnabled = false;
      this.gestureAxisSummary = '等待人脸姿态';
      this.gestureLeftBlink = '—';
      this.gestureRightBlink = '—';
      this.gestureJawOpen = '—';
      this.gestureLastEvent = '追踪已停止';
      this.gestureSelectionIndex = 0;
      this.gestureConfirmCount = 0;
      this.facePenControlEnabled = false;
      this.facePenLastCommand = '追踪已停止 · 面部控制已关闭';
      this.gpuSurfaceController.clear();
    }
  }

  aboutToAppear(): void {
    this.lastWindowFocusState = this.windowFocusState;
    if (this.windowFocusState === 'INACTIVE') {
      this.inactiveFrameBaseline = this.frameCallbackCount;
      this.inactiveStartAtMs = Date.now();
    }
    this.frameAgeTimerId = setInterval(() => {
      const focusState = this.windowFocusState;
      if (focusState !== this.lastWindowFocusState) {
        this.lastWindowFocusState = focusState;
        if (focusState === 'INACTIVE') {
          this.inactiveFrameBaseline = this.frameCallbackCount;
          this.framesWhileInactive = 0;
          this.inactiveStartAtMs = Date.now();
          this.inactiveElapsedMs = 0;
        } else if (focusState === 'ACTIVE') {
          this.inactiveStartAtMs = 0;
          this.inactiveElapsedMs = 0;
          this.framesWhileInactive = 0;
        }
      }
      if (this.inactiveStartAtMs > 0) {
        this.inactiveElapsedMs = Date.now() - this.inactiveStartAtMs;
      }
      this.frameAgeMs = this.frameLastSeenAtMs > 0 ?
        Date.now() - this.frameLastSeenAtMs : -1;

      // INACTIVE is not background: split-screen must keep the AR session alive.
      // Only a genuinely HIDDEN window triggers session cleanup.
      if (this.windowLifecycleState === 'HIDDEN' && this.arContext !== undefined &&
        !this.hiddenStopRequested) {
        this.hiddenStopRequested = true;
        this.stopTracking();
      }
      if (this.windowLifecycleState !== 'HIDDEN') {
        this.hiddenStopRequested = false;
      }
    }, 250);
  }

  aboutToDisappear(): void {
    if (this.frameAgeTimerId >= 0) {
      clearInterval(this.frameAgeTimerId);
      this.frameAgeTimerId = -1;
    }
    this.stopTracking();
  }

  build() {
    if (this.showSculptureExperience) {
      SculptureExperience({
        controller: this.sculptureController,
        trackingActive: this.arContext !== undefined,
        faceDetected: this.faceCount > 0,
        onExit: () => {
          this.exitSculptureExperience();
        }
      })
    } else {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 5 }) {
          Text('FaceLab')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F4F7FB')
          Text('AR Face Tracking Lab · 0.8.0-alpha.1')
            .fontSize(13)
            .fontColor('#9AA9BC')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Button('进入 FORM BEYOND · 液态雕塑')
          .width('100%')
          .height(48)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .enabled(this.faceCount > 0 && this.arContext !== undefined)
          .backgroundColor('#243B43')
          .fontColor('#E8F5F7')
          .onClick(() => {
            this.enterSculptureExperience();
          })

        Column({ space: 6 }) {
          Text('TARGET DEVICE')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8DA2BC')
          Text('MatePad Pro 13.2 (2023)')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#F4F7FB')
          Text('HarmonyOS 7.0.0.111 SP8 · SDK 26.0.0')
            .fontSize(12)
            .fontColor('#AAB8C8')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(15)
        .backgroundColor('#172235')
        .borderRadius(15)

        Column({ space: 8 }) {
          Row() {
            Text('SESSION STATUS')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor('#8DA2BC')
            Blank()
            Text(this.faceCount > 0 ? 'FACE DETECTED' : 'FACE NOT DETECTED')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.faceCount > 0 ? '#63D6A5' : '#F2C078')
          }
          .width('100%')
          Text(this.status)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('#F4F7FB')
          Text('当前追踪到的人脸：' + this.faceCount.toString())
            .fontSize(13)
            .fontColor('#AAB8C8')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(15)
        .backgroundColor('#172235')
        .borderRadius(15)

        Row({ space: 10 }) {
          Button(this.isStarting ? '正在启动…' : '开始追踪')
            .layoutWeight(1)
            .height(48)
            .enabled(!this.isStarting && this.arContext === undefined)
            .backgroundColor('#3D83F6')
            .onClick(() => {
              this.startTracking();
            })
          Button('停止追踪')
            .layoutWeight(1)
            .height(48)
            .enabled(this.arContext !== undefined)
            .backgroundColor('#34445D')
            .onClick(() => {
              this.stopTracking();
            })
        }
        .width('100%')

        Column({ space: 10 }) {
          Row() {
            Column({ space: 4 }) {
              Text('SPLIT-SCREEN CAMERA PROBE · 0.7')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8DA2BC')
              Text('只观察窗口状态与 AR 帧回调，不注入系统输入')
                .fontSize(11)
                .fontColor('#9AA9BC')
            }
            .layoutWeight(1)
            Button('重置失焦计数')
              .height(34)
              .fontSize(10)
              .backgroundColor('#34445D')
              .onClick(() => {
                this.resetSplitProbeCounters();
              })
          }
          .width('100%')
          Text('窗口模式：' + this.windowMode + '  ·  生命周期：' + this.windowLifecycleState)
            .fontSize(12)
            .fontColor('#D2DCE8')
          Text('焦点：' + this.windowFocusState + '  ·  可见：' + (this.windowVisible ? '是' : '否'))
            .fontSize(12)
            .fontColor('#D2DCE8')
          Text('AR 帧回调：' + this.frameCallbackCount.toString() +
            '  ·  估算回调率：' + this.frameRateHz.toFixed(1) + ' Hz')
            .fontSize(12)
            .fontColor('#D2DCE8')
          Text('最近帧距今：' + (this.frameAgeMs >= 0 ? this.frameAgeMs.toFixed(0) + ' ms' : '尚无') +
            '  ·  最近间隔：' + this.frameLastIntervalMs.toFixed(1) + ' ms')
            .fontSize(12)
            .fontColor('#D2DCE8')
          Text('失焦期间回调：' + this.framesWhileInactive.toString() +
            '  ·  失焦观察时长：' + (this.inactiveElapsedMs / 1000).toFixed(1) + ' s' +
            '  ·  最大帧间隔：' + this.frameMaxGapMs.toFixed(1) + ' ms')
            .fontSize(12)
            .fontColor('#D2DCE8')
          Text(this.splitProbeStatus())
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.splitProbeStatusColor())
          Text('最近窗口事件')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8DA2BC')
          Text(this.windowEventLog.length > 0 ? this.windowEventLog : '等待窗口事件…')
            .fontSize(10)
            .fontColor('#9AA9BC')
            .lineHeight(15)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(15)
        .backgroundColor('#172235')
        .borderRadius(15)

        Column({ space: 8 }) {
          Text('LIVE CAMERA / AR VIEW')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8DA2BC')
          if (this.arContext !== undefined) {
            ARView({ context: this.arContext })
              .width('100%')
              .height(340)
              .borderRadius(12)
          } else {
            Column({ space: 8 }) {
              Text('摄像头预览尚未启动')
                .fontSize(16)
                .fontColor('#D2DCE8')
              Text('点击“开始追踪”，授权相机后启动 AR Engine 前置人脸会话。')
                .fontSize(12)
                .fontColor('#9AA9BC')
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .height(220)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#111C2D')
            .borderRadius(12)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(15)
        .backgroundColor('#172235')
        .borderRadius(15)

        Column({ space: 10 }) {
          Row() {
            Column({ space: 4 }) {
              Text('FACE VISUALIZER')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8DA2BC')
              Text('来自 AR Engine 的实时三维人脸几何')
                .fontSize(12)
                .fontColor('#AAB8C8')
            }
            .layoutWeight(1)
            Row({ space: 6 }) {
              Button('采集基准')
                .height(34)
                .fontSize(11)
                .enabled(this.faceCount > 0 && this.arContext !== undefined)
                .backgroundColor('#285B55')
                .onClick(() => {
                  this.captureNeutralBaseline();
                })
              Button('重置视角')
                .height(34)
                .fontSize(11)
                .backgroundColor('#34445D')
                .onClick(() => {
                  this.gpuSurfaceController.resetView();
                })
            }
          }
          .width('100%')
          Row({ space: 6 }) {
            Button('线框')
              .layoutWeight(1)
              .height(36)
              .fontSize(12)
              .backgroundColor(this.meshViewMode === 'wireframe' ? '#285B55' : '#34445D')
              .onClick(() => {
                this.setMeshViewMode('wireframe');
              })
            Button('实体')
              .layoutWeight(1)
              .height(36)
              .fontSize(12)
              .backgroundColor(this.meshViewMode === 'surface' ? '#285B55' : '#34445D')
              .onClick(() => {
                this.setMeshViewMode('surface');
              })
            Button('形变热力')
              .layoutWeight(1)
              .height(36)
              .fontSize(11)
              .backgroundColor(this.meshViewMode === 'deformation' ? '#285B55' : '#34445D')
              .onClick(() => {
                this.setMeshViewMode('deformation');
              })
            Button('部位分区')
              .layoutWeight(1)
              .height(36)
              .fontSize(11)
              .backgroundColor(this.meshViewMode === 'regions' ? '#285B55' : '#34445D')
              .onClick(() => {
                this.setMeshViewMode('regions');
              })
          }
          .width('100%')
          FaceGpuSurface({ controller: this.gpuSurfaceController })
            .width('100%')
          Text(this.meshLabelsAvailable ?
            '四种模式均由 OpenGL ES 原生 GPU 绘制；部位分区直接使用 AR Engine 三角面语义标签。' :
            '四种模式均由 OpenGL ES 原生 GPU 绘制；当前设备未返回可用的三角面区域标签。')
            .fontSize(11)
            .fontColor('#8190A5')
            .lineHeight(17)
          Divider()
          Text('FACE DATA')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8DA2BC')
          Row() {
            Column({ space: 4 }) {
              Text('3D MESH')
                .fontSize(10)
                .fontColor('#9AA9BC')
              Text(this.meshSummary)
                .fontSize(13)
                .fontColor('#F4F7FB')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            Column({ space: 4 }) {
              Text('HEAD POSE')
                .fontSize(10)
                .fontColor('#9AA9BC')
              Text(this.poseSummary)
                .fontSize(13)
                .fontColor('#F4F7FB')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          Column({ space: 4 }) {
            Text('BLEND SHAPES')
              .fontSize(10)
              .fontColor('#9AA9BC')
            Text(this.blendSummary)
              .fontSize(13)
              .fontColor('#F4F7FB')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          Divider()
          Row() {
            Column({ space: 3 }) {
              Text('LEFT BLINK')
                .fontSize(10)
                .fontColor('#9AA9BC')
              Text(this.leftBlink)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#63D6A5')
            }
            .layoutWeight(1)
            Column({ space: 3 }) {
              Text('RIGHT BLINK')
                .fontSize(10)
                .fontColor('#9AA9BC')
              Text(this.rightBlink)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#63D6A5')
            }
            .layoutWeight(1)
            Column({ space: 3 }) {
              Text('JAW OPEN')
                .fontSize(10)
                .fontColor('#9AA9BC')
              Text(this.jawOpen)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#63D6A5')
            }
            .layoutWeight(1)
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(15)
        .backgroundColor('#172235')
        .borderRadius(15)

        Column({ space: 10 }) {
          Row() {
            Column({ space: 4 }) {
              Text('GESTURE INTERACTION LAB')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8DA2BC')
              Text(this.gestureLabEnabled ? '手势输入已启用' : '手势输入关闭 · 原始数据监测中')
                .fontSize(12)
                .fontColor(this.gestureLabEnabled ? '#63D6A5' : '#AAB8C8')
            }
            .layoutWeight(1)
            Button(this.gestureLabEnabled ? '关闭输入' : '启用输入')
              .height(36)
              .fontSize(12)
              .enabled(this.gestureLabEnabled || (this.faceCount > 0 && this.arContext !== undefined))
              .backgroundColor(this.gestureLabEnabled ? '#7A4A4A' : '#285B55')
              .onClick(() => {
                this.toggleGestureLab();
              })
          }
          .width('100%')
          Text('HEAD POSE INPUT')
            .fontSize(10)
            .fontColor('#9AA9BC')
          Text(this.gestureAxisSummary)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#F4F7FB')
          Row() {
            Column({ space: 3 }) {
              Text('LEFT BLINK')
                .fontSize(9)
                .fontColor('#9AA9BC')
              Text(this.gestureLeftBlink)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#63D6A5')
            }
            .layoutWeight(1)
            Column({ space: 3 }) {
              Text('RIGHT BLINK')
                .fontSize(9)
                .fontColor('#9AA9BC')
              Text(this.gestureRightBlink)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#63D6A5')
            }
            .layoutWeight(1)
            Column({ space: 3 }) {
              Text('JAW OPEN')
                .fontSize(9)
                .fontColor('#9AA9BC')
              Text(this.gestureJawOpen)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#63D6A5')
            }
            .layoutWeight(1)
          }
          .width('100%')
          Divider()
          Text('交互演示 · 眼部单眨切换焦点，张嘴保持确认')
            .fontSize(12)
            .fontColor('#D2DCE8')
          Row({ space: 8 }) {
            Button('选项 A')
              .layoutWeight(1)
              .height(48)
              .fontSize(12)
              .backgroundColor(this.gestureSelectionIndex === 0 ? '#285B55' : '#34445D')
              .onClick(() => {
                this.gestureSelectionIndex = 0;
              })
            Button('选项 B')
              .layoutWeight(1)
              .height(48)
              .fontSize(12)
              .backgroundColor(this.gestureSelectionIndex === 1 ? '#285B55' : '#34445D')
              .onClick(() => {
                this.gestureSelectionIndex = 1;
              })
            Button('选项 C')
              .layoutWeight(1)
              .height(48)
              .fontSize(12)
              .backgroundColor(this.gestureSelectionIndex === 2 ? '#285B55' : '#34445D')
              .onClick(() => {
                this.gestureSelectionIndex = 2;
              })
          }
          .width('100%')
          Text('当前焦点：选项 ' + String.fromCharCode(65 + this.gestureSelectionIndex) +
            ' · 已确认 ' + this.gestureConfirmCount.toString() + ' 次')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#63D6A5')
          Text(this.gestureLastEvent)
            .fontSize(12)
            .fontColor('#F4F7FB')
          Button('重置演示')
            .width('100%')
            .height(36)
            .backgroundColor('#34445D')
            .onClick(() => {
              this.resetGestureDemo();
            })
          Text('识别规则：单眼权重 ≥ 0.72 触发，回落至 ≤ 0.35 后重新待命；自然双眼眨眼不触发。张嘴权重 ≥ 0.72 并保持 350 ms 触发确认，回落到 ≤ 0.40 后重新待命。演示动作只改变本卡片内的焦点和计数，不控制系统或其他应用。触控与 M-Pencil 仍可直接操作选项。')
            .fontSize(11)
            .fontColor('#8190A5')
            .lineHeight(17)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(15)
        .backgroundColor('#172235')
        .borderRadius(15)

        Column({ space: 10 }) {
          Row() {
            Column({ space: 4 }) {
              Text('FACE PEN · 0.1')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8DA2BC')
              Text(this.facePenControlEnabled ? '面部颜色控制已启用' : 'M-Pencil 本地画布 · 面部控制默认关闭')
                .fontSize(12)
                .fontColor(this.facePenControlEnabled ? '#63D6A5' : '#AAB8C8')
            }
            .layoutWeight(1)
            Button(this.facePenControlEnabled ? '暂停面部控制' : '启用面部控制')
              .height(36)
              .fontSize(12)
              .enabled(this.facePenControlEnabled || (this.faceCount > 0 && this.arContext !== undefined))
              .backgroundColor(this.facePenControlEnabled ? '#7A4A4A' : '#285B55')
              .onClick(() => {
                this.toggleFacePenControl();
              })
          }
          .width('100%')

          Text('手动选择笔色')
            .fontSize(12)
            .fontColor('#D2DCE8')
          Row({ space: 6 }) {
            Button('墨黑')
              .layoutWeight(1)
              .height(38)
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor(this.facePenTargetColorIndex() === 0 ? '#285B55' : '#34445D')
              .onClick(() => {
                this.requestFacePenColor(0, '手动选择');
              })
            Button('朱红')
              .layoutWeight(1)
              .height(38)
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor(this.facePenTargetColorIndex() === 1 ? '#285B55' : '#34445D')
              .onClick(() => {
                this.requestFacePenColor(1, '手动选择');
              })
            Button('钴蓝')
              .layoutWeight(1)
              .height(38)
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor(this.facePenTargetColorIndex() === 2 ? '#285B55' : '#34445D')
              .onClick(() => {
                this.requestFacePenColor(2, '手动选择');
              })
          }
          .width('100%')
          Row({ space: 6 }) {
            Button('松绿')
              .layoutWeight(1)
              .height(38)
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor(this.facePenTargetColorIndex() === 3 ? '#285B55' : '#34445D')
              .onClick(() => {
                this.requestFacePenColor(3, '手动选择');
              })
            Button('琥珀')
              .layoutWeight(1)
              .height(38)
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor(this.facePenTargetColorIndex() === 4 ? '#285B55' : '#34445D')
              .onClick(() => {
                this.requestFacePenColor(4, '手动选择');
              })
            Button('紫藤')
              .layoutWeight(1)
              .height(38)
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor(this.facePenTargetColorIndex() === 5 ? '#285B55' : '#34445D')
              .onClick(() => {
                this.requestFacePenColor(5, '手动选择');
              })
          }
          .width('100%')

          Text(this.facePenPendingColorIndex >= 0 ?
            '当前笔画仍使用已锁定的颜色；下一笔将使用 ' +
              FACE_PEN_PALETTE[this.facePenPendingColorIndex].name :
            '当前笔色：' + FACE_PEN_PALETTE[this.facePenSelectedColorIndex].name)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#63D6A5')
          FacePenCanvas({
            selectedColor: FACE_PEN_PALETTE[this.facePenSelectedColorIndex].value,
            selectedColorName: FACE_PEN_PALETTE[this.facePenSelectedColorIndex].name,
            onStrokeStateChange: (active: boolean) => {
              this.onFacePenStrokeStateChange(active);
            },
            onInputStatus: (message: string) => {
              this.facePenStatus = message;
            }
          })
            .width('100%')
          Text(this.facePenStatus)
            .fontSize(12)
            .fontColor('#D2DCE8')
          Text(this.facePenLastCommand)
            .fontSize(12)
            .fontColor('#63D6A5')
          Text('左眼单眨：上一种颜色；右眼单眨：下一种颜色。复用 0.5.2 的 80 ms 确认与 650 ms 冷却，不重复触发第二套识别器。笔尖落下时锁定颜色；书写中收到眨眼或手动调色，只排队给下一笔。')
            .fontSize(11)
            .fontColor('#8190A5')
            .lineHeight(17)
          Text('本功能只控制 FaceLab 自己的画布，不修改华为笔记或其他应用。面部控制需要先启动追踪并手动启用；人脸丢失时自动暂停。')
            .fontSize(11)
            .fontColor('#8190A5')
            .lineHeight(17)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(15)
        .backgroundColor('#172235')
        .borderRadius(15)

        Column({ space: 10 }) {
          Text('POSE EXPLORER')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8DA2BC')
          Text(this.poseCalibrated ? '姿态基准已建立' : '等待姿态基准')
            .fontSize(11)
            .fontColor(this.poseCalibrated ? '#63D6A5' : '#9AA9BC')
          Row() {
            Column({ space: 4 }) {
              Text('PITCH · 上下点头 (X)')
                .fontSize(10)
                .fontColor('#9AA9BC')
              Text(this.rotationX)
                .fontSize(21)
                .fontWeight(FontWeight.Bold)
                .fontColor('#63D6A5')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            Column({ space: 4 }) {
              Text('YAW · 左右转头 (Y)')
                .fontSize(10)
                .fontColor('#9AA9BC')
              Text(this.rotationY)
                .fontSize(21)
                .fontWeight(FontWeight.Bold)
                .fontColor('#63D6A5')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            Column({ space: 4 }) {
              Text('ROLL · 左右歪头 (Z)')
                .fontSize(10)
                .fontColor('#9AA9BC')
              Text(this.rotationZ)
                .fontSize(21)
                .fontWeight(FontWeight.Bold)
                .fontColor('#63D6A5')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          Row() {
            Column({ space: 4 }) {
              Text('姿态连续性')
                .fontSize(10)
                .fontColor('#9AA9BC')
              Text(this.trackingStabilityLabel)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#63D6A5')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            Column({ space: 4 }) {
              Text('短时姿态变化')
                .fontSize(10)
                .fontColor('#9AA9BC')
              Text(this.trackingStabilitySummary)
                .fontSize(12)
                .fontColor('#F4F7FB')
            }
            .layoutWeight(2)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          Text('QUATERNION')
            .fontSize(10)
            .fontColor('#9AA9BC')
          Text(this.quaternionSummary)
            .fontSize(12)
            .fontColor('#F4F7FB')
          Text('RELATIVE TRANSLATION')
            .fontSize(10)
            .fontColor('#9AA9BC')
          Text(this.translationSummary)
            .fontSize(12)
            .fontColor('#F4F7FB')
          Button('校准当前姿态为零点')
            .width('100%')
            .height(42)
            .enabled(this.faceCount > 0 && this.arContext !== undefined)
            .backgroundColor('#285B55')
            .onClick(() => {
              this.calibratePose();
            })
          Text('首次检测到人脸时自动建立姿态零点。X 为上下点头（Pitch），Y 为左右转头（Yaw），Z 为左右歪头（Roll），方向已按 MatePad 实测动作对应；正负号表示相反方向。短时连续性是基于相邻姿态帧变化的启发式指标，并非 AR Engine 官方置信度。平移显示相对校准点的 AR 坐标差。')
            .fontSize(11)
            .fontColor('#8190A5')
            .lineHeight(17)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(15)
        .backgroundColor('#172235')
        .borderRadius(15)

        Column({ space: 10 }) {
          Text('NEUTRAL EXPRESSION BASELINE')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8DA2BC')
          Text(this.neutralCalibrated ? '中性表情基准已建立' : '尚未建立中性表情基准')
            .fontSize(12)
            .fontColor(this.neutralCalibrated ? '#63D6A5' : '#9AA9BC')
          Text('相对中性网格形变')
            .fontSize(10)
            .fontColor('#9AA9BC')
          Text(this.neutralDeformationSummary)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#F4F7FB')
          Button('采集 / 重新采集中性表情')
            .width('100%')
            .height(42)
            .enabled(this.faceCount > 0 && this.arContext !== undefined)
            .backgroundColor('#285B55')
            .onClick(() => {
              this.captureNeutralBaseline();
            })
          Text('采集时请正视屏幕、放松面部，不要眨眼或张嘴。之后的 RMS / MAX 表示当前网格相对这张中性参考网格的变化幅度；它可能同时受到表情和头部姿态影响。')
            .fontSize(11)
            .fontColor('#8190A5')
            .lineHeight(17)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(15)
        .backgroundColor('#172235')
        .borderRadius(15)

        Column({ space: 10 }) {
          Text('MESH DIAGNOSTICS')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8DA2BC')
          Text(this.meshSummary)
            .fontSize(14)
            .fontColor('#F4F7FB')
          Text('相邻帧网格变化')
            .fontSize(10)
            .fontColor('#9AA9BC')
          Text(this.meshMotionSummary)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#63D6A5')
          Button('重置网格位移基准')
            .width('100%')
            .height(42)
            .enabled(this.faceCount > 0 && this.arContext !== undefined)
            .backgroundColor('#34445D')
            .onClick(() => {
              this.resetMeshBaseline();
            })
          Text('这里比较当前帧与上一帧，用于观察短时网格波动；中性表情基准比较则显示在上方独立卡片。RMS 为顶点位移均方根，MAX 为单个顶点最大位移。数值使用原始坐标单位，不换算为毫米。')
            .fontSize(11)
            .fontColor('#8190A5')
            .lineHeight(17)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(15)
        .backgroundColor('#172235')
        .borderRadius(15)

        if (this.errorMessage.length > 0) {
          Column({ space: 5 }) {
            Text('诊断信息')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#F2C078')
            Text(this.errorMessage)
              .fontSize(12)
              .fontColor('#D2DCE8')
              .lineHeight(19)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(15)
          .backgroundColor('#2A2630')
          .borderRadius(15)
        }

        Text('本版本只在本机实时处理面部数据，不保存、不上传。AR 人脸追踪不等于读取 dToF 原始数据或系统人脸认证数据。')
          .fontSize(11)
          .fontColor('#8190A5')
          .lineHeight(18)
          .width('100%')
      }
      .width('100%')
      .padding(20)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0C1422')
    }
  }
}
