import {
  LinkedListDocument,
  LinkedNode,
  addNode,
  analyzeDocument,
  cloneDocument,
  createEmptyDocument,
  deleteNode,
  findNode,
  moveNode,
  setHead,
  setNext,
  setNodeValue
} from '../domain/LinkedListModel';
import { generateCpp } from '../codegen/CppLinkedListGenerator';
import { highlightCpp, formatCppDisplayToken, measureCppLineWidth, CppDisplayLine, CppToken } from '../codegen/CppSyntaxHighlighter';

@Component
struct NodeCard {
  // Keep changing fields as primitive @Prop values. Passing the whole
  // LinkedNode object did not refresh the next label reliably on the MatePad.
  @Prop nodeId: string = 'N0';
  @Prop nodeValue: number = 0;
  @Prop nextId: string | null = null;
  @Prop positionX: number = 0;
  @Prop positionY: number = 0;
  @Prop selected: boolean = false;
  onTap: (id: string) => void = (id: string) => {};
  onMove: (id: string, x: number, y: number) => void =
    (id: string, x: number, y: number) => {};

  @State dragOffsetX: number = 0;
  @State dragOffsetY: number = 0;

  build() {
    Column({ space: 5 }) {
      Text(this.nodeId)
        .fontSize(11)
        .fontColor('#64748B')
      Text(this.nodeValue.toString())
        .fontSize(23)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17212B')
      Text('next → ' + (this.nextId === null ? 'nullptr' : this.nextId))
        .fontSize(11)
        .fontColor('#52616B')
    }
    .width(136)
    .height(88)
    .padding(10)
    .backgroundColor(this.selected ? '#E2F3EF' : '#FFFFFF')
    .border({
      width: this.selected ? 2 : 1,
      color: this.selected ? '#168477' : '#D9E0E7'
    })
    .borderRadius(14)
    .position({ x: this.positionX, y: this.positionY })
    .translate({ x: this.dragOffsetX, y: this.dragOffsetY })
    .onClick(() => {
      this.onTap(this.nodeId);
    })
    .gesture(
      PanGesture({ fingers: 1, distance: 4 })
        .onActionStart(() => {
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
        })
        .onActionUpdate((event: GestureEvent | undefined) => {
          if (event !== undefined) {
            this.dragOffsetX = event.offsetX;
            this.dragOffsetY = event.offsetY;
          }
        })
        .onActionEnd((event: GestureEvent | undefined) => {
          if (event !== undefined) {
            this.onMove(
              this.nodeId,
              this.positionX + event.offsetX,
              this.positionY + event.offsetY
            );
          }
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
        })
        .onActionCancel(() => {
          this.dragOffsetX = 0;
          this.dragOffsetY = 0;
        })
    )
  }
}
@Entry
@Component
struct Index {
  @State @Watch('drawConnections') document: LinkedListDocument = createEmptyDocument();
  @State selectedId: string = '';
  @State valueInput: string = '';
  @State connectionSourceId: string = '';
  @State showCode: boolean = false;
  // Floating C++ workspace geometry is kept in page state so collapsing the
  // panel and opening it again preserves its position and size for this session.
  @State codePanelX: number = 340;
  @State codePanelY: number = 220;
  @State codePanelWidth: number = 720;
  @State codePanelHeight: number = 500;
  @State viewportWidth: number = 0;
  @State viewportHeight: number = 0;
  // Width of the actual horizontal code viewport. Short source lines must
  // occupy at least this width; otherwise Scroll may center their content.
  @State codeLineViewportWidth: number = 0;
  @State generatedCode: string = '';
  @State codeLines: CppDisplayLine[] = [];
  // 11 is the original compact size; font controls affect only C++ source tokens.
  @State codeFontSize: number = 14;
  @State warnings: string[] = [];
  @State message: string = '先添加一个节点。拖动节点只改变位置，不会改变指针关系。';
  @State statusText: string = '空画布';
  @State canUndo: boolean = false;
  @State canRedo: boolean = false;

  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D =
    new CanvasRenderingContext2D(this.canvasSettings);
  private canvasReady: boolean = false;
  private undoStack: LinkedListDocument[] = [];
  private redoStack: LinkedListDocument[] = [];
  private panelDragStartX: number = 0;
  private panelDragStartY: number = 0;
  private panelResizeStartWidth: number = 720;
  private panelResizeStartHeight: number = 500;

