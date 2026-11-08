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
