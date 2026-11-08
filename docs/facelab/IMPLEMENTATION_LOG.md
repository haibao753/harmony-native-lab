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

## 2026-11-08 — 0.4.2 Performance & Geometry Visualization

### 用户真机反馈

- 0.4.1 能运行，但实时追踪明显卡顿。
- 线框、实体、形变热力模式之间的视觉差异不明显；部位分区模式最容易辨识。

### 代码改进

- 将 AR 网格发布节流由 200 ms（5 Hz）调整为 100 ms（10 Hz），并用 processing guard 防止异步帧处理重入。
- 复用回调层顶点与形变 TypedArray；只在拓扑版本变化时刷新三角索引、边和标签缓存。
- 在 Index.ets 复用五组普通数组；逐帧只更新顶点与形变，拓扑数组仅在 meshTopologyRevision 改变时更新。
- 文本诊断降为约 2 Hz，网格数据继续按约 10 Hz 发布。
- FaceMeshViewer 复用投影点对象和面分组缓存，减少每次绘制的临时对象与数组分配。
- 线框仅绘制边；实体按三维面法线分桶着色；形变热力采用 8 档高对比色阶且不叠加线框；区域模式缓存语义面分组。
- Canvas 显示绘制调用频率与 JS 绘制提交耗时，辅助判断瓶颈。

### 验收边界

- 本次提交只完成代码和静态契约，不声称已通过 DevEco 构建或 MatePad 真机性能验收。
- 10 Hz 是数据发布目标，不等于真实 Canvas 帧率，也不等于 60 FPS。
- 若 Canvas 绘制仍占据主要耗时，下一阶段应先用设备数据确认瓶颈，再评估 ArkGraphics3D 原生 GPU 网格方案。


## 2026-11-08 — 0.4.3 Live Deformation Heatmap & Lite Rendering

### 用户真机反馈
- 0.4.2 实体模型可见，但整体仍卡顿，热力图没有可见内容。

### 代码改进
- 将网格发布间隔调整为 200 ms（约 5 Hz）。
- 未采集中性基准时以相邻帧逐顶点位移显示动态热力；采集后显示相对中性网格位移。
- 热力图图例区分 LIVE MOTION Δ 与 NEUTRAL Δ，并将采集基准入口移到观察器标题栏。

### 验收边界
- 代码改动尚需 DevEco 构建和 MatePad 真机回归；5 Hz 不保证 Canvas 流畅。

## 2026-11-08 — 0.5.0 OpenGL ES 3.0 Native Face Renderer

### 目标
将高频几何绘制从 ArkUI Canvas 移出，减少 ArkTS UI 边界数组转换和 CPU 绘图命令提交。

### 已提交到功能分支的代码
- 新增 CMake / NDK native module，链接 XComponent、NativeWindow、EGL 和 OpenGL ES 3。
- 新增 C++ FaceGpuRenderer：独立渲染线程、EGL 生命周期、VBO / EBO、顶点法线、实体光照与顶点热力着色。
- 新增 Node-API：接收 AR 回调中的 Float32Array / Uint32Array，传递网格、姿态、模式和视角参数。
- 新增 ArkTS XComponent Surface 控制器，管理 Surface 生命周期、单指旋转、双指缩放和重置视角。
- 将线框、实体和热力模式接入原生 GPU；区域分区暂时沿用 Canvas 实现。
- 将应用版本号更新为 0.5.0 / versionCode 10008。

### 验证边界
- GitHub 文件提交成功不等于 HarmonyOS 原生模块构建成功。
- 当前环境未运行 DevEco Studio / HarmonyOS SDK 编译；C++ NDK、ArkTS 类型和 XComponent 生命周期仍待本地构建验证。
- MatePad Pro 13.2（2023）实测尚未完成；帧率、热力可见性、手势、启动 / 停止资源释放均待验收。


## 2026-11-08 — 0.5.0 ArkTS XComponent SDK 26 compile correction

- User's first DevEco SDK 26 build confirmed CMake / native C++ compilation succeeds; ArkTS failed because XComponentController and XComponentType were incorrectly imported as named exports from @kit.ArkUI.
- Official ArkUI XComponent declarations define XComponentController and XComponentType as global ArkTS declarations in component/xcomponent.d.ts and component/enums.d.ts. They must be referenced without importing them from @kit.ArkUI.
- Keep the ArkTS XComponentOptions form with type: XComponentType.SURFACE and controller: this.controller. This uses the ArkTS-side lifecycle callbacks documented by Huawei and avoids NativeXComponentParameters, which is the separate API 19+ native-side lifecycle path and does not accept controller.
- Updated entry module package version from 0.1.0 to 0.5.0 to align package metadata with this release. This is a SemVer version string; whether it eliminates the user's hvigor warning must be confirmed by a fresh build.
- Next gate: rerun DevEco SDK 26 CompileArkTS, then inspect any subsequent diagnostics. Native CMake success is not a substitute for full HAP success.

