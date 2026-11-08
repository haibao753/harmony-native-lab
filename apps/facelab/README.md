# FaceLab

HarmonyOS 原生三维人脸与新型交互实验应用。

## 稳定基线：0.5.2 — Gesture Interaction Lab

当前开发版本：`0.8.0-alpha.1` — FaceLab Art 0.1 / FORM BEYOND（液态雕塑交互原型，待 MatePad 真机验收）。

- 线框、实体、形变热力和部位分区全部使用 OpenGL ES 3.0 原生 GPU 渲染。
- 使用 ArkTS XComponent SURFACE / EGL / NativeWindow；C++ 侧使用 VBO / EBO 绘制。
- Node-API 直接接收 AR 回调 TypedArray，GPU 模式不再转换为 ArkUI 普通数组。
- 原生线程目标约 30 Hz 重绘，AR Mesh 数据仍约 5 Hz 更新；实际帧率待 MatePad 实测。
- 部位分区通过 AR Engine 三角面标签为每个三角面分配颜色，使用 GPU 三角形绘制，不再进入 ArkUI Canvas。
- 0.5.1 四种 GPU 模式已在 MatePad Pro 13.2（2023）真机验证流畅，部位分区卡顿问题已解决。

## 0.7.0-alpha.1 — Split-Screen Camera Continuity Probe

- 显式声明主窗口支持 fullscreen / split / floating。
- 使用 API 20+ `windowStageLifecycleEvent` 记录前台/后台生命周期；使用主窗口 `windowEvent` 单独记录 ACTIVE / INACTIVE 焦点变化。
- 监听 `windowStatusDidChange` 与 `windowVisibilityChange`，显示窗口模式、可见性和焦点状态。
- AR 回调独立统计 `onFrameUpdate` 调用次数、估算回调率、最近帧间隔和最大间隔；不会将 5 Hz 网格发布频率误当成相机帧率。
- 分屏失焦后，统计 10 秒观察窗口内的 AR 回调数量；初步阈值为至少 50 次回调、估算回调率至少 5 Hz、持续检测到人脸且最近帧距今小于 1.5 秒。
- `INACTIVE` 不触发停止追踪；只有窗口进入 `HIDDEN` 才清理 AR 会话。后台相机断流遵循系统隐私策略，不尝试保活或绕过。
- 当前只提供可观测性与实验面板，不控制华为笔记，也不注入系统级触摸事件。
- 源码检查通过不代表相机在分屏失焦时持续工作；DevEco 构建和 MatePad 实测是结论依据。

## 0.5.2 — Gesture Interaction Lab

- 增加约 30 Hz 的轻量姿态 / BlendShapes 采样；Mesh / GPU 数据仍维持约 5 Hz 发布，不增加几何数据复制频率。
- 增加单眼眨眼边沿识别：闭合阈值 0.72、对侧眼开放阈值 0.35、单侧闭合持续 80 ms、650 ms 冷却；双眼同时闭合按自然眨眼处理，不触发单眼动作。
- 增加张嘴确认：权重达到 0.72 并保持 350 ms 才触发，回落到 0.40 后重新待命，并设置 1000 ms 冷却。
- 新增本地交互演示：左 / 右单眨切换 A/B/C 焦点，持续张嘴确认当前选项；触控和 M-Pencil 仍可直接选择。
- 手势输入默认关闭；需用户显式启用。演示不注入系统级输入、不控制其他应用。
- 所有识别在设备本地内存完成，不保存、不上传面部数据。

## 0.4.3 — Live Deformation Heatmap & Lite Rendering

- 修复 ArkUI `@Prop` 响应式代理与 JavaScript TypedArray 内部槽不兼容导致的首帧绘制崩溃。
- AR 回调层继续使用 TypedArray；UI 边界复用稳定的普通 `number[]`，避免每帧重新分配和重复代理包装。
- 网格回调节流回约 5 Hz，降低持续追踪时的 JS / Canvas 工作量。
- 未采集中性表情基准时，热力图显示相邻帧动态位移；采集基准后显示相对中性表情的形变。
- 将“采集基准”按钮移到三维观察器标题栏，避免用户找不到热力图前置操作。
- 保留 0.4.2 的缓存和四种差异化渲染模式；明确 Canvas 仍有性能上限。

## 0.4.0 — Face Visualizer

