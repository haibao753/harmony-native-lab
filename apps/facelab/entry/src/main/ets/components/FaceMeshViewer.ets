interface FaceMeshProjectedPoint {
  x: number;
  y: number;
  z: number;
  rx: number;
  ry: number;
  rz: number;
}

@Component
export struct FaceMeshViewer {
  @Prop vertices: number[] = [];
  @Prop triangles: number[] = [];
  @Prop edges: number[] = [];
  @Prop deformation: number[] = [];
  @Prop labels: number[] = [];
  @Prop @Watch('redraw') revision: number = 0;
  @Prop @Watch('redraw') mode: string = 'wireframe';
  @Prop @Watch('redraw') hasNeutral: boolean = false;
  @Prop @Watch('redraw') hasLabels: boolean = false;
  @Prop @Watch('redraw') hasMesh: boolean = false;
  @Prop @Watch('redraw') posePitch: number = 0;
  @Prop @Watch('redraw') poseYaw: number = 0;
  @Prop @Watch('redraw') poseRoll: number = 0;
  @Prop @Watch('redraw') topologyRevision: number = 0;
  @Prop @Watch('resetView') resetKey: number = 0;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private canvasReady: boolean = false;
  private yaw: number = 0;
  private pitch: number = 0;
  private roll: number = 0;
  private zoom: number = 1;
  private lastTouchX: number = -1;
  private lastTouchY: number = -1;
  private lastPinchDistance: number = 0;
  private projectedPoints: FaceMeshProjectedPoint[] = [];
  private surfaceBins: number[][] = [[], [], [], [], [], []];
  private deformationBins: number[][] = [[], [], [], [], [], [], [], []];
  private regionBins: number[][] = [[], [], [], [], [], [], [], [], [], []];
  private cachedTopologyRevision: number = -1;
  private lastDrawTimestamp: number = 0;
  private drawFps: number = 0;
  private lastDrawCostMs: number = 0;
  private surfaceColors: string[] = ['#17263D', '#203A59', '#2B5678', '#367C91', '#5DAAA8', '#B6D8C7'];
  private deformationColors: string[] = ['#2457C5', '#1688D4', '#21B6C8', '#48C78E', '#B9D94A', '#F3D34A', '#F39A38', '#E94D5A'];

  redraw(_propertyName?: string): void {
    this.draw();
  }

  resetView(_propertyName?: string): void {
    this.yaw = 0;
    this.pitch = 0;
    this.roll = 0;
    this.zoom = 1;
    this.lastTouchX = -1;
    this.lastTouchY = -1;
    this.lastPinchDistance = 0;
    this.draw();
  }

  private heatColor(value: number): string {
    const t = Math.max(0, Math.min(1, value));
    let red: number = 0;
    let green: number = 0;
    let blue: number = 0;
    if (t < 0.5) {
      const k = t * 2;
      red = Math.floor(35 + 20 * k);
      green = Math.floor(105 + 125 * k);
      blue = Math.floor(220 - 35 * k);
    } else {
      const k = (t - 0.5) * 2;
      red = Math.floor(55 + 200 * k);
      green = Math.floor(230 - 145 * k);
      blue = Math.floor(185 - 105 * k);
    }
    return 'rgb(' + red.toString() + ',' + green.toString() + ',' + blue.toString() + ')';
  }

  private drawAxis(width: number, height: number): void {
    const ctx = this.context;
    const ox = width - 54;
    const oy = height - 48;
    const length = 25;
    ctx.lineWidth = 2;
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'left';

    ctx.beginPath();
    ctx.moveTo(ox, oy);
    ctx.lineTo(ox + length, oy);
    ctx.strokeStyle = '#F28B82';
    ctx.stroke();
    ctx.fillStyle = '#F28B82';
    ctx.fillText('X', ox + length + 3, oy + 3);

    ctx.beginPath();
    ctx.moveTo(ox, oy);
    ctx.lineTo(ox, oy - length);
    ctx.strokeStyle = '#75D6A5';
    ctx.stroke();
    ctx.fillStyle = '#75D6A5';
    ctx.fillText('Y', ox - 4, oy - length - 5);

    ctx.beginPath();
    ctx.moveTo(ox, oy);
    ctx.lineTo(ox - 17, oy + 17);
    ctx.strokeStyle = '#78A9F8';
    ctx.stroke();
    ctx.fillStyle = '#78A9F8';
    ctx.fillText('Z', ox - 29, oy + 25);
  }

