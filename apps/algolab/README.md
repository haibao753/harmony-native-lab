# AlgoLab

HarmonyOS NEXT 原生交互式数据结构实验工具。

## 产品定位

让学习者通过可视化实验、预测和逐步演示，理解数据结构的逻辑关系、内存引用与 C++ 实现。

AlgoLab 不替代华为笔记、系统浏览器、课程平台或通用 AI 助手。它专注于结构操作、状态观察和确定性代码生成。

## v1.2.0-alpha.2（教学工作台预览）

在 1.1 Memory Explorer 基础上，将产品重心从“结构编辑与信息检查”推进到“概念学习与算法过程理解”。

新增：
1. 链表学习路径：节点组成、head、next 指针、遍历、nullptr、环和可达性七个知识点；
2. 每个知识点包含概念说明、关键结论、常见误区和动手实验；
3. 遍历逐步演示：从当前画布结构生成只读步骤轨迹，展示 current、已访问节点、当前节点/指针边和对应 C++ 行；
4. 操作前预测：每一步先回答问题，再查看反馈与原因，之后进入下一步；
5. 教学、内存和 C++ 检查器按需切换，步骤高亮与 1.1 的画布/内存/代码映射共享同一状态。

演示只改变教学高亮和讲解，不修改链表文档，也不执行 C++ 程序。当前版本继续只聚焦单链表，不引入其他数据结构或自由笔迹功能。

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
- [链表课程与遍历轨迹引擎](entry/src/main/ets/domain/LinkedListLessonEngine.ets)
- [教学工作台组件](entry/src/main/ets/components/TeachingWorkbench.ets)
- [C++ 代码生成器](entry/src/main/ets/codegen/CppLinkedListGenerator.ets)
- [ArkUI 页面原型](entry/src/main/ets/pages/Index.ets)

## 实现记录

- [首轮实现记录与手动验收场景](../../docs/IMPLEMENTATION_LOG.md)
- [AlgoLab 1.2.0-alpha.2 教学工作台预览说明](../../docs/releases/v1.2.0-alpha.2.md)
- [AlgoLab 1.1.0 开发预览说明](../../docs/releases/v1.1.0.md)
- [AlgoLab 1.0.0 基线发布说明](../../docs/releases/v1.0.0.md)

## 目标平台

- 设备系统：HarmonyOS 7.0.0
- 对应 API：26.0.0（API 26）
- 工具链：HarmonyOS SDK / DevEco 26.0.0 Release

## 工程状态

本分支基于 `feat/algolab-1.1-memory-explorer`，新增教学工作台与单链表遍历轨迹。源码提交和测试用例已写入 GitHub；尚未在 DevEco Studio 26.0.0.865 / HarmonyOS SDK 26.0.0.105 重新编译，也尚未在 MatePad Pro 13.2 真机验收。GitHub 源码更新不代表 ArkTS 编译或 HAP 构建通过。
