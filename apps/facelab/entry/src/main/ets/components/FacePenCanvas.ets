import { StylusFrameBoost } from '@kit.Penkit';

export interface FacePenColor {
  name: string;
  value: string;
}

export const FACE_PEN_PALETTE: FacePenColor[] = [
  { name: '墨黑', value: '#20242B' },
  { name: '朱红', value: '#D94B4B' },
  { name: '钴蓝', value: '#246BFD' },
  { name: '松绿', value: '#239B6E' },
  { name: '琥珀', value: '#E0A128' },
  { name: '紫藤', value: '#7A4CC2' }
];

/**
 * FacePen's local drawing surface.
 *
 * Only ArkUI stylus events are accepted. Each pointer-down snapshots the
 * selected color; subsequent palette changes cannot recolor the active stroke.
 */
@Component
export struct FacePenCanvas {
  @Prop selectedColor: string = '#20242B';
  @Prop selectedColorName: string = '墨黑';

  onStrokeStateChange: (active: boolean) => void = () => {};
  onInputStatus: (message: string) => void = () => {};

  @State canvasReady: boolean = false;
  @State isStrokeActive: boolean = false;
  @State completedStrokeCount: number = 0;
  @State statusText: string = '画布初始化中…';

  private context: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private activePointerId: number = -1;
  private activeStrokeColor: string = '#20242B';
  private lastX: number = 0;
  private lastY: number = 0;
  private stylusFrameBoost: StylusFrameBoost | undefined = undefined;
  private stylusFrameBoostAttempted: boolean = false;

  private refreshStylusFrame(action: number): void {
    if (!this.stylusFrameBoostAttempted) {
      this.stylusFrameBoostAttempted = true;
      try {
        this.stylusFrameBoost = new StylusFrameBoost();
      } catch (_) {
        this.stylusFrameBoost = undefined;
        return;
      }
    }
    const boost = this.stylusFrameBoost;
    if (boost === undefined) {
      return;
    }
    try {
      const result = boost.forceRefreshOneFrame(action);
      if (result !== 0) {
        this.stylusFrameBoost = undefined;
      }
    } catch (_) {
      // The normal Canvas path remains usable when frame boost is unavailable.
      this.stylusFrameBoost = undefined;
    }
  }

  private lineWidthFor(point: TouchObject): number {
    const pressure = point.pressure;
    if (pressure === undefined || pressure <= 0) {
      return 3.2;
    }
    const normalized = Math.max(0, Math.min(1, pressure / 65535));
    return 1.8 + normalized * 3.0;
  }

  private startStroke(point: TouchObject): void {
    if (!this.canvasReady) {
      this.statusText = '画布尚未就绪，请稍后再写';
      return;
    }
    if (this.isStrokeActive) {
      this.finishStroke(false);
    }

    this.isStrokeActive = true;
    this.activePointerId = point.id;
    // Stroke transaction: freeze the color exactly once, at DOWN.
    this.activeStrokeColor = this.selectedColor;
    this.lastX = point.x;
    this.lastY = point.y;

    const width = this.lineWidthFor(point);
    this.context.beginPath();
    this.context.fillStyle = this.activeStrokeColor;
    this.context.arc(point.x, point.y, width / 2, 0, Math.PI * 2);
    this.context.fill();

    this.statusText = '书写中 · 本笔颜色已锁定';
    this.onStrokeStateChange(true);
    this.onInputStatus('M-Pencil 书写中 · ' + this.selectedColorName);
  }

  private drawTo(point: TouchObject): void {
    if (!this.isStrokeActive || point.id !== this.activePointerId) {
      return;
    }

    const dx = point.x - this.lastX;
    const dy = point.y - this.lastY;
    if (dx * dx + dy * dy >= 0.04) {
      this.context.beginPath();
      this.context.strokeStyle = this.activeStrokeColor;
      this.context.lineWidth = this.lineWidthFor(point);
      this.context.lineCap = 'round';
      this.context.lineJoin = 'round';
      this.context.moveTo(this.lastX, this.lastY);
      this.context.lineTo(point.x, point.y);
      this.context.stroke();
    }

    this.lastX = point.x;
    this.lastY = point.y;
  }

