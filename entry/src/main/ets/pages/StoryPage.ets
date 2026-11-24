import { promptAction } from '@kit.ArkUI';
import { C } from '../common/Theme';
import { ChoiceCard, StatBar } from '../component/Common';
import { ChoiceView, StatView, StoryView } from '../model/Types';
import { game } from '../service/GameService';

function emptyView(): StoryView {
  return {
    nodeId: '',
    chapter: '',
    scene: '',
    title: '',
    speaker: '',
    lines: [],
    choices: [],
    stats: [],
    ending: null,
    turn: 0
  };
}

/**
 * 故事页：单向数据流。
 * 引擎产出 StoryView -> 页面只负责渲染；每次选择后重新取一次视图。
 */
@Component
export struct StoryPage {
  stack: NavPathStack = new NavPathStack();
  @State view: StoryView = emptyView();
  @State shownText: string = '';
  @State typing: boolean = false;
  @State busy: boolean = false;
  @State endingId: string = '';
  @State endingTitle: string = '';
  @State endingRank: string = '';
  @State endingCaption: string = '';
  @State endingDesc: string = '';
  private fullText: string = '';
  private timerId: number = -1;

  aboutToAppear(): void {
    this.view = game.view();
    this.applyEndingState();
  }

  aboutToDisappear(): void {
    this.stopTyping();
    AppStorage.setOrCreate('homeRefreshTick', Date.now());
  }

  private applyEndingState(): void {
    const ending = this.view.ending;
    if (ending !== null) {
      this.endingId = ending.id;
      this.endingTitle = ending.title;
      this.endingRank = ending.rank;
      this.endingCaption = ending.caption;
      this.endingDesc = ending.description;
      this.stopTyping();
      this.shownText = this.view.lines.join('\n\n');
    } else {
      this.endingId = '';
      this.startTyping();
    }
  }

  private startTyping(): void {
    this.stopTyping();
    this.fullText = this.view.lines.join('\n\n');
    this.shownText = '';
    this.typing = true;
    const step: number = Math.max(8, game.settings.textSpeed);
    this.timerId = setInterval(() => {
      if (this.shownText.length >= this.fullText.length) {
        this.finishTyping();
        return;
      }
      this.shownText = this.fullText.substring(0, Math.min(this.fullText.length, this.shownText.length + 2));
    }, step);
  }

  private finishTyping(): void {
    this.stopTyping();
    this.shownText = this.fullText;
    this.typing = false;
  }

  private stopTyping(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.typing = false;
  }

