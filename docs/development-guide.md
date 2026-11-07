# HarmonyOS 原生开发指南

## 1. 环境准备

1. 安装 DevEco Studio。
2. 通过 SDK Manager 安装与目标设备兼容的 HarmonyOS SDK、工具链和模拟器组件。
3. 使用 DevEco Studio 创建 Stage 模型应用工程。
4. 连接 MatePad Pro 13.2 或启动兼容的模拟器，开启开发者选项及 USB 调试（如采用真机调试）。
5. 首次构建前，记录以下版本信息。

| 项目 | 记录 |
|---|---|
| DevEco Studio | 26.0.0 Release（建议与 SDK 配套） |
| HarmonyOS SDK / API Level | HarmonyOS 26.0.0 Release / API 26 |

| 设备型号 | Huawei MatePad Pro 13.2 |
| 设备系统版本 | HarmonyOS 7.0.0（API 26.0.0） |
| 构建时间与结果 | 待首次构建后填写 |

## 2. 创建首个工程

在 DevEco Studio 中创建一个原生 Stage 模型应用。模板名称、向导选项会随 IDE 版本变化，选择当前 SDK 推荐的 ArkTS / ArkUI 工程模板即可。

将 IDE 生成的工程配置、模块配置、资源目录和源码整体提交到仓库。不要手工猜测或复制其他 API 级别的 hvigor、oh-package 或 module 配置。

## 3. 推荐实现顺序

1. 工程能在模拟器或真机启动。
2. 建立页面导航、主题和基础布局。
3. 建立应用状态与数据模型。
4. 实现本地存储和导入导出。
5. 接入设备能力（相机、传感器、文件等）时逐项验证权限和 API 兼容性。
6. 最后接入远程 AI 服务；密钥不得硬编码进仓库或客户端。

## 4. 验证要求

每个功能至少记录：
- 使用的 SDK / API Level；
- 目标设备与系统版本；
- 构建是否成功；
- 真机或模拟器测试结果；
- 权限、性能、兼容性与已知问题。

未经真实构建与设备验证，不标记为“已完成”或“可运行”。

## 5. Git 工作流

- `main`：保持可审阅的稳定状态。
- `feat/<topic>`：功能开发。
- `fix/<topic>`：问题修复。
- 提交信息使用简洁前缀，例如 `feat:`、`fix:`、`docs:`、`chore:`。
- 大功能通过 PR 合并，并在 PR 描述中附测试证据。


## 6. 云端命令行构建（无需安装 DevEco Studio 图形界面）

华为官方支持使用 HarmonyOS Command Line Tools + Hvigor 在 Linux、Windows 和 macOS 上构建 HAP，也明确将该方式用于 CI 流水线。命令行工具包内含 HarmonyOS SDK。官方 Linux 流水线指南建议使用 32GB 及以上内存、100GB 及以上磁盘；实际云端环境还需核对系统库和工具链兼容性。

建议流程：

1. 目标设备已确认运行 HarmonyOS 7.0.0；华为官方版本表对应 API 26.0.0。
2. 选择 HarmonyOS 26.0.0 Release SDK，以及配套的 DevEco Studio / Command Line Tools 26.0.0 Release。官方 DevEco Studio 26.0.0.865 发布说明列出了配套 SDK、Hvigor、ohpm 和 Node.js 版本。
3. 可使用官方 DevEco CLI 按 API 26 创建 Stage 工程（例如 `devecocli create --project-path ./AlgoLab --app-name AlgoLab --bundle-name com.haibao.algolab --api-level 26`），也可用匹配版本的官方 Stage 模板。不要手写猜测 `hvigor`、`module.json5` 或签名配置。
4. 获取官方 Command Line Tools，按华为文档配置其自带的 Node.js、hvigorw、ohpm 和 hdc。命令行工具内含匹配的 HarmonyOS SDK。
5. 在 Linux CI 环境按官方流水线文档安装系统依赖并执行与该工具版本匹配的 Hvigor 构建任务。具体命令以 26.0.0 工具包内的模板与帮助信息为准。
6. 若要安装到真机，还需按官方流程准备调试签名文件；证书、Profile、私钥和密码不得提交到 GitHub 仓库。

参考：
- [华为官方：搭建命令行构建流水线](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-command-line-building-app/)
- [华为官方：Hvigor 命令行工具](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-hvigor-commandline/)

当前仓库尚未生成完整 Stage 工程，因此暂不添加会失败的 GitHub Actions 构建工作流。设备系统与 API 对应关系已确认，下一步应使用官方 26.0.0 CLI / 模板生成工程外壳，再加入 CI 构建和产物归档。


## 7. 已确认的 AlgoLab 目标版本

- 目标设备系统：HarmonyOS 7.0.0。
- 对应 API：26.0.0（API 26）。
- 开发套件：HarmonyOS SDK 26.0.0 Release。
- 推荐工具配套：DevEco Studio 26.0.0 Release 与同版本 Command Line Tools。
- 官方发布说明示例版本：DevEco Studio / Command Line Tools 26.0.0.865。

版本依据：
- [华为官方：API 版本与设备系统对应表](https://developer.huawei.com/consumer/en/doc/harmonyos-releases/sdk-version-percentage/)
- [华为官方：升级适配至 API 26.0.0](https://developer.huawei.com/consumer/en/doc/harmonyos-releases/upgrade-adaptation)
- [华为官方：DevEco Studio 26.0.0 Release 说明](https://developer.huawei.com/consumer/cn/doc/doccenter-release-notes/deveco-studio-new-features-2600/)
- [华为官方：DevEco CLI 创建与构建命令](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-deveco-cli-options/)

注意：API 版本对应关系已经确认，但工程模板、具体 API 签名与 HAP 构建仍需用匹配的 26.0.0 工具链实际验证。


## 8. 官方 CLI 工程生成与源码接入

仓库新增 `scripts/bootstrap-algolab-stage.sh`。该脚本不伪造工程配置，而是调用已经安装并配置 API 26 的华为官方 DevEco CLI：

```bash
bash scripts/bootstrap-algolab-stage.sh
cd dist/AlgoLab-Stage
devecocli build --modules entry --build-mode debug
```

脚本固定 API 26、包名 `com.haibao.algolab`，先调用 `devecocli create` 生成官方 Empty Ability Stage 工程，再检查官方模板生成的关键文件，最后覆盖 AlgoLab 的三个 ArkTS 源码文件。若 CLI 不存在、模板文件不符合预期或输出目录已存在，脚本会停止，不会静默覆盖。

DevEco CLI 官方命令文档：
- [创建 HarmonyOS 应用工程](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-deveco-cli-options/)
- [命令行构建 HAP / APP](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-command-line-building-app/)

CLI 的安装前提是配套的 DevEco Studio 26.0.0 或 Command Line Tools 26.0.0 及以上；官方 Command Line Tools 下载需从华为下载中心获取，并按官方流程校验完整性。CLI npm 包说明可参考 [@deveco/deveco-cli](https://www.npmjs.com/package/@deveco/deveco-cli)。

## 9. 云端构建资源要求

华为 Linux 流水线文档要求 64 位 Linux、GLIBC 2.28 或更高、至少 8 GB 内存（推荐 16 GB）及 100 GB 以上磁盘。不能假定普通 GitHub-hosted runner 满足这些条件。当前先提供可复现的工程生成脚本；只有在云端 runner 资源与官方工具包来源都确认后，才启用自动 HAP 构建，避免提交一个注定失败的 CI 工作流。
