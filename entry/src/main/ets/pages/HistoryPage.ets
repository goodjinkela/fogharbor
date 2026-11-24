import { C } from '../common/Theme';
import { LogItem } from '../model/Types';
import { game } from '../service/GameService';

function two(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

function clock(ts: number): string {
  const date = new Date(ts);
  return `${two(date.getHours())}:${two(date.getMinutes())}`;
}

/** 剧情回顾：按时间线回看本局做过的每一次选择 */
@Component
export struct HistoryPage {
  stack: NavPathStack = new NavPathStack();
  @State logs: LogItem[] = [];
  @State clue: number = 0;
  @State trust: number = 0;
  @State sanity: number = 0;

  aboutToAppear(): void {
    const state = game.current();
    this.logs = state.logs;
    this.clue = state.stats.clue;
    this.trust = state.stats.trust;
    this.sanity = state.stats.sanity;
  }

  build() {
    NavDestination() {
      Column() {
        Row({ space: 6 }) {
          Text('‹')
            .fontSize(30)
            .fontColor(C.SUB)
            .width(30)
            .textAlign(TextAlign.Center)
            .onClick(() => this.stack.pop())
          Column({ space: 3 }) {
            Text('剧情回顾')
              .fontSize(20)
              .fontColor(C.TEXT)
              .width('100%')
              .textAlign(TextAlign.Start)
            Text(`本局共 ${this.logs.length} 次决策`)
              .fontSize(11)
              .fontColor(C.DIM)
              .width('100%')
              .textAlign(TextAlign.Start)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 10, right: 18, top: 12, bottom: 10 })

        Row({ space: 10 }) {
          Text(`线索 ${this.clue}`).fontSize(11).fontColor(C.GOLD)
          Text(`信任 ${this.trust}`).fontSize(11).fontColor(C.TEAL)
          Text(`理智 ${this.sanity}`).fontSize(11).fontColor(C.BLUE)
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 8 })

        if (this.logs.length === 0) {
          Column({ space: 10 }) {
            Text('还没有做出任何选择')
              .fontSize(14)
              .fontColor(C.SUB)
            Text('回到故事里，迈出第一步。')
              .fontSize(12)
              .fontColor(C.DIM)
            Button('回到故事')
              .height(40)
              .fontSize(13)
              .fontColor('#171208')
              .backgroundColor(C.GOLD)
              .borderRadius(12)
              .margin({ top: 10 })
              .onClick(() => this.stack.pop())
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column({ space: 0 }) {
              ForEach(this.logs, (item: LogItem, index: number) => {
                Row({ space: 12 }) {
                  Column({ space: 4 }) {
                    Text(`${index + 1}`)
                      .width(22)
                      .height(22)
                      .borderRadius(11)
                      .textAlign(TextAlign.Center)
                      .fontSize(10)
                      .fontColor(C.GOLD)
                      .backgroundColor('#1E1A0F')
                    Row()
                      .width(1)
                      .layoutWeight(1)
                      .backgroundColor(C.LINE)
                  }
                  .width(22)
                  .alignItems(HorizontalAlign.Center)

                  Column({ space: 5 }) {
                    Row() {
                      Text(item.nodeTitle)
                        .fontSize(11)
                        .fontColor(C.DIM)
                      Blank()
                      Text(clock(item.at))
                        .fontSize(10)
                        .fontColor('#3F4C5A')
                    }
                    .width('100%')

                    Text(item.choiceText)
                      .fontSize(14)
                      .fontColor(C.TEXT)
                      .lineHeight(21)
                      .width('100%')
                      .textAlign(TextAlign.Start)

                    if (item.deltaText.length > 0) {
                      Text(item.deltaText)
                        .fontSize(10)
                        .fontColor(C.TEAL)
                        .width('100%')
                        .textAlign(TextAlign.Start)
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  .padding({ bottom: 18 })
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
              }, (item: LogItem, index: number) => `${item.at}-${index}`)
            }
            .width('100%')
            .padding({ left: 18, right: 18, top: 6, bottom: 24 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(C.BG)
    }
    .hideTitleBar(true)
    .backgroundColor(C.BG)
  }
}
