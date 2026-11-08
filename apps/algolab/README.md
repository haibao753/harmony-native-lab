# AlgoLab

HarmonyOS NEXT 原生交互式数据结构实验工具。

## 产品定位

让学习者先通过触控和手写笔创造、操作数据结构，再逐步理解节点、指针、内存引用与 C++ 代码之间的关系。

AlgoLab 不替代华为笔记、系统浏览器、课程平台或通用 AI 助手。它专注于结构操作、状态观察和确定性代码生成。

## v1.2.0-alpha.1（AlgoLab 1.2 Alpha 1）

**HarmonyOS Native Interaction：Touch + M-Pencil Dual Mode**

本 Alpha 首先建立双模输入基础，不引入 Pen Kit HandwriteComponent 的独立长画布，避免与当前可平移、缩放的结构画布产生坐标和手势冲突。

已实现的源码能力：
1. 使用 ArkUI `TouchEvent.sourceTool` 区分 M-Pencil（`SourceTool.Pen`）和手指（`SourceTool.Finger`）。
2. M-Pencil 在结构画布上绘制独立笔迹；笔迹保存在 `InkDocument`，不修改 `LinkedListDocument`。
3. 手写笔迹拥有独立撤销、重做和清空历史，不与链表结构撤销/重做混用。
4. 手指保留节点选择和拖动；双指支持画布平移与捏合缩放。
5. 笔迹与结构画布共享坐标变换，平移/缩放时批注随画布移动。
6. 笔迹模型、输入来源分类和坐标变换均有独立单元测试。

### 当前边界

- 这是原生 ArkUI Pointer/Touch 事件适配，不代表 Pen Kit 高级工具栏、波轮菜单或手写识别已接入。
- 暂不支持笔迹与节点对象的语义绑定、图形识别转节点、压感曲线细分或橡皮擦套索。
- 需要在 MatePad Pro 13.2 上确认真实 M-Pencil 的 sourceTool 上报、掌托防误触、双指手势冲突、笔迹流畅度和缩放坐标。
- GitHub 静态检查不等于 DevEco ArkTS 编译或真机验收。

## v1.1.0（AlgoLab 1.1 开发预览）

首个稳定功能基线聚焦单链表交互与 C++ 代码学习。

已包含：
1. 在画布上创建、编辑、移动节点，并通过选择起点和目标建立/断开 `next` 指针；
2. 设置 `head`，识别可达节点、断链、环和不可达节点；
3. 撤销/重做结构操作；
4. 从结构模型确定性生成只读 C++ 示例；
5. C++ 语法高亮、行号、逐行中文教学注释，以及注释显示/隐藏；
6. 右侧停靠式 C++ 检查器，支持语法高亮、行号、逐行中文注释、注释开关和字号调节（默认 14vp；小/中/大 11/14/17vp）。
7. 教学内存视图：显示 head、节点 data/next、可达性、环入口和共享后继；点击记录可同步选中画布节点。
8. C++ 代码行与结构联动：点击节点创建、next 赋值或 head 赋值语句，定位对应节点；点击 next 赋值行会高亮对应连接。

### 视觉与工作空间

- 采用 Soft Precision 视觉语言：暖灰白底色、石墨文字、陶土橙强调、低对比哑光表面。
- 画布作为主工作区；内存检查器与 C++ 检查器按需停靠在右侧，不再覆盖画布。
- 内存和代码检查器互斥显示；代码行注释位于源码下方，保留 12vp 中文说明。

当前版本边界：
- 内存视图使用 N1、N2 等教学对象标识，不是真实物理地址或运行时地址。
- 尚未实现真正的 C++ 编译/执行、本地持久化和直接拖拽端口连线。
- 代码区左对齐、注释开关、紧凑字号工具栏和 Soft Precision 工作空间重构已同步到仓库；本轮 UI 修改仍需在 DevEco Studio 重新构建并完成 MatePad 回归验收。

## 产品与技术文档

- [产品需求](../../docs/PRODUCT_SPEC.md)
- [交互设计](../../docs/INTERACTION_DESIGN.md)
- [技术架构](../../docs/TECHNICAL_ARCHITECTURE.md)

## 原生源码

- [源码入口说明](entry/README.md)
- [单链表模型](entry/src/main/ets/domain/LinkedListModel.ets)
- [C++ 代码生成器](entry/src/main/ets/codegen/CppLinkedListGenerator.ets)
- [ArkUI 页面原型](entry/src/main/ets/pages/Index.ets)

## 实现记录

- [首轮实现记录与手动验收场景](../../docs/IMPLEMENTATION_LOG.md)
- [AlgoLab 1.2.0-alpha.1 开发说明](../../docs/releases/v1.2.0-alpha.1.md)
- [AlgoLab 1.1.0 开发预览说明](../../docs/releases/v1.1.0.md)
- [AlgoLab 1.0.0 基线发布说明](../../docs/releases/v1.0.0.md)

## 目标平台

- 设备系统：HarmonyOS 7.0.0
- 对应 API：26.0.0（API 26）
- 工具链：HarmonyOS SDK / DevEco 26.0.0 Release

## 工程状态

本目录包含 DevEco Studio 官方模板生成的 Stage 工程。用户已反馈在 Windows 的 DevEco Studio 26.0.0.865、HarmonyOS SDK 26.0.0.105 下构建成功，并已在 MatePad Pro 13.2（HarmonyOS 7.0.0）运行。真机截图确认节点创建、连接、值编辑和代码同步可用；但节点卡片的 next 标签刷新异常已在当前开发分支修复，需重新构建并复验。当前连接仍采用选择起点、再选择目标的方式；直接拖拽连接端口、本地持久化和 C++ 真正编译执行尚未实现。1.2 Alpha 1 的 M-Pencil 双模输入与双指画布手势已进入独立开发分支，尚待 DevEco 编译和真机验收。