  aboutToAppear(): void {
    this.refreshDerivedState();
  }

  private syncSelectedValueInput(): void {
    const selectedNode = findNode(this.document, this.selectedId);
    this.valueInput = selectedNode === null ? '' : selectedNode.value.toString();
  }

  private refreshDerivedState(): void {
    this.syncSelectedValueInput();
    const generated = generateCpp(this.document);
    this.generatedCode = generated.code;
    this.codeLines = highlightCpp(generated.code, generated.annotations);
    this.warnings = generated.warnings;
    const analysis = analyzeDocument(this.document);

    if (this.document.nodes.length === 0) {
      this.statusText = '空画布';
    } else if (this.document.headId === null) {
      this.statusText = 'head 为空';
    } else if (analysis.hasCycle) {
      this.statusText = '检测到环，入口：' + (analysis.cycleEntryId === null ? '未知' : analysis.cycleEntryId);
    } else if (analysis.unreachableIds.length > 0) {
      this.statusText = analysis.unreachableIds.length.toString() + ' 个节点从 head 不可达';
    } else {
      this.statusText = '从 head 可达 ' + analysis.reachableIds.length.toString() + ' 个节点';
    }
  }

  private applyDocument(nextDocument: LinkedListDocument): void {
    this.undoStack.push(cloneDocument(this.document));
    if (this.undoStack.length > 50) {
      this.undoStack.shift();
    }
    this.redoStack = [];
    this.canUndo = this.undoStack.length > 0;
    this.canRedo = false;
    this.document = nextDocument;
    this.refreshDerivedState();
  }

  private addNewNode(): void {
    const index = this.document.nodes.length;
    const nodeId = 'N' + this.document.nextNodeNumber.toString();
    const x = 36 + (index % 4) * 174;
    const y = 42 + Math.floor(index / 4) * 132;
    const value = this.document.nextNodeNumber * 10;
    const nextDocument = addNode(this.document, value, x, y);
    this.applyDocument(nextDocument);
    this.selectedId = nodeId;
    this.syncSelectedValueInput();
    this.message = '已创建 ' + nodeId + '。可以修改 data，再尝试连接其他节点。';
  }

  private handleNodeTap(nodeId: string): void {
    if (this.connectionSourceId !== '') {
      const sourceId = this.connectionSourceId;
      const nextDocument = setNext(this.document, sourceId, nodeId);
      this.connectionSourceId = '';
      if (nextDocument !== null) {
        this.applyDocument(nextDocument);
        this.selectedId = nodeId;
        this.syncSelectedValueInput();
        this.message = sourceId + ' 的 next 现在指向 ' + nodeId + '。';
      }
      return;
    }
    this.selectedId = nodeId;
    this.syncSelectedValueInput();
    this.message = '已选择 ' + nodeId + '。可以修改 data、设为 head 或连接 next。';
  }

  private applySelectedValue(): void {
    if (this.selectedId === '') {
      this.message = '请先选择一个节点。';
      return;
    }
    const rawValue = this.valueInput.trim();
    const nextValue = Number(rawValue);
    if (rawValue.length === 0 || nextValue % 1 !== 0) {
      this.message = '请输入有效整数，例如 10 或 -3。';
      return;
    }
    const nodeId = this.selectedId;
    const nextDocument = setNodeValue(this.document, nodeId, nextValue);
    if (nextDocument !== null) {
      this.applyDocument(nextDocument);
      this.message = nodeId + '.data 已更新为 ' + nextValue.toString() + '，生成的 C++ 代码已同步。';
    }
  }

  private beginConnection(): void {
    if (this.connectionSourceId !== '') {
      this.connectionSourceId = '';
      this.message = '已取消连接操作。';
      return;
    }
    if (this.selectedId === '') {
      this.message = '请先选择一个起点节点。';
      return;
    }
    this.connectionSourceId = this.selectedId;
    this.message = '正在编辑 ' + this.selectedId + ' 的 next：请点击目标节点。';
  }

  private disconnectSelected(): void {
    if (this.selectedId === '') {
      this.message = '请先选择需要断开 next 的节点。';
      return;
    }
    const nextDocument = setNext(this.document, this.selectedId, null);
    if (nextDocument !== null) {
      this.applyDocument(nextDocument);
      this.message = this.selectedId + ' 的 next 已设为 nullptr。';
    }
  }

  private setSelectedAsHead(): void {
    if (this.selectedId === '') {
      this.message = '请先选择一个节点。';
      return;
    }
    const nextDocument = setHead(this.document, this.selectedId);
    if (nextDocument !== null) {
      this.applyDocument(nextDocument);
      this.message = this.selectedId + ' 现在是 head。';
    }
  }

  private deleteSelectedNode(): void {
    if (this.selectedId === '') {
      this.message = '请先选择要删除的节点。';
      return;
    }
    const removedId = this.selectedId;
    const nextDocument = deleteNode(this.document, removedId);
    if (nextDocument !== null) {
      this.applyDocument(nextDocument);
      this.selectedId = '';
      this.connectionSourceId = '';
      this.syncSelectedValueInput();
      this.message = '已删除 ' + removedId + '，指向它的 next 已断开；可以撤销恢复。';
    }
  }

  private moveSelectedNode(nodeId: string, x: number, y: number): void {
    const nextDocument = moveNode(this.document, nodeId, x, y);
    if (nextDocument !== null) {
      this.applyDocument(nextDocument);
      this.message = '节点位置已改变，指针关系保持不变。';
    }
  }

  private undo(): void {
    if (this.undoStack.length === 0) {
      return;
    }
    this.redoStack.push(cloneDocument(this.document));
    const previous = this.undoStack.pop();
    if (previous !== undefined) {
      this.document = previous;
      this.canUndo = this.undoStack.length > 0;
      this.canRedo = true;
      this.connectionSourceId = '';
      this.refreshDerivedState();
      this.message = '已撤销上一步操作。';
    }
  }

  private redo(): void {
    if (this.redoStack.length === 0) {
      return;
    }
    this.undoStack.push(cloneDocument(this.document));
    const next = this.redoStack.pop();
    if (next !== undefined) {
      this.document = next;
      this.canUndo = true;
      this.canRedo = this.redoStack.length > 0;
      this.connectionSourceId = '';
      this.refreshDerivedState();
      this.message = '已恢复操作。';
    }
  }

  private clampCodePanelX(value: number): number {
    if (this.viewportWidth <= 0) {
      return Math.max(0, value);
    }
    return Math.max(0, Math.min(value, this.viewportWidth - this.codePanelWidth));
  }

  private clampCodePanelY(value: number): number {
    if (this.viewportHeight <= 0) {
      return Math.max(0, value);
    }
    return Math.max(0, Math.min(value, this.viewportHeight - this.codePanelHeight));
  }

  private clampCodePanelWidth(value: number): number {
    const maxWidth = this.viewportWidth > 0
      ? Math.max(360, this.viewportWidth - this.codePanelX - 12)
      : 1200;
    return Math.max(360, Math.min(value, maxWidth));
  }

  private clampCodePanelHeight(value: number): number {
    const maxHeight = this.viewportHeight > 0
      ? Math.max(280, this.viewportHeight - this.codePanelY - 12)
      : 900;
    return Math.max(280, Math.min(value, maxHeight));
  }

  private normalizeCodePanelBounds(): void {
    if (this.viewportWidth > 0) {
      this.codePanelWidth = this.clampCodePanelWidth(this.codePanelWidth);
      this.codePanelX = this.clampCodePanelX(this.codePanelX);
    }
    if (this.viewportHeight > 0) {
      this.codePanelHeight = this.clampCodePanelHeight(this.codePanelHeight);
      this.codePanelY = this.clampCodePanelY(this.codePanelY);
    }
  }

