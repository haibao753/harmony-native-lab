> **代码面板工具栏收纳与中文注释开关（2026-11-08）**：新增 `showAnnotations` 状态和“注释：开/关”按钮。关闭时不再渲染每行右侧注释列，也不保留空白占位，因此源码 Scroll 可利用释放出的横向空间；重新开启后恢复原有 12vp 注释。将原先始终占据一行的 A−/A+/小/中/大控件收纳到“字号 当前值”入口下，默认仅显示紧凑工具栏，点击后展开字号调节行；小/中/大仍为 11/14/17vp，A−/A+ 仍限制在 10–22vp。保留当前 14vp 默认代码字号、整行 Span 高亮、视口宽度左对齐机制、拖动与缩放面板。新增 GitHub Actions 静态检查。**尚未在 DevEco Studio 或 MatePad 真机验证本轮 ArkUI 交互和隐藏注释后的实际布局。**

> **代码区左对齐根因修复（2026-11-08）**：再次根据 MatePad 真机截图定位，之前的问题不是 TextAlign，而是短代码行的 Text 宽度小于水平 Scroll 的可视宽度；滚动容器会将较窄的内容放在视口中间，因此 `#include` 等无缩进行也看起来居中。本轮在每行代码 Scroll 上通过 `onAreaChange` 读取真实视口宽度，并将源码 Text 宽度设为 `max(整行测量宽度, 视口宽度)`；短行因此铺满视口并从左边缘开始，长行仍保留自身所需宽度并可横向滚动。新增短行视口宽度回归测试及 CI 静态检查。保留默认 14vp 中字号、11/14/17vp 预设和 12vp 中文注释字号。**本轮尚未在 DevEco Studio 编译或 MatePad 真机验证，需重点确认 `onAreaChange` 回调宽度、短行首列位置、缩进列位置及长行横向滚动。**

> **C++ 代码行排版重构与注释字号调整（2026-11-08）**：此前将每个语法 Token 作为独立 Text 放入 Row，即使设置 Start 对齐，真机仍出现整行居中。现改为每一源代码行只使用一个 Text 段落，内部通过多个 Span 保留 Token 颜色；Text 设 TextAlign.Start，并按整行字符数与当前等宽字号估算 intrinsic width，放在水平 Scroll 中，使短行从首列起始、长行可横向滚动。代码默认字号由 11vp 调整为 14vp（中），小/中/大仍为 11/14/17vp，A−/A+ 范围仍为 10–22vp；右侧中文注释独立提高至 12vp，最多显示三行，注释栏宽度增加至 198vp，代码行高度适配注释。增加行宽测量测试及 CI 静态检查。**仍需 DevEco Studio / MatePad 真机重新构建验证 Span 排版、前导空格列位置、长行横向滚动和注释可读性。**

> **真机缩进问题二次修复（2026-11-08）**：用户截图表明不仅带缩进的语句，连本应从第 1 列开始的 `#include`、`struct` 也整体居中，说明上一版 NBSP 空白保留并未解决布局根因。当前修复在每个源码 token Text 上显式设置 `TextAlign.Start`，在 token Row 上显式设置 `FlexAlign.Start`，同时保留 Row 的内容自然宽度，避免固定宽度破坏横向滚动。字号控制保持不变。**此修复尚未在 MatePad 真机验证，必须重新构建观察无缩进行是否从代码列最左侧开始、四空格缩进是否显示为四列。**

> **代码缩进与字号控制（2026-11-08）**：针对真机反馈，C++ token 展示层新增空白格式化：普通空格转换为不换行空格、Tab 转换为四个等宽空白，避免 ArkUI 将分段 Text 中的前导空格折叠；词法 Token 与生成的 C++ 原文保持不变。新增仅作用于源码 token 的字号状态，默认 11vp 保留为小字体版本，A−/A+ 支持 10–22vp 连续调节，并提供小/中/大 11/14/17vp 快捷档；代码行高度随字号变化，行号与右侧注释保持原有小字号。新增空白显示单元测试与 CI 源码检查。**尚未在 DevEco Studio / MatePad 对本轮修改进行编译或真机验证。**

> **ArkTS 编译错误修复（2026-11-08）**：根据 MatePad/DevEco Studio 编译日志修复 C++ 词法分析器中的单引号字符判断，原代码误写成未闭合字符串，造成后续一系列级联解析错误；同时为 CppToken、TokenizeResult 和 CppDisplayLine 对象显式声明类型，符合 ArkTS 的 arkts-no-untyped-obj-literals 约束。补充 C++ 数字分隔符测试。**修复已提交 GitHub，但仍需用户重新运行 DevEco Studio 的 Assemble Hap，确认 ArkTS 编译通过；当前不能宣称真机验证通过。**

