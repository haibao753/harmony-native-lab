# FaceLab 技术说明

## 1. 技术栈
- ArkTS + ArkUI。
- Stage 模型。
- HarmonyOS SDK / Compile SDK 26.0.0。
- AR Engine Kit：`@kit.AREngine`。
- 当前入口：`apps/facelab/entry/src/main/ets/pages/Index.ets`。

## 2. 0.1.0 能力检查

```ts
import { arEngine, arViewController } from '@kit.AREngine';

const faceSupported = arViewController.isARTypeSupported(
  arEngine.ARFeatureType.ARENGINE_FEATURE_TYPE_FACE
);

const depthSupported = arViewController.isARTypeSupported(
  arEngine.ARFeatureType.ARENGINE_FEATURE_TYPE_DEPTH
);
```

FACE 和 DEPTH 必须分别判断。能力探测不是传感器数据读取，也不是相机预览。

## 3. 后续人脸会话

华为 ArkTS 人脸跟踪指南的数据流：
1. 检查 FACE 特性支持。
2. 申请并获得 `ohos.permission.CAMERA`。
3. 创建 `arViewController.ARViewContext`，按官方 AR 会话指南配置人脸跟踪和前置镜头。
4. 设置继承自 `arViewController.ARViewCallback` 的回调类。
5. 在 `onFrameUpdate` 中从 session 获取 frame。
6. 使用 `ARSession.getAllTrackables(arEngine.ARTrackableType.FACE)` 获取人脸对象。
7. 从 `ARFace.getGeometry()` 获取网格，从 `ARFace.getBlendShapes()` 获取微表情数据。
8. 按官方生命周期及时释放 frame 及相关资源。

具体会话初始化、ARView 组件和三维渲染代码必须以 API 26 SDK 类型定义和官方示例为准；在真机能力检查通过前，不提前假设这些步骤可用。

## 4. 关键边界
- AR Engine 的 FACE 是系统提供的人脸跟踪能力；它不等同于系统人脸认证。
- MatePad 的 dToF 硬件存在，不代表普通应用可以读取原始 ToF 帧或人脸认证数据。
- AR Engine 的 DEPTH 是独立的深度估计特性，不应描述成“读取 dToF 原始数据”。
- AR Engine 当前文档说明仅在中国大陆地区提供服务；设备地区、服务可用性和系统版本都可能影响结果。
- AR Engine 不支持模拟器，必须真机验证。
- 人脸网格与动作参数属于敏感个人数据；本项目默认只在设备本地实时处理。

## 5. 权限
当前模块声明了 `ohos.permission.CAMERA`，但 0.1.0 不主动请求该权限，因为能力查询页面不启动相机。进入 0.2.0 后，必须在用户明确点击“开始追踪”时请求授权，并在拒绝时保持应用可用且说明原因。

## 6. 官方资料
- [AR Engine 人脸跟踪（ArkTS）](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arengine-face/)
- [AR Engine 开发准备与硬件要求](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arengine-preparations/)
- [AR Engine API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arengine-api-arengine/)
- [AR Engine 支持机型列表](https://developer.huawei.com/consumer/cn/forum/topic/0208215774177333398)
- [AR Engine 概览](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arengine-overview/)
