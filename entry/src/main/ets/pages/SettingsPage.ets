import { promptAction } from '@kit.ArkUI';
import { C } from '../common/Theme';
import { AppSettings } from '../model/Types';
import { game } from '../service/GameService';

/** 设置页：阅读节奏、动效开关、数据清除与关于信息 */
@Component
export struct SettingsPage {
  stack: NavPathStack = new NavPathStack();
  @State speed: number = 24;
  @State motion: boolean = true;

  aboutToAppear(): void {
    this.speed = game.settings.textSpeed;
    this.motion = game.settings.motion;
  }

  private apply(): void {
    const settings: AppSettings = { textSpeed: this.speed, motion: this.motion };
    game.saveSettings(settings);
  }

  private confirmClear(): void {
    AlertDialog.show({
      title: '清除所有数据',
      message: '将删除全部存档、已解锁结局和设置，且无法恢复。确定继续吗？',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '清除',
        fontColor: C.RED,
        action: () => {
          this.clearAll();
        }
      }
    });
  }

  private async clearAll(): Promise<void> {
    await game.resetAll();
    this.speed = game.settings.textSpeed;
    this.motion = game.settings.motion;
    AppStorage.setOrCreate('homeRefreshTick', Date.now());
    promptAction.showToast({ message: '数据已清除' });
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(11)
      .fontColor(C.DIM)
      .letterSpacing(2)
      .width('100%')
      .textAlign(TextAlign.Start)
      .margin({ top: 18, bottom: 2 })
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
          Text('设置')
            .fontSize(20)
            .fontColor(C.TEXT)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 10, right: 18, top: 12, bottom: 10 })

        Scroll() {
          Column() {
            this.SectionTitle('阅读')

            Column({ space: 10 }) {
              Row() {
                Text('文字速度').fontSize(14).fontColor(C.TEXT)
                Blank()
                Text(`${this.speed} ms/字`).fontSize(11).fontColor(C.GOLD)
              }
              .width('100%')

              Slider({
                value: this.speed,
                min: 8,
                max: 60,
                step: 2,
                style: SliderStyle.OutSet
              })
                .width('100%')
                .blockColor(C.GOLD)
                .selectedColor(C.GOLD)
                .trackColor(C.LINE)
                .onChange((value: number, mode: SliderChangeMode) => {
                  this.speed = Math.round(value);
                  if (mode === SliderChangeMode.End) {
                    this.apply();
                  }
                })

              Row() {
                Text('快').fontSize(10).fontColor(C.DIM)
                Blank()
                Text('慢').fontSize(10).fontColor(C.DIM)
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .borderRadius(18)
            .backgroundColor(C.CARD)

            this.SectionTitle('交互')

            Row() {
              Column({ space: 4 }) {
                Text('界面动效').fontSize(14).fontColor(C.TEXT)
                Text('选项淡入、卡片按压反馈').fontSize(10).fontColor(C.DIM)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Toggle({ type: ToggleType.Switch, isOn: this.motion })
                .selectedColor(C.GOLD)
                .onChange((isOn: boolean) => {
                  this.motion = isOn;
                  this.apply();
                })
            }
            .width('100%')
            .padding(16)
            .borderRadius(18)
            .backgroundColor(C.CARD)

            this.SectionTitle('数据')

            Column({ space: 12 }) {
              Row() {
                Column({ space: 4 }) {
                  Text('清除所有数据').fontSize(14).fontColor(C.TEXT)
                  Text('存档、结局图鉴、阅读设置').fontSize(10).fontColor(C.DIM)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Button('清除')
                  .height(34)
                  .fontSize(12)
                  .fontColor(C.RED)
                  .backgroundColor('transparent')
                  .border({ width: 1, color: '#3A2A2A' })
                  .borderRadius(10)
                  .onClick(() => this.confirmClear())
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .borderRadius(18)
            .backgroundColor(C.CARD)

            this.SectionTitle('关于')

            Column({ space: 8 }) {
              Row() {
                Text('版本').fontSize(12).fontColor(C.SUB)
                Blank()
                Text('1.0.0').fontSize(12).fontColor(C.DIM)
              }
              .width('100%')
              Row() {
                Text('技术栈').fontSize(12).fontColor(C.SUB)
                Blank()
                Text('ArkTS · ArkUI · preferences').fontSize(12).fontColor(C.DIM)
              }
              .width('100%')
              Row() {
                Text('开发环境').fontSize(12).fontColor(C.SUB)
                Blank()
                Text('DevEco Studio 5.0.13 / API 17').fontSize(12).fontColor(C.DIM)
              }
              .width('100%')
              Row() {
                Text('课程').fontSize(12).fontColor(C.SUB)
                Blank()
                Text('移动应用开发基础').fontSize(12).fontColor(C.DIM)
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .borderRadius(18)
            .backgroundColor(C.CARD)

            Text('《雾港回声》 交互式剧情探索与多分支决策系统')
              .fontSize(10)
              .fontColor('#3F4C5A')
              .margin({ top: 22, bottom: 26 })
          }
          .width('100%')
          .padding({ left: 18, right: 18 })
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
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
