# FaceLab

HarmonyOS 原生三维人脸与新型交互实验应用。

## 当前版本：0.3.0 — Pose & Mesh Explorer

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
- 对相邻帧人脸网格顶点计算 RMS / MAX 位移，支持重置比较基准。
- AR 资源在帧处理后释放；停止追踪时销毁 ARViewContext。
- UI 数据更新节流到约 5 Hz，避免高频刷新。

## 目标设备

- Huawei MatePad Pro 13.2（2023 款）
- HarmonyOS 7.0.0.111 SP8
- DevEco Studio 26.0.0
- Compile SDK / HarmonyOS SDK API 26.0.0

## 已知真机结果

用户已在目标平板运行 0.1.0：
- AR Engine FACE：SUPPORTED
- AR Engine DEPTH：NOT SUPPORTED

这证明设备报告支持 FACE 特性，但不保证每个子接口（Geometry / BlendShapes）都能成功调用。0.2.0 会逐项显示子接口结果。

## 打开工程

在 DevEco Studio 中打开本目录：`apps/facelab`。同步依赖后构建 entry 模块，并部署到真实 MatePad。AR Engine 必须在真机上验证。

## 测试步骤

1. 安装 0.2.0。
2. 点击“开始追踪”。
3. 在系统弹窗中允许 FaceLab 使用摄像头。
4. 将脸放在前置摄像头画面内，观察人脸计数、Mesh、Pose 和 BlendShapes 指标。
5. 闭合左眼、闭合右眼、张开嘴巴，观察三个权重是否变化。
6. 左右转头、上下点头、左右歪头，观察 Pose Explorer 的 X/Y/Z 角度和相对平移。
7. 点击“校准当前姿态为零点”，确认角度与平移回到接近零值。
8. 观察 Mesh Diagnostics 的相邻帧 RMS / MAX 位移；分别保持静止、转头、眨眼、张嘴，对比变化。
9. 点击“重置网格位移基准”，等待下一帧建立基准。
10. 点击“停止追踪”，确认相机预览关闭。
11. 将结果和 DevEco 编译日志反馈到项目 issue / 对话中。

## 隐私

所有数据只在设备内存中用于实时展示，不保存、不上传。FaceLab 不进行身份识别，不访问系统人脸认证数据，也不读取 dToF 原始传感器帧。
