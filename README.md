# Harmony Native Lab

面向 HarmonyOS NEXT（纯血鸿蒙）的原生应用实验室，用于沉淀应用需求、ArkTS / ArkUI 实现、交互实验、架构决策与验证记录。

> **开发原则：原生优先。** 使用 ArkTS、ArkUI、Stage 模型及 HarmonyOS SDK 提供的系统能力；不以 Android APK 套壳或 WebView 包装作为默认实现路线。

## 首个应用：AlgoLab

**AlgoLab 是一款让学习者通过创造和操作数据结构，逐步理解其内存表示与 C++ 实现的交互式实验工具。**

它不是综合课程平台、笔记软件、浏览器或通用 AI 聊天应用。华为笔记、系统浏览器和 HarmonyOS 多窗口等已有能力优先复用，不重复建设。

首个版本只聚焦单链表：用户在画布上创建节点、编辑 next 指针，观察结构状态，并获得与结构模型确定性同步的 C++ 代码。教学内存视图是后续功能，不代表当前原型已经实现。

## 目标设备与开发环境

- 主要体验设备：Huawei MatePad Pro 13.2（2023 款；系统版本已确认为 HarmonyOS 7.0.0，最终设备兼容性仍需 HAP 真机验证）。
- 主工作流：Windows 本机 DevEco Studio 26.0.0.865 + HarmonyOS SDK 26.0.0.105（API 26）；用户已在本机完成构建。
- SDK：HarmonyOS 26.0.0 Release（API 26），对应目标设备 HarmonyOS 7.0.0。
- 语言与 UI：ArkTS + ArkUI。
- 应用模型：Stage 模型。

已将 DevEco Studio 官方模板生成的 API 26 Stage 工程放在 `apps/algolab`，并接入现有 ArkTS 源码。打开工程与继续开发请看[本机开发指南](docs/development-guide.md)。

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
│   ├── TECHNICAL_ARCHITECTURE.md
│   └── IMPLEMENTATION_LOG.md
├── .github/
│   └── workflows/
│       └── algolab-bootstrap-check.yml
├── scripts/
│   ├── README.md
│   └── bootstrap-algolab-stage.sh
├── apps/
│   └── algolab/
│       ├── README.md
│       └── entry/src/main/ets/
│           ├── domain/
│           ├── codegen/
│           └── pages/
├── shared/
└── experiments/
```

## 产品与工程文档

- [AlgoLab 产品需求](docs/PRODUCT_SPEC.md)
- [AlgoLab 交互设计](docs/INTERACTION_DESIGN.md)
- [AlgoLab 技术架构](docs/TECHNICAL_ARCHITECTURE.md)
- [首轮实现记录与验收场景](docs/IMPLEMENTATION_LOG.md)
- [开发环境与工作流](docs/development-guide.md)
- [官方 Stage 工程生成脚本](scripts/README.md)
- [云端构建 Runner 接入指南（可选，暂缓）](docs/cloud-build-runner.md)
- [手动触发 HAP 构建工作流](.github/workflows/algolab-harmonyos-hap.yml)
- [GitHub Actions 轻量检查](.github/workflows/algolab-bootstrap-check.yml)
- [仓库通用架构约定](docs/architecture.md)
- [AlgoLab 应用入口](apps/algolab/README.md)

## 开发原则

1. 先把单链表的交互闭环做好，再扩展其他结构。
2. 图形位置与逻辑指针关系分离。
3. 结构到 C++ 的生成采用确定性规则；AI 不作为结构事实来源。
4. 核心编辑、分析和代码预览优先离线可用。
5. 每个系统 API、构建结果和设备能力都必须通过目标 SDK / 真机验证。
6. 不在公开仓库中提交密钥、签名材料或个人数据。

## 当前状态

用户已反馈在 Windows 本机使用 DevEco Studio 26.0.0.865 和 HarmonyOS SDK 26.0.0.105 构建成功，并已在 Huawei MatePad Pro 13.2（HarmonyOS 7.0.0）启动应用。2026-11-08 的真机截图确认了节点创建、next 连接、data 修改与 C++ 生成同步；同时发现节点卡片的 next 标签没有及时刷新。本分支已将节点字段改为独立的原始类型属性，并补充模型/代码一致性测试，仍需用户重新构建并在平板复验。当前连接交互仍采用选择起点、再选择目标的方式；直接拖拽连接端口、内存视图和 C++ 真正编译执行仍待实现。GitHub Actions 轻量检查不等同于 ArkTS 编译。
