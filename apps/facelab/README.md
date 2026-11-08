# FaceLab

HarmonyOS 原生三维人脸与新型交互实验应用。

## 当前版本：0.5.0 — OpenGL ES Native Face Renderer

- 线框、实体和形变热力迁移到 OpenGL ES 3.0 原生 GPU 渲染。
- 使用 ArkTS XComponent SURFACE / EGL / NativeWindow；C++ 侧使用 VBO / EBO 绘制。
- Node-API 直接接收 AR 回调 TypedArray，GPU 模式不再转换为 ArkUI 普通数组。
- 原生线程目标约 30 Hz 重绘，AR Mesh 数据仍约 5 Hz 更新；实际帧率待 MatePad 实测。
- 保留单指旋转、双指缩放和视角重置；部位分区暂保留 Canvas 兼容路径。
- DevEco 构建和真机验收尚未完成，不宣称性能问题已解决。

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

1. 安装 0.5.0。
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


## 0.5.0 构建与验收

1. 在 DevEco Studio 打开 apps/facelab，使用 HarmonyOS SDK 26.0.0。
2. 确认 entry 模块已读取 externalNativeOptions，CMake 指向 entry/src/main/cpp/CMakeLists.txt。
3. 构建 arm64-v8a HAP；检查 native 库 libfacelab_native.so 已打包。
4. 安装到 MatePad Pro 13.2（2023），打开 FaceLab 并启动追踪。
5. 确认 XComponent Surface 创建成功，能显示原生 GPU 人脸网格。
6. 依次检查线框、实体和形变热力；与 0.4.3 对比可见帧率和卡顿。
7. 单指拖动旋转、双指捏合缩放，点击“重置视角”。
8. 切换部位分区，确认 Canvas 兼容路径仍能显示设备返回的区域标签。
9. 停止追踪并离开页面，确认相机关闭、渲染线程退出、Surface 销毁后可重新进入。
10. 回填 DevEco 完整构建日志、设备截图和性能数据至 docs/facelab/DEVICE_MATRIX.md。

## SDK 26 XComponent API note

`XComponentController` and `XComponentType` are ArkTS global declarations in the ArkUI component API; do not import them as named exports from `@kit.ArkUI`. Use the ArkTS XComponent options object with `type: XComponentType.SURFACE` and `controller`. Do not confuse it with the API 19+ `NativeXComponentParameters` overload, which is a separate native-side lifecycle API.

## 0.5.0 技术边界

GPU 渲染线程目标约 30 Hz，AR Engine 网格发布仍约 5 Hz；两者不是同一帧率。当前没有设备实测数据，不能承诺达到 30 FPS，也不能预先认定卡顿已消除。所有面部数据仅在内存中处理，不保存、不上传。
