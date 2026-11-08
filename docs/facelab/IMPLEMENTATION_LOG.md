# FaceLab 实现记录

## 2026-11-08 — 0.2.0 AR Face Session

### 已实现（代码层面）

- 增加用户主动触发的 CAMERA 权限申请。
- 在 module.json5 声明 CAMERA、GYROSCOPE、ACCELEROMETER。
- 使用官方 FACE 配置初始化 ARViewContext。
- 使用 ARView 显示 AR 场景和前置相机预览。
- 增加 ARViewCallback 帧回调和追踪人脸计数。
- 读取 ARPose 矩阵、ARGeometry 顶点 / 索引缓冲区、ARBlendShapes 类型 / 权重数据。
- 展示左眼眨眼、右眼眨眼、张嘴三个 BlendShapes 权重。
- 对回调 UI 更新节流至约 5 Hz。
- 帧结束后释放 ARPose、ARGeometry、ARBlendShapes、ARFrame。
- 停止追踪和页面退出时销毁 ARViewContext。
- 不保存、不上传面部数据。

### 已有真机证据

0.1.0 在 MatePad Pro 13.2（2023）、HarmonyOS 7.0.0.111 SP8 上检测到：
- FACE：SUPPORTED
- DEPTH：NOT SUPPORTED

### 尚未完成 / 尚未验证

- 0.2.0 尚未在 DevEco Studio 本地构建。
- 尚未在目标 MatePad 安装 0.2.0。
- ARViewContext.init() 是否成功尚未验证。
- ARView 相机预览、人脸计数、Mesh、Pose、BlendShapes 均待真机验证。
- 当前页面展示 Mesh 统计信息，尚未将网格绘制为独立 3D 面部模型。

### 验收步骤

1. 在 DevEco Studio 打开 `apps/facelab`。
2. 使用 HarmonyOS SDK 26.0.0 同步并构建 entry 模块。
3. 部署到 MatePad Pro 13.2（2023）。
4. 点击“开始追踪”，允许相机权限。
5. 检查 ARView 是否出现前置摄像头预览。
6. 将脸放入画面，检查人脸数、Mesh、Pose、BlendShapes 是否有数据。
7. 分别眨左眼、眨右眼、张嘴，观察对应权重。
8. 点击“停止追踪”，确认摄像头预览关闭。
9. 将构建日志和真机截图回填到 DEVICE_MATRIX.md。


## 2026-11-08 — 0.2.1 runtime diagnostic patch

- User's first 0.2.0 device run showed `TypeError: Cannot read property ARFeatureType of undefined`.
- Replaced runtime enum-member dereferences on `arEngine` with Huawei-documented numeric enum values, retaining ArkTS enum type annotations.
- Added explicit startup-stage diagnostics.
- This patch has not yet been rebuilt or tested on the user's device.


## 2026-11-08 — 0.2.2 duplicate capability-probe bypass

- User's 0.2.1 run still failed at `检查 FACE 能力` with `Cannot read property ARFeatureType of undefined`.
- The exact failure stage isolates the exception to the repeated capability-probe path.
- 0.1.0 already proved FACE support on this exact target device, so 0.2.2 removes the redundant probe from the Start flow.
- Restored official Huawei ArkTS enum member expressions for session configuration and callback trackable / state / BlendShape types.
- This patch has not yet been rebuilt or tested on the user's MatePad.
