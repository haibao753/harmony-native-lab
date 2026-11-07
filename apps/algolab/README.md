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
3. 展开教学内存视图；
4. 查看与结构模型同步的 C++ 代码；
5. 通过试错和撤销理解结构变化。

## 文档

- [产品需求](../../docs/PRODUCT_SPEC.md)
- [交互设计](../../docs/INTERACTION_DESIGN.md)
- [技术架构](../../docs/TECHNICAL_ARCHITECTURE.md)

## 工程状态

当前为产品与技术方案阶段，尚未生成或验证可运行的 HarmonyOS Stage 工程。请先确定 DevEco Studio / HarmonyOS SDK / API Level，再基于官方模板建立工程。本文不代表已有 HAP 构建产物。
