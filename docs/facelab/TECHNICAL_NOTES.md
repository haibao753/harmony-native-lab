# FaceLab 技术说明

## 1. 技术栈

- ArkTS + ArkUI，Stage 模型。
- HarmonyOS SDK / Compile SDK 26.0.0。
- AR Engine Kit：`@kit.AREngine`。
- Graphics 3D Kit：`@kit.ArkGraphics3D`。
- 入口页面：`apps/facelab/entry/src/main/ets/pages/Index.ets`。
- 帧回调：`apps/facelab/entry/src/main/ets/common/FaceTrackingCallback.ets`。

## 2. 已验证的设备能力

目标设备 MatePad Pro 13.2（2023）、HarmonyOS 7.0.0.111 SP8、SDK 26.0.0：
- `ARENGINE_FEATURE_TYPE_FACE`：真机检测为 true。
- `ARENGINE_FEATURE_TYPE_DEPTH`：真机检测为 false。

FACE 与 DEPTH 是独立特性。人脸追踪不依赖通用 AR 深度估计能力，也不代表可读取 dToF 原始数据。

## 3. 0.2.0 AR 会话初始化

官方 ArkTS 人脸跟踪示例要求：
1. 检查 FACE 特性。
2. 请求 CAMERA 权限；同时在 module.json5 声明 GYROSCOPE 和 ACCELEROMETER（这两项为 system_grant）。
3. 加载 AR 场景：`Scene.load()`。
4. 创建 `arViewController.ARViewContext`。
5. 设置 scene 和继承自 `ARViewCallback` 的回调。
6. 设置 FACE 配置：
   - `type: arEngine.ARType.FACE`
   - `planeFindingMode: arEngine.ARPlaneFindingMode.DISABLED`
   - `powerMode: arEngine.ARPowerMode.NORMAL`
   - `focusMode: arEngine.ARFocusMode.AUTO`
   - `cameraLensFacing: arEngine.ARCameraLensFacing.FRONT`
   - `multiFaceMode: arEngine.ARMultiFaceMode.MULTIFACE_ENABLE`
7. 调用 `await context.init()`。
8. 使用 `ARView({ context })` 呈现 AR 场景和相机预览。

必须先设置 scene、callback、config，再调用 init；否则可能出现 1009200202（缺少场景）或 1009200203（缺少配置）。

## 4. 帧数据读取

在 `ARViewCallback.onFrameUpdate(ctx, sysBootTs)` 中：
- 从 `ctx.session` 获取 ARSession。
- 调用 `session.getFrame()` 获取当前帧。
- 调用 `session.getAllTrackables(arEngine.ARTrackableType.FACE)` 获取人脸。
- 只处理 `state === arEngine.ARTrackingState.TRACKING` 的人脸。
- `face.getPose().getMatrix()` 获取 4×4 位姿矩阵。
- `face.getGeometry().getVertices()` / `getIndices()` 获取 Mesh 数据。
- `face.getBlendShapes().getTypes()` / `getData()` 获取表情类型与权重。
- 使用完毕后释放 ARPose、ARGeometry、ARBlendShapes 和 ARFrame。

当前 UI 以约 5 Hz 更新统计值，ARView 的场景渲染仍由 AR Engine 自身驱动。

## 5. 权限

- `ohos.permission.CAMERA`：user_grant，用户点击“开始追踪”后通过 `abilityAccessCtrl.createAtManager().requestPermissionsFromUser()` 请求。
- `ohos.permission.GYROSCOPE`：system_grant，在 module.json5 声明。
- `ohos.permission.ACCELEROMETER`：system_grant，在 module.json5 声明。

ARViewContext.init() 文档要求以上三项权限。若用户拒绝 CAMERA，应用不启动 AR 会话。

## 6. 错误码

- 201：权限未授予。
- 801：设备不兼容。
- 1009200007：配置不支持。
- 1009200008：资源耗尽。
- 1009200009：服务不可用。
- 1009200010：相机不可用。
- 1009200201：ARView 非法操作。
- 1009200202：缺少 AR 场景。
- 1009200203：缺少 AR 配置。
- 1009200204：AR 会话初始化失败。
- 1009200205：AR 场景相机节点创建失败。

## 7. 隐私与数据生命周期

- 不保存、不上传相机帧、人脸 Mesh 或 BlendShapes。
- 仅在内存中展示实时统计。
- 停止追踪或页面退出时销毁 ARViewContext。
- 不访问系统人脸认证模板或 TEE 安全数据。
- 不宣称可以读取 dToF 原始深度帧。

## 8. 官方资料

- [AR Engine 人脸跟踪（ArkTS）](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arengine-face/)
- [ARViewController / ARViewContext API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arengine-api-arviewcontroller/)
- [AR Engine API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arengine-api-arengine/)
- [用户授权申请](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/request-user-authorization/)
- [系统权限列表](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/permissions-for-all/)


## 9. 0.2.0 runtime enum compatibility diagnostic

The first 0.2.0 device run failed before AR session creation with:
`TypeError: Cannot read property ARFeatureType of undefined`.

Huawei's API reference documents the following enum numeric values:
- `ARFeatureType.ARENGINE_FEATURE_TYPE_FACE = 6`
- `ARType.FACE = 0x10`
- `ARCameraLensFacing.FRONT = 1`
- `ARMultiFaceMode.MULTIFACE_ENABLE = 0x800`
- `ARTrackableType.FACE = 0x50000002`
- `ARTrackingState.TRACKING = 0`
- `ARBlendShapeType.EYE_BLINK_LEFT = 0`, `EYE_BLINK_RIGHT = 7`, `JAW_OPEN = 17`

To avoid runtime property dereferences on the `arEngine` namespace object, 0.2.1 uses these documented numeric enum values with the corresponding ArkTS enum types. This is a compatibility workaround, not evidence that the device's AR Engine service is unavailable. The app now also records the exact startup stage in its diagnostic message.

If the next run fails, the stage label distinguishes capability check, scene loading, callback creation, configuration, and session initialization.
