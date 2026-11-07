# AlgoLab 技术架构（Technical Architecture）

- 版本：技术方案 v0.1
- 平台：HarmonyOS NEXT 原生应用
- 语言/UI：ArkTS + ArkUI
- 应用模型：Stage
- 工程状态：尚未生成并验证真实 DevEco Studio 工程；SDK/API Level 待确定

## 1. 架构目标

1. 将数据结构语义放在独立、可测试的领域层，而不是写在 UI 手势回调中。
2. 画布位置和逻辑指针关系完全分离。
3. 代码生成必须确定性、可复现，并能映射回结构元素。
4. 核心功能离线可用，不依赖 AI。
5. UI 适配平板窗口和触控输入，但不依赖未验证的设备专有能力。
6. 先用最小原生工程验证 ArkTS/ArkUI 能力，再逐步实现完整产品。

## 2. 分层结构

```text
ArkUI Presentation
  ├── WorkspacePage
  ├── StructureCanvas
  ├── NodeView / PointerView
  ├── ContextToolbar
  ├── MemoryInspector
  └── CodeDrawer
          |
          v
Application Layer
  ├── WorkspaceController
  ├── CommandDispatcher
  ├── UndoRedoManager
  └── ViewState
          |
          v
Domain Layer（纯逻辑，尽量不依赖 UI）
  ├── LinkedListDocument
  ├── GraphValidator
  ├── ReachabilityAnalyzer
  ├── CycleDetector
  ├── StructureCommands
  ├── MemoryModelPresenter
  └── CppCodeGenerator
          |
          v
Infrastructure
  ├── LocalDocumentRepository
  ├── Serialization / Migration
  └── Optional AI Service Adapter（后续版本）
```

实际目录以 DevEco Studio 当前版本生成的 Stage 模板为基础。上述是逻辑模块划分，不是未经 SDK 验证的固定工程目录。

## 3. 核心领域模型

建议使用稳定 ID，而不是把画布坐标当作节点身份。

示意类型（概念模型，需按目标 ArkTS 版本调整）：

```ts
type NodeId = string;

interface Point {
  x: number;
  y: number;
}

interface ListNode {
  id: NodeId;
  value: number;
  nextId: NodeId | null;
  position: Point;
}

interface LinkedListDocument {
  schemaVersion: number;
  documentId: string;
  title: string;
  headId: NodeId | null;
  nodes: ListNode[];
  viewport: {
    offsetX: number;
    offsetY: number;
    scale: number;
  };
}
```

### 语义约束

- `id` 是应用内部稳定身份，不是 C++ 指针或真实内存地址。
- `value` 是首版整数数据。
- `nextId` 是逻辑引用；null 表示 nullptr。
- `position` 只影响画布布局，不影响数据结构语义。
- `headId` 是根引用，与任何节点的 next 字段独立。
- `viewport` 是视图状态，不参与代码生成。

### 图形与逻辑分离

移动节点只更新 `position`。
建立连接只更新源节点的 `nextId`。
改变 head 只更新 `headId`。
这三种操作必须是不同领域命令，并有独立测试。

## 4. 领域分析

实现纯逻辑函数：

- `validateDocument(document)`：检查 ID 唯一、head 引用存在、nextId 引用存在、值合法。
- `getReachableNodes(document)`：从 head 沿 nextId 计算可达节点。
- `detectCycle(document)`：识别从 head 可达路径中的环。
- `getUnreachableNodes(document)`：找出没有从 head 到达的节点。
- `getIncomingReferences(document, nodeId)`：检查哪些节点的 nextId 指向目标节点。
- `classifyStructure(document)`：区分空结构、正常链、环、不可达节点、共享后继等状态。

由于每个节点只有一个 next 字段，从 head 出发的遍历可以使用 visited 集合检测环。多个前驱可以指向同一节点，但应标记为共享后继，而不是误称为普通线性链表。

