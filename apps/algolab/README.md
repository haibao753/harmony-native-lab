# AlgoLab

HarmonyOS NEXT 原生交互式数据结构实验工具。

## 产品定位

让学习者先通过触控和手写笔创造、操作数据结构，再逐步理解节点、指针、内存引用与 C++ 代码之间的关系。

AlgoLab 不替代华为笔记、系统浏览器、课程平台或通用 AI 助手。它专注于结构操作、状态观察和确定性代码生成。

## v1.0.0（AlgoLab 1.0）

首个稳定功能基线聚焦单链表交互与 C++ 代码学习。

已包含：
1. 在画布上创建、编辑、移动节点，并通过选择起点和目标建立/断开 `next` 指针；
2. 设置 `head`，识别可达节点、断链、环和不可达节点；
3. 撤销/重做结构操作；
4. 从结构模型确定性生成只读 C++ 示例；
5. C++ 语法高亮、行号、逐行中文教学注释，以及注释显示/隐藏；
6. 浮动代码面板，支持拖动、缩放、滚动和字号调节（默认 14vp；小/中/大 11/14/17vp）。

当前版本边界：
- 尚未实现真正的 C++ 编译/执行、内存视图、本地持久化和直接拖拽端口连线。
- 代码区左对齐、注释开关和紧凑字号工具栏的最新修改已同步到仓库；这些最新 UI 修改仍需在 DevEco Studio 重新构建并完成 MatePad 回归验收。

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

## 目标平台

- 设备系统：HarmonyOS 7.0.0
- 对应 API：26.0.0（API 26）
- 工具链：HarmonyOS SDK / DevEco 26.0.0 Release

## 工程状态

本目录包含 DevEco Studio 官方模板生成的 Stage 工程。用户已反馈在 Windows 的 DevEco Studio 26.0.0.865、HarmonyOS SDK 26.0.0.105 下构建成功，并已在 MatePad Pro 13.2（HarmonyOS 7.0.0）运行。真机截图确认节点创建、连接、值编辑和代码同步可用；但节点卡片的 next 标签刷新异常已在当前开发分支修复，需重新构建并复验。当前连接仍采用选择起点、再选择目标的方式；直接拖拽连接端口、内存视图、本地持久化和 C++ 真正编译执行尚未实现。
