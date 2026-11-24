import { C } from '../common/Theme';

/** 三维属性条：每一格代表 1 点，直观展示 0~10 的变化 */
@Component
export struct StatBar {
  @Prop label: string = '';
  @Prop value: number = 0;
  @Prop max: number = 10;
  @Prop accent: string = C.GOLD;

  private ticks(): number[] {
    const list: number[] = [];
    for (let i = 0; i < this.max; i++) {
      list.push(i);
    }
    return list;
  }

  build() {
    Column({ space: 6 }) {
      Row() {
        Text(this.label).fontSize(12).fontColor(C.SUB)
        Blank()
        Text(`${this.value}`).fontSize(13).fontColor(this.accent).fontWeight(FontWeight.Medium)
      }
      .width('100%')

      Row() {
        ForEach(this.ticks(), (i: number) => {
          Row()
            .height(4)
            .layoutWeight(1)
            .borderRadius(2)
            .backgroundColor(i < this.value ? this.accent : C.LINE)
            .margin({ left: i === 0 ? 0 : 3 })
        }, (i: number) => `${this.label}-${i}`)
      }
      .width('100%')
    }
    .width('100%')
  }
}

/** 剧情选项卡片：条件不满足时置灰并给出原因 */
@Component
export struct ChoiceCard {
  @Prop index: number = 1;
  @Prop text: string = '';
  @Prop tag: string = '';
  @Prop locked: boolean = false;
  @Prop hint: string = '';
  onPick: (id: string) => void = () => {
  };
  @Prop choiceId: string = '';
  @State pressed: boolean = false;

  build() {
    Row({ space: 12 }) {
      Text(`${this.index}`)
        .width(26)
        .height(26)
        .borderRadius(13)
        .textAlign(TextAlign.Center)
        .fontSize(12)
        .fontColor(this.locked ? C.DIM : C.GOLD)
        .backgroundColor(this.locked ? C.CARD_HI : '#1E1A0F')
        .border({ width: 1, color: this.locked ? C.LINE : C.GOLD_DIM })

      Column({ space: 5 }) {
        Text(this.text)
          .fontSize(15)
          .fontColor(this.locked ? C.DIM : C.TEXT)
          .lineHeight(22)
          .width('100%')
          .textAlign(TextAlign.Start)
        if (this.locked) {
          Text(this.hint)
            .fontSize(11)
            .fontColor(C.GOLD_DIM)
            .width('100%')
            .textAlign(TextAlign.Start)
        } else if (this.tag.length > 0) {
          Text(this.tag)
            .fontSize(11)
            .fontColor(C.TEAL)
            .width('100%')
            .textAlign(TextAlign.Start)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .borderRadius(16)
    .backgroundColor(this.locked ? C.CARD : C.CARD_HI)
    .border({ width: 1, color: this.locked ? C.LINE : '#2A3644' })
    .opacity(this.locked ? 0.6 : 1)
    .scale({ x: this.pressed ? 0.98 : 1, y: this.pressed ? 0.98 : 1 })
    .animation({ duration: 120, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else {
        this.pressed = false;
      }
    })
    .onClick(() => {
      if (!this.locked) {
        this.onPick(this.choiceId);
      }
    })
  }
}

/** 首页 / 设置页的入口行 */
@Component
export struct MenuRow {
  @Prop badge: string = '';
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop accent: string = C.GOLD;
  onTap: () => void = () => {
  };

  build() {
    Row({ space: 12 }) {
      Text(this.badge)
        .width(34)
        .height(34)
        .borderRadius(12)
        .textAlign(TextAlign.Center)
        .fontSize(14)
        .fontColor(this.accent)
        .backgroundColor(C.CARD_HI)
      Column({ space: 3 }) {
        Text(this.title).fontSize(15).fontColor(C.TEXT).width('100%').textAlign(TextAlign.Start)
        if (this.subtitle.length > 0) {
          Text(this.subtitle).fontSize(11).fontColor(C.DIM).width('100%').textAlign(TextAlign.Start)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('›').fontSize(18).fontColor(C.DIM)
    }
    .width('100%')
    .padding({ left: 14, right: 16, top: 12, bottom: 12 })
    .borderRadius(16)
    .backgroundColor(C.CARD)
    .onClick(() => this.onTap())
  }
}
