# HarmonyOS 原生开发指南

## 1. 环境准备

1. 安装 DevEco Studio。
2. 通过 SDK Manager 安装与目标设备兼容的 HarmonyOS SDK、工具链和模拟器组件。
3. 使用 DevEco Studio 创建 Stage 模型应用工程。
4. 连接 MatePad Pro 13.2 或启动兼容的模拟器，开启开发者选项及 USB 调试（如采用真机调试）。
5. 首次构建前，记录以下版本信息。

| 项目 | 记录 |
|---|---|
| DevEco Studio | 待填写 |
| HarmonyOS SDK / API Level | 待填写 |
| 设备型号 | Huawei MatePad Pro 13.2 |
| 设备系统版本 | 待填写 |
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

华为官方支持使用 HarmonyOS Command Line Tools + Hvigor 在 Linux、Windows 和 macOS 上构建 HAP，也明确将该方式用于 CI 流水线。命令行工具包内含 HarmonyOS SDK；Linux 构建环境要求 64 位系统、GLIBC 2.28 或更高，官方建议内存至少 8GB、磁盘 100GB 及以上。

建议流程：

1. 先确认目标平板的 HarmonyOS 完整版本，并据此选择兼容的 Command Line Tools / SDK。
2. 获取官方 Command Line Tools，按华为文档配置 JDK、Node.js、hvigorw、ohpm 和 hdc。
3. 用 DevEco 官方 Stage 模板或匹配版本的模板生成完整工程配置；不要手写猜测 `hvigor`、`module.json5` 或签名配置。
4. 在 Linux CI 环境安装依赖后执行 `hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon`。
5. 若要安装到真机，还需按官方流程准备调试签名文件；证书、Profile、私钥和密码不得提交到 GitHub 仓库。

参考：
- [华为官方：搭建命令行构建流水线](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-command-line-building-app/)
- [华为官方：Hvigor 命令行工具](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-hvigor-commandline/)

当前仓库尚未生成完整 Stage 工程，因此暂不添加会失败的 GitHub Actions 构建工作流。待工程外壳与 SDK 版本确定后，再加入 CI 构建和产物归档。
