# HarmonyOS 原生开发指南

## 1. 目标平台

- 主要设备：Huawei MatePad Pro 13.2（2023 款）。
- 设备系统：HarmonyOS 7.0.0（用户确认）。
- 对应开发 API：HarmonyOS 26.0.0 Release / API 26。
- 推荐工具链：Command Line Tools 26.0.0 Release。
- 技术栈：ArkTS + ArkUI + Stage 模型。

DevEco Studio 图形界面不是强制条件。本项目优先采用华为官方 Command Line Tools + DevEco CLI 生成工程和构建 HAP。

## 2. 工具链准备

1. 从[华为开发者下载中心](https://developer.huawei.com/consumer/cn/download/)获取 Command Line Tools 26.0.0 Release，并按官方流程校验下载完整性。
2. 按华为命令行构建指南配置工具包中的 SDK、Hvigor、ohpm、Node.js 和 HDC。
3. 安装满足 DevEco CLI 要求的 Node.js，然后安装 CLI：

```bash
npm install -g @deveco/deveco-cli@latest
devecocli help
```

4. 确认 CLI 可正常启动，并且已安装 API 26 对应 SDK。

官方参考：
- [DevEco CLI 命令说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-deveco-cli-options/)
- [DevEco CLI npm 包](https://www.npmjs.com/package/@deveco/deveco-cli)
- [HarmonyOS 命令行构建流水线](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-command-line-building-app/)

## 3. 生成官方 Stage 工程

在仓库根目录执行：

```bash
bash scripts/bootstrap-algolab-stage.sh
```

脚本固定 API 26 与包名 `com.haibao.algolab`，调用官方 `devecocli create` 的 Empty Ability 模板生成 Stage 工程，检查官方模板生成的关键配置文件，再覆盖 AlgoLab 的领域模型、C++ 代码生成器和 ArkUI 页面。

默认输出：`dist/AlgoLab-Stage`。如果 CLI 不存在、模板结构不符合预期或输出目录已存在，脚本会停止，不会手工伪造或静默覆盖工程元数据。

## 4. 构建 HAP

```bash
cd dist/AlgoLab-Stage
devecocli build --modules entry --build-mode debug
```

华为 CLI 文档说明，指定模块构建会生成 HAP / HSP / HAR；首次构建的实际产物路径以工具输出为准。此步骤需要真实安装的 API 26 工具链，不能仅靠 GitHub 文件编辑完成。

## 5. 云端构建资源要求

华为 Linux 流水线文档列出的环境要求：
- 64 位 Linux；
- GLIBC 2.28 或更高；
- 内存至少 8 GB，推荐 16 GB 及以上；
- 磁盘 100 GB 及以上；
- Command Line Tools 26.0.0 及以上建议使用 JDK 21。

因此不能假定普通 GitHub-hosted runner 一定满足要求。启用自动 HAP 构建前，必须确认 runner 的内存、磁盘、系统库，以及 Command Line Tools 的合法下载来源和完整性校验。当前仓库尚未配置自动构建工作流。

## 6. 真机安装与验证

1. 在平板开启开发者选项与 USB 调试。
2. 使用匹配版本的 HDC 检查设备连接。
3. 按华为官方流程准备调试签名；证书、Profile、私钥和密码不得提交到 GitHub。
4. 构建后通过 HDC 安装 HAP，并在 MatePad Pro 13.2 上逐项验证触控、拖动、布局和稳定性。

## 7. 验收记录要求

每次验证至少记录：
- HarmonyOS 系统版本与 API Level；
- Command Line Tools / DevEco CLI 版本；
- 构建命令与构建结果；
- HAP 产物路径与签名状态；
- 真机型号、系统版本和测试结果；
- 已知问题与未覆盖场景。

未经真实 SDK 构建和设备测试，不标记为“已完成”或“可运行”。
