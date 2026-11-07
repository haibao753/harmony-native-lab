# AlgoLab 首轮实现记录

> 状态更新（2026-11-07）：本文下方保留早期实现与云端引导记录，其中“尚未生成工程/构建”的描述反映当时状态。现在 `apps/algolab` 已包含官方 DevEco Studio 模板生成的工程，Windows DevEco Studio 26.0.0.865 与 HarmonyOS SDK 26.0.0.105 已构建未签名 debug HAP；签名和真机测试仍待完成。详见 [开发指南](development-guide.md)。


## 当前分支

`feat/algolab-first-native-slice`

## 已写入源码

- `entry/src/main/ets/domain/LinkedListModel.ets`
  - 创建和复制文档；
  - 创建、移动、修改 next、设置 head、删除节点；
  - 从 head 计算可达节点；
  - 检测环、不可达节点和共享后继。
- `entry/src/main/ets/codegen/CppLinkedListGenerator.ets`
  - 生成 Node 定义、动态创建、next 赋值和 head 设置；
  - 生成带访问集合的遍历示例，避免环导致普通遍历无限循环；
  - 对所有创建的节点逐个释放；
  - 提供代码行到节点/连接的映射和结构警告。
- `entry/src/main/ets/pages/Index.ets`
  - ArkUI 工作台页面；
  - 创建节点、移动节点；
  - 选择起点后建立 next 连接，并可取消连接模式；
  - 删除节点时清除指向它的引用，并支持撤销；
  - 断开 next、设置 head；
  - 撤销和重做；
  - 展开 C++ 代码面板。

## 本轮新增的工程引导

- 新增 `scripts/bootstrap-algolab-stage.sh`：通过华为官方 DevEco CLI 创建 API 26 Empty Ability Stage 工程，再覆盖 AlgoLab 的领域模型、C++ 生成器与 ArkUI 页面。
- 新增 `scripts/README.md`：记录 CLI 前置条件、生成方式、构建命令与云端资源约束。
- 新增 `.github/workflows/algolab-bootstrap-check.yml`：在 GitHub Actions 中检查引导脚本 Bash 语法和源码输入文件是否存在；它不是 HarmonyOS SDK 编译。
- 已从 GitHub 重新读取并核对上述文件。
- **尚未执行脚本**：当前没有已配置 API 26 Command Line Tools 的可用构建运行器，因此没有声称 Stage 工程已生成或 HAP 已构建。

## 尚未完成

- 在具备官方 Command Line Tools 26.0.0 的运行器中执行 Stage 工程生成脚本；
- SDK/API Level 对应的 ArkTS 编译验证；
- SDK/API Level 确认及 ArkTS 编译；
- MatePad Pro 13.2 真机手势、布局和性能验证；
- 直接拖拽连接端口；
- 节点值编辑、删除节点的 UI；
- 内存视图；
- 本地持久化；
- 代码行与画布的双向定位；
- 真正的 C++ 编译执行。

## 首轮手动验收场景

1. 空画布创建 N1、N2、N3，默认整数值依次为 10、20、30。
2. 选择 N1，执行“连接 next”，再选择 N2；重复操作连接 N2 -> N3。
3. 展开代码，检查是否出现 N1/N2/N3 创建语句及对应 next 赋值。
4. 拖动 N2，确认箭头关系和生成代码不变。
5. 断开 N2 的 next，确认 N3 被标记为从 head 不可达。
6. 设置 N3 的 next 指向 N2，确认检测到环，并检查生成代码带有访问集合。
7. 撤销和重做上述操作，确认结构状态可恢复。

## 验证声明

本轮只完成了 GitHub 源码写入与静态审阅，没有 DevEco Studio / HarmonyOS SDK 构建环境，也没有 MatePad 真机测试。不能将当前源码描述为已构建、已安装或已运行。


## 云端工具链接入准备（本轮）

- 新增 `scripts/build-algolab-hap.sh`：先生成 API 26 Stage 工程，再调用官方 DevEco CLI 构建 entry HAP，并收集实际生成的 `.hap` 文件。
- 新增 `.github/workflows/algolab-harmonyos-hap.yml`：手动触发，要求带 `harmonyos-api-26` 标签的 Linux self-hosted runner；先验证 glibc、内存、可用磁盘和 SDK 路径，再构建并上传 HAP。
- 新增 `docs/cloud-build-runner.md`：记录云端 VM 规格、华为工具包获取与完整性校验、GitHub Runner 注册和安全要求。
- **尚未接通实际云端机器**：当前没有可供本次会话使用的云厂商账号或已注册 Runner，也没有可直接安装的华为 Command Line Tools 下载包。没有声称已经执行 HAP 构建。