  drawConnections(): void {
    if (!this.canvasReady) {
      return;
    }
    this.canvasContext.clearRect(0, 0, 1800, 900);
    this.canvasContext.strokeStyle = '#91A0AE';
    this.canvasContext.lineWidth = 2.5;

    for (let i = 0; i < this.document.nodes.length; i++) {
      const source = this.document.nodes[i];
      if (source.nextId === null) {
        continue;
      }
      const target = findNode(this.document, source.nextId);
      if (target === null) {
        continue;
      }

      let startX = source.position.x + 136;
      let endX = target.position.x;
      if (target.position.x < source.position.x) {
        startX = source.position.x;
        endX = target.position.x + 136;
      }
      const startY = source.position.y + 44;
      const endY = target.position.y + 44;

      this.canvasContext.beginPath();
      if (source.id === target.id) {
        this.canvasContext.moveTo(source.position.x + 68, source.position.y);
        this.canvasContext.bezierCurveTo(
          source.position.x + 150, source.position.y - 70,
          source.position.x + 160, source.position.y + 125,
          source.position.x + 76, source.position.y + 88
        );
      } else {
        this.canvasContext.moveTo(startX, startY);
        this.canvasContext.lineTo(endX, endY);
      }
      this.canvasContext.stroke();

      const angle = Math.atan2(endY - startY, endX - startX);
      this.canvasContext.beginPath();
      this.canvasContext.moveTo(endX, endY);
      this.canvasContext.lineTo(
        endX - 10 * Math.cos(angle - 0.45),
        endY - 10 * Math.sin(angle - 0.45)
      );
      this.canvasContext.moveTo(endX, endY);
      this.canvasContext.lineTo(
        endX - 10 * Math.cos(angle + 0.45),
        endY - 10 * Math.sin(angle + 0.45)
      );
      this.canvasContext.stroke();
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: 12 }) {
      Row() {
        Column({ space: 3 }) {
          Text('AlgoLab')
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor('#17212B')
          Text('单链表 · 自由实验')
            .fontSize(12)
            .fontColor('#718096')
        }
        Blank()
        Button('＋ 节点')
          .onClick(() => this.addNewNode())
      }
      .width('100%')

      // Separate structure actions from value/history controls for a calmer
      // landscape tablet toolbar.
      Row({ space: 8 }) {
        Button(this.connectionSourceId === '' ? '连接 next' : '取消连接')
          .type(ButtonType.Normal)
          .onClick(() => this.beginConnection())
        Button('断开')
          .type(ButtonType.Normal)
          .onClick(() => this.disconnectSelected())
        Button('设为 head')
          .type(ButtonType.Normal)
          .onClick(() => this.setSelectedAsHead())
        Button('删除节点')
          .type(ButtonType.Normal)
          .onClick(() => this.deleteSelectedNode())
      }
      .width('100%')

      Row({ space: 8 }) {
        if (this.selectedId !== '') {
          Text(this.selectedId + '.data')
            .fontSize(12)
            .fontColor('#52616B')
          TextInput({ text: this.valueInput, placeholder: '整数' })
            .width(96)
            .height(40)
            .onChange((value: string) => {
              this.valueInput = value;
            })
          Button('应用')
            .type(ButtonType.Normal)
            .onClick(() => this.applySelectedValue())
        }
        Button('撤销')
          .enabled(this.canUndo)
          .type(ButtonType.Normal)
          .onClick(() => this.undo())
        Button('重做')
          .enabled(this.canRedo)
          .type(ButtonType.Normal)
          .onClick(() => this.redo())
        Button(this.showCode ? '收起代码' : '查看 C++')
          .type(ButtonType.Capsule)
          .onClick(() => {
            this.showCode = !this.showCode;
            if (this.showCode) {
              this.normalizeCodePanelBounds();
            }
          })
      }
      .width('100%')

      Row() {
        Text(this.statusText)
          .fontSize(12)
          .fontColor('#147D70')
        Blank()
        if (this.selectedId !== '') {
          Text('选中：' + this.selectedId)
            .fontSize(12)
            .fontColor('#52616B')
        }
      }
      .width('100%')

      Stack() {
        Canvas(this.canvasContext)
          .width('100%')
          .height('100%')
          .backgroundColor('#F4F7F8')
          .onReady(() => {
            this.canvasReady = true;
            this.drawConnections();
          })

        ForEach(
          this.document.nodes,
          (node: LinkedNode) => {
            NodeCard({
              nodeId: node.id,
              nodeValue: node.value,
              nextId: node.nextId,
              positionX: node.position.x,
              positionY: node.position.y,
              selected: this.selectedId === node.id,
              onTap: (id: string) => this.handleNodeTap(id),
              onMove: (id: string, x: number, y: number) => this.moveSelectedNode(id, x, y)
            })
          },
          (node: LinkedNode) => node.id
        )

        if (this.document.nodes.length === 0) {
          Column({ space: 8 }) {
            Text('从一个节点开始')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#334155')
            Text('点击右上角「＋ 节点」，然后尝试拖动它。')
              .fontSize(13)
              .fontColor('#64748B')
          }
          .alignItems(HorizontalAlign.Center)
          .position({ x: 30, y: 150 })
        }
      }
      .width('100%')
      .height(480)
      .borderRadius(18)
      .clip(true)

      Text(this.message)
        .fontSize(13)
        .fontColor('#52616B')
        .width('100%')

      }
      .padding(16)
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')