- 用户主动点击后申请相机权限。
- 初始化 AR Engine FACE 会话，使用前置摄像头。
- 通过 ARView 展示 AR 摄像头场景。
- 在 AR 帧回调中统计追踪到的人脸数量。
- 尝试读取人脸 Mesh 顶点 / 三角面、头部 Pose 矩阵和 BlendShapes。
- 展示左眼眨眼、右眼眨眼、张嘴三个表情参数。
- 读取 `ARPose.rotation` 四元数与 `ARPose.translation` 平移向量。
- 首次检测人脸时自动建立姿态基准；支持用户重新校准。
- 计算相对四元数并转换为标准 XYZ 欧拉角，显示相对平移。
- 对角度和平移做指数平滑，角度差使用最短环绕路径。
- 按 MatePad 实测结果标注 X=Pitch（上下点头）、Y=Yaw（左右转头）、Z=Roll（左右歪头）。
- 支持采集自然放松表情的中性 Mesh 基准，并显示当前网格相对中性基准的 RMS / MAX 形变。
- 保留相邻帧网格位移指标，独立观察短时网格变化。
- 根据连续姿态帧变化显示“较平稳 / 轻微变化 / 头部运动中”提示；该指标是本地启发式估计，不是 AR Engine 官方置信度。
- AR 资源在帧处理后释放；停止追踪时销毁 ARViewContext。
- UI 数据更新节流到约 5 Hz，避免高频刷新。
- 将 AR Engine 返回的 XYZ 顶点、三角面索引和可选三角面区域标签传递给独立观察器。
- 使用 ArkUI Canvas 将真实人脸 Mesh 做三维旋转投影，实时显示线框、半透明表面、形变热力图和面部区域分区。
- 通过 ARPose 相对姿态驱动网格旋转；支持单指拖动观察和双指捏合缩放。
- 对三角面边进行去重缓存，避免每帧重复构建拓扑；网格数据只保留在内存中。

## 目标设备

- Huawei MatePad Pro 13.2（2023 款）
- HarmonyOS 7.0.0.111 SP8
- DevEco Studio 26.0.0
- Compile SDK / HarmonyOS SDK API 26.0.0

## 已知真机结果

用户已在目标平板运行 0.1.0：
- AR Engine FACE：SUPPORTED
- AR Engine DEPTH：NOT SUPPORTED

这证明设备报告支持 FACE 特性，但不保证每个子接口（Geometry / BlendShapes / TriangleLabels）都能成功调用。0.4.0 继续显示已有诊断，并增加实时 Mesh 可视化；区域标签能力按运行时结果可选显示。

## 打开工程

在 DevEco Studio 中打开本目录：`apps/facelab`。同步依赖后构建 entry 模块，并部署到真实 MatePad。AR Engine 必须在真机上验证。

## 测试步骤

1. 安装 0.5.2。
2. 点击“开始追踪”。
3. 在系统弹窗中允许 FaceLab 使用摄像头。
4. 将脸放在前置摄像头画面内，观察人脸计数、Mesh、Pose 和 BlendShapes 指标。
5. 闭合左眼、闭合右眼、张开嘴巴，观察三个权重是否变化。
6. 左右转头、上下点头、左右歪头，观察 Yaw（Y）、Pitch（X）、Roll（Z）和相对平移。
7. 点击“校准当前姿态为零点”，确认角度与平移回到接近零值。
8. 先自然放松面部并正视屏幕，点击“采集 / 重新采集中性表情”。
9. 分别眨眼、张嘴，观察“相对中性网格形变”的 RMS / MAX 是否变化；保持静止并观察相邻帧网格变化。
10. 左右转头、点头、歪头，观察姿态连续性提示是否在静止时较平稳、运动时明显变化。
11. 点击“重置网格位移基准”，等待下一帧重新建立相邻帧比较基准。
12. 在 Face Visualizer 中切换线框、实体、形变热力、部位分区四种模式。
13. 对比四种模式：线框应只有青色边线；实体应为连续深蓝/青绿色明暗表面；形变热力应显示蓝—青—黄—红色阶且不叠加线框；部位分区应保留五官区域语义颜色。
14. 观察 Canvas 右上角的绘制调用频率与 JS 提交耗时，记录持续静止和转头时的数值。
15. 单指拖动网格，确认可旋转；双指捏合，确认可缩放；点击“重置视角”确认恢复默认观察角度。
16. 转头、点头、歪头，确认模型跟随实时姿态变化；张嘴和眨眼，确认几何网格同步变化。
17. 若“部位分区”显示设备未返回标签，记录该接口是否在当前设备不可用；其他模式应继续工作。
18. 点击“停止追踪”，确认相机预览关闭、网格清空；重新启动一次，检查是否有资源残留或卡顿加重。
19. 将 DevEco 编译日志、四模式截图、绘制频率与 JS 耗时反馈到项目对话中。

## 0.4.3 验证状态

