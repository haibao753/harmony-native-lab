# Harmony Native Lab

面向 HarmonyOS NEXT（纯血鸿蒙）的原生应用实验室。这里用于沉淀应用需求、ArkTS / ArkUI 实现、交互实验、架构决策与验证记录。

> **开发原则：原生优先。** 使用 ArkTS、ArkUI、Stage 模型及 HarmonyOS SDK 提供的系统能力；不以 Android APK 套壳或 WebView 包装作为默认实现路线。

## 目标设备与开发环境

- 主要体验设备：Huawei MatePad Pro 13.2（具体系统版本、设备 API 能力以实际设备为准）。
- IDE：DevEco Studio。
- SDK：与目标设备系统版本匹配的 HarmonyOS SDK。
- 语言与 UI：ArkTS + ArkUI。
- 应用模型：Stage 模型。

请先在 DevEco Studio 中创建对应 API 级别的 **Empty Ability / Stage 模型** 工程，再将生成的工程文件纳入本仓库。不同 DevEco Studio / SDK 版本生成的工程模板、构建配置和 API 签名可能不同，因此本仓库不会伪造未经 SDK 验证的 hvigor 配置或声称示例已编译通过。

## 仓库结构

```text
harmony-native-lab/
├── README.md
├── .gitignore
├── docs/
│   ├── architecture.md
│   └── development-guide.md
├── apps/
│   └── math-workspace/
│       └── README.md
├── shared/
│   └── README.md
└── experiments/
    └── README.md
```

## 当前规划

### 首个应用：Math Workspace（智能数学工作台）

围绕平板的大屏、触控与手写笔体验，探索：
- 数学公式输入、编辑与结构化表示；
- 公式与推导步骤的关联；
- 几何图形、函数图像与动态可视化；
- AI 辅助解释、推导检查与知识关联；
- 本地优先的数据管理与可控的云端 AI 接入。

以上是产品方向，不代表这些能力已经实现。

## 开发流程

1. 在 DevEco Studio 中创建 Stage 模型原生工程，并记录 DevEco Studio、SDK、API Level 与设备系统版本。
2. 先实现最小可运行页面，使用模拟器或真实设备验证。
3. 每次引入系统 Kit 或设备能力时，核对目标 API 级别、权限声明和设备兼容性。
4. 以小步提交维护代码；较大功能使用独立分支和 PR。
5. 记录构建结果、测试设备、已知限制和复现步骤。

## 文档

- [开发环境与工作流](docs/development-guide.md)
- [架构约定](docs/architecture.md)
- [Math Workspace 应用规划](apps/math-workspace/README.md)
- [共享模块约定](shared/README.md)
- [实验记录约定](experiments/README.md)

## 状态

当前仓库处于**初始化与方案阶段**。尚未提交可运行的 HarmonyOS 应用工程；首次真实构建必须由安装了匹配 HarmonyOS SDK 的 DevEco Studio 完成并验证。
