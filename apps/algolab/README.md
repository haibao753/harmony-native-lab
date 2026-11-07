# AlgoLab

HarmonyOS NEXT 原生交互式数据结构实验工具。

## 产品定位

让学习者先通过触控和手写笔创造、操作数据结构，再逐步理解节点、指针、内存引用与 C++ 代码之间的关系。

AlgoLab 不替代华为笔记、系统浏览器、课程平台或通用 AI 助手。它专注于结构操作、状态观察和确定性代码生成。

## v0.1

首个实验对象：单链表。

核心闭环：
1. 在画布上创建节点并连接 next 指针；
2. 观察 head 可达性、断链、环和不可达节点；
3. 展开教学内存视图（后续实现）；
4. 查看与结构模型同步的 C++ 代码；
5. 通过试错和撤销理解结构变化。

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

## 工程状态

已开始编写 ArkTS / ArkUI 源码，但尚未补齐 DevEco Studio 生成的 Stage 工程配置，尚未完成 SDK 编译或 MatePad 真机验证。当前连接操作采用选择起点与目标节点的方式；直接拖拽连接端口、内存视图和 C++ 真正编译执行均在后续阶段。
