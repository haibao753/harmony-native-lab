# Harmony Native Lab

面向 HarmonyOS NEXT（纯血鸿蒙）的原生应用实验室，用于沉淀应用需求、ArkTS / ArkUI 实现、交互实验、架构决策与验证记录。

> **开发原则：原生优先。** 使用 ArkTS、ArkUI、Stage 模型及 HarmonyOS SDK 提供的系统能力；不以 Android APK 套壳或 WebView 包装作为默认实现路线。

## 首个应用：AlgoLab

**AlgoLab 是一款让学习者通过创造和操作数据结构，逐步理解其内存表示与 C++ 实现的交互式实验工具。**

它不是综合课程平台、笔记软件、浏览器或通用 AI 聊天应用。华为笔记、系统浏览器和 HarmonyOS 多窗口等已有能力优先复用，不重复建设。

首个版本只聚焦单链表：用户在画布上创建节点、编辑 next 指针，观察结构状态，按需查看教学内存模型，并获得与结构模型确定性同步的 C++ 代码。

## 目标设备与开发环境

- 主要体验设备：Huawei MatePad Pro 13.2（2023 款；具体系统版本与 API 能力待实机确认）。
- IDE：DevEco Studio（用户当前尚未安装）。
- SDK：待选择与目标设备兼容的 HarmonyOS SDK。
- 语言与 UI：ArkTS + ArkUI。
- 应用模型：Stage 模型。

请基于当前 DevEco Studio 和 HarmonyOS SDK 创建官方 Stage 工程。不同版本的工程模板、构建配置和 API 签名可能不同，因此仓库不会伪造未经 SDK 验证的 hvigor 配置，也不会声称未执行的构建已经通过。

## 仓库结构

```text
harmony-native-lab/
├── README.md
├── .gitignore
├── docs/
│   ├── architecture.md
│   ├── development-guide.md
│   ├── PRODUCT_SPEC.md
│   ├── INTERACTION_DESIGN.md
│   └── TECHNICAL_ARCHITECTURE.md
├── apps/
│   └── algolab/
│       └── README.md
├── shared/
└── experiments/
```

## 产品与工程文档

- [AlgoLab 产品需求](docs/PRODUCT_SPEC.md)
- [AlgoLab 交互设计](docs/INTERACTION_DESIGN.md)
- [AlgoLab 技术架构](docs/TECHNICAL_ARCHITECTURE.md)
- [开发环境与工作流](docs/development-guide.md)
- [仓库通用架构约定](docs/architecture.md)
- [AlgoLab 应用入口](apps/algolab/README.md)

## 开发原则

1. 先把单链表的交互闭环做好，再扩展其他结构。
2. 图形位置与逻辑指针关系分离。
3. 结构到 C++ 的生成采用确定性规则；AI 不作为结构事实来源。
4. 核心编辑、分析、保存和代码预览离线可用。
5. 每个系统 API、构建结果和设备能力都必须通过目标 SDK / 真机验证。
6. 不在公开仓库中提交密钥、签名材料或个人数据。

## 当前状态

当前仓库处于**产品方案与技术设计阶段**。已建立 AlgoLab 的产品需求、交互设计和技术架构文档；尚未提交可运行的 HarmonyOS 原生工程，也没有已验证的 HAP 构建产物。云端构建能力仍需先用实际 SDK 和工具链做最小验证。
