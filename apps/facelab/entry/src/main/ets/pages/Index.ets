import { arEngine, arViewController } from '@kit.AREngine';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State faceStatus: string = '尚未检测';
  @State depthStatus: string = '尚未检测';
  @State summary: string = '点击“检测设备能力”，查询当前设备的 AR Engine 特性支持情况。';
  @State checked: boolean = false;

  private checkCapabilities(): void {
    try {
      const faceSupported: boolean = arViewController.isARTypeSupported(
        arEngine.ARFeatureType.ARENGINE_FEATURE_TYPE_FACE
      );
      const depthSupported: boolean = arViewController.isARTypeSupported(
        arEngine.ARFeatureType.ARENGINE_FEATURE_TYPE_DEPTH
      );

      this.faceStatus = faceSupported ? 'SUPPORTED' : 'NOT SUPPORTED';
      this.depthStatus = depthSupported ? 'SUPPORTED' : 'NOT SUPPORTED';
      this.checked = true;

      if (faceSupported && depthSupported) {
        this.summary = '设备报告支持人脸追踪与 AR 深度估计。下一步可以尝试创建 AR 会话。';
      } else if (faceSupported) {
        this.summary = '设备支持人脸追踪，但未报告支持 AR 深度估计。可以继续验证面部网格与表情数据。';
      } else if (depthSupported) {
        this.summary = '设备支持 AR 深度估计，但未报告支持 AR 人脸追踪。深度估计不等于读取 dToF 原始数据。';
      } else {
        this.summary = '设备未报告支持这两项 AR Engine 特性。请记录结果，并核对官方支持机型列表。';
      }
    } catch (error) {
      const err = error as BusinessError;
      this.faceStatus = 'CHECK FAILED';
      this.depthStatus = 'CHECK FAILED';
      this.checked = true;
      this.summary = '能力查询失败。错误码：' + err.code.toString() + '；信息：' + err.message;
    }
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Column({ space: 6 }) {
          Text('FaceLab')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F4F7FB')
          Text('HarmonyOS · AR Capability Probe 0.1.0')
            .fontSize(13)
            .fontColor('#9AA9BC')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')

        Column({ space: 8 }) {
          Text('TARGET DEVICE')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8DA2BC')
          Text('MatePad Pro 13.2 (2023)')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#F4F7FB')
          Text('HarmonyOS 7.0.0.111 SP8 · Compile SDK 26.0.0')
            .fontSize(12)
            .fontColor('#AAB8C8')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .backgroundColor('#172235')
        .borderRadius(16)

        Column({ space: 12 }) {
          Text('DEVICE CAPABILITIES')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8DA2BC')

          Row() {
            Column({ space: 4 }) {
              Text('FACE TRACKING')
                .fontSize(12)
                .fontColor('#AAB8C8')
              Text(this.faceStatus)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.faceStatus === 'SUPPORTED' ? '#63D6A5' : '#F2C078')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text('DEPTH ESTIMATION')
                .fontSize(12)
                .fontColor('#AAB8C8')
              Text(this.depthStatus)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.depthStatus === 'SUPPORTED' ? '#63D6A5' : '#F2C078')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .backgroundColor('#172235')
        .borderRadius(16)

        Button('检测设备能力')
          .width('100%')
          .height(52)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#3D83F6')
          .onClick(() => this.checkCapabilities())

        Column({ space: 8 }) {
          Text(this.checked ? '检测结果' : '等待检测')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F4F7FB')
          Text(this.summary)
            .fontSize(14)
            .fontColor('#D2DCE8')
            .lineHeight(22)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .backgroundColor('#202D41')
        .borderRadius(16)

        Column({ space: 8 }) {
          Text('重要说明')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F4F7FB')
          Text('本页面只查询 AR Engine 特性支持情况，不会启动摄像头，也不会读取 dToF 原始深度数据。FACE 人脸追踪与 DEPTH 深度估计是两项独立能力。')
            .fontSize(12)
            .fontColor('#AAB8C8')
            .lineHeight(19)
          Text('当前版本不采集、不上传、不保存人脸图像或生物特征。')
            .fontSize(12)
            .fontColor('#AAB8C8')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .backgroundColor('#172235')
        .borderRadius(16)
      }
      .width('100%')
      .padding(22)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0C1422')
  }
}
