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


## 2026-11-08 — 0.3.0 Pose & Mesh Explorer

### Implemented in code

- Read `ARPose.rotation` and `ARPose.translation` directly.
- Capture an automatic first-pose baseline and expose a next-frame recalibration method.
- Compute relative orientation with inverse-baseline quaternion multiplication.
- Convert normalized relative quaternion to standard XYZ Euler angles.
- Smooth Euler angles with shortest-angle interpolation and translation deltas with an exponential filter.
- Display raw quaternion and relative translation.
- Parse the observed XYZ Float32 face-vertex buffer with a strict byte-length guard.
- Compare adjacent vertex snapshots and display per-vertex displacement RMS and MAX.
- Add UI controls for pose recalibration and mesh baseline reset.
- Preserve camera session setup, face tracking, BlendShapes reads, and resource release.

### Validation status

- Official Huawei AR Engine API reference confirms ARPose.rotation is Quaternion, ARPose.translation is Vec3, and ARGeometry exposes vertex and index ArrayBuffers.
- Official ArkGraphics 3D type reference confirms Quaternion and Vec3 x/y/z/w fields.
- The code changes are committed to a dedicated feature branch.
- No DevEco SDK build or MatePad hardware test has been run in this environment. The user's next build is required to validate ArkTS compatibility and confirm axis directions / mesh displacement behavior.


## 2026-11-08 — 0.3.1 Motion Intelligence

### Implemented in code

- Rename the verified physical pose semantics in the UI: X = Pitch (nodding), Y = Yaw (left/right turn), Z = Roll (side tilt), based on the user's MatePad 0.3.0 action test.
- Add user-triggered neutral-expression mesh capture. The next valid face geometry frame is copied as an in-memory baseline.
- Compute current mesh displacement relative to the neutral baseline (RMS / MAX), separately from the existing adjacent-frame mesh displacement.
- Add a rolling eight-sample pose-continuity heuristic based on consecutive raw Euler-angle changes.
- Display continuity as “较平稳 / 轻微变化 / 头部运动中”; this is not an AR Engine confidence score.
- Clear neutral mesh and temporal samples when tracking is lost or the callback stops.
- Bump app version metadata to 0.3.1 / versionCode 10003.

### Validation boundary

- Source changes and documentation have been committed to a new feature branch stacked on the 0.3.0 branch.
- Static source review only. The GitHub connector cannot run DevEco Studio, compile ArkTS, package a HAP, or test the MatePad.
- User must build and install 0.3.1 locally. Verify neutral capture, blink / jaw deformation, head movement, continuity feedback, recalibration, and stop cleanup.


### 0.3.1 device acceptance update

- User reports that 0.3.1 successfully ran on the MatePad Pro 13.2 (2023) and that no obvious issues were noticed.
- User specifically verified that, after capturing a neutral-expression mesh baseline, blinking and opening the mouth change the current-vs-neutral mesh RMS / MAX values.
- This confirms that the neutral-reference geometry metric responds to at least these two expression actions on the target device.
- No calibrated mapping from RMS / MAX to expression intensity is claimed; values remain in raw mesh coordinate units and may also reflect head-pose changes.
- Head-pose continuity feedback, recalibration, and stop / restart cleanup have not yet been separately recorded as individually accepted tests.
- GitHub Actions source-contract checks passed. DevEco build and hardware smoke test were completed by the user on the target device.


## 2026-11-08 — 0.4.0 Face Visualizer

### Implemented in code

- Added `FaceMeshViewer.ets`, an ArkUI Canvas-based 3D projection viewer.
- Pass copied XYZ mesh vertices, triangle indices, unique edge pairs, and per-vertex neutral-baseline displacement from the AR callback to the viewer.
- Added wireframe, translucent surface, deformation heatmap, and semantic region color modes.
- Read optional `ARGeometry.getTriangleLabels()` and map the documented label IDs to face regions.
- Apply the live relative ARPose Euler angles to the face-local mesh projection, then combine with user inspection rotation.
- Added one-finger drag rotation, two-finger pinch zoom, and view reset.
- Bumped app version to 0.4.0 / versionCode 10004.
- Kept the existing approximately 5 Hz callback update throttle and in-memory-only data handling.

### Validation boundary

- Static source review and GitHub source-contract checks only.
- No DevEco Studio build or MatePad 0.4.0 hardware test has been performed by the assistant.
- The user must verify ArkTS compilation, Canvas rendering, region-label availability, live head-pose transform direction, expression deformation, gesture interaction, performance, and stop / restart cleanup.


## 2026-11-08 — 0.4.1 Runtime Stability Hotfix

### Root cause and fix

- The MatePad first-frame JSCrash identified FaceMeshViewer.ets:158:40 and `TypeError: This value does not have a [[TypedArrayName]] internal slot`.
- The failure was caused by TypedArray values crossing the ArkUI `@Prop` observation boundary; TypedArray accessors require a genuine TypedArray receiver.
- Kept typed geometry buffers inside FaceTrackingCallback for processing, then converted vertices, triangles, edges, deformation, and optional labels with Array.from() in Index.ets.
- Restricted all five FaceMeshViewer array props to ordinary number[] values.
- Updated the visible app version and app metadata to 0.4.1 / versionCode 10005.
- Added a dedicated release note, 0.4.1 source-contract checks, and kept the old 0.4.0 check script as a compatibility alias.

### Verification boundary

- GitHub Actions run 42459080651 passed the shell syntax and FaceLab 0.4.1 source-contract steps.
- DevEco Studio compilation and MatePad hardware retest have not yet been performed; no runtime success is claimed.