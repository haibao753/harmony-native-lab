import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { ARView, arEngine, arViewController } from '@kit.AREngine';
import { Scene } from '@kit.ArkGraphics3D';
import { BusinessError } from '@kit.BasicServicesKit';
import { FaceMetrics, FaceTrackingCallback } from '../common/FaceTrackingCallback';

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
  @State poseCalibrated: boolean = false;
  @State errorMessage: string = '';

  private faceCallback: FaceTrackingCallback | undefined = undefined;

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
    this.poseCalibrated = metrics.poseCalibrated;
    this.status = metrics.faceCount > 0 ? '正在追踪人脸' : 'AR 已运行，等待人脸进入画面';
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

  private async startTracking(): Promise<void> {
    if (this.isStarting || this.arContext !== undefined) {
      return;
    }

    this.isStarting = true;
    this.errorMessage = '';
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
      this.poseCalibrated = false;
    }
  }

  aboutToDisappear(): void {
    this.stopTracking();
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Column({ space: 5 }) {
          Text('FaceLab')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F4F7FB')
          Text('AR Face Tracking Lab · 0.3.0')
            .fontSize(13)
            .fontColor('#9AA9BC')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

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
          Text('POSE EXPLORER')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8DA2BC')
          Row() {
            Column({ space: 4 }) {
              Text('ROTATION X')
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
              Text('ROTATION Y')
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
              Text('ROTATION Z')
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
          Text('首次检测到人脸时自动建立基准。角度为标准 XYZ 欧拉角分解；设备实际轴向与正负方向请通过转头实验确认。平移显示相对校准点的 AR 坐标差。')
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
          Text('相邻帧顶点位移')
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
          Text('RMS 表示所有顶点三维位移的均方根，MAX 表示单个顶点的最大位移。当前显示原始坐标单位，不擅自换算为毫米。')
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