领域层不得依赖画布组件或 ArkUI 事件对象。

## 5. 命令与撤销/重做

建议把用户操作建模为显式命令：
- CreateNode
- DeleteNode
- SetNodeValue
- MoveNode
- SetNext
- ClearNext
- SetHead
- ClearHead

每条命令需要：
- 输入参数；
- 执行前验证；
- 应用后的新文档状态；
- 可逆信息或前一状态快照；
- 面向用户的结果摘要。

v0.1 可以先使用不可变文档快照实现可靠撤销/重做；性能足够后再考虑更细粒度命令历史。不要直接在多个 UI 组件中分别修改同一份节点数组。

## 6. C++ 代码生成

### 基本原则

- 代码生成器只读取经过验证的领域模型。
- 生成结果必须可重复：相同文档产生相同代码。
- 变量名由稳定节点顺序生成（例如 n1、n2），不直接使用用户输入作为标识符。
- 生成代码行与节点 ID / 字段关系之间的映射，用于代码高亮。
- 用户输入的节点值必须按整数解析和校验，不能拼接任意代码。
- 生成代码与任意 C++ 代码解析是两个不同问题。

### 建议生成步骤

1. 输出必要的头文件与 Node 结构定义。
2. 为文档中的节点生成分配语句。
3. 生成每个非空 nextId 对应的指针赋值。
4. 生成 head 指针设置。
5. 生成适用于当前结构状态的示例遍历/检查代码。
6. 生成与分配节点一一对应的释放代码，避免遗漏或重复释放。

### 环与安全遍历

普通的 `while (p != nullptr)` 遍历遇到环会无限循环。若文档包含环，代码生成器必须：
- 明确标记结构包含环；
- 不生成会无限运行的普通遍历；
- 生成带访问集合的安全演示，或只生成结构构造代码并明确提示需要环检测；
- 对每个动态分配节点只释放一次。

v0.1 可以先支持结构构造代码和清晰的状态提示；完整可运行程序模板需经过真实 C++ 编译器验证后才能标记为可运行。

### 双向映射边界

v0.1 支持：
- 结构模型 -> C++ 代码；
- 代码行 -> 对应节点/连接的高亮映射。

v0.1 不支持任意 C++ 源码 -> 结构模型。未来如果支持有限代码编辑，也必须限制在明确的生成代码子集，并在解析失败时保留原模型、显示差异，不静默覆盖用户内容。

## 7. 内存视图

内存视图展示的是教学模型，不是真实进程内存检查器。

- 展示稳定的对象标识，例如 N1、N2；
- 字段展示 data 与 next；
- next 显示目标对象标识或 nullptr；
- 可视化箭头与结构画布保持一致；
- 若采用类似十六进制的模拟地址，必须清楚标注为模拟地址，并且不声称等于 C++ 运行时地址。

只有连接真实 C++ 运行时调试器/执行环境后，才可能展示真实地址；这不属于 v0.1。

## 8. ArkTS / ArkUI 实现策略

- 使用 Stage 模型原生应用结构。
- 主画布采用适合目标 SDK 的原生绘制能力；Canvas/自定义绘制方案需在 SDK 确定后验证。
- 节点命中测试、连接端口吸附和画布坐标变换放在独立交互控制层。
- 手势目标包括点击、拖动、双指平移/缩放；手写笔精细交互作为增强项，不能成为没有验证的硬依赖。
- 窗口尺寸变化时调整工具栏与抽屉布局；不要自行实现系统分屏。
- 视图状态和领域文档状态分离，避免缩放/平移触发代码重新生成。
- 本地存储 API 以目标 HarmonyOS SDK 的官方文档为准；需要版本化序列化和迁移策略。

具体组件、手势 API、文件 API、分享 API 和设备能力必须按最终 DevEco Studio、SDK、API Level 重新核对。本文不把未经实际编译的 API 签名当作已验证事实。

## 9. 本地数据与隐私