  private handleTouch(event: TouchEvent): void {
    const touches = event.touches;
    if (touches.length === 1) {
      const point = touches[0];
      if (this.lastTouchX >= 0) {
        this.yaw += (point.x - this.lastTouchX) * 0.012;
        this.pitch += (point.y - this.lastTouchY) * 0.012;
        this.pitch = Math.max(-1.35, Math.min(1.35, this.pitch));
      }
      this.lastTouchX = point.x;
      this.lastTouchY = point.y;
      this.lastPinchDistance = 0;
      this.draw();
      return;
    }
    if (touches.length >= 2) {
      const first = touches[0];
      const second = touches[1];
      const dx = second.x - first.x;
      const dy = second.y - first.y;
      const distance = Math.sqrt(dx * dx + dy * dy);
      if (this.lastPinchDistance > 0 && distance > 0) {
        this.zoom = this.zoom * distance / this.lastPinchDistance;
        this.zoom = Math.max(0.65, Math.min(2.8, this.zoom));
      }
      this.lastPinchDistance = distance;
      this.lastTouchX = -1;
      this.lastTouchY = -1;
      this.draw();
      return;
    }
    this.lastTouchX = -1;
    this.lastTouchY = -1;
    this.lastPinchDistance = 0;
  }

  private resetBins(bins: number[][], count: number): void {
    while (bins.length < count) {
      bins.push([]);
    }
    while (bins.length > count) {
      bins.pop();
    }
    for (let i = 0; i < bins.length; i++) {
      bins[i].length = 0;
    }
  }

  private rebuildRegionBins(): void {
    this.resetBins(this.regionBins, 10);
    if (!this.hasLabels || this.labels.length !== Math.floor(this.triangles.length / 3)) {
      this.cachedTopologyRevision = this.topologyRevision;
      return;
    }
    const vertexCount = Math.floor(this.vertices.length / 3);
    for (let i = 0; i + 2 < this.triangles.length; i += 3) {
      const triangleNumber = Math.floor(i / 3);
      const bucket = this.labels[triangleNumber] + 1;
      const a = this.triangles[i];
      const b = this.triangles[i + 1];
      const c = this.triangles[i + 2];
      if (bucket < 0 || bucket >= this.regionBins.length ||
        a >= vertexCount || b >= vertexCount || c >= vertexCount) {
        continue;
      }
      this.regionBins[bucket].push(a, b, c);
    }
    this.cachedTopologyRevision = this.topologyRevision;
  }