      // A separate overlay keeps the code workspace independent from the
      // linked-list canvas and the page's normal vertical layout.
      if (this.showCode) {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Text('⠿ 移动')
              .fontSize(13)
              .fontColor('#52616B')
              .width(64)
              .height(36)
              .textAlign(TextAlign.Center)
              .gesture(
                PanGesture({ fingers: 1, distance: 2 })
                  .onActionStart(() => {
                    this.panelDragStartX = this.codePanelX;
                    this.panelDragStartY = this.codePanelY;
                  })
                  .onActionUpdate((event: GestureEvent | undefined) => {
                    if (event !== undefined) {
                      this.codePanelX = this.clampCodePanelX(this.panelDragStartX + event.offsetX);
                      this.codePanelY = this.clampCodePanelY(this.panelDragStartY + event.offsetY);
                    }
                  })
                  .onActionEnd((event: GestureEvent | undefined) => {
                    if (event !== undefined) {
                      this.codePanelX = this.clampCodePanelX(this.panelDragStartX + event.offsetX);
                      this.codePanelY = this.clampCodePanelY(this.panelDragStartY + event.offsetY);
                    }
                  })
              )
            Text('由当前结构生成的 C++')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#17212B')
            Blank()
            Button('收起')
              .type(ButtonType.Capsule)
              .onClick(() => {
                this.showCode = false;
              })
          }
          .width('100%')
          .height(40)
          .padding({ left: 4, right: 4 })
          .backgroundColor('#E9EEF3')
          .borderRadius(10)

          Row({ space: 10 }) {
            Text('关键字').fontSize(9).fontColor('#C792EA')
            Text('类型/函数').fontSize(9).fontColor('#82AAFF')
            Text('字符串').fontSize(9).fontColor('#C3E88D')
            Text('数字').fontSize(9).fontColor('#F78C6C')
            Text('注释').fontSize(9).fontColor('#7FAD7A')
            Text('指针/运算符').fontSize(9).fontColor('#80CBC4')
          }
          .width('100%')
          .height(20)

          Row({ space: 6 }) {
            Text('代码字号')
              .fontSize(10)
              .fontColor('#52616B')
            Button('A−')
              .type(ButtonType.Normal)
              .onClick(() => {
                this.codeFontSize = Math.max(10, this.codeFontSize - 1);
              })
            Text(this.codeFontSize.toString() + ' vp')
              .fontSize(10)
              .fontColor('#52616B')
              .width(42)
              .textAlign(TextAlign.Center)
            Button('A+')
              .type(ButtonType.Normal)
              .onClick(() => {
                this.codeFontSize = Math.min(22, this.codeFontSize + 1);
              })
            Button('小')
              .type(ButtonType.Normal)
              .onClick(() => {
                this.codeFontSize = 11;
              })
            Button('中')
              .type(ButtonType.Normal)
              .onClick(() => {
                this.codeFontSize = 14;
              })
            Button('大')
              .type(ButtonType.Normal)
              .onClick(() => {
                this.codeFontSize = 17;
              })
          }
          .width('100%')
          .height(30)

