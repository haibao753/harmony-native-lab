# AlgoLab 原生源码入口

当前目录开始承载 ArkTS / ArkUI 原生源码，目标工程形态为 DevEco Studio Stage 模型应用。

## 当前源码

- `src/main/ets/domain/LinkedListModel.ets`：单链表文档模型、节点操作、可达性与环分析。
- `src/main/ets/codegen/CppLinkedListGenerator.ets`：从结构模型确定性生成 C++ 构造/遍历/释放代码，并保留代码行映射。
- `src/main/ets/pages/Index.ets`：首个 ArkUI 工作台页面原型，包含节点创建、节点拖动、通过选择起点/目标建立 next、断开连接、设置 head、删除节点、取消连接、撤销/重做和代码面板。

## 重要状态说明

这些文件是首轮原生源码实现，不等同于完整 DevEco Studio 工程。仓库尚未包含由特定 DevEco Studio / HarmonyOS SDK 版本生成的 `hvigor`、`oh-package`、`module.json5` 等工程配置。用户已安装 DevEco Studio，目标平板系统为 HarmonyOS 7.0.0；本机 IDE 版本和 API 26 SDK 安装情况仍待核验，不能声称源码已构建或已在 MatePad 真机运行。

下一步应先用目标 SDK 的官方 Stage 模板补齐工程外壳，再编译并修正任何 ArkTS 版本差异。Canvas、PanGesture 和 ArkUI 组件属性均须以实际 SDK 类型定义为准。

## 首轮交互边界

- 节点移动只改画布坐标，不改变 next 指针。
- 连接采用“选中起点 → 点击连接 next → 选择目标节点”的可靠交互；后续真机验证后再升级为直接拖拽连接端口。
- 首轮代码面板只读，代码由结构模型确定性生成。
- 当前没有内置 C++ 编译执行器，也没有 AI 手绘识别。


## 生成官方 Stage 工程

优先使用 Windows 本机的 DevEco Studio 官方向导创建工程并接入这三个源码文件，详见[本机开发指南](../../../docs/development-guide.md)。Linux CLI 脚本属于可选路线，尚未在 API 26 环境中实测。
