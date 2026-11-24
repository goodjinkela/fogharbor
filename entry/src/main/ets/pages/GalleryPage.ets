import { C } from '../common/Theme';
import { Ending } from '../model/Types';
import { ENDINGS } from '../model/StoryData';
import { game } from '../service/GameService';

function rankColor(rank: string): string {
  if (rank === 'S') {
    return C.GOLD;
  }
  if (rank === 'A') {
    return C.TEAL;
  }
  if (rank === 'B') {
    return C.BLUE;
  }
  return C.DIM;
}

/** 结局图鉴：解锁记录单独持久化，重开新游戏也不会丢失 */
@Component
export struct GalleryPage {
  stack: NavPathStack = new NavPathStack();
  @State unlocked: string[] = [];

  aboutToAppear(): void {
    this.unlocked = game.unlocked;
  }

  private isUnlocked(id: string): boolean {
    return this.unlocked.includes(id);
  }

  private progress(): number {
    return ENDINGS.length === 0 ? 0 : this.unlocked.length / ENDINGS.length;
  }

  @Builder
  Card(item: Ending, unlocked: boolean) {
    Column({ space: 6 }) {
      Row() {
        Text(unlocked ? item.rank : '?')
          .fontSize(20)
          .fontColor(unlocked ? rankColor(item.rank) : C.DIM)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(unlocked ? '已解锁' : '未解锁')
          .fontSize(9)
          .fontColor(unlocked ? C.TEAL : C.DIM)
      }
      .width('100%')

      Text(unlocked ? item.title : '？？？')
        .fontSize(18)
        .fontColor(unlocked ? C.TEXT : C.DIM)
        .letterSpacing(2)
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ top: 4 })

      Text(unlocked ? item.caption : '在故事里走到这个结局')
        .fontSize(10)
        .fontColor(unlocked ? C.SUB : '#3C4854')
        .width('100%')
        .textAlign(TextAlign.Start)

      if (unlocked) {
        Text(item.description)
          .fontSize(10)
          .lineHeight(16)
          .fontColor('#7E8C9B')
          .maxLines(4)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .height(168)
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .borderRadius(18)
    .backgroundColor(unlocked ? C.CARD : '#0C1218')
    .border({ width: 1, color: unlocked ? '#2B3744' : C.LINE })
    .opacity(unlocked ? 1 : 0.75)
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
            Text('结局图鉴')
              .fontSize(20)
              .fontColor(C.TEXT)
              .width('100%')
              .textAlign(TextAlign.Start)
            Text(`已收集 ${this.unlocked.length} / ${ENDINGS.length} 个结局`)
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

        Column() {
          Row() {
            Row()
              .height(4)
              .width(`${Math.round(this.progress() * 100)}%`)
              .borderRadius(2)
              .backgroundColor(C.GOLD)
          }
          .width('100%')
          .height(4)
          .borderRadius(2)
          .backgroundColor(C.LINE)
        }
        .width('100%')
        .padding({ left: 18, right: 18 })

        Grid() {
          ForEach(ENDINGS, (item: Ending) => {
            GridItem() {
              this.Card(item, this.isUnlocked(item.id))
            }
          }, (item: Ending) => item.id)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .layoutWeight(1)
        .padding({ left: 18, right: 18, top: 16, bottom: 20 })
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(C.BG)
    }
    .hideTitleBar(true)
    .backgroundColor(C.BG)
  }
}