0.4.3 将网格发布节流调整为约 5 Hz；热力图在未采集中性基准时回退为相邻帧动态位移，采集后切换为中性基准形变。以上仍需 DevEco 构建与 MatePad 真机验收。若仍明显卡顿，下一步不再继续堆叠 Canvas 微优化，而是评估 ArkGraphics3D GPU 原生网格渲染。

## 0.4.2 验证状态

0.4.2 已加入约 10 Hz 网格发布目标、异步回调互斥、稳定数组复用、静态拓扑缓存、投影点复用和差异化几何着色，并显示绘制调用频率与 JS 绘制提交耗时。这些属于代码级优化；实际流畅度必须在 MatePad 上测量。Canvas 仍是 CPU/Canvas 绘制方案，不承诺 60 FPS；若真机仍明显卡顿，下一阶段应评估 ArkGraphics3D / GPU 原生网格渲染。

## 0.4.1 验证状态

0.4.1 修复了 TypedArray / ArkUI `@Prop` 代理兼容问题；0.4.2 在此基础上复用普通数组，避免逐帧重新分配。历史 0.4.1 构建记录保留在实现日志中。

## 0.3.1 验证状态

**真机初步运行成功**

用户反馈：0.3.1 已在 MatePad Pro 13.2（2023）上成功运行，整体感觉没有明显问题。进一步确认：采集中性表情基准后，眨眼和张嘴动作会引起相对中性网格 RMS / MAX 数值变化，说明当前网格形变指标能够响应这些面部动作。

姿态轴向映射依据用户对 0.3.0 的真机动作反馈；正负方向仍按实时读数判断。中性网格形变指标可能同时受到表情和头部姿态影响；姿态连续性提示为启发式指标，不代表 AR Engine 官方追踪置信度。0.4.0 已加入 Canvas 网格观察器；该实现是三维投影绘制，不是独立 GPU 3D 场景。

## 隐私

所有数据只在设备内存中用于实时展示，不保存、不上传。FaceLab 不进行身份识别，不访问系统人脸认证数据，也不读取 dToF 原始传感器帧。


## 0.5.1 构建与验收

1. 在 DevEco Studio 打开 apps/facelab，使用 HarmonyOS SDK 26.0.0。
2. 确认 entry 模块已读取 externalNativeOptions，CMake 指向 entry/src/main/cpp/CMakeLists.txt。
3. 构建 arm64-v8a HAP；检查 native 库 libfacelab_native.so 已打包。
4. 安装到 MatePad Pro 13.2（2023），打开 FaceLab 并启动追踪。
5. 确认 XComponent Surface 创建成功，能显示原生 GPU 人脸网格。
6. 依次检查线框、实体和形变热力；与 0.4.3 对比可见帧率和卡顿。
7. 单指拖动旋转、双指捏合缩放，点击“重置视角”。
8. 切换部位分区，确认 GPU 着色正确区分非脸部、脸部、嘴唇、左右眼、左右眉、眉心和鼻子。
9. 停止追踪并离开页面，确认相机关闭、渲染线程退出、Surface 销毁后可重新进入。
10. 回填 DevEco 完整构建日志、设备截图和性能数据至 docs/facelab/DEVICE_MATRIX.md。

## SDK 26 XComponent API note

`XComponentController` and `XComponentType` are ArkTS global declarations in the ArkUI component API; do not import them as named exports from `@kit.ArkUI`. Use the ArkTS XComponent options object with `type: XComponentType.SURFACE` and `controller`. Do not confuse it with the API 19+ `NativeXComponentParameters` overload, which is a separate native-side lifecycle API.

## 0.5.1 技术边界

GPU 渲染线程目标约 30 Hz，AR Engine 网格发布仍约 5 Hz；两者不是同一帧率。0.5.1 已在 MatePad Pro 13.2（2023）成功构建并部署；尚无分模式 FPS、温升和功耗的量化记录，因此不承诺达到 30 FPS。所有面部数据仅在内存中处理，不保存、不上传。

## Native module packaging (SDK 26)

The native library's ArkTS declaration package follows the HarmonyOS project layout:
- `entry/src/main/cpp/types/libfacelab_native/index.d.ts`
- `entry/src/main/cpp/types/libfacelab_native/oh-package.json5`
- `entry/oh-package.json5` declares `libfacelab_native.so` as a local dependency.
- `entry/build-profile.json5` lists the module under `arkOptions.runtimeOnly.packages`.

After pulling this change, synchronize OHPM dependencies in DevEco Studio before rebuilding.


## 0.5.1 — GPU Region Rendering