> **C++ 语法着色与逐行教学注释（2026-11-08）**：浮动代码工作区现增加原生 ArkTS 词法高亮，区分关键字、类型、标准库标识符、函数、字符串/头文件、数字、字面量、注释、预处理指令、运算符与标点；代码区增加行号。C++ 生成器同时为结构体、字段、动态分配、next 指针赋值、head、遍历、安全环检测、输出和 delete 释放生成逐行解释。解释以右侧彩色注释轨道显示，不混入实际 C++ 源码，复制/编译时不会污染代码。**本轮源码尚未通过 DevEco ArkTS 编译或 MatePad 真机验证；需要重点检查多行滚动、较窄窗口下的注释显示和词法颜色。**

> **浮动代码工作区更新（2026-11-08）**：根据 MatePad Pro 13.2 真机反馈，将原先固定在页面底部、仅 210vp 高的 C++ 代码区域改为独立浮动面板。面板提供拖动手柄、右下角缩放手柄、独立滚动区域、收起入口，以及基于根容器尺寸的边界约束；位置和尺寸保存在页面状态中，收起后再次打开会保留本次会话中的几何状态。**当前仅完成 GitHub 源码更新与静态检查设计，尚未在 DevEco Studio 编译或真机复验；尤其需要确认 ArkUI 手势、Stack 定位和 onAreaChange 在目标 SDK 上正常工作。**

# AlgoLab 首轮实现记录
> **真机反馈更新（2026-11-08）**：用户已在 MatePad Pro 13.2（HarmonyOS 7.0.0）成功构建并启动 AlgoLab。截图确认三个节点的创建、next 连接、节点 data 修改以及 C++ 代码同步；同时暴露出 NodeCard 的 next 文本仍显示 `nullptr` 的 UI 状态刷新问题。本分支将节点 ID、值、nextId 和坐标改为独立的原始类型 `@Prop`，避免把普通 interface 对象整体传入子组件，并新增模型/代码一致性回归测试。**本次源码变更尚未经过新的 DevEco 构建或真机复验。**


> 历史说明：本文下方部分“尚未生成工程/构建”的内容记录的是早期阶段；当前状态以 2026-11-08 真机反馈更新为准。用户已在 MatePad Pro 13.2（HarmonyOS 7.0.0）启动应用，当前 UI 修复仍待重新构建和复验。详见 [开发指南](development-guide.md)。


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
- 本分支本次 UI 状态刷新修复的 DevEco 编译与 MatePad 真机复验；
- MatePad Pro 13.2 真机手势、布局和性能验证；
- 直接拖拽连接端口；
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

## 早期阶段验证声明

以下说明仅记录最初通过 GitHub 写入源码、尚未接入本机 DevEco Studio 的阶段。2026-11-08 用户已完成首轮真机启动与交互验证；当前分支新增的 UI 状态刷新修复仍需再次构建和真机复验。


## 云端工具链接入准备（本轮）

- 新增 `scripts/build-algolab-hap.sh`：先生成 API 26 Stage 工程，再调用官方 DevEco CLI 构建 entry HAP，并收集实际生成的 `.hap` 文件。
- 新增 `.github/workflows/algolab-harmonyos-hap.yml`：手动触发，要求带 `harmonyos-api-26` 标签的 Linux self-hosted runner；先验证 glibc、内存、可用磁盘和 SDK 路径，再构建并上传 HAP。
- 新增 `docs/cloud-build-runner.md`：记录云端 VM 规格、华为工具包获取与完整性校验、GitHub Runner 注册和安全要求。
- **尚未接通实际云端机器**：当前没有可供本次会话使用的云厂商账号或已注册 Runner，也没有可直接安装的华为 Command Line Tools 下载包。没有声称已经执行 HAP 构建。

## 2026-11-08：首轮真机反馈与修复

### 已由用户在 MatePad Pro 13.2 验证

1. 成功构建并启动应用（HarmonyOS 7.0.0）。
2. 创建 N1、N2、N3，并将 next 连接为 N1 → N2 → N3。
3. 修改 N3.data 为 30，生成的 C++ 代码同步变化。

### 截图发现的问题

- 连线和 C++ 代码已反映 N1 → N2 → N3，但节点卡片内的 next 标签仍显示 `nullptr`。
- 工具栏操作挤在同一行，平板横屏下视觉密度过高。

### 本次源码调整

- NodeCard 不再接收整个 `LinkedNode` 对象；改为接收 `nodeId`、`nodeValue`、`nextId`、`positionX`、`positionY` 等原始类型属性，降低 ForEach 子组件对普通对象嵌套字段更新的依赖。
- 将结构编辑操作与值编辑/历史/代码操作拆分为两行工具栏，减少单行横向拥挤。
- 增加回归测试：验证 setNext 生成的新文档保留正确的目标引用、旧文档不被修改，且 C++ 生成结果包含对应赋值语句。

### 验证边界

- 本次只完成 GitHub 源码更新和静态审阅；GitHub Actions 轻量工作流不执行 ArkTS 编译。
- 新代码需要用户在 DevEco Studio 重新构建，并在平板确认 next 标签、拖动、连接、撤销和代码同步。
