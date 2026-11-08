# AlgoLab 原生源码入口

当前目录开始承载 ArkTS / ArkUI 原生源码，目标工程形态为 DevEco Studio Stage 模型应用。

## 当前源码

- `src/main/ets/domain/LinkedListModel.ets`：单链表文档模型、节点操作、可达性与环分析。
- `src/main/ets/codegen/CppLinkedListGenerator.ets`：从结构模型确定性生成 C++ 构造/遍历/释放代码，并为关键语句生成逐行教学注释。
- `src/main/ets/codegen/CppSyntaxHighlighter.ets`：原生 ArkTS C++ 词法着色，将关键字、类型、函数、字符串、数字、注释、预处理指令和运算符拆分为彩色 Token。
- `src/main/ets/pages/Index.ets`：ArkUI 工作台页面，包含节点创建/拖动、通过选择起点/目标建立 next、断开连接、设置 head、删除节点、撤销/重做，以及可拖动、可缩放、可滚动的浮动 C++ 代码工作区；代码采用 One Dark 风格语法着色，并在每行右侧显示不同颜色的概念、指针、内存、安全性和控制流讲解；C++ 源码默认使用 14vp 中字体，支持 A−/A+ 连续调整（10–22vp）以及小/中/大预设（11/14/17vp）；右侧中文逐行注释独立使用 12vp 字号。每一行源码使用单个 Text 段落与多个彩色 Span，按整行计算内容宽度并从首列左对齐，保留缩进和横向滚动，不修改实际生成源码。

## 重要状态说明

仓库 `apps/algolab` 包含由 DevEco Studio 官方模板生成的 Stage 工程；`module.json5` 补充了 tablet 设备类型。用户已在 Windows DevEco Studio 26.0.0.865 / HarmonyOS SDK 26.0.0.105 构建成功，并在 MatePad Pro 13.2（HarmonyOS 7.0.0）运行应用。2026-11-08 真机截图确认节点创建、next 连接、data 编辑和 C++ 同步；当前开发分支进一步修复了节点卡片 next 标签刷新问题，仍待重新构建和真机复验。

## 首轮交互边界

- 节点移动只改画布坐标，不改变 next 指针。
- 连接采用“选中起点 → 点击连接 next → 选择目标节点”的可靠交互；后续真机验证后再升级为直接拖拽连接端口。
- 首轮代码面板只读，代码由结构模型确定性生成。
- 当前没有内置 C++ 编译执行器，也没有 AI 手绘识别。


## 生成官方 Stage 工程

在 DevEco Studio 中直接打开仓库的 `apps/algolab`，详见[本机开发指南](../../../docs/development-guide.md)。Linux CLI 脚本是可选的历史路线，尚未在 API 26 环境中实测。
