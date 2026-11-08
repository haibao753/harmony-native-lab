import {
  LinkedListDocument,
  LinkedNode,
  MemoryNodeSnapshot,
  MemorySnapshot,
  addNode,
  createMemorySnapshot,
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
import { CodeLineLink, generateCpp } from '../codegen/CppLinkedListGenerator';
import { highlightCpp, formatCppDisplayToken, measureCppLineWidth, CppDisplayLine, CppToken } from '../codegen/CppSyntaxHighlighter';
import { LinkedListTraceStep, buildTraversalTrace, getLinkedListLesson } from '../domain/LinkedListLessonEngine';
import { TeachingWorkbench } from '../components/TeachingWorkbench';

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
  @Prop isHead: boolean = false;
  onTap: (id: string) => void = (id: string) => {};
  onMove: (id: string, x: number, y: number) => void =
    (id: string, x: number, y: number) => {};

  @State dragOffsetX: number = 0;
  @State dragOffsetY: number = 0;

  build() {
    Column({ space: 5 }) {
      Row({ space: 6 }) {
        Text(this.nodeId)
          .fontSize(11)
          .fontColor('#827D74')
        if (this.isHead) {
          Text('HEAD')
            .fontSize(9)
            .fontColor('#9A6038')
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
            .backgroundColor('#F2E4D8')
            .borderRadius(5)
        }
      }
      Text(this.nodeValue.toString())
        .fontSize(23)
        .fontWeight(FontWeight.Bold)
        .fontColor('#292720')
      Text('next → ' + (this.nextId === null ? 'nullptr' : this.nextId))
        .fontSize(11)
        .fontColor('#716C63')
    }
    .width(136)
    .height(88)
    .padding(10)
    .backgroundColor(this.selected ? '#F6E9DE' : '#FFFEFC')
    .border({
      width: this.selected ? 2 : 1,
      color: this.selected ? '#B96F3F' : '#DED9D0'
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
  @State selectedEdgeSourceId: string = '';
  @State selectedEdgeTargetId: string = '';
  @State selectedCodeLineNumber: number = 0;
  @State valueInput: string = '';
  @State connectionSourceId: string = '';
  @State showCode: boolean = false;
  @State showMemory: boolean = false;
  @State showTeaching: boolean = false;
  @State activeLessonId: string = 'node';
  @State traceSteps: LinkedListTraceStep[] = [];
  @State traceStepIndex: number = 0;
  @State predictionChoice: number = -1;
  @State predictionCorrect: boolean = false;
  @State predictionFeedback: string = '';
  @State traceStepTitle: string = '';
  @State traceStepExplanation: string = '';
  @State traceCurrentLabel: string = 'current = nullptr';
  @State traceVisitedLabel: string = '尚未访问';
  @State traceCodeLineNumber: number = 0;
  @State traceCodeLineText: string = '';
  @State traceQuestion: string = '';
  @State traceOptionA: string = '';
  @State traceOptionB: string = '';
  @State traceOptionC: string = '';
  // Used to tune the docked inspector width for narrower tablet windows.
  @State viewportWidth: number = 0;
  // Width of the actual horizontal code viewport. Short source lines must
  // occupy at least this width; otherwise Scroll may center their content.
  @State codeLineViewportWidth: number = 0;
  @State generatedCode: string = '';
  @State codeLines: CppDisplayLine[] = [];
  @State codeLineLinks: CodeLineLink[] = [];
  @State memorySnapshot: MemorySnapshot = createMemorySnapshot(createEmptyDocument());
  // 11 is the original compact size; font controls affect only C++ source tokens.
  @State codeFontSize: number = 14;
  @State showAnnotations: boolean = true;
  @State showCodeSettings: boolean = false;
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
    this.codeLineLinks = generated.lineLinks;
    this.memorySnapshot = createMemorySnapshot(this.document);
    this.selectedCodeLineNumber = 0;
    this.selectedEdgeSourceId = '';
    this.selectedEdgeTargetId = '';
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


  private clearTrace(): void {
    this.traceSteps = [];
    this.traceStepIndex = 0;
    this.predictionChoice = -1;
    this.predictionCorrect = false;
    this.predictionFeedback = '';
    this.traceStepTitle = '';
    this.traceStepExplanation = '';
    this.traceCurrentLabel = 'current = nullptr';
    this.traceVisitedLabel = '尚未访问';
    this.traceCodeLineNumber = 0;
    this.traceCodeLineText = '';
    this.traceQuestion = '';
    this.traceOptionA = '';
    this.traceOptionB = '';
    this.traceOptionC = '';
  }

  private selectLesson(lessonId: string): void {
    this.activeLessonId = lessonId;
    this.clearTrace();
  }

  private startTraversalTrace(): void {
    if (this.document.nodes.length === 0) {
      this.message = '请先创建至少一个节点，再运行链表遍历演示。';
      return;
    }
    this.activeLessonId = 'traversal';
    this.traceSteps = buildTraversalTrace(this.document, this.generatedCode);
    this.traceStepIndex = 0;
    this.predictionChoice = -1;
    this.predictionCorrect = false;
    this.predictionFeedback = '';
    this.showTeaching = true;
    this.showMemory = false;
    this.showCode = false;
    this.applyTraceStep(0);
  }

  private applyTraceStep(index: number): void {
    if (index < 0 || index >= this.traceSteps.length) {
      return;
    }
    const step = this.traceSteps[index];
    this.traceStepTitle = step.title;
    this.traceStepExplanation = step.explanation;
    this.traceCurrentLabel = step.currentId === ''
      ? 'current = nullptr'
      : 'current = &' + step.currentId;
    this.traceVisitedLabel = step.visitedLabel;
    this.traceCodeLineNumber = step.codeLineNumber;
    this.traceCodeLineText = '';
    if (step.codeLineNumber > 0) {
      const lines = this.generatedCode.split('\n');
      if (step.codeLineNumber <= lines.length) {
        this.traceCodeLineText = lines[step.codeLineNumber - 1].trim();
      }
    }
    this.traceQuestion = step.question;
    this.traceOptionA = step.optionA;
    this.traceOptionB = step.optionB;
    this.traceOptionC = step.optionC;
    this.selectedId = step.activeNodeId;
    this.selectedEdgeSourceId = step.edgeSourceId;
    this.selectedEdgeTargetId = step.edgeTargetId;
    this.selectedCodeLineNumber = step.codeLineNumber;
    this.syncSelectedValueInput();
    this.statusText = this.traceCurrentLabel;
    this.message = step.explanation;
    this.drawConnections();
  }

  private answerPrediction(option: number): void {
    if (this.traceStepIndex >= this.traceSteps.length) {
      return;
    }
    const step = this.traceSteps[this.traceStepIndex];
    this.predictionChoice = option;
    this.predictionCorrect = option === step.correctOption;
    this.predictionFeedback = (this.predictionCorrect ? '判断正确。' : '正确思路：') + step.feedback;
  }

  private previousTraceStep(): void {
    if (this.traceStepIndex <= 0) {
      return;
    }
    this.traceStepIndex--;
    this.predictionChoice = -1;
    this.predictionCorrect = false;
    this.predictionFeedback = '';
    this.applyTraceStep(this.traceStepIndex);
  }

  private nextTraceStep(): void {
    if (this.predictionChoice < 0 || this.traceStepIndex >= this.traceSteps.length - 1) {
      return;
    }
    this.traceStepIndex++;
    this.predictionChoice = -1;
    this.predictionCorrect = false;
    this.predictionFeedback = '';
    this.applyTraceStep(this.traceStepIndex);
  }

  private restartTrace(): void {
    if (this.traceSteps.length === 0) {
      this.startTraversalTrace();
      return;
    }
    this.traceStepIndex = 0;
    this.predictionChoice = -1;
    this.predictionCorrect = false;
    this.predictionFeedback = '';
    this.applyTraceStep(0);
  }

  private openMemoryFromTeaching(): void {
    this.showTeaching = false;
    this.showCode = false;
    this.showMemory = true;
  }

  private openCodeFromTeaching(): void {
    this.showTeaching = false;
    this.showMemory = false;
    this.showCode = true;
  }

  private applyDocument(nextDocument: LinkedListDocument): void {
    this.clearTrace();
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
        this.selectedEdgeSourceId = sourceId;
        this.selectedEdgeTargetId = nodeId;
        this.syncSelectedValueInput();
        this.drawConnections();
        this.message = sourceId + ' 的 next 现在指向 ' + nodeId + '。';
      }
      return;
    }
    this.selectedId = nodeId;
    this.selectedEdgeSourceId = '';
    this.selectedEdgeTargetId = '';
    this.selectedCodeLineNumber = 0;
    this.syncSelectedValueInput();
    this.drawConnections();
    this.message = '已选择 ' + nodeId + '。可以修改 data、设为 head 或连接 next。';
  }

  private handleMemoryNodeTap(nodeId: string): void {
    if (findNode(this.document, nodeId) === null) {
      return;
    }
    this.selectedId = nodeId;
    this.selectedEdgeSourceId = '';
    this.selectedEdgeTargetId = '';
    this.selectedCodeLineNumber = 0;
    this.syncSelectedValueInput();
    this.drawConnections();
    this.message = '内存对象 ' + nodeId + ' 已选中；画布中的对应节点也已同步选中。';
  }

  private handleCodeLineTap(lineNumber: number): void {
    let selectedLink: CodeLineLink | null = null;
    for (let i = 0; i < this.codeLineLinks.length; i++) {
      if (this.codeLineLinks[i].lineNumber === lineNumber) {
        selectedLink = this.codeLineLinks[i];
        break;
      }
    }
    if (selectedLink === null || findNode(this.document, selectedLink.nodeId) === null) {
      return;
    }

    this.selectedCodeLineNumber = lineNumber;
    this.selectedId = selectedLink.nodeId;
    this.selectedEdgeSourceId = selectedLink.role === 'next' ? selectedLink.nodeId : '';
    this.selectedEdgeTargetId = selectedLink.role === 'next' && selectedLink.targetNodeId !== null
      ? selectedLink.targetNodeId
      : '';
    this.syncSelectedValueInput();
    this.drawConnections();

    if (selectedLink.role === 'next' && selectedLink.targetNodeId !== null) {
      this.message = 'C++ 第 ' + lineNumber.toString() + ' 行对应 ' +
        selectedLink.nodeId + ' → ' + selectedLink.targetNodeId + ' 这条指针连接。';
    } else if (selectedLink.role === 'head') {
      this.message = 'C++ 第 ' + lineNumber.toString() + ' 行设置 head，画布已定位到 ' +
        selectedLink.nodeId + '。';
    } else if (selectedLink.role === 'delete') {
      this.message = 'C++ 第 ' + lineNumber.toString() + ' 行释放 ' + selectedLink.nodeId + '。';
    } else {
      this.message = 'C++ 第 ' + lineNumber.toString() + ' 行创建 ' + selectedLink.nodeId + '。';
    }
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
      this.clearTrace();
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
      this.clearTrace();
      this.canUndo = true;
      this.canRedo = this.redoStack.length > 0;
      this.connectionSourceId = '';
      this.refreshDerivedState();
      this.message = '已恢复操作。';
    }
  }

  drawConnections(): void {
    if (!this.canvasReady) {
      return;
    }
    this.canvasContext.clearRect(0, 0, 1800, 900);
    this.canvasContext.strokeStyle = '#AAA398';
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

      const isHighlighted = source.id === this.selectedEdgeSourceId &&
        source.nextId === this.selectedEdgeTargetId;
      this.canvasContext.strokeStyle = isHighlighted ? '#B96F3F' : '#AAA398';
      this.canvasContext.lineWidth = isHighlighted ? 4 : 2.5;

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
      Column({ space: 14 }) {
        // Brand header: quiet typography, one clear primary action.
        Row({ space: 12 }) {
          Column({ space: 2 }) {
            Text('AlgoLab')
              .fontSize(27)
              .fontWeight(FontWeight.Bold)
              .fontColor('#292720')
            Text('DATA STRUCTURE LABORATORY')
              .fontSize(9)
              .fontWeight(FontWeight.Medium)
              .fontColor('#928B80')
              .letterSpacing(1.4)
          }
          Blank()
          Text('1.2  /  TEACHING WORKBENCH')
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor('#8C857A')
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor('#ECE8E0')
            .borderRadius(8)
          Button(this.showTeaching ? '关闭教学' : '教学工作台')
            .type(ButtonType.Normal)
            .height(40)
            .padding({ left: 14, right: 14 })
            .backgroundColor(this.showTeaching ? '#F2E4D8' : '#EAE6DE')
            .fontColor(this.showTeaching ? '#9A6038' : '#48443C')
            .borderRadius(11)
            .onClick(() => {
              this.showTeaching = !this.showTeaching;
              if (this.showTeaching) {
                this.showMemory = false;
                this.showCode = false;
              }
            })
          Button('＋ 新建节点')
            .type(ButtonType.Normal)
            .height(40)
            .padding({ left: 18, right: 18 })
            .backgroundColor('#292720')
            .fontColor('#FFFFFF')
            .borderRadius(11)
            .onClick(() => this.addNewNode())
        }
        .width('100%')
        .height(54)

        // Primary structure actions are grouped; destructive action is visually quiet.
        Row({ space: 8 }) {
          Button(this.connectionSourceId === '' ? '连接 next' : '取消连接')
            .type(ButtonType.Normal)
            .height(38)
            .backgroundColor(this.connectionSourceId === '' ? '#EAE6DE' : '#F3E3D5')
            .fontColor(this.connectionSourceId === '' ? '#48443C' : '#A35F32')
            .borderRadius(9)
            .onClick(() => this.beginConnection())
          Button('断开 next')
            .type(ButtonType.Normal)
            .height(38)
            .backgroundColor('#EAE6DE')
            .fontColor('#48443C')
            .borderRadius(9)
            .onClick(() => this.disconnectSelected())
          Button('设为 head')
            .type(ButtonType.Normal)
            .height(38)
            .backgroundColor('#EAE6DE')
            .fontColor('#48443C')
            .borderRadius(9)
            .onClick(() => this.setSelectedAsHead())
          Button('删除节点')
            .type(ButtonType.Normal)
            .height(38)
            .backgroundColor('#F1EAE4')
            .fontColor('#9A5B43')
            .borderRadius(9)
            .onClick(() => this.deleteSelectedNode())
          Blank()
        }
        .width('100%')

        // Contextual editing and history stay in a compact secondary strip.
        Row({ space: 8 }) {
          if (this.selectedId !== '') {
            Text(this.selectedId + '.data')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#716C63')
            TextInput({ text: this.valueInput, placeholder: '整数' })
              .width(92)
              .height(36)
              .backgroundColor('#ECE8E0')
              .borderRadius(8)
              .onChange((value: string) => {
                this.valueInput = value;
              })
            Button('应用')
              .type(ButtonType.Normal)
              .height(36)
              .backgroundColor('#DCC7B5')
              .fontColor('#5A3925')
              .borderRadius(8)
              .onClick(() => this.applySelectedValue())
          } else {
            Text('选择节点后可编辑 data')
              .fontSize(11)
              .fontColor('#938C81')
          }
          Blank()
          Button('撤销')
            .enabled(this.canUndo)
            .type(ButtonType.Normal)
            .height(34)
            .backgroundColor('#ECE8E0')
            .fontColor('#514C44')
            .borderRadius(8)
            .onClick(() => this.undo())
          Button('重做')
            .enabled(this.canRedo)
            .type(ButtonType.Normal)
            .height(34)
            .backgroundColor('#ECE8E0')
            .fontColor('#514C44')
            .borderRadius(8)
            .onClick(() => this.redo())
        }
        .width('100%')
        .height(38)

        // Main work area: the canvas owns the space; inspectors dock to its side.
        Row({ space: 14 }) {
          Column({ space: 10 }) {
            Row({ space: 8 }) {
              Column({ space: 2 }) {
                Text('链表结构')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#292720')
                Text('点击选择 · 拖动调整位置 · 连接 next 建立引用')
                  .fontSize(10)
                  .fontColor('#8A847A')
              }
              Blank()
              Text(this.document.nodes.length.toString() + ' OBJECTS')
                .fontSize(10)
                .fontWeight(FontWeight.Medium)
                .fontColor('#8A847A')
                .padding({ left: 9, right: 9, top: 6, bottom: 6 })
                .backgroundColor('#EEEAE2')
                .borderRadius(7)
            }
            .width('100%')

            Stack() {
              Canvas(this.canvasContext)
                .width('100%')
                .height('100%')
                .backgroundColor('#F1EFE9')
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
                    isHead: this.document.headId === node.id,
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
                Column({ space: 9 }) {
                  Text('从一个节点开始')
                    .fontSize(19)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#39352E')
                  Text('创建节点，然后观察数据、指针与内存引用如何变化。')
                    .fontSize(12)
                    .fontColor('#898378')
                  Button('＋ 创建第一个节点')
                    .type(ButtonType.Normal)
                    .height(36)
                    .backgroundColor('#292720')
                    .fontColor('#FFFFFF')
                    .borderRadius(9)
                    .onClick(() => this.addNewNode())
                }
                .alignItems(HorizontalAlign.Center)
                .position({ x: 30, y: 132 })
              }
            }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('#F1EFE9')
            .borderRadius(16)
            .clip(true)

            Row({ space: 8 }) {
              Text(this.statusText)
                .fontSize(11)
                .fontColor('#9A6038')
              Text('·')
                .fontSize(11)
                .fontColor('#B4ADA2')
              Text(this.message)
                .fontSize(11)
                .fontColor('#777168')
                .maxLines(1)
                .layoutWeight(1)
            }
            .width('100%')
          }
          .layoutWeight(1)
          .height('100%')
          .padding(14)
          .backgroundColor('#FFFEFC')
          .border({ width: 1, color: '#E5E0D7' })
          .borderRadius(18)


          // Teaching workbench is the guided learning surface. It never mutates
          // the linked-list document; it only drives the active pointer/code highlights.
          if (this.showTeaching) {
            TeachingWorkbench({
              activeLessonId: this.activeLessonId,
              lessonTitle: getLinkedListLesson(this.activeLessonId).title,
              lessonSubtitle: getLinkedListLesson(this.activeLessonId).subtitle,
              lessonConcept: getLinkedListLesson(this.activeLessonId).concept,
              lessonKeyPoint: getLinkedListLesson(this.activeLessonId).keyPoint,
              lessonMisconception: getLinkedListLesson(this.activeLessonId).misconception,
              lessonTask: getLinkedListLesson(this.activeLessonId).task,
              hasDocument: this.document.nodes.length > 0,
              traceReady: this.traceSteps.length > 0,
              stepIndex: this.traceStepIndex,
              stepCount: this.traceSteps.length,
              stepTitle: this.traceStepTitle,
              stepExplanation: this.traceStepExplanation,
              currentLabel: this.traceCurrentLabel,
              visitedLabel: this.traceVisitedLabel,
              codeLineNumber: this.traceCodeLineNumber,
              codeLineText: this.traceCodeLineText,
              question: this.traceQuestion,
              optionA: this.traceOptionA,
              optionB: this.traceOptionB,
              optionC: this.traceOptionC,
              selectedOption: this.predictionChoice,
              predictionCorrect: this.predictionCorrect,
              predictionFeedback: this.predictionFeedback,
              canGoPrevious: this.traceSteps.length > 0 && this.traceStepIndex > 0,
              canGoNext: this.predictionChoice >= 0 && this.traceStepIndex < this.traceSteps.length - 1,
              onSelectLesson: (lessonId: string) => this.selectLesson(lessonId),
              onStartTrace: () => this.startTraversalTrace(),
              onAnswer: (option: number) => this.answerPrediction(option),
              onPrevious: () => this.previousTraceStep(),
              onNext: () => this.nextTraceStep(),
              onRestart: () => this.restartTrace(),
              onOpenMemory: () => this.openMemoryFromTeaching(),
              onOpenCode: () => this.openCodeFromTeaching(),
              onClose: () => {
                this.showTeaching = false;
              }
            })
          }

          // Memory inspector: a docked companion to the canvas, never a floating obstruction.
          if (this.showMemory) {
            Column({ space: 12 }) {
              Row({ space: 8 }) {
                Column({ space: 2 }) {
                  Text('内存检查器')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#292720')
                  Text('SYMBOLIC MEMORY')
                    .fontSize(9)
                    .fontColor('#928B80')
                    .letterSpacing(1.1)
                }
                Blank()
                Button('×')
                  .type(ButtonType.Normal)
                  .width(32)
                  .height(32)
                  .backgroundColor('#EEEAE2')
                  .fontColor('#625C52')
                  .borderRadius(9)
                  .onClick(() => {
                    this.showMemory = false;
                  })
              }
              .width('100%')

              Column({ space: 5 }) {
                Text('HEAD POINTER')
                  .fontSize(9)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#928B80')
                Text(this.memorySnapshot.headId === null
                  ? 'nullptr'
                  : '&' + this.memorySnapshot.headId)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#9A6038')
                  .fontFamily('monospace')
              }
              .width('100%')
              .padding(13)
              .backgroundColor('#F3E9DF')
              .borderRadius(11)

              Row({ space: 6 }) {
                Column({ space: 2 }) {
                  Text(this.memorySnapshot.reachableCount.toString())
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#4D594A')
                  Text('可达')
                    .fontSize(10)
                    .fontColor('#827D74')
                }
                .layoutWeight(1)
                .padding(10)
                .backgroundColor('#F0F1EA')
                .borderRadius(9)
                Column({ space: 2 }) {
                  Text(this.memorySnapshot.unreachableCount.toString())
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.memorySnapshot.unreachableCount > 0 ? '#A45F3D' : '#4D594A')
                  Text('不可达')
                    .fontSize(10)
                    .fontColor('#827D74')
                }
                .layoutWeight(1)
                .padding(10)
                .backgroundColor('#F3EEE8')
                .borderRadius(9)
              }
              .width('100%')

              if (this.memorySnapshot.hasCycle || this.memorySnapshot.hasSharedSuccessor) {
                Row({ space: 6 }) {
                  if (this.memorySnapshot.hasCycle) {
                    Text('检测到环')
                      .fontSize(10)
                      .fontColor('#A45F3D')
                      .padding({ left: 7, right: 7, top: 5, bottom: 5 })
                      .backgroundColor('#F3E6DC')
                      .borderRadius(7)
                  }
                  if (this.memorySnapshot.hasSharedSuccessor) {
                    Text('共享后继')
                      .fontSize(10)
                      .fontColor('#78634F')
                      .padding({ left: 7, right: 7, top: 5, bottom: 5 })
                      .backgroundColor('#EEEAE2')
                      .borderRadius(7)
                  }
                }
                .width('100%')
              }

              Scroll() {
                Column({ space: 8 }) {
                  if (this.memorySnapshot.nodes.length === 0) {
                    Text('还没有节点。先在画布上创建一个节点。')
                      .fontSize(12)
                      .fontColor('#898378')
                      .width('100%')
                      .padding(12)
                  }
                  ForEach(this.memorySnapshot.nodes, (memoryNode: MemoryNodeSnapshot) => {
                    Column({ space: 8 }) {
                      Row({ space: 6 }) {
                        Text(memoryNode.id)
                          .fontSize(13)
                          .fontWeight(FontWeight.Bold)
                          .fontColor('#292720')
                        if (memoryNode.isHead) {
                          Text('HEAD')
                            .fontSize(8)
                            .fontColor('#9A6038')
                            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                            .backgroundColor('#F3E6DC')
                            .borderRadius(5)
                        }
                        if (memoryNode.isCycleEntry) {
                          Text('环入口')
                            .fontSize(8)
                            .fontColor('#A45F3D')
                            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                            .backgroundColor('#F5EBD9')
                            .borderRadius(5)
                        }
                        Blank()
                        Text(memoryNode.isReachable ? '可达' : '不可达')
                          .fontSize(10)
                          .fontColor(memoryNode.isReachable ? '#66765B' : '#A45F3D')
                      }
                      Row({ space: 8 }) {
                        Text('data')
                          .fontSize(10)
                          .fontColor('#928B80')
                          .width(38)
                        Text(memoryNode.data.toString())
                          .fontSize(13)
                          .fontColor('#39352E')
                          .fontFamily('monospace')
                      }
                      Row({ space: 8 }) {
                        Text('next')
                          .fontSize(10)
                          .fontColor('#928B80')
                          .width(38)
                        Text(memoryNode.nextId === null ? 'nullptr' : '&' + memoryNode.nextId)
                          .fontSize(12)
                          .fontColor(memoryNode.nextId === null ? '#A49D92' : '#9A6038')
                          .fontFamily('monospace')
                      }
                      if (memoryNode.incomingCount > 1) {
                        Text('共享后继 · ' + memoryNode.incomingCount.toString() + ' 个引用')
                          .fontSize(9)
                          .fontColor('#78634F')
                      }
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor(this.selectedId === memoryNode.id ? '#F6E9DE' : '#F7F5F0')
                    .border({
                      width: this.selectedId === memoryNode.id ? 1.5 : 1,
                      color: this.selectedId === memoryNode.id ? '#B96F3F' : '#E7E2D9'
                    })
                    .borderRadius(10)
                    .onClick(() => this.handleMemoryNodeTap(memoryNode.id))
                  }, (memoryNode: MemoryNodeSnapshot) => memoryNode.id)
                }
                .width('100%')
              }
              .layoutWeight(1)
              .width('100%')

              Text('N1 等是教学对象标识，不是真实内存地址。')
                .fontSize(9)
                .fontColor('#928B80')
                .maxLines(2)
                .width('100%')
            }
            .width(this.viewportWidth > 1250 ? 360 : 320)
            .height('100%')
            .padding(14)
            .backgroundColor('#FFFEFC')
            .border({ width: 1, color: '#E5E0D7' })
            .borderRadius(18)
          }

          // C++ inspector: code, annotations and controls share one quiet surface.
          if (this.showCode) {
            Column({ space: 9 }) {
              Row({ space: 8 }) {
                Column({ space: 2 }) {
                  Text('C++ 代码')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#292720')
                  Text('GENERATED FROM CURRENT STRUCTURE')
                    .fontSize(8)
                    .fontColor('#928B80')
                    .letterSpacing(0.7)
                }
                Blank()
                Button('×')
                  .type(ButtonType.Normal)
                  .width(32)
                  .height(32)
                  .backgroundColor('#EEEAE2')
                  .fontColor('#625C52')
                  .borderRadius(9)
                  .onClick(() => {
                    this.showCode = false;
                  })
              }
              .width('100%')

              Row({ space: 7 }) {
                Button(this.showAnnotations ? '注释开' : '注释关')
                  .type(ButtonType.Normal)
                  .height(30)
                  .backgroundColor(this.showAnnotations ? '#F3E6DC' : '#EEEAE2')
                  .fontColor(this.showAnnotations ? '#9A6038' : '#625C52')
                  .borderRadius(8)
                  .onClick(() => {
                    this.showAnnotations = !this.showAnnotations;
                  })
                Button('字号 ' + this.codeFontSize.toString() + ' ' + (this.showCodeSettings ? '−' : '+'))
                  .type(ButtonType.Normal)
                  .height(30)
                  .backgroundColor('#EEEAE2')
                  .fontColor('#625C52')
                  .borderRadius(8)
                  .onClick(() => {
                    this.showCodeSettings = !this.showCodeSettings;
                  })
              }
              .width('100%')

              if (this.showCodeSettings) {
                Row({ space: 5 }) {
                  Button('A−')
                    .type(ButtonType.Normal)
                    .height(28)
                    .backgroundColor('#EEEAE2')
                    .fontColor('#514C44')
                    .borderRadius(7)
                    .onClick(() => {
                      this.codeFontSize = Math.max(10, this.codeFontSize - 1);
                    })
                  Text(this.codeFontSize.toString() + ' vp')
                    .fontSize(10)
                    .fontColor('#716C63')
                    .width(42)
                    .textAlign(TextAlign.Center)
                  Button('A+')
                    .type(ButtonType.Normal)
                    .height(28)
                    .backgroundColor('#EEEAE2')
                    .fontColor('#514C44')
                    .borderRadius(7)
                    .onClick(() => {
                      this.codeFontSize = Math.min(22, this.codeFontSize + 1);
                    })
                  Button('小')
                    .type(ButtonType.Normal)
                    .height(28)
                    .backgroundColor('#EEEAE2')
                    .fontColor('#514C44')
                    .borderRadius(7)
                    .onClick(() => {
                      this.codeFontSize = 11;
                    })
                  Button('中')
                    .type(ButtonType.Normal)
                    .height(28)
                    .backgroundColor('#EEEAE2')
                    .fontColor('#514C44')
                    .borderRadius(7)
                    .onClick(() => {
                      this.codeFontSize = 14;
                    })
                  Button('大')
                    .type(ButtonType.Normal)
                    .height(28)
                    .backgroundColor('#EEEAE2')
                    .fontColor('#514C44')
                    .borderRadius(7)
                    .onClick(() => {
                      this.codeFontSize = 17;
                    })
                }
                .width('100%')
              }

              Scroll() {
                Column({ space: 5 }) {
                  ForEach(this.codeLines, (line: CppDisplayLine) => {
                    Column({ space: 4 }) {
                      Row({ space: 5 }) {
                        Text(line.lineNumber.toString())
                          .fontSize(9)
                          .fontColor('#A49D92')
                          .fontFamily('monospace')
                          .width(22)
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
                          .width(measureCppLineWidth(line, this.codeFontSize, this.codeLineViewportWidth))
                          .textAlign(TextAlign.Start)
                          .fontSize(this.codeFontSize)
                          .fontFamily('monospace')
                          .height(this.codeFontSize + 12)
                        }
                        .scrollable(ScrollDirection.Horizontal)
                        .layoutWeight(1)
                        .height(this.codeFontSize + 12)
                        .onAreaChange((oldArea: Area, newArea: Area) => {
                          const nextWidth = Number(newArea.width);
                          if (Math.abs(nextWidth - this.codeLineViewportWidth) > 0.5) {
                            this.codeLineViewportWidth = nextWidth;
                          }
                        })
                      }
                      .width('100%')
                      .padding({ top: 4, bottom: 4, left: 5, right: 5 })
                      .backgroundColor(line.lineNumber === this.selectedCodeLineNumber
                        ? '#3D342D'
                        : (line.lineNumber % 2 === 0 ? '#292A29' : '#242524'))
                      .borderRadius(5)
                      .onClick(() => this.handleCodeLineTap(line.lineNumber))

                      if (this.showAnnotations && line.annotationText !== '') {
                        Text(line.annotationText)
                          .fontSize(12)
                          .fontColor('#8B8378')
                          .maxLines(3)
                          .width('100%')
                          .padding({ left: 30, right: 4, top: 1, bottom: 3 })
                      }
                    }
                    .width('100%')
                  }, (line: CppDisplayLine) => line.lineNumber.toString())

                  ForEach(this.warnings, (warning: string) => {
                    Text('注意 · ' + warning)
                      .fontSize(9)
                      .fontColor('#A45F3D')
                      .width('100%')
                      .padding(8)
                      .backgroundColor('#F3E9DF')
                      .borderRadius(7)
                  }, (warning: string) => warning)
                }
                .width('100%')
              }
              .layoutWeight(1)
              .width('100%')
              .padding(8)
              .backgroundColor('#F4F2ED')
              .borderRadius(10)

              Text('只读预览 · 点击代码行可定位画布节点或指针连接')
                .fontSize(9)
                .fontColor('#928B80')
                .width('100%')
            }
            .width(this.viewportWidth > 1250 ? 440 : 380)
            .height('100%')
            .padding(14)
            .backgroundColor('#FFFEFC')
            .border({ width: 1, color: '#E5E0D7' })
            .borderRadius(18)
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
      .padding(18)
      .width('100%')
      .height('100%')
      .backgroundColor('#F4F2ED')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F2ED')
    .onAreaChange((oldArea: Area, newArea: Area) => {
      this.viewportWidth = Number(newArea.width);
    })
  }
}