### 0.4.3 — Live Deformation Heatmap & Lite Rendering
- 网格数据回调节流回约 5 Hz，降低 Canvas / ArkTS 侧持续工作量。
- 未采集中性表情时，以相邻帧逐顶点位移作为实时动态热力；采集中性基准后，以当前网格相对中性网格的位移作为热力。
- 将基准采集操作前置到观察器标题栏，降低功能发现成本。
- 如果 5 Hz 仍无法满足流畅度，下一阶段评估 ArkGraphics3D GPU 原生网格渲染，不再仅叠加 Canvas 优化。

### 0.5.0 — Interaction Lab