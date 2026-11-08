import { LINKED_LIST_LESSONS, LinkedListLesson } from '../domain/LinkedListLessonEngine';

@Component
export struct TeachingWorkbench {
  @Prop activeLessonId: string = 'node';
  @Prop lessonTitle: string = '节点的组成';
  @Prop lessonSubtitle: string = '';
  @Prop lessonConcept: string = '';
  @Prop lessonKeyPoint: string = '';
  @Prop lessonMisconception: string = '';
  @Prop lessonTask: string = '';
  @Prop hasDocument: boolean = false;
  @Prop traceReady: boolean = false;
  @Prop stepIndex: number = 0;
  @Prop stepCount: number = 0;
  @Prop progressPercent: number = 0;
  @Prop isPlaying: boolean = false;
  @Prop canPlay: boolean = false;
  @Prop stepTitle: string = '';
  @Prop stepExplanation: string = '';
  @Prop currentLabel: string = 'current = nullptr';
  @Prop visitedLabel: string = '尚未访问';
  @Prop codeLineNumber: number = 0;
  @Prop codeLineText: string = '';
  @Prop question: string = '';
  @Prop optionA: string = '';
  @Prop optionB: string = '';
  @Prop optionC: string = '';
  @Prop selectedOption: number = -1;
  @Prop predictionCorrect: boolean = false;
  @Prop predictionFeedback: string = '';
  @Prop canGoPrevious: boolean = false;
  @Prop canGoNext: boolean = false;

  onSelectLesson: (lessonId: string) => void = (lessonId: string) => {};
  onStartTrace: () => void = () => {};
  onAnswer: (option: number) => void = (option: number) => {};
  onPrevious: () => void = () => {};
  onNext: () => void = () => {};
  onTogglePlay: () => void = () => {};
  onRestart: () => void = () => {};
  onOpenMemory: () => void = () => {};
  onOpenCode: () => void = () => {};
  onClose: () => void = () => {};

  build() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Column({ space: 2 }) {
          Text('教学工作台')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#292720')
          Text('LINKED LIST · LEARN BY EXPLORING')
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
          .onClick(() => this.onClose())
      }
      .width('100%')

