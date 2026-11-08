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


## 10. 0.2.2 — skip duplicate FACE capability probe

The user reproduced the same `Cannot read property ARFeatureType of undefined` exception at the exact startup stage `检查 FACE 能力`, even after the numeric enum workaround. This narrows the failure to the repeated `isARTypeSupported()` call path in the 0.2.x startup flow, not to camera permission, scene loading, or ARViewContext initialization.

FaceLab 0.1.0 had already run the same capability probe successfully on the same MatePad Pro 13.2 (2023), HarmonyOS 7.0.0.111 SP8, reporting FACE=SUPPORTED. Therefore 0.2.2 removes the duplicate runtime capability probe and uses the device-specific 0.1.0 result as the precondition. The AR session's `context.init()` is now the decisive runtime validation.

The AR session configuration and callback return to Huawei's documented ArkTS enum member expressions (for example `arEngine.ARType.FACE`, `arEngine.ARTrackableType.FACE`, and `arEngine.ARBlendShapeType.EYE_BLINK_LEFT`). This follows the official face-tracking guide and avoids hand-maintained magic enum values.

If startup still fails, the new stage label should now advance to scene loading, callback creation, FACE configuration, or AR session initialization.


## 11. 0.3.0 — Pose Explorer

### Pose source

Huawei AR Engine exposes `ARPose.rotation` as an ArkGraphics3D `Quaternion` (x/y/z/w) and `ARPose.translation` as a `Vec3` (x/y/z). The API reference also documents `getMatrix()` as a 16-value column-major matrix. FaceLab now reads the typed quaternion and translation properties directly rather than reverse-engineering the matrix.

### Relative orientation

- The first valid face pose after tracking begins becomes the automatic baseline.
- The UI calibration button requests that the next valid pose become the new baseline.
- Relative rotation is computed as `inverse(qBaseline) * qCurrent`.
- The relative quaternion is normalized before conversion.
- Displayed angles use the standard XYZ Tait-Bryan decomposition, in degrees.
- The UI deliberately labels axes X/Y/Z rather than asserting device-specific yaw/pitch/roll semantics. Confirm the physical axis directions and signs on the MatePad before renaming them.
- Rotation and translation deltas use an exponential smoothing factor of 0.35. Angular smoothing follows the shortest path across the ±180° boundary.

### Translation

The displayed values are `current.translation - baseline.translation`. They are relative AR coordinate deltas; the UI does not attach a length unit until the face-pose coordinate scale is confirmed on-device.

### Mesh diagnostics

- The device's observed face-vertex buffer is parsed as three Float32 coordinates (XYZ) per vertex; the parser validates that the ArrayBuffer byte length is divisible by 12.
- A copied previous-frame vertex snapshot is retained in memory only.
- For each vertex, displacement is `sqrt(dx² + dy² + dz²)`.
- RMS is `sqrt(sum(displacement²) / vertexCount)`; MAX is the largest per-vertex displacement in the frame pair.
- Values are shown in raw coordinate units because the ArkTS API page describes the ArrayBuffer but does not state a physical unit or vertex packing in its short signature. The observed 3482-vertex count on the target device is consistent with the current XYZ Float32 interpretation.
- The next valid frame after a reset establishes a fresh comparison baseline.
- When face tracking is lost, the previous mesh snapshot and pose baseline are cleared to avoid comparing unrelated face sessions.

### Scope

0.3.0 is a numerical Pose & Mesh diagnostics release. It does not yet render a standalone 3D mesh viewer. Existing ARView camera preview, FACE tracking, BlendShapes, and resource release behavior remain in place.

### Official references

- [AR Engine API — ARPose, ARGeometry, ARFace](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arengine-api-arengine/)
- [ArkGraphics 3D SceneType — Quaternion and Vec3](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-scene-types/)


## 12. 0.3.1 — Motion Intelligence

### Physical pose semantics

The user tested the 0.3.0 build on the target MatePad and confirmed the physical action mapping:
- X → Pitch: nodding up / down.
- Y → Yaw: turn left / right.
- Z → Roll: tilt left / right.