  private finishStroke(completed: boolean): void {
    if (!this.isStrokeActive) {
      return;
    }

    this.isStrokeActive = false;
    this.activePointerId = -1;
    if (completed) {
      this.completedStrokeCount++;
      this.statusText = '笔画完成 · 共 ' + this.completedStrokeCount.toString() + ' 笔';
      this.onInputStatus('笔画完成 · ' + this.completedStrokeCount.toString() + ' 笔');
    } else {
      this.statusText = '输入已中断 · 当前笔画已结束';
      this.onInputStatus('笔画输入已中断');
    }
    this.onStrokeStateChange(false);
  }

  private handleTouch(event: TouchEvent): void {
    // A system interruption must close an active transaction even if the
    // platform reports a non-pen source on the cancellation event.
    if (event.type === TouchType.Cancel) {
      if (this.isStrokeActive) {
        event.stopPropagation();
        this.finishStroke(false);
        this.refreshStylusFrame(event.type);
      }
      return;
    }

    if (event.sourceTool !== SourceTool.Pen) {
      return;
    }
    // Keep stylus movement from being interpreted as Scroll / 3D-surface input.
    event.stopPropagation();

    const point: TouchObject | undefined = event.changedTouches.length > 0 ?
      event.changedTouches[0] :
      (event.touches.length > 0 ? event.touches[0] : undefined);

    if (event.type === TouchType.Down) {
      if (point !== undefined) {
        this.startStroke(point);
      }
      this.refreshStylusFrame(event.type);
      return;
    }

    if (!this.isStrokeActive) {
      return;
    }

    if (event.type === TouchType.Move) {
      const history = event.getHistoricalPoints();
      for (let i = 0; i < history.length; i++) {
        const historicalPoint = history[i].touchObject;
        if (historicalPoint.id === this.activePointerId) {
          this.drawTo(historicalPoint);
        }
      }
      if (point !== undefined) {
        this.drawTo(point);
      }
      this.refreshStylusFrame(event.type);
      return;
    }

    if (event.type === TouchType.Up) {
      if (point !== undefined) {
        this.drawTo(point);
      }
      this.finishStroke(true);
      this.refreshStylusFrame(event.type);
    }
  }

  private clearCanvas(): void {
    if (!this.canvasReady || this.isStrokeActive) {
      return;
    }
    this.context.clearRect(0, 0, 10000, 10000);
    this.completedStrokeCount = 0;
    this.statusText = '画布已清空 · 可以重新书写';
    this.onInputStatus('画布已清空');
  }

  aboutToDisappear(): void {
    if (this.isStrokeActive) {
      this.finishStroke(false);
    }
  }

  build() {
    Column({ space: 8 }) {
      Row() {
        Text(this.isStrokeActive ? '正在书写 · 颜色已冻结' : this.statusText)
          .fontSize(12)
          .fontColor(this.isStrokeActive ? '#239B6E' : '#AAB8C8')
          .layoutWeight(1)
        Button('清空画布')
          .height(32)
          .fontSize(11)
          .enabled(this.canvasReady && !this.isStrokeActive)
          .backgroundColor('#34445D')
          .onClick(() => {
            this.clearCanvas();
          })
      }
      .width('100%')

      Canvas(this.context)
        .width('100%')
        .height(420)
        .backgroundColor('#FCFDFE')
        .borderRadius(12)
        .onReady(() => {
          this.canvasReady = true;
          this.statusText = '画布已就绪 · 请用 M-Pencil 书写';
        })
        .onTouch((event?: TouchEvent) => {
          if (event !== undefined) {
            this.handleTouch(event);
          }
        })

      Text('仅接受手写笔（SourceTool.Pen）输入；本版以 M-Pencil 为目标设备。手指可用于页面滚动和调色，笔压可用时会映射为线宽。')
        .fontSize(11)
        .fontColor('#8190A5')
        .lineHeight(17)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
