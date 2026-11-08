# FaceLab 实现记录

## 2026-11-08 — 0.1.0 Capability Probe

### 已完成
- 建立独立的 API 26 Stage 工程骨架：`apps/facelab`。
- 配置独立 bundleName：`com.haibao.facelab`。
- 添加 FACE 人脸追踪与 DEPTH 深度估计两项能力检查。
- 加入错误码显示和设备信息说明。
- 明确 AR Engine 人脸跟踪与 dToF 原始数据访问的区别。
- 默认不启动摄像头，不采集或保存面部数据。

### 尚未完成 / 尚未验证
- 尚未在 DevEco Studio 本地构建。
- 尚未安装到 MatePad Pro 13.2（2023）真机。
- 尚未验证 FACE / DEPTH 返回值。
- 尚未创建 AR 会话或显示真实人脸网格。

### 验收步骤
1. 在 DevEco Studio 打开 `apps/facelab`。
2. 使用 API 26 SDK 同步并构建 entry 模块。
3. 将应用部署到 MatePad Pro 13.2（2023）。
4. 点击“检测设备能力”。
5. 记录 FACE、DEPTH 状态及异常信息，并将结果回填到 `DEVICE_MATRIX.md`。
