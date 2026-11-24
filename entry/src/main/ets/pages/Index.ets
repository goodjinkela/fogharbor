import { common } from '@kit.AbilityKit';
import { C } from '../common/Theme';
import { MenuRow } from '../component/Common';
import { game } from '../service/GameService';
import { GalleryPage } from './GalleryPage';
import { HistoryPage } from './HistoryPage';
import { SavesPage } from './SavesPage';
import { SettingsPage } from './SettingsPage';
import { StoryPage } from './StoryPage';

@Entry
@Component
struct Index {
  @State stack: NavPathStack = new NavPathStack();
  @State ready: boolean = false;
  @State hasAuto: boolean = false;
  @State autoChapter: string = '';
  @State autoTime: string = '';
  @State unlockedCount: number = 0;
  @State endingTotal: number = 5;
  @StorageProp('homeRefreshTick') @Watch('onRefreshTick') tick: number = 0;

  aboutToAppear(): void {
    this.bootstrap();
  }

  private async bootstrap(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    await game.init(context);
    this.ready = true;
    await this.refresh();
  }

  onRefreshTick(): void {
    this.refresh();
  }

  private async refresh(): Promise<void> {
    const slots = await game.slots();
    if (slots.length > 0) {
      const auto = slots[0];
      this.hasAuto = auto.exists;
      this.autoChapter = auto.chapter;
      this.autoTime = auto.savedAt;
    }
    this.unlockedCount = game.unlocked.length;
  }

  private startNewStory(): void {
    game.startNew();
    this.stack.pushPathByName('Story', null);
  }

  private async continueStory(): Promise<void> {
    if (this.hasAuto) {
      await game.loadFrom(0);
    } else {
      game.startNew();
    }
    this.stack.pushPathByName('Story', null);
  }

  @Builder
  TitleBlock() {
    Column({ space: 10 }) {
      Text('THE FOG HARBOR FILES')
        .fontSize(10)
        .fontColor(C.GOLD)
        .letterSpacing(4)
      Text('雾港回声')
        .fontSize(44)
        .fontColor(C.TEXT)
        .letterSpacing(10)
        .fontWeight(FontWeight.Medium)
      Row({ space: 10 }) {
        Row().width(28).height(1).backgroundColor(C.GOLD_DIM)
        Text('1937 · 上海').fontSize(12).fontColor(C.SUB).letterSpacing(3)
        Row().width(28).height(1).backgroundColor(C.GOLD_DIM)
      }
      .margin({ top: 2 })
      Text('一封匿名信，一艘不该存在的船，\n和二十七个没能开口的人。')
        .fontSize(13)
        .fontColor(C.DIM)
        .lineHeight(24)
        .textAlign(TextAlign.Center)
        .margin({ top: 10 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 26 })
  }

  @Builder
  ContinueCard() {
    Column({ space: 8 }) {
      Row() {
        Text('上次的进度')
          .fontSize(11)
          .fontColor(C.TEAL)
          .letterSpacing(2)
        Blank()
        Text(this.autoTime)
          .fontSize(11)
          .fontColor(C.DIM)
      }
      .width('100%')
      Text(this.autoChapter)
        .fontSize(15)
        .fontColor(C.TEXT)
        .width('100%')
        .textAlign(TextAlign.Start)
      Text('继续调查')
        .fontSize(11)
        .fontColor(C.DIM)
        .width('100%')
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor(C.CARD)
    .border({ width: 1, color: '#2A3644' })
  }

  @Builder
  Home() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 165,
          colors: [['#05070A', 0], ['#0C141E', 0.5], ['#070A0F', 1]]
        })

      Circle()
        .width(340)
        .height(340)
        .fill('#16283A')
        .opacity(0.55)
        .blur(70)
        .position({ x: -90, y: -110 })

      Circle()
        .width(260)
        .height(260)
        .fill('#241E10')
        .opacity(0.5)
        .blur(80)
        .position({ x: 240, y: 520 })

      Scroll() {
        Column({ space: 16 }) {
          this.TitleBlock()

          if (!this.ready) {
            Row({ space: 8 }) {
              LoadingProgress().width(18).height(18).color(C.GOLD)
              Text('正在恢复进度…').fontSize(12).fontColor(C.DIM)
            }
            .margin({ top: 40 })
          } else {
            Column({ space: 12 }) {
              if (this.hasAuto) {
                this.ContinueCard()
              }

              Button(this.hasAuto ? '继续调查' : '开始调查')
                .width('100%')
                .height(54)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#171208')
                .backgroundColor(C.GOLD)
                .borderRadius(16)
                .onClick(() => {
                  this.continueStory();
                })

              Row({ space: 12 }) {
                Button('读取存档')
                  .layoutWeight(1)
                  .height(46)
                  .fontSize(14)
                  .fontColor(C.TEXT)
                  .backgroundColor(C.CARD_HI)
                  .borderRadius(14)
                  .onClick(() => this.stack.pushPathByName('LoadGame', null))
                Button(this.hasAuto ? '重新开始' : '新的故事')
                  .layoutWeight(1)
                  .height(46)
                  .fontSize(14)
                  .fontColor(C.SUB)
                  .backgroundColor(C.CARD)
                  .borderRadius(14)
                  .border({ width: 1, color: C.LINE })
                  .onClick(() => this.startNewStory())
              }
              .width('100%')
            }
            .width('100%')
            .margin({ top: 30 })

            Column({ space: 10 }) {
              MenuRow({
                badge: '卷',
                title: '结局图鉴',
                subtitle: `已收集 ${this.unlockedCount} / ${this.endingTotal} 个结局`,
                onTap: () => this.stack.pushPathByName('Gallery', null)
              })
              MenuRow({
                badge: '档',
                title: '存档管理',
                subtitle: '自动存档与三个手动存档位',
                onTap: () => this.stack.pushPathByName('LoadGame', null)
              })
              MenuRow({
                badge: '设',
                title: '设置',
                subtitle: '文字速度、动效与数据清除',
                onTap: () => this.stack.pushPathByName('Settings', null)
              })
              MenuRow({
                badge: '关',
                title: '关于本作',
                subtitle: '《移动应用开发基础》期末大作业',
                onTap: () => this.stack.pushPathByName('Settings', null)
              })
            }
            .width('100%')
            .margin({ top: 14 })

            Text('交互式剧情探索 · 多分支决策 · 进度存档')
              .fontSize(10)
              .fontColor('#42505F')
              .letterSpacing(1)
              .margin({ top: 18, bottom: 18 })
          }
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 70, bottom: 30 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  PageMap(name: string) {
    if (name === 'Story') {
      StoryPage({ stack: this.stack })
    } else if (name === 'SaveGame') {
      SavesPage({ stack: this.stack, mode: 'save' })
    } else if (name === 'LoadGame') {
      SavesPage({ stack: this.stack, mode: 'load' })
    } else if (name === 'Gallery') {
      GalleryPage({ stack: this.stack })
    } else if (name === 'History') {
      HistoryPage({ stack: this.stack })
    } else if (name === 'Settings') {
      SettingsPage({ stack: this.stack })
    }
  }

  build() {
    Navigation(this.stack) {
      this.Home()
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.PageMap)
    .backgroundColor(C.BG)
  }
}