- 将 AR Engine 的 Int32Array 三角面标签通过 Node-API 直接传入 C++。
- 在 C++ 原生渲染器中按三角面展开顶点，并为该三角形的三个顶点写入相同区域 ID，避免共享顶点跨区域造成颜色插值混合。
- GLSL ES 使用 flat region varying 选择与旧版一致的十种区域色板；通过 glDrawArrays(GL_TRIANGLES) 在 GPU 上绘制。
- 移除 Index.ets 中部位分区专用的普通 number[] 复制和 FaceMeshViewer Canvas 分支。
- 其他三种 GPU 模式保持原有索引绘制路径；所有面部数据仍只在本机内存处理。
- 0.5.1 已成功构建并部署到 MatePad Pro 13.2（2023）；用户确认部署成功。分模式帧率、温升与功耗尚无量化记录。


## 0.5.1 稳定版本冻结（2026-11-08）

- 状态：已合并至 `main`，PR #11。
- 正式版本：`0.5.1`（versionCode `10009`）。
- 发布提交：`beceadcb871543d943c28cd482c1ded8680fd71c`。
- 发布分支：`release/facelab-0.5.1`。
- 用户已确认 0.5.1 成功构建并部署到 MatePad Pro 13.2（2023）。
- 该版本作为稳定基线冻结；后续功能和性能改动应从新分支开始，不直接改写此发布快照。
- 当前没有分模式 FPS、温升或功耗的量化基准；不得将目标帧率写成实测结果。


## 0.5.2 手势交互验收

1. 在 DevEco Studio 使用 SDK 26.0.0 构建并安装 0.5.2。
2. 启动追踪并校准当前姿态为零点。
3. 确认 Gesture Interaction Lab 默认关闭；未启用时只显示姿态 / BlendShapes 数值，不触发演示动作。
4. 启用手势输入，依次尝试左眼单眨、右眼单眨，确认焦点在 A / B / C 之间切换。
5. 正常双眼眨眼，确认不会触发单眼切换。
6. 张嘴并保持至少约 350 ms，确认当前选项计数增加；短暂张嘴不应触发。
7. 关闭手势输入，确认手势不再改变焦点；使用触控 / M-Pencil 仍可直接选择选项。
8. 停止追踪并重新启动，确认手势状态、计数和检测器锁存状态正确重置。
9. 连续运行至少 5 分钟，观察 GPU 四模式是否仍然流畅，且高频手势采样没有引入明显卡顿。


## 0.6.0-alpha.1 — FacePen Prototype

- 新增 FacePen 本地手写画布，使用 ArkUI Canvas / CanvasRenderingContext2D。
- 只接受 `SourceTool.Pen` 手写笔输入；M-Pencil 是目标设备，但不按品牌限制其他手写笔；手指仍可用于页面滚动和调色。
- 墨黑、朱红、钴蓝、松绿、琥珀、紫藤六色可手动选择。
- 左眼单眨选择上一色，右眼单眨选择下一色；复用 0.5.2 已有的 wink 事件和冷却逻辑。
- 使用笔画事务：DOWN 时冻结颜色；书写中颜色指令只进入 pending；UP / CANCEL 结束后再应用待切换颜色。
- API 26 `StylusFrameBoost` 作为可选低延迟优化按需调用；不可用或返回失败时自动退回普通 Canvas 绘制。
- 人脸丢失时自动暂停面部颜色控制；手动调色和 M-Pencil 书写不依赖人脸追踪。
- FacePen 画布独立于 GPU 人脸 Surface，不修改现有 GPU 渲染路径或 AR 会话生命周期。
- 当前仅控制 FaceLab 自己的画布，不控制华为笔记或其他第三方应用。
- DevEco SDK 26 构建、M-Pencil 输入识别、压感映射、连续书写性能和眨眼误触率仍需 MatePad 真机验收。


## 0.8.0-alpha.1 — FaceLab Art 0.1 / FORM BEYOND

- 新增独立的全屏艺术体验：FORM BEYOND。
- 使用现有 XComponent / EGL / OpenGL ES 3.0 GPU 渲染链路，不改变原有四种人脸网格模式。
- 以程序化 UV 球面网格生成连续液态雕塑；面部动作驱动顶点形变。
- 左眼单眨使形体生长，右眼单眨形成侵蚀凹陷，张嘴确认触发形变脉冲。
- Roll（左右歪头）改变形变场的重力方向；Pitch / Yaw 控制观察角度。
- 新增 Chrome 风格的程序化反射着色与纯黑 Void 背景。
- 触控拖动和双指缩放保留为手动观察后备方式。
- FaceLab 仍只在本机内存处理面部数据；不保存、不上传、不控制第三方应用。
- 本版本是艺术原型；设备构建、帧率、误触率和持续运行表现仍需 MatePad 真机验收。