  private draw(): void {
    if (!this.canvasReady) {
      return;
    }
    const drawStartedAt = Date.now();
    const ctx = this.context;
    const width = ctx.width;
    const height = ctx.height;
    if (width <= 0 || height <= 0) {
      return;
    }

    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = '#0B1422';
    ctx.fillRect(0, 0, width, height);
    ctx.font = '11px sans-serif';
    ctx.textAlign = 'left';
    ctx.fillStyle = '#91A7C2';
    ctx.fillText('LIVE FACE MESH · 3D PROJECTION', 14, 21);

    if (!this.hasMesh || this.vertices.length < 9 || this.triangles.length < 3) {
      ctx.font = '14px sans-serif';
      ctx.fillStyle = '#D2DCE8';
      ctx.textAlign = 'center';
      ctx.fillText('等待 AR Engine 提供人脸网格…', width / 2, height / 2);
      ctx.font = '11px sans-serif';
      ctx.fillStyle = '#8190A5';
      ctx.fillText('请启动追踪并让人脸进入摄像头画面', width / 2, height / 2 + 24);
      this.drawAxis(width, height);
      this.finishDraw(drawStartedAt);
      return;
    }

    const vertexCount = Math.floor(this.vertices.length / 3);
    let minX = Number.POSITIVE_INFINITY;
    let maxX = Number.NEGATIVE_INFINITY;
    let minY = Number.POSITIVE_INFINITY;
    let maxY = Number.NEGATIVE_INFINITY;
    let minZ = Number.POSITIVE_INFINITY;
    let maxZ = Number.NEGATIVE_INFINITY;

    for (let i = 0; i < vertexCount; i++) {
      const x = this.vertices[i * 3];
      const y = this.vertices[i * 3 + 1];
      const z = this.vertices[i * 3 + 2];
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
      if (z < minZ) minZ = z;
      if (z > maxZ) maxZ = z;
    }

    const centerX = (minX + maxX) * 0.5;
    const centerY = (minY + maxY) * 0.5;
    const centerZ = (minZ + maxZ) * 0.5;
    const modelRange = Math.max(maxX - minX, maxY - minY, maxZ - minZ, 0.0001);
    const scale = Math.min(width * 0.78, height * 0.78) / modelRange * this.zoom;
    const viewYaw = this.yaw + this.poseYaw * Math.PI / 180;
    const viewPitch = this.pitch + this.posePitch * Math.PI / 180;
    const viewRoll = this.roll + this.poseRoll * Math.PI / 180;
    const cosYaw = Math.cos(viewYaw);
    const sinYaw = Math.sin(viewYaw);
    const cosPitch = Math.cos(viewPitch);
    const sinPitch = Math.sin(viewPitch);
    const cosRoll = Math.cos(viewRoll);
    const sinRoll = Math.sin(viewRoll);

    if (this.projectedPoints.length !== vertexCount) {
      this.projectedPoints = [];
      for (let i = 0; i < vertexCount; i++) {
        this.projectedPoints.push({ x: 0, y: 0, z: 0, rx: 0, ry: 0, rz: 0 });
      }
    }

    for (let i = 0; i < vertexCount; i++) {
      const rawX = this.vertices[i * 3] - centerX;
      const rawY = this.vertices[i * 3 + 1] - centerY;
      const rawZ = this.vertices[i * 3 + 2] - centerZ;
      const rollX = rawX * cosRoll - rawY * sinRoll;
      const rollY = rawX * sinRoll + rawY * cosRoll;
      const pitchY = rollY * cosPitch - rawZ * sinPitch;
      const pitchZ = rollY * sinPitch + rawZ * cosPitch;
      const yawX = rollX * cosYaw + pitchZ * sinYaw;
      const yawZ = -rollX * sinYaw + pitchZ * cosYaw;
      const perspective = 1 / Math.max(0.55, 1 + yawZ / (modelRange * 4));
      const point = this.projectedPoints[i];
      point.x = width * 0.5 + yawX * scale * perspective;
      point.y = height * 0.52 - pitchY * scale * perspective;
      point.z = yawZ;
      point.rx = yawX;
      point.ry = pitchY;
      point.rz = yawZ;
    }

    if (this.mode === 'surface') {
      this.resetBins(this.surfaceBins, 6);
      const lightX = -0.34;
      const lightY = 0.62;
      const lightZ = 0.71;
      for (let i = 0; i + 2 < this.triangles.length; i += 3) {
        const a = this.triangles[i];
        const b = this.triangles[i + 1];
        const c = this.triangles[i + 2];
        if (a >= vertexCount || b >= vertexCount || c >= vertexCount) {
          continue;
        }
        const pa = this.projectedPoints[a];
        const pb = this.projectedPoints[b];
        const pc = this.projectedPoints[c];
        const ux = pb.rx - pa.rx;
        const uy = pb.ry - pa.ry;
        const uz = pb.rz - pa.rz;
        const vx = pc.rx - pa.rx;
        const vy = pc.ry - pa.ry;
        const vz = pc.rz - pa.rz;
        const nx = uy * vz - uz * vy;
        const ny = uz * vx - ux * vz;
        const nz = ux * vy - uy * vx;
        const normalLength = Math.sqrt(nx * nx + ny * ny + nz * nz);
        const diffuse = normalLength > 0.000001 ?
          Math.abs((nx * lightX + ny * lightY + nz * lightZ) / normalLength) : 0;
        const intensity = 0.16 + Math.min(1, diffuse) * 0.84;
        const bucket = Math.min(5, Math.floor(intensity * 6));
        this.surfaceBins[bucket].push(a, b, c);
      }
      for (let bucket = 0; bucket < this.surfaceBins.length; bucket++) {
        const faces = this.surfaceBins[bucket];
        if (faces.length === 0) {
          continue;
        }
        ctx.beginPath();
        for (let i = 0; i + 2 < faces.length; i += 3) {
          const a = this.projectedPoints[faces[i]];
          const b = this.projectedPoints[faces[i + 1]];
          const c = this.projectedPoints[faces[i + 2]];
          ctx.moveTo(a.x, a.y);
          ctx.lineTo(b.x, b.y);
          ctx.lineTo(c.x, c.y);
          ctx.closePath();
        }
        ctx.fillStyle = this.surfaceColors[bucket];
        ctx.globalAlpha = 0.98;
        ctx.fill();
      }
      ctx.globalAlpha = 1;
    } else if (this.mode === 'regions') {
      if (this.hasLabels && this.labels.length === Math.floor(this.triangles.length / 3)) {
        if (this.cachedTopologyRevision !== this.topologyRevision) {
          this.rebuildRegionBins();
        }
        const regionColors: string[] = [
          '#27364A', '#71849A', '#D66BA0', '#F08DB6', '#53C5D9',
          '#6D9EF2', '#E5B85C', '#D99B4A', '#B58AE0', '#65C99B'
        ];
        for (let bucket = 0; bucket < this.regionBins.length; bucket++) {
          const faces = this.regionBins[bucket];
          if (faces.length === 0) {
            continue;
          }
          ctx.beginPath();
          for (let i = 0; i + 2 < faces.length; i += 3) {
            const a = this.projectedPoints[faces[i]];
            const b = this.projectedPoints[faces[i + 1]];
            const c = this.projectedPoints[faces[i + 2]];
            ctx.moveTo(a.x, a.y);
            ctx.lineTo(b.x, b.y);
            ctx.lineTo(c.x, c.y);
            ctx.closePath();
          }
          ctx.fillStyle = regionColors[bucket];
          ctx.globalAlpha = 0.94;
          ctx.fill();
        }
        ctx.globalAlpha = 1;
        this.drawEdges(width, height, 0.22, '#C8D8E8', 0.35);
      } else {
        ctx.font = '12px sans-serif';
        ctx.fillStyle = '#F2C078';
        ctx.fillText('当前设备暂未返回面部区域标签', 14, 43);
      }
    } else if (this.mode === 'deformation') {
      if (this.hasNeutral && this.deformation.length === vertexCount) {
        let maxDeformation = 0;
        for (let i = 0; i < this.deformation.length; i++) {
          if (this.deformation[i] > maxDeformation) {
            maxDeformation = this.deformation[i];
          }
        }
        const heatScale = Math.max(maxDeformation * 0.62, 0.00001);
        this.resetBins(this.deformationBins, 8);
        for (let i = 0; i + 2 < this.triangles.length; i += 3) {
          const a = this.triangles[i];
          const b = this.triangles[i + 1];
          const c = this.triangles[i + 2];
          if (a >= vertexCount || b >= vertexCount || c >= vertexCount) {
            continue;
          }
          const amount = (this.deformation[a] + this.deformation[b] + this.deformation[c]) / 3;
          const normalized = Math.max(0, Math.min(1, amount / heatScale));
          const bucket = Math.min(7, Math.floor(normalized * 8));
          this.deformationBins[bucket].push(a, b, c);
        }
        for (let bucket = 0; bucket < this.deformationBins.length; bucket++) {
          const faces = this.deformationBins[bucket];
          if (faces.length === 0) {
            continue;
          }
          ctx.beginPath();
          for (let i = 0; i + 2 < faces.length; i += 3) {
            const a = this.projectedPoints[faces[i]];
            const b = this.projectedPoints[faces[i + 1]];
            const c = this.projectedPoints[faces[i + 2]];
            ctx.moveTo(a.x, a.y);
            ctx.lineTo(b.x, b.y);
            ctx.lineTo(c.x, c.y);
            ctx.closePath();
          }
          ctx.fillStyle = this.deformationColors[bucket];
          ctx.globalAlpha = 0.98;
          ctx.fill();
        }
        ctx.globalAlpha = 1;
        const legendX = 14;
        const legendY = height - 25;
        for (let i = 0; i < this.deformationColors.length; i++) {
          ctx.fillStyle = this.deformationColors[i];
          ctx.fillRect(legendX + i * 18, legendY, 16, 7);
        }
        ctx.font = '9px sans-serif';
        ctx.fillStyle = '#C6D3E1';
        ctx.fillText('LOW', legendX, legendY - 5);
        ctx.textAlign = 'right';
        ctx.fillText('HIGH · ' + maxDeformation.toFixed(4), width - 14, legendY - 5);
        ctx.textAlign = 'left';
      } else {
        ctx.font = '12px sans-serif';
        ctx.fillStyle = '#F2C078';
        ctx.fillText('先采集中性表情基准以启用形变热力图', 14, 43);
      }
    } else {
      // Wireframe is intentionally edge-only: no hidden face fill or surface overlay.
      this.drawEdges(width, height, 1, '#69D9E8', 0.9);
    }

    ctx.font = '10px sans-serif';
    ctx.fillStyle = '#91A7C2';
    ctx.textAlign = 'right';
    ctx.fillText(vertexCount.toString() + ' vertices · ' +
      Math.floor(this.triangles.length / 3).toString() + ' triangles', width - 12, 21);
    ctx.fillText('CANVAS ' + this.drawFps.toFixed(1) + ' FPS · ' +
      this.lastDrawCostMs.toString() + ' ms', width - 12, 39);
    ctx.textAlign = 'left';
    ctx.fillStyle = '#8190A5';
    ctx.fillText('P ' + this.posePitch.toFixed(1) + '°  Y ' +
      this.poseYaw.toFixed(1) + '°  R ' + this.poseRoll.toFixed(1) + '°', 14, 39);
    this.drawAxis(width, height);
    this.finishDraw(drawStartedAt);
  }

