import { InkDocument, InkStroke } from '../ink/InkStrokeModel';

@Component
export struct InkLayer {
  @Prop @Watch('draw') document: InkDocument = {
    nextStrokeNumber: 1,
    strokes: []
  };
  @Prop @Watch('draw') renderMode: string = 'full';

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private ready: boolean = false;

  private drawSegment(stroke: InkStroke, startIndex: number): void {
    if (stroke.points.length === 0) {
      return;
    }
    if (stroke.points.length === 1) {
      const point = stroke.points[0];
      this.context.beginPath();
      this.context.fillStyle = stroke.color;
      this.context.arc(
        point.x,
        point.y,
        stroke.width * point.pressure * 0.5,
        0,
        Math.PI * 2
      );
      this.context.fill();
      return;
    }

    const index = Math.max(1, startIndex);
    const previous = stroke.points[index - 1];
    const current = stroke.points[index];
    this.context.beginPath();
    this.context.strokeStyle = stroke.color;
    this.context.lineWidth = stroke.width * (previous.pressure + current.pressure) * 0.5;
    this.context.moveTo(previous.x, previous.y);
    this.context.lineTo(current.x, current.y);
    this.context.stroke();
  }

  private draw(): void {
    if (!this.ready) {
      return;
    }

    if (this.renderMode === 'append' && this.document.strokes.length > 0) {
      const active = this.document.strokes[this.document.strokes.length - 1];
      this.drawSegment(active, active.points.length - 1);
      return;
    }

    this.context.clearRect(0, 0, 4000, 2400);
    this.context.lineCap = 'round';
    this.context.lineJoin = 'round';

    for (let i = 0; i < this.document.strokes.length; i++) {
      const stroke: InkStroke = this.document.strokes[i];
      if (stroke.points.length === 0) {
        continue;
      }

      if (stroke.points.length === 1) {
        this.drawSegment(stroke, 0);
        continue;
      }

      for (let j = 1; j < stroke.points.length; j++) {
        this.drawSegment(stroke, j);
      }
    }
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)
      .onReady(() => {
        this.ready = true;
        this.draw();
      })
  }
}
