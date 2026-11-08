# FaceLab 产品定义

## 1. 定位

FaceLab 是一个 HarmonyOS 原生视觉与交互实验应用，优先研究 MatePad 前置摄像头模组可公开调用的 AR 能力。首要目标是用可复现的实验确认能力边界，再把可用的视觉数据转化为平板交互。

## 2. 用户与设备

- 主要设备：Huawei MatePad Pro 13.2（2023 款）。
- 系统：HarmonyOS 7.0.0.111 SP8。
- 开发：DevEco Studio / HarmonyOS SDK 26.0.0。
- UI 与语言：ArkUI / ArkTS，Stage 模型。

## 3. 核心原则

1. 先做设备能力探测，再设计依赖该能力的功能。
2. 区分 AR Engine 人脸跟踪、AR 深度估计、摄像头 RGB 图像和 dToF 原始传感器数据。
3. 不假设设备拥有的硬件一定开放给普通应用。
4. 默认本地处理，不上传人脸图像、网格或面部动作数据。
5. 设备兼容性、API 行为和性能均以真机测试为准。

## 4. 版本路线

### 0.1.0 — Capability Probe
- 检测 FACE 人脸追踪特性。
- 检测 DEPTH 深度估计特性。
- 展示结果与异常。
- 不打开摄像头，不采集图像。

### 0.2.0 — AR Session
仅在 FACE 特性检测通过后实施：
- 申请相机权限。
- 创建 ARViewContext 并配置前置摄像头人脸追踪。
- 接收 ARViewCallback 帧更新。
- 获取当前 ARFace 对象。

### 0.3.0 — Face Data
- 读取 ARFace 几何网格。
- 读取人脸姿态。
- 读取 ARBlendShapes 微表情数据。
- 记录顶点数量、三角形索引数量、关键参数范围与帧率，不默认持久化原始数据。

### 0.3.1 — Motion Intelligence
- 将已在 MatePad 实测的 X / Y / Z 轴映射为 Pitch / Yaw / Roll。
- 采集中性表情网格基准，显示相对基准的面部网格形变。
- 将相邻帧网格变化与中性基准形变分开显示。
- 增加基于连续姿态帧变化的短时连续性提示，并明确其不是 SDK 置信度。

### 0.4.0 — Face Visualizer
- 将 AR Engine 实时人脸 Mesh 的顶点和三角面索引传递给独立观察器。
- 使用 ArkUI Canvas 做三维投影绘制，提供线框、半透明表面、形变热力和区域分区四种模式。
- 使用 ARPose 相对姿态驱动网格随真实头部运动；支持单指旋转、双指缩放和视角重置。
- 使用 getTriangleLabels() 的可选结果区分嘴唇、眼睛、眉毛、眉心、鼻子等区域；设备不支持时回退到其他显示模式。
- 缓存拓扑边，限制 UI 数据更新频率，保持本地内存处理。
- 明确本版本 Canvas 方案是三维投影绘制，不是独立 GPU 3D 场景；后续根据真机性能评估是否迁移 ArkGraphics3D。

### 0.4.1 — Runtime Stability Hotfix
- 修复 MatePad 首帧网格绘制时 TypedArray 经 ArkUI `@Prop` 观察代理触发的运行时异常。
- AR 回调层保留 Float32Array / Uint32Array / Int32Array；跨入 FaceMeshViewer 前将五类网格数据转换为普通 number[]。
- FaceMeshViewer 的 @Prop 不再接收 TypedArray；增加源码契约检查防止边界回归。
- 版本号更新为 0.4.1 / versionCode 10005。
- DevEco 编译与 MatePad 真机回归仍是发布验收条件，源码检查通过不等于设备验收通过。

### 0.4.2 — Performance & Geometry Visualization
- 将网格更新目标频率提升至约 10 Hz，并增加异步帧处理互斥，避免回调重入。
- UI 边界复用普通 `number[]`；仅在拓扑版本变化时更新三角索引、边和区域标签，逐帧复用顶点与形变数组。
- 缓存投影点、区域三角面分组与绘制分桶，减少逐帧临时对象和数组分配。
- 线框仅显示边；实体采用三维面法线光照；形变热力使用独立高对比度色阶，不叠加完整线框。
- 增加 Canvas 绘制调用频率与 JS 提交耗时诊断；仍需真机验证，不将 Canvas 方案描述为 GPU 原生 3D 场景。

### 0.4.3 — Live Deformation Heatmap & Lite Rendering
- 网格发布节流回约 5 Hz；未采集中性基准时显示相邻帧动态位移，采集后显示相对中性网格形变。
- 保留 Canvas 四模式方案，但明确它仍有 CPU / Canvas 性能上限。

### 0.5.0 — GPU Native Face Renderer
- 将线框、实体表面和形变热力三种高频模式迁移到 OpenGL ES 3.0 原生 GPU 渲染。
- 使用 ArkTS XComponent SURFACE + NativeWindow + EGL 建立原生渲染表面。
- 通过 Node-API 将 AR 回调的 Float32Array / Uint32Array 直接交给 C++，不再为 GPU 模式转换为 ArkUI 普通数组。
- C++ 侧缓存顶点与拓扑，使用 VBO / EBO 绘制；实体模式加入顶点法线光照，热力模式按顶点位移着色。
- 原生渲染线程以约 30 Hz 重绘最近一份网格，AR 数据更新仍维持约 5 Hz；目标帧率不是设备实测承诺。
- 保留单指旋转、双指缩放和视角重置；部位分区暂时保留 Canvas 兼容实现。
- 所有图像和几何数据仍只在本机内存处理；停止或销毁 Surface 时释放 EGL / NativeWindow 资源。
- DevEco 构建和 MatePad 真机性能验收是发布门槛；静态源码检查不代表 GPU 管线已运行成功。
- 头部左右转动、点头与倾斜映射为可配置操作。
- 探索眨眼、张嘴等 BlendShapes 触发方式。
- 与触控笔、触摸输入结合，避免仅靠面部动作产生误触。

### 0.5.1 — GPU Region Rendering
- 将 AR Engine 的三角面标签（-1 至 8）经 Node-API Int32Array 直接传递至 C++。
- 使用每三角形展开的 GPU 顶点缓冲，为每个三角面赋予固定区域 ID，避免共享顶点的区域边界颜色混合。
- 在 GLSL ES 中按区域 ID 选择与原 Canvas 方案对应的十种颜色，并通过 glDrawArrays(GL_TRIANGLES) 绘制。
- 移除部位分区的 ArkUI Canvas / number[] 专用路径，使四种显示模式统一使用原生 GPU Surface。
- 其他三种 GPU 模式继续使用原有 indexed VBO / EBO 绘制；AR 数据更新频率和本地隐私策略保持不变。
- DevEco SDK 26 构建、区域颜色映射和 MatePad 性能对比仍需真机验收。

## 5. 非目标
- 不访问系统人脸解锁或认证模板。
- 不尝试绕过 TEE、安全权限或系统隐私边界。
- 不以未经验证的 dToF 数据作为产品功能基础。
- 不作为医疗、身份认证、驾驶辅助或生命安全用途。
