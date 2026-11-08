# FaceLab 设备兼容性记录

最后更新：2026-11-08。

| 项目 | 已知信息 | 状态 |
|---|---|---|
| 目标设备 | MatePad Pro 13.2（2023） | 用户提供 |
| 系统版本 | HarmonyOS 7.0.0.111 SP8 | 用户提供 |
| Compile SDK | 26.0.0 | 用户提供 |
| AR Engine FACE | 真机能力检测返回 true | <span>已验证</span> |
| AR Engine DEPTH | 真机能力检测返回 false | <span>已验证</span> |
| ARViewContext.init | 尚未在 0.2.0 真机验证 | 待测 |
| ARFace.getGeometry | 尚未在 0.2.0 真机验证 | 待测 |
| ARFace.getBlendShapes | 尚未在 0.2.0 真机验证 | 待测 |
| dToF 原始数据访问 | 不因硬件或 FACE 支持而推断开放 | 不作假设 |
| AR 模拟器 | AR Engine 需真机验证 | 不适用 |

## 首次真机能力检测（0.1.0）

用户在 MatePad Pro 13.2（2023）上运行 FaceLab 0.1.0，截图显示：
- FACE TRACKING：SUPPORTED
- DEPTH ESTIMATION：NOT SUPPORTED

这证明 `arViewController.isARTypeSupported(ARENGINE_FEATURE_TYPE_FACE)` 在该设备上返回 true。

## 0.2.0 待验证项目

| 日期 | 系统 | AR 会话初始化 | 人脸数 | Mesh | Pose | BlendShapes | 备注 |
|---|---|---|---:|---|---|---|---|
| 待测 | 7.0.0.111 SP8 | 待测 | — | 待测 | 待测 | 待测 | 首次运行 0.2.0 |

## 官方支持列表核对

华为公开的 AR Engine 支持机型列表列出 MatePad Pro 13.2 英寸 2025 全系列，但未列出 2023 款。因此本项目将真机能力检测结果作为设备证据，同时对 ARViewContext 初始化及各子接口分别做运行时验证。

## 来源

