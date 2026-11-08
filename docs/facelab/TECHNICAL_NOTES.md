

## 16. 0.4.3 — Live Deformation Heatmap & Lite Rendering

- 网格发布最小间隔调整为 200 ms（约 5 Hz），减少页面侧网格更新和 Canvas 绘制压力。ARView 的场景渲染由 AR Engine 独立驱动。
- 若 `neutralVertices` 已采集，`meshDeformation[i]` 为当前顶点相对中性基准的三维位移长度。
- 若尚未采集中性基准，`meshDeformation[i]` 回退为当前顶点相对上一帧的位移长度；热力图标记为 `LIVE MOTION Δ`。
- 采集中性基准后热力图标记为 `NEUTRAL Δ`。
- 这两种数值描述不同时间参考，不应直接混为同一种表情强度指标。
- 若降低至约 5 Hz 后仍明显卡顿，Canvas 投影渲染仍可能是主要瓶颈，应评估 ArkGraphics3D GPU 原生网格渲染。
