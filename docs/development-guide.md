# HarmonyOS 原生开发指南

## 目标与状态

- 开发电脑：Windows 11，用户已安装 DevEco Studio；安装版本和 SDK 组件仍需在本机核验。
- 目标工具链：DevEco Studio 26.0.0 Release 与 HarmonyOS SDK API 26；目标平板为 HarmonyOS 7.0.0。
- 技术栈：ArkTS、ArkUI、Stage 模型。
- 当前仓库只有源码原型，尚无由官方工具生成的完整 Stage 工程，也没有已验证的 HAP。现有 GitHub Actions 轻量检查不编译 ArkTS。

## 本机创建官方工程

1. 在 DevEco Studio 的 About 中核对版本，在 SDK Manager 确认安装 HarmonyOS SDK API 26；实际界面和选项以安装版本为准。
2. 使用 DevEco Studio 官方向导创建 ArkTS 的 Empty Ability Stage 应用。应用名可用 `AlgoLab`，包名使用 `com.haibao.algolab`；选择可用的 API 26 目标。不要手工补写或猜测工程元数据。
3. 记录生成目录和 IDE、SDK 的实际版本，先构建一次未修改的模板；保留原始生成的工程文件和构建日志。
4. 将仓库以下三个文件复制到生成工程的对应路径，仅替换模板页面，不覆盖任何工程元数据、配置或资源：

   - `apps/algolab/entry/src/main/ets/domain/LinkedListModel.ets` → `entry/src/main/ets/domain/LinkedListModel.ets`
   - `apps/algolab/entry/src/main/ets/codegen/CppLinkedListGenerator.ets` → `entry/src/main/ets/codegen/CppLinkedListGenerator.ets`
   - `apps/algolab/entry/src/main/ets/pages/Index.ets` → `entry/src/main/ets/pages/Index.ets`

   缺少 `domain` 和 `codegen` 目录时在源码目录下创建。保留模板原始页面的备份，并按官方 IDE 的实际路径检查。
5. 在 DevEco Studio 中构建 entry 模块，根据实际 SDK 编译诊断修正 ArkTS；记录编译日志、产物路径及签名状态。IDE 创建成功不代表源码编译通过。

## 真机验证

通过 DevEco Studio 的实际指引连接平板并配置调试签名；证书、Profile、私钥和密码不提交到 GitHub。只有构建成功且签名与设备条件满足时才安装 HAP，逐项验证触控、节点拖动、连接、撤销与布局。记录设备型号、系统、结果和未覆盖场景。

## 可选：Linux 自托管 Runner

仓库保留手动触发的 [HAP 工作流](../.github/workflows/algolab-harmonyos-hap.yml)和 [Runner 接入指南](cloud-build-runner.md)；它们是后续可选方案，本地开发不需要购买云主机或注册 Runner。现有 Bash 脚本及云构建路线尚未在 API 26 工具链上验证。

## 验证记录

每次记录实际 IDE/SDK 版本、构建命令或 IDE 操作、结果、HAP 路径和签名状态，以及真机测试结果。未经真实 SDK 构建或设备测试，不标记为相应步骤已通过。
