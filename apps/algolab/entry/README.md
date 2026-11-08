# AlgoLab 原生源码入口

当前目录开始承载 ArkTS / ArkUI 原生源码，目标工程形态为 DevEco Studio Stage 模型应用。

## 当前源码

- `src/main/ets/domain/LinkedListModel.ets`：单链表文档模型、节点操作、可达性与环分析；`createMemorySnapshot` 从同一权威模型生成只读教学内存记录（对象标识、data、next、head、可达性、环入口、入引用数）。
- `src/main/ets/codegen/CppLinkedListGenerator.ets`：从结构模型确定性生成 C++ 构造/遍历/释放代码，并为关键语句生成逐行教学注释和代码行到节点/连接的映射。
- `src/main/ets/codegen/CppSyntaxHighlighter.ets`：原生 ArkTS C++ 词法着色，将关键字、类型、函数、字符串、数字、注释、预处理指令和运算符拆分为彩色 Token。
- `src/main/ets/interaction/InputRouter.ets`：将 ArkUI SourceTool 输入源映射为 finger / pen / other。
- `src/main/ets/interaction/CoordinateMapper.ets`：画布坐标逆变换、缩放锚点和缩放范围约束。
- `src/main/ets/ink/InkStrokeModel.ets`：与链表模型完全独立的笔迹文档、笔划和点数据，提供不可变更新、追加和清除。
- `src/main/ets/components/InkLayer.ets`：使用 ArkUI Canvas 绘制独立笔迹，不参与命中测试。
- `src/main/ets/pages/Index.ets`：ArkUI 工作台页面，包含节点创建/拖动、通过选择起点/目标建立 next、断开连接、设置 head、删除节点、撤销/重做，以及 1.2 Alpha 1 的 M-Pencil 输入路由、笔迹历史和双指画布手势。页面采用 Soft Precision 视觉语言：暖灰白背景、石墨文字、陶土橙强调与低对比哑光表面；链表画布作为主工作区，内存检查器和 C++ 检查器按需停靠在右侧，不再以浮窗遮挡画布。C++ 源码采用语法高亮和行号，每行可点击定位节点或高亮 next 连接；逐行中文注释显示在源码下方，使用 12vp 字号并可隐藏。C++ 源码默认 14vp，支持 A−/A+ 连续调整（10–22vp）以及小/中/大预设（11/14/17vp）。每一行源码使用单个 Text 段落与多个彩色 Span；通过 onAreaChange 读取代码 Scroll 的实际视口宽度，并将 Text 宽度设为视口宽度与整行测量宽度的较大值，确保短行从最左侧开始、长行仍可横向滚动；保留缩进，不修改实际生成源码。字号入口默认紧凑，点击后才展开调节项。页面另提供教学内存视图，展示 head、data、next、可达性、环入口和共享后继，并与画布选中状态同步。

## 重要状态说明

仓库 `apps/algolab` 包含由 DevEco Studio 官方模板生成的 Stage 工程；`module.json5` 补充了 tablet 设备类型。用户已在 Windows DevEco Studio 26.0.0.865 / HarmonyOS SDK 26.0.0.105 构建成功，并在 MatePad Pro 13.2（HarmonyOS 7.0.0）运行应用。2026-11-08 真机截图确认节点创建、next 连接、data 编辑和 C++ 同步；当前开发分支进一步修复了节点卡片 next 标签刷新问题，仍待重新构建和真机复验。

## 1.2 Alpha 1 双模输入边界

- 使用 `TouchEvent.sourceTool` 区分 `SourceTool.Pen` 与 `SourceTool.Finger`；手指节点拖动只响应 Finger。
- M-Pencil 笔迹进入独立 `InkDocument`，不写入 `LinkedListDocument`；笔迹撤销/重做与图结构历史完全分离。
- 笔迹点通过当前画布 scale/offset 逆变换到图空间，因此随画布平移和缩放。
- 双指 PanGesture 与 PinchGesture 在父级优先识别；节点卡片保留单指拖动。
- 本 Alpha 尚未接入 Pen Kit HandwriteComponent、自定义波轮菜单、图形识别和笔迹语义绑定；这些功能需要在当前输入基础上分阶段实现。

## 首轮交互边界

- 节点移动只改画布坐标，不改变 next 指针。
- 连接采用“选中起点 → 点击连接 next → 选择目标节点”的可靠交互；后续真机验证后再升级为直接拖拽连接端口。
- C++ 检查器只读，代码由结构模型确定性生成；1.1 增加代码行到节点/连接的单向定位，不支持任意编辑后反向解析。
- 当前没有内置 C++ 编译执行器，也没有 AI 手绘识别。


## 生成官方 Stage 工程

在 DevEco Studio 中直接打开仓库的 `apps/algolab`，详见[本机开发指南](../../../docs/development-guide.md)。Linux CLI 脚本是可选的历史路线，尚未在 API 26 环境中实测。
