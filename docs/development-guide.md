# HarmonyOS 原生开发指南

## 当前工程与已验证环境

- 项目目录：仓库内的 `apps/algolab`；由 DevEco Studio 官方 Stage 模板生成，并接入原有三个 ArkTS 源文件。
- 实际构建环境：Windows、DevEco Studio 26.0.0.865、HarmonyOS SDK 26.0.0.105（API 26）。
- 用户已反馈本机构建成功，并已在 Huawei MatePad Pro 13.2（HarmonyOS 7.0.0）启动应用。
- 2026-11-08 真机截图验证了节点创建、next 连接、data 编辑与 C++ 代码同步；截图同时暴露 NodeCard 的 next 标签未随结构变化刷新。本分支已改用独立原始类型 `@Prop`，但新改动仍需重新构建和真机复验。
- 工程的设备类型在官方模板基础上加入 tablet。

## 在 Windows 本机继续开发

1. 在 DevEco Studio 中打开 `apps/algolab`，确认 SDK Manager 已安装 HarmonyOS API 26；按本机情况配置 SDK。
2. 等待工程同步及依赖安装，再构建 entry 模块。具体产物和诊断以本机 IDE 输出为准。
3. 使用 IDE 的官方签名与设备调试流程生成可安装的调试包；证书、Profile、私钥、密码和本机配置不要提交到 GitHub。
4. 在平板验证启动、触控、拖动、连接、撤销、代码显示与横竖屏布局，记录结果和问题。

## 工程来源与文件

工程元数据由官方 DevEco Studio 模板生成；`entry/src/main/module.json5` 在模板设备类型中补充了 `tablet`。三个原型源码文件保留了仓库原有内容。本机 `local.properties`、构建产物、IDE 状态、依赖缓存和签名材料不纳入仓库。

## 可选：Linux 自托管 Runner

仓库保留历史 Bash 生成脚本、[手动 HAP 工作流](../.github/workflows/algolab-harmonyos-hap.yml)和 [Runner 接入指南](cloud-build-runner.md)，用于后续实验；它们不是打开或构建现有 Windows 工程的前提，且尚未在 API 26 环境实测。无需购买云主机。

每次构建和设备验证应记录 IDE/SDK 版本、构建结果、产物路径及签名状态、设备和测试结果。不要将未执行的测试标记为通过。