  private async pick(choiceId: string): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    const result = await game.choose(choiceId);
    this.busy = false;
    if (!result.ok) {
      promptAction.showToast({ message: result.message });
      return;
    }
    this.view = game.view();
    this.applyEndingState();
  }

  private goHome(): void {
    this.stack.clear();
  }

  @Builder
  Header() {
    Row({ space: 6 }) {
      Text('‹')
        .fontSize(30)
        .fontColor(C.SUB)
        .width(30)
        .textAlign(TextAlign.Center)
        .onClick(() => this.stack.pop())
      Column({ space: 3 }) {
        Text(this.view.chapter)
          .fontSize(12)
          .fontColor(C.GOLD)
          .letterSpacing(2)
          .width('100%')
          .textAlign(TextAlign.Start)
        Text(this.view.scene)
          .fontSize(11)
          .fontColor(C.DIM)
          .width('100%')
          .textAlign(TextAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(`决策 ${this.view.turn}`)
        .fontSize(11)
        .fontColor(C.DIM)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(10)
        .backgroundColor(C.CARD)
    }
    .width('100%')
    .padding({ left: 10, right: 16, top: 10, bottom: 6 })
  }

  @Builder
  StatsRow() {
    Row({ space: 14 }) {
      ForEach(this.view.stats, (item: StatView) => {
        StatBar({ label: item.label, value: item.value, max: item.max, accent: item.accent })
      }, (item: StatView) => item.key)
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 6, bottom: 10 })
  }

  @Builder
  EndingPanel() {
    Column({ space: 14 }) {
      Text(`结局 · ${this.endingRank}`)
        .fontSize(11)
        .fontColor(C.GOLD)
        .letterSpacing(3)
      Text(this.endingTitle)
        .fontSize(32)
        .fontColor(C.TEXT)
        .letterSpacing(4)
      Text(this.endingCaption)
        .fontSize(13)
        .fontColor(C.TEAL)
        .letterSpacing(1)
      Divider()
        .color(C.LINE)
        .margin({ top: 4, bottom: 4 })
      Text(this.endingDesc)
        .fontSize(14)
        .lineHeight(26)
        .fontColor('#C6D2DE')
        .textAlign(TextAlign.Start)
      Row({ space: 12 }) {
        Button('返回首页')
          .layoutWeight(1)
          .height(46)
          .fontSize(15)
          .fontColor('#171208')
          .backgroundColor(C.GOLD)
          .borderRadius(14)
          .onClick(() => this.goHome())
        Button('结局图鉴')
          .layoutWeight(1)
          .height(46)
          .fontSize(15)
          .fontColor(C.TEXT)
          .backgroundColor(C.CARD_HI)
          .borderRadius(14)
          .onClick(() => this.stack.pushPathByName('Gallery', null))
      }
      .width('100%')
      .margin({ top: 6 })
    }
    .width('100%')
    .padding(22)
    .borderRadius(22)
    .backgroundColor('#0F1620')
    .border({ width: 1, color: '#2A3644' })
    .margin({ top: 18 })
  }

  @Builder
  Footer() {
    Row() {
      Column({ space: 3 }) {
        Text('存档').fontSize(12).fontColor(C.SUB)
        Text('SAVE').fontSize(9).fontColor(C.DIM).letterSpacing(1)
      }
      .layoutWeight(1)
      .onClick(() => this.stack.pushPathByName('SaveGame', null))

      Column({ space: 3 }) {
        Text('回顾').fontSize(12).fontColor(C.SUB)
        Text('LOG').fontSize(9).fontColor(C.DIM).letterSpacing(1)
      }
      .layoutWeight(1)
      .onClick(() => this.stack.pushPathByName('History', null))

      Column({ space: 3 }) {
        Text('首页').fontSize(12).fontColor(C.SUB)
        Text('HOME').fontSize(9).fontColor(C.DIM).letterSpacing(1)
      }
      .layoutWeight(1)
      .onClick(() => this.goHome())
    }
    .width('100%')
    .padding({ top: 10, bottom: 14 })
    .border({ width: { top: 1 }, color: C.LINE })
  }

  build() {
    NavDestination() {
      Column() {
        this.Header()
        this.StatsRow()

        Scroll() {
          Column({ space: 18 }) {
            Column({ space: 6 }) {
              Text(this.view.title)
                .fontSize(24)
                .fontWeight(FontWeight.Medium)
                .fontColor(C.TEXT)
                .letterSpacing(1)
                .width('100%')
                .textAlign(TextAlign.Start)
              Row({ space: 8 }) {
                Row().width(18).height(1).backgroundColor(C.GOLD_DIM)
                Text(this.view.speaker)
                  .fontSize(12)
                  .fontColor(C.GOLD)
                  .letterSpacing(1)
              }
              .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 6 })

            Text(this.shownText.length > 0 ? this.shownText : '　')
              .fontSize(16.5)
              .lineHeight(30)
              .fontColor('#D3DEE9')
              .width('100%')
              .textAlign(TextAlign.Start)
              .onClick(() => {
                if (this.typing) {
                  this.finishTyping();
                }
              })

            if (this.typing) {
              Text('轻触文字，跳过打字')
                .fontSize(11)
                .fontColor(C.DIM)
                .width('100%')
                .textAlign(TextAlign.Start)
            }

            if (this.endingId.length > 0) {
              this.EndingPanel()
            } else if (!this.typing && this.view.choices.length > 0) {
              Column({ space: 10 }) {
                Text('你的选择')
                  .fontSize(11)
                  .fontColor(C.DIM)
                  .letterSpacing(2)
                  .width('100%')
                  .textAlign(TextAlign.Start)
                  .margin({ bottom: 2 })
                ForEach(this.view.choices, (item: ChoiceView, index: number) => {
                  ChoiceCard({
                    index: index + 1,
                    text: item.text,
                    tag: item.tag,
                    locked: item.locked,
                    hint: item.hint,
                    choiceId: item.id,
                    onPick: (id: string) => {
                      this.pick(id);
                    }
                  })
                }, (item: ChoiceView) => item.id)
              }
              .width('100%')
              .transition(TransitionEffect.OPACITY.animation({ duration: 260, curve: Curve.EaseOut }))
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 10, bottom: 28 })
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        this.Footer()
      }
      .width('100%')
      .height('100%')
      .linearGradient({
        angle: 175,
        colors: [['#080B10', 0], ['#101A26', 0.55], ['#080B10', 1]]
      })
    }
    .hideTitleBar(true)
    .backgroundColor(C.BG)
  }
}