          Scroll() {
            Column({ space: 2 }) {
              ForEach(this.codeLines, (line: CppDisplayLine) => {
                Row({ space: 6 }) {
                  Text(line.lineNumber.toString())
                    .fontSize(9)
                    .fontColor('#64748B')
                    .fontFamily('monospace')
                    .width(26)
                    .textAlign(TextAlign.End)

                  Scroll() {
                    Text() {
                      ForEach(line.tokens, (token: CppToken) => {
                        Span(formatCppDisplayToken(token.text))
                          .fontSize(this.codeFontSize)
                          .fontColor(token.color)
                          .fontFamily('monospace')
                      }, (token: CppToken) => token.id)
                    }
                    // One Text paragraph owns the entire source line. Span children
                    // only change token color; they cannot distribute tokens as Row items.
                    .width(measureCppLineWidth(line, this.codeFontSize, this.codeLineViewportWidth))
                    .textAlign(TextAlign.Start)
                    .fontSize(this.codeFontSize)
                    .fontFamily('monospace')
                    .height(this.codeFontSize + 11)
                  }
                  .scrollable(ScrollDirection.Horizontal)
                  .layoutWeight(1)
                  .height(this.codeFontSize + 11)
                  .onAreaChange((oldArea: Area, newArea: Area) => {
                    const nextWidth = Number(newArea.width);
                    if (Math.abs(nextWidth - this.codeLineViewportWidth) > 0.5) {
                      this.codeLineViewportWidth = nextWidth;
                    }
                  })

                  if (line.annotationText !== '') {
                    Row({ space: 3 }) {
                      Text('▏')
                        .fontSize(12)
                        .fontColor(line.annotationColor)
                      Text(line.annotationText)
                        .fontSize(12)
                        .fontColor(line.annotationColor)
                        .maxLines(3)
                        .width(178)
                    }
                    .width(198)
                    .height(46)
                  } else {
                    Blank()
                      .width(198)
                  }
                }
                .width('100%')
                .height(Math.max(this.codeFontSize + 19, 48))
                .padding({ top: 1, bottom: 1 })
                .backgroundColor(line.lineNumber % 2 === 0 ? '#1B2733' : '#17212B')
                .borderRadius(3)
              }, (line: CppDisplayLine) => line.lineNumber.toString())

              ForEach(this.warnings, (warning: string) => {
                Text('⚠ ' + warning)
                  .fontSize(10)
                  .fontColor('#FFCB6B')
                  .width('100%')
                  .padding(6)
                  .backgroundColor('#29313B')
                  .borderRadius(6)
              }, (warning: string) => warning)
            }
            .width('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .padding(10)
          .backgroundColor('#17212B')
          .borderRadius(12)

          Row() {
            Text('拖动右侧手柄调整窗口大小')
              .fontSize(10)
              .fontColor('#718096')
            Blank()
            Text('◢')
              .fontSize(24)
              .fontColor('#2563EB')
              .width(48)
              .height(40)
              .textAlign(TextAlign.Center)
              .gesture(
                PanGesture({ fingers: 1, distance: 2 })
                  .onActionStart(() => {
                    this.panelResizeStartWidth = this.codePanelWidth;
                    this.panelResizeStartHeight = this.codePanelHeight;
                  })
                  .onActionUpdate((event: GestureEvent | undefined) => {
                    if (event !== undefined) {
                      this.codePanelWidth = this.clampCodePanelWidth(
                        this.panelResizeStartWidth + event.offsetX
                      );
                      this.codePanelHeight = this.clampCodePanelHeight(
                        this.panelResizeStartHeight + event.offsetY
                      );
                    }
                  })
                  .onActionEnd((event: GestureEvent | undefined) => {
                    if (event !== undefined) {
                      this.codePanelWidth = this.clampCodePanelWidth(
                        this.panelResizeStartWidth + event.offsetX
                      );
                      this.codePanelHeight = this.clampCodePanelHeight(
                        this.panelResizeStartHeight + event.offsetY
                      );
                    }
                  })
              )
          }
          .width('100%')
          .height(40)
        }
        .width(this.codePanelWidth)
        .height(this.codePanelHeight)
        .padding(10)
        .backgroundColor('#F7F8FA')
        .border({ width: 1, color: '#D7E0E8' })
        .borderRadius(16)
        .position({ x: this.codePanelX, y: this.codePanelY })
        .zIndex(10)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .onAreaChange((oldArea: Area, newArea: Area) => {
      this.viewportWidth = Number(newArea.width);
      this.viewportHeight = Number(newArea.height);
      this.normalizeCodePanelBounds();
    })
  }
}