- [AR Engine 支持机型列表](https://developer.huawei.com/consumer/cn/forum/topic/0208215774177333398)
- [AR Engine 人脸跟踪（ArkTS）](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arengine-face/)


## 0.3.0 真机姿态轴向验证（用户反馈）

用户在 MatePad Pro 13.2（2023）上运行 FaceLab 0.3.0，并通过实际头部动作确认：
- X：上下点头（Pitch）。
- Y：左右转头（Yaw）。
- Z：左右歪头（Roll）。

以上记录为用户实机动作观察；各轴正负方向仍以应用实时读数为准。0.3.1 新增的中性网格比较与连续性提示仍待重新构建和真机验收。


## 0.3.1 中性网格形变真机验证（2026-11-08）

用户在 MatePad Pro 13.2（2023）上反馈：
- 0.3.1 已成功运行，整体感觉没有明显问题。
- 先采集中性表情基准，再进行眨眼、张嘴动作时，相对中性网格的 RMS / MAX 数值会发生变化。

该结果确认中性基准形变指标能够响应至少这两类表情动作。尚未据此推断数值与表情强度之间存在经过标定的线性关系；指标仍为原始网格坐标单位，且可能受到头部姿态变化影响。


## 0.4.0 Face Visualizer 验收状态（2026-11-08）

- 代码层面：新增 Canvas 三维投影观察器、网格模式、手势交互、姿态驱动与可选三角面标签读取。
- 设备层面：待在 MatePad Pro 13.2（2023）上使用 SDK 26.0.0 构建并验证。
- 必测：网格可见、四种模式、单指旋转、双指缩放、真实头姿驱动、表情形变、停止后清理。
- 三角面标签：华为公开 API 提供 getTriangleLabels() 及标签值定义，但目标设备运行时是否支持仍待真机验证。

## 0.4.1 首帧崩溃修复验收状态（2026-11-08）

- 崩溃证据：MatePad JSCrash 指向 FaceMeshViewer.ets:158:40，异常为 TypedArray internal slot 缺失。
- 代码修复：AR 回调层保留类型化缓冲区；Index.ets 在组件边界将顶点、三角索引、边、形变和标签全部转换为普通 number[]。
- 自动检查：GitHub Actions 0.4.1 stability contracts 已通过。
- DevEco Studio / SDK 26.0.0 编译：待用户本地验证。
- MatePad 首帧绘制、四种模式、手势、头姿驱动、表情形变、停止与重启：待真机验收。
- TriangleLabels：可选能力，未返回标签时其余三种显示模式仍应正常工作。

## 0.4.2 性能与几何可视化回归（2026-11-08）

用户在 MatePad Pro 13.2（2023）上运行 0.4.1 后反馈：实时追踪明显卡顿；线框、实体、形变热力三种模式视觉差异不明显，部位分区最清晰。

0.4.2 针对该反馈进行代码级优化：
- 网格发布目标由 200 ms（5 Hz）调整为 100 ms（10 Hz），并增加异步帧处理互斥。
- 复用普通数组，避免每帧重新分配五组 JS 数组；静态拓扑仅在拓扑版本变化时转换。
- 缓存投影点和区域面分组；复用实体光照、形变热力的绘制分桶。
- 线框改为 edge-only；实体使用法线光照分级；形变热力使用独立高对比度色阶。
- Canvas 显示绘制调用频率和 JS 提交耗时，辅助真机定位瓶颈。

以上是代码实现状态，不代表设备已达到 10 FPS 或已消除卡顿。DevEco 编译和真机性能、四种模式差异仍待验收。


## 0.4.3 真机回归（2026-11-08）
- 用户反馈：0.4.2 实体模型已可见，但整体仍比较卡，热力图没有内容。
- 0.4.3 将网格发布节流调整为约 5 Hz；未采集中性基准时显示相邻帧动态位移，采集后显示中性基准形变。
- DevEco 构建、热力图两种基准状态及性能变化待真机验证。

## 0.5.0 GPU Native Renderer 验收计划（2026-11-08）

| 项目 | 预期 | 状态 |
|---|---|---|
| HarmonyOS NDK CMake 构建 | arm64-v8a 原生库成功编译并打包 | 待 DevEco |
| XComponent Surface | 创建 / 尺寸变化 / 销毁回调正常 | 待真机 |
| EGL / GLES 3.2 | Surface 上出现原生 GPU 绘制内容 | 待真机 |
| 线框 | 只绘制边，模型可随头姿更新 | 待真机 |
| 实体 | 面法线光照有明显明暗层次 | 待真机 |
| 形变热力 | 顶点位移映射蓝—青—绿—黄—红 | 待真机 |
| 单指旋转 | 手指拖动改变观察视角 | 待真机 |
| 双指缩放 | 捏合改变模型缩放 | 待真机 |
| 重置视角 | 恢复初始视角与缩放 | 待真机 |
| 性能 | 与 0.4.3 对比卡顿、功耗、温升和可见帧率 | 待测量 |
| 生命周期 | 停止追踪 / 离开页面后释放相机、线程、EGL 和 NativeWindow | 待真机 |

目标设备：MatePad Pro 13.2（2023），HarmonyOS 7.0.0.111 SP8，Compile SDK 26.0.0。


## 0.5.0 / 0.5.1 user feedback (2026-11-08)

- User successfully deployed FaceLab 0.5.0 on MatePad Pro 13.2 (2023).
- User reports wireframe, shaded surface and deformation heatmap are now very smooth.
- User reports region mode remains laggy; code inspection confirms it was still using the old ArkUI Canvas viewer and copying typed mesh buffers into ordinary number[] arrays.
- FaceLab 0.5.1 moves semantic region rendering to the native GPU path using per-triangle AR Engine labels and a flat per-triangle region attribute.
- 0.5.1 DevEco build, label rendering, and performance comparison are pending. Do not infer the region lag is solved until the user confirms on device.


## 0.5.1 final deployment and freeze (2026-11-08)

- PR #11 was retargeted to `main`, source-contract CI passed, and the complete FaceLab history from 0.1 through 0.5.1 was merged.
- User confirmed FaceLab 0.5.1 successfully built and deployed on MatePad Pro 13.2 (2023), HarmonyOS 7.0.0.111 SP8, SDK 26.0.0.
- Stable release version: 0.5.1 / versionCode 10009.
- Main merge commit: `beceadcb871543d943c28cd482c1ded8680fd71c`.
- A release snapshot branch `release/facelab-0.5.1` pins this release.
- No numerical per-mode FPS, thermal or battery benchmark was supplied; do not infer a 30 FPS guarantee or quantify performance from the successful deployment alone.


## 0.5.1 GPU region mode acceptance (2026-11-08)
- User confirms the 0.5.1 region mode no longer lags on MatePad Pro 13.2 (2023).
- All four visualization modes are considered smooth in the user's target-device test.
- This is a qualitative user acceptance result; no numerical FPS / thermal / battery benchmark is recorded.

## 0.5.2 Gesture Interaction Lab — pending device acceptance
| Test | Expected result | Status |
|---|---|---|
| SDK 26 ArkTS + NDK build | HAP packages successfully | Pending DevEco |
| 30 Hz pose / BlendShapes sampling | Gesture inputs update without increasing mesh publication cadence | Pending device |
| Left unilateral wink | Focus moves to previous option once per closure | Pending device |
| Right unilateral wink | Focus moves to next option once per closure | Pending device |
| Natural bilateral blink | No unilateral-wink action | Pending device |
| Sustained jaw open | Confirms selected option after 350 ms threshold hold | Pending device |
| Gesture input disabled | No demo action is triggered | Pending device |
| Touch / M-Pencil fallback | Direct option selection still works | Pending device |
| GPU rendering regression | All four visualization modes remain smooth | Pending device |
| Stop / restart | Camera, gesture latches and counters reset cleanly | Pending device |