      Scroll() {
        Column({ space: 11 }) {
          Text('学习路径')
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor('#827D74')
          Column({ space: 5 }) {
            ForEach(LINKED_LIST_LESSONS, (lesson: LinkedListLesson) => {
              Column({ space: 3 }) {
                Text(lesson.title)
                  .fontSize(12)
                  .fontWeight(this.activeLessonId === lesson.id ? FontWeight.Bold : FontWeight.Medium)
                  .fontColor(this.activeLessonId === lesson.id ? '#8E512F' : '#39352E')
                Text(lesson.subtitle)
                  .fontSize(9)
                  .fontColor('#8A847A')
              }
              .width('100%')
              .padding({ left: 10, right: 10, top: 8, bottom: 8 })
              .backgroundColor(this.activeLessonId === lesson.id ? '#F3E6DC' : '#F7F5F0')
              .border({
                width: this.activeLessonId === lesson.id ? 1.5 : 1,
                color: this.activeLessonId === lesson.id ? '#D8B69D' : '#E7E2D9'
              })
              .borderRadius(9)
              .onClick(() => this.onSelectLesson(lesson.id))
            }, (lesson: LinkedListLesson) => lesson.id)
          }
          .width('100%')

          Column({ space: 7 }) {
            Text(this.lessonTitle)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#292720')
            Text(this.lessonSubtitle)
              .fontSize(10)
              .fontColor('#928B80')
            Text(this.lessonConcept)
              .fontSize(12)
              .fontColor('#514C44')
              .lineHeight(19)
              .width('100%')
            Column({ space: 4 }) {
              Text('本节要点')
                .fontSize(10)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8E512F')
              Text(this.lessonKeyPoint)
                .fontSize(11)
                .fontColor('#514C44')
                .lineHeight(17)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#F3E9DF')
            .borderRadius(9)
            Column({ space: 4 }) {
              Text('常见误区')
                .fontSize(10)
                .fontWeight(FontWeight.Bold)
                .fontColor('#8B6249')
              Text(this.lessonMisconception)
                .fontSize(10)
                .fontColor('#71685D')
                .lineHeight(16)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#F7F5F0')
            .borderRadius(9)
            Column({ space: 4 }) {
              Text('动手实验')
                .fontSize(10)
                .fontWeight(FontWeight.Bold)
                .fontColor('#5F6B53')
              Text(this.lessonTask)
                .fontSize(10)
                .fontColor('#5D6257')
                .lineHeight(16)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#EFF1E9')
            .borderRadius(9)
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFEFC')
          .border({ width: 1, color: '#E7E2D9' })
          .borderRadius(12)

          Column({ space: 8 }) {
            Row({ space: 6 }) {
              Text('算法逐步演示')
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor('#292720')
              Blank()
              if (this.traceReady) {
                Text('STEP ' + (this.stepIndex + 1).toString() + ' / ' + this.stepCount.toString())
                  .fontSize(9)
                  .fontColor('#8E512F')
              }
            }
            .width('100%')

            if (this.traceReady) {
              Row() {
                Row()
                  .width(this.progressPercent.toString() + '%')
                  .height(5)
                  .backgroundColor('#B96F3F')
                  .borderRadius(5)
              }
              .width('100%')
              .height(5)
              .backgroundColor('#EEEAE2')
              .borderRadius(5)
              Text(this.stepTitle)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#39352E')
              Text(this.stepExplanation)
                .fontSize(11)
                .fontColor('#625C52')
                .lineHeight(17)
                .width('100%')

              Column({ space: 5 }) {
                Text('当前指针')
                  .fontSize(9)
                  .fontColor('#928B80')
                Text(this.currentLabel)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#8E512F')
                  .fontFamily('monospace')
                Text('已访问：' + this.visitedLabel)
                  .fontSize(10)
                  .fontColor('#66705C')
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#F3E9DF')
              .borderRadius(9)

              Column({ space: 4 }) {
                Text(this.codeLineNumber > 0
                  ? 'C++ 第 ' + this.codeLineNumber.toString() + ' 行'
                  : '对应 C++ 语句')
                  .fontSize(9)
                  .fontColor('#928B80')
                Text(this.codeLineText === '' ? '未找到对应源码行' : this.codeLineText)
                  .fontSize(10)
                  .fontColor('#E8E4DC')
                  .fontFamily('monospace')
                  .width('100%')
                  .maxLines(2)
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#292A29')
              .borderRadius(9)

              Text(this.question)
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor('#39352E')
                .width('100%')
              Column({ space: 5 }) {
                Button('A · ' + this.optionA)
                  .type(ButtonType.Normal)
                  .width('100%')
                  .height(38)
                  .backgroundColor(this.selectedOption === 0 ? '#EAD4C3' : '#F7F5F0')
                  .fontColor('#51463D')
                  .borderRadius(8)
                  .onClick(() => this.onAnswer(0))
                Button('B · ' + this.optionB)
                  .type(ButtonType.Normal)
                  .width('100%')
                  .height(38)
                  .backgroundColor(this.selectedOption === 1 ? '#EAD4C3' : '#F7F5F0')
                  .fontColor('#51463D')
                  .borderRadius(8)
                  .onClick(() => this.onAnswer(1))
                Button('C · ' + this.optionC)
                  .type(ButtonType.Normal)
                  .width('100%')
                  .height(38)
                  .backgroundColor(this.selectedOption === 2 ? '#EAD4C3' : '#F7F5F0')
                  .fontColor('#51463D')
                  .borderRadius(8)
                  .onClick(() => this.onAnswer(2))
              }
              .width('100%')

              if (this.selectedOption >= 0) {
                Column({ space: 4 }) {
                  Text(this.predictionCorrect ? '回答正确' : '再想一想')
                    .fontSize(10)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.predictionCorrect ? '#5F6B53' : '#A45F3D')
                  Text(this.predictionFeedback)
                    .fontSize(10)
                    .fontColor('#625C52')
                    .lineHeight(16)
                }
                .width('100%')
                .padding(10)
                .backgroundColor(this.predictionCorrect ? '#EFF1E9' : '#F7EEE8')
                .borderRadius(9)
              }

              Row({ space: 5 }) {
                Button('上一步')
                  .type(ButtonType.Normal)
                  .layoutWeight(1)
                  .height(34)
                  .enabled(this.canGoPrevious)
                  .backgroundColor('#EEEAE2')
                  .fontColor('#514C44')
                  .borderRadius(8)
                  .onClick(() => this.onPrevious())
                Button(this.isPlaying ? '暂停' : '播放')
                  .type(ButtonType.Normal)
                  .layoutWeight(1)
                  .height(34)
                  .enabled(this.canPlay || this.isPlaying)
                  .backgroundColor(this.isPlaying ? '#F3E6DC' : '#292720')
                  .fontColor(this.isPlaying ? '#8E512F' : '#FFFFFF')
                  .borderRadius(8)
                  .onClick(() => this.onTogglePlay())
                Button('下一步')
                  .type(ButtonType.Normal)
                  .layoutWeight(1)
                  .height(34)
                  .enabled(this.canGoNext && !this.isPlaying)
                  .backgroundColor(this.canGoNext && !this.isPlaying ? '#292720' : '#E6E2DA')
                  .fontColor(this.canGoNext && !this.isPlaying ? '#FFFFFF' : '#9B958A')
                  .borderRadius(8)
                  .onClick(() => this.onNext())
              }
              .width('100%')
              Text('连续播放用于快速观察完整流程；暂停后可逐步预测并答题。')
                .fontSize(9)
                .fontColor('#928B80')
                .width('100%')
              Button('重新演示')
                .type(ButtonType.Normal)
                .width('100%')
                .height(30)
                .backgroundColor('#F7F5F0')
                .fontColor('#716C63')
                .borderRadius(8)
                .onClick(() => this.onRestart())
            } else {
              Text(this.hasDocument
                ? '以当前画布中的链表为素材，逐步观察 current、next 和循环条件的变化。演示只改变高亮与讲解，不会修改你的链表。'
                : '先在画布上创建至少一个节点。创建并连接节点后，就可以运行逐步演示。')
                .fontSize(10)
                .fontColor('#716C63')
                .lineHeight(16)
              Button('开始逐步演示')
                .type(ButtonType.Normal)
                .width('100%')
                .height(38)
                .enabled(this.hasDocument)
                .backgroundColor(this.hasDocument ? '#292720' : '#E6E2DA')
                .fontColor(this.hasDocument ? '#FFFFFF' : '#9B958A')
                .borderRadius(8)
                .onClick(() => this.onStartTrace())
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFEFC')
          .border({ width: 1, color: '#E7E2D9' })
          .borderRadius(12)
        }
        .width('100%')
      }
      .width('100%')
      .padding({ right: 2 })

      Row({ space: 8 }) {
        Button('内存视图')
          .type(ButtonType.Normal)
          .layoutWeight(1)
          .height(36)
          .backgroundColor('#F3E9DF')
          .fontColor('#8E512F')
          .borderRadius(8)
          .onClick(() => this.onOpenMemory())
        Button('C++ 代码')
          .type(ButtonType.Normal)
          .layoutWeight(1)
          .height(36)
          .backgroundColor('#292A29')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .onClick(() => this.onOpenCode())
      }
      .width('100%')
    }
    .width(370)
    .height('100%')
    .padding(14)
    .backgroundColor('#FFFEFC')
    .border({ width: 1, color: '#E5E0D7' })
    .borderRadius(18)
  }
}