## 2026-11-08 — SDK 26 NAPI native build correction

- User's second DevEco build confirmed ArkTS now compiles, but Ninja stopped because SDK 26 could not locate `napi/native_node_api.h`.
- Removed that include; the required Node-API functions are declared through `napi/native_api.h`.
- Fixed an important HarmonyOS API semantic difference: `napi_get_typedarray_info` returns byte length in HarmonyOS, not element count. Float32Array and Uint32Array copies now calculate element count from bytes to avoid out-of-bounds reads.
- Moved native declarations into the official `src/main/cpp/types/libfacelab_native` package structure and registered the .so dependency and runtime package.
- Changed the internal entry package version to 1.0.0 while retaining app version 0.5.0, to remove the persistent SemVer warning.
- Full SDK 26 NDK rebuild and HAP packaging remain pending user validation.


## 2026-11-08 — FaceLab 0.5.0 MatePad feedback and 0.5.1 GPU regions

### User hardware feedback
- User successfully built and deployed FaceLab 0.5.0 to MatePad Pro 13.2 (2023).
- User reports wireframe, surface and deformation heatmap are now very smooth.
- User reports Regions mode remains as laggy as the earlier Canvas implementation.

### 0.5.1 source changes
- Added Int32Array triangle-label input to the Node-API bridge and native renderer.
- Added a per-triangle expanded vertex upload path for region mode, preserving hard boundaries on shared mesh vertices.
- Added flat region-ID interpolation and a ten-color GLSL palette matching the previous Canvas mapping.
- Routed all four visualizer modes through the same XComponent native GPU Surface.
- Removed the Regions-only ArkUI Canvas branch and its per-frame number[] geometry copies.
- Bumped application version to 0.5.1 / versionCode 10009.

### Validation boundary
- The three original GPU modes have user-confirmed smooth performance on the target tablet.
- 0.5.1 region GPU code has passed static source-contract review only so far; DevEco SDK 26 compilation, label color mapping and device performance still require user verification.


## 2026-11-08 — FaceLab 0.5.1 stable release frozen

- Retargeted PR #11 from the stacked 0.4.3 feature branch to `main`; verified main was the merge base and the PR included the full FaceLab development history.
- Marked PR ready for review after source-contract CI passed.
- Squash-merged PR #11 into main.
- Merge commit: `beceadcb871543d943c28cd482c1ded8680fd71c`.
- User confirmed successful 0.5.1 build and deployment on MatePad Pro 13.2 (2023).
- Frozen application version 0.5.1 / versionCode 10009.
- A dedicated `release/facelab-0.5.1` branch is created as the stable source snapshot.
- Quantitative frame-rate, thermal and battery measurements are not available; deployment success is recorded without inventing performance numbers.


## 2026-11-08 — FaceLab 0.5.1 device acceptance
- User confirms all four visualizer modes, including semantic face-region mode, are now smooth on MatePad Pro 13.2 (2023).
- The region-mode lag is considered resolved for the target device.
- FaceLab 0.5.1 remains the frozen stable baseline at versionCode 10009.

## 2026-11-08 — FaceLab 0.5.2 Gesture Interaction Lab
### Implemented in source
- Split AR callback cadence: sample pose / BlendShapes at up to approximately 30 Hz while publishing mesh geometry and GPU updates at approximately 5 Hz.
- Added unilateral eye-wink detection with close / release hysteresis, an 80 ms unilateral-closure confirmation window, edge-triggering and a 650 ms cooldown; simultaneous bilateral closure is ignored as a natural blink.
- Added sustained jaw-open confirmation requiring weight >= 0.72 for 350 ms, with release at <= 0.40 and a 1000 ms cooldown.
- Added an opt-in local interaction demo: left / right wink cycles focus among A / B / C; sustained jaw-open confirms the focused option.
- Gesture input defaults off. Touch and M-Pencil remain available. No system-level input injection or external-app control is performed.
- Face gesture state resets when tracking is lost or the callback stops.

### Validation boundary
- Static source-contract checks are the first gate.
- DevEco SDK 26 compilation and MatePad runtime verification are still required; no successful HAP build or device test is claimed yet.
- Verify natural bilateral blinking does not trigger wink actions, thresholds feel usable, gesture sampling does not degrade the smooth GPU modes, and stop / restart clears state.
