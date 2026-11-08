# FaceLab

HarmonyOS 原生三维人脸与新型交互实验应用。当前版本首先验证目标设备是否支持 AR Engine 的人脸追踪与深度估计特性；通过能力检查后，再逐步接入人脸网格、头部姿态和微表情数据。

> **重要边界：** AR Engine 人脸追踪能力不等于直接读取前置 dToF 传感器原始数据。FaceLab 不尝试绕过系统安全通道，也不会读取人脸认证数据。

## 当前版本：0.1.0 — Capability Probe

- 查询 `ARENGINE_FEATURE_TYPE_FACE` 人脸追踪能力。
- 查询 `ARENGINE_FEATURE_TYPE_DEPTH` 深度估计能力。
- 分开显示检测结果，避免把深度估计误认为原始 dToF 数据访问。
- 检测失败时显示错误码和信息。
- 本阶段不启动相机预览、不采集或保存图像/生物特征数据。

## 目标设备

- Huawei MatePad Pro 13.2（2023 款）
- HarmonyOS 7.0.0.111 SP8
- DevEco Studio 26.0.0
- Compile SDK / HarmonyOS SDK API 26.0.0
- ArkTS + ArkUI + Stage 模型

**设备兼容性尚未验证。** 华为当前公开的 AR Engine 支持机型列表列出了 MatePad Pro 13.2 英寸 2025 全系列，但没有列出 2023 款。请以目标平板上 `arViewController.isARTypeSupported()` 的实际检测结果为准。

## 打开工程

在 DevEco Studio 中打开本目录：`apps/facelab`。等待依赖同步后，选择 entry 模块构建并部署到真实 MatePad。AR Engine 不支持模拟器，必须使用真实设备验证。

## 下一步路线

1. **0.1.0 能力探针：** FACE / DEPTH 支持情况。
2. **0.2.0 AR 会话：** 申请相机权限，创建 ARViewContext，启动前置相机人脸跟踪。
3. **0.3.0 面部数据：** 读取 ARFace 几何网格、姿态和 BlendShapes。
4. **0.4.0 三维可视化：** 绘制实时面部网格、关键部位与参数仪表盘。
5. **0.5.0 交互实验：** 头部姿态、眨眼、张嘴等动作映射为可配置的平板操作。

## 安全与隐私

- 相机权限只在真正启动 AR 会话时申请；0.1.0 仅进行能力查询。
- 默认不保存相机帧、人脸网格或面部动作数据。
- 不做人脸身份识别，不尝试访问系统人脸解锁数据。
- 不用于医疗诊断、生命安全或高风险身份验证场景。