  private drawEdges(width: number, height: number, alpha: number, color: string, lineWidth: number): void {
    const ctx = this.context;
    const vertexCount = this.projectedPoints.length;
    ctx.beginPath();
    for (let i = 0; i + 1 < this.edges.length; i += 2) {
      const a = this.edges[i];
      const b = this.edges[i + 1];
      if (a >= vertexCount || b >= vertexCount) {
        continue;
      }
      const pa = this.projectedPoints[a];
      const pb = this.projectedPoints[b];
      ctx.moveTo(pa.x, pa.y);
      ctx.lineTo(pb.x, pb.y);
    }
    ctx.globalAlpha = alpha;
    ctx.strokeStyle = color;
    ctx.lineWidth = lineWidth;
    ctx.stroke();
    ctx.globalAlpha = 1;
  }

  private finishDraw(startedAt: number): void {
    const now = Date.now();
    if (this.lastDrawTimestamp > 0 && now > this.lastDrawTimestamp) {
      const instantaneousFps = 1000 / (now - this.lastDrawTimestamp);
      this.drawFps = this.drawFps <= 0 ? instantaneousFps :
        this.drawFps * 0.7 + instantaneousFps * 0.3;
    }
    this.lastDrawTimestamp = now;
    this.lastDrawCostMs = now - startedAt;
  }

  build() {
    Column({ space: 0 }) {
      Canvas(this.context)
        .width('100%')
        .height(340)
        .backgroundColor('#0B1422')
        .borderRadius(12)
        .onReady(() => {
          this.canvasReady = true;
          this.draw();
        })
        .onTouch((event: TouchEvent) => {
          this.handleTouch(event);
        })
    }
    .width('100%')
    .backgroundColor('#0B1422')
    .borderRadius(12)
  }
}