The UI now uses these semantic labels. The sign of each angle is not hard-coded as a left/right or up/down direction; users should read the live positive / negative value because the physical sign convention has not been separately recorded.

### Neutral-expression mesh baseline

- The user can request capture of the next valid face mesh while keeping a relaxed, forward-facing neutral expression.
- The captured XYZ Float32 vertex array is copied into an in-memory baseline.
- Current-vs-neutral per-vertex displacement is summarized as RMS and MAX.
- This is separate from the previous-frame mesh displacement calculation.
- The neutral baseline is cleared when tracking is lost or the callback stops, avoiding comparison against another face-tracking session.
- The metric is geometric displacement in raw coordinate units. It may reflect both expression and head-pose effects; it is not a pure expression coefficient.

### Pose continuity heuristic

- Keep the previous raw Euler sample and a rolling window of up to eight consecutive pose-step magnitudes.
- Each step is the Euclidean norm of the shortest-path X/Y/Z angular differences.
- Show the average step and a qualitative label: at or below 0.8° = “较平稳”; at or below 2.5° = “轻微变化”; above 2.5° = “头部运动中”.
- These thresholds are initial heuristics at the current approximately 5 Hz UI sampling cadence. They are not official AR Engine tracking-confidence values and require device observation.
- The label describes measured pose change, not whether movement is intentional or whether the tracker has lost confidence.

### Privacy and lifecycle

Neutral mesh samples and pose-step history remain in memory only. They are cleared when tracking is lost or the callback stops. No face data is persisted or uploaded.


## 13. 0.4.0 — Face Visualizer

### Data path

- `ARGeometry.getVertices()` returns the face mesh vertex buffer.
- `ARGeometry.getIndices()` returns triangle indices.
- `ARGeometry.getTriangleLabels()` is queried in an isolated optional try/catch. If the device/runtime does not return a label buffer with one label per triangle, region mode reports that labels are unavailable and the other modes continue.
- The observed target-device vertex layout remains XYZ Float32. Triangle indices are interpreted as 32-bit values, consistent with the existing 0.3.x byte-count assumption; confirm on the target build.
- A unique undirected edge list is built once per topology-size change and cached.
- Each frame copies current vertices and per-vertex displacement from the neutral baseline into in-memory buffers for the UI.

### Triangle label values

Huawei's HarmonyOS AR Engine reference documents:
- -1: non-face
- 0: face other
- 1: lower lip
- 2: upper lip
- 3: left eye
- 4: right eye
- 5: left brow
- 6: right brow
- 7: brow center
- 8: nose

The UI only uses these labels when the returned buffer length matches the triangle count. It does not infer semantic regions from vertex positions.

### Rendering

- `FaceMeshViewer` owns one `CanvasRenderingContext2D` instance alongside its Canvas component.
- It computes a centered, aspect-fit projection from the current XYZ vertex bounds.
- The renderer supports wireframe, translucent surface, deformation heatmap, and semantic region color modes.
- The current relative Pitch / Yaw / Roll from ARPose is combined with user inspection rotation.
- One-finger drag changes inspection rotation; two-finger pinch changes zoom; reset restores user inspection offsets and zoom.
- Rendering is event-driven by the existing approximately 5 Hz metrics callback, not a separate animation timer.

### Performance and limitations

- The renderer is a 3D-to-2D projection using ArkUI CanvasRenderingContext2D. It is not an ArkGraphics3D scene or a GPU-native mesh renderer.
- Canvas drawing queues commands while visible; avoid introducing an unbounded high-frequency producer. The existing 5 Hz callback throttle is retained.
- Surface/region modes draw all triangle faces; wireframe uses a cached unique edge list.
- Region labels are optional and device-dependent. If unavailable, wireframe, surface, and deformation modes remain usable.
- Face region coloring is based on Huawei's explicit per-triangle labels, not guessed facial landmark coordinates.
- All vertex, index, label, and deformation arrays remain in memory and are cleared when tracking stops or is lost.
