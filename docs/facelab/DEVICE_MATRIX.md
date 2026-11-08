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

用户在 MatePad Pro 13.2（2023）运行 0.4.3 后反馈：
- 形变热力图已经出现。
- 整体运行仍然明显卡顿。

这确认了热力数据通路可用，但 5 Hz 降低 ArkTS / Canvas 负载并未解决整体卡顿。此后不再将 Canvas 微优化作为主路线。

## 0.5.0 GPU Renderer 验收（待真机）

| 项目 | 目标 / 实现 | 状态 |
|---|---|---|
| 渲染容器 | ArkTS XComponent SURFACE | 待 DevEco 构建与真机 |
| 原生窗口 | SurfaceId → OHNativeWindow | 待真机 |
| 图形上下文 | EGL + OpenGL ES 3.2 | 待真机 |
| 动态顶点 | VBO + glBufferSubData | 源码已实现，待真机 |
| 静态拓扑 | EBO，按 topologyRevision 更新 | 源码已实现，待真机 |
| 热力着色 | 逐顶点 deformation attribute + fragment shader | 源码已实现，待真机 |
| 区域着色 | 三角标签聚合至顶点 attribute | 源码已实现，待真机 |
| 渲染循环 | 原生线程，目标约 30 FPS | 源码已实现，待测 |
| AR 数据更新 | 约 5 Hz | 继承 0.4.3，待测 |
| Surface 生命周期 | create / resize / destroy | 源码已实现，待真机 |
| 性能 / 稳定性 | CPU、GPU、端到端延迟、连续运行 | 待测 |

目标设备仍为 MatePad Pro 13.2（2023）、HarmonyOS 7.0.0.111 SP8、SDK 26.0.0。源码支持和 API 文档可用不代表目标设备已经通过运行验收。


### 0.5.0 性能诊断字段（源码已加入，待设备测量）

- Render FPS：原生渲染线程每秒完成的绘制次数。
- AR mesh update Hz：原生层收到新网格快照的频率。
- NAPI copy ms：TypedArray 复制到 native snapshot 的耗时。
- GL submission CPU ms：CPU 侧提交 OpenGL 绘制命令的耗时，不等于 GPU 执行耗时。
- Vertex / triangle count：当前网格规模。

这些字段在 FaceLab 观察器下方显示。需在 MatePad 上记录空闲、稳定追踪、快速转头、停止重启等场景的数据。