- v0.1 不要求登录和云同步。
- 文档默认保存在本地应用沙箱。
- 导出文件由用户主动触发。
- 不在仓库、源码或客户端中硬编码 API Key。
- 若未来增加 AI 服务，客户端调用受控后端；后端密钥放在服务端安全配置中。
- AI 输入只包含用户主动请求解释所需的结构摘要；不默认上传全部实验记录。

## 10. AI 集成边界

AI 是可选解释层，不是结构事实来源。

后续可支持：
- “解释当前节点的 next 为什么是 nullptr”；
- “用更简单的话解释这行生成代码”；
- “我想把这个节点插到中间，应该怎么操作？”；
- 自由手绘草图识别，但必须让用户确认识别结果后才能写入正式模型。

不得让模型直接修改领域文档而不经过验证器和用户确认。AI 输出的代码不能绕过确定性生成器成为当前结构的权威代码。

## 11. 测试策略

### 领域层单元测试

- 空文档与单节点；
- 正常链；
- 断链和不可达节点；
- 自环与多节点环；
- 共享后继；
- 删除被引用节点；
- 设置/清除 head；
- 节点移动不改变逻辑结构；
- 撤销/重做往返一致。

### 代码生成测试

- 相同文档生成稳定输出；
- 不同结构生成正确的 next 赋值；
- nullptr 正确表达；
- 环结构不会生成无限普通遍历；
- 每个动态分配对象只释放一次；
- 代码映射指向正确节点和连接；
- 非法模型不生成代码。

### UI / 设备测试

- 节点拖动与画布平移不冲突；
- 连接预览、吸附、取消和替换；
- 手指和手写笔操作；
- 横屏、竖屏和窄窗口；
- 撤销/重做；
- 保存恢复；
- MatePad Pro 13.2 真机验证；
- 目标 API Level 的构建与权限核对。

## 12. 工程目录建议

先用 DevEco Studio 创建当前 SDK 推荐的 Stage 模型工程，再将业务模块放入对应源码目录。建议逻辑模块：

```text
apps/algolab/
  app/                 # Stage 工程入口与配置（由 IDE 生成）
  src/
    domain/            # 文档模型、验证、遍历、环检测
    application/       # 命令、状态协调、撤销重做
    presentation/      # ArkUI 页面、画布、节点、抽屉
    codegen/           # 确定性 C++ 生成与代码映射
    persistence/       # 本地存储与版本迁移
    tests/             # 单元测试和生成器测试
```

此结构是目标组织方式，不是可直接编译的完整工程模板。

## 13. 构建与发布风险

当前用户电脑尚未安装 DevEco Studio，仓库也尚无真实 HarmonyOS 工程。下一步需要确定可用的 DevEco Studio / HarmonyOS SDK 版本，并生成官方模板。

GitHub Actions 或云端 Linux 构建是否可行，取决于华为 SDK 获取方式、许可条款、工具链兼容性、签名和构建环境。必须先做最小构建验证，不能仅凭存在命令行工具就宣称云端构建已打通。

v0.1 的“运行 C++”也需要单独决策：可先导出源码供外部编译；云端 C++ 沙箱涉及网络、隔离、成本和隐私，未经验证不纳入首期承诺。


## 14. 官方接口参考

以下官方文档用于实现阶段核对接口；最终以项目实际安装的 HarmonyOS SDK 类型定义和编译结果为准：

- [Canvas 自定义绘制（ArkTS）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-drawing-customization-on-canvas/)
- [PanGesture API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-gestures-pangesture/)
- [ArkTS 单一手势事件指导](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/arkts-gesture-events-single-gesture/)

本轮页面使用 Canvas 绘制指针连接线，使用 PanGesture 拖动节点。官方文档说明 Canvas 可绘制基础图形与文本，PanGesture 提供开始、更新、结束和取消等回调；但这不等于本仓库源码已通过目标 SDK 编译或真机验证。
