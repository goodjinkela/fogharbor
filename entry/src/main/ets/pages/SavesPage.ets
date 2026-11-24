import { promptAction } from '@kit.ArkUI';
import { C } from '../common/Theme';
import { SaveSlotView } from '../model/Types';
import { game } from '../service/GameService';

/**
 * 存档页：mode = 'save' 时写入当前进度，mode = 'load' 时读取并进入故事。
 * 自动存档位只读，不允许手动覆盖或删除。
 */
@Component
export struct SavesPage {
  stack: NavPathStack = new NavPathStack();
  mode: string = 'load';
  @State slots: SaveSlotView[] = [];
  @State busy: boolean = false;

  aboutToAppear(): void {
    this.refresh();
  }

  private async refresh(): Promise<void> {
    this.slots = await game.slots();
  }

  private async onSave(slot: SaveSlotView): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    const ok: boolean = await game.saveTo(slot.slot);
    this.busy = false;
    promptAction.showToast({ message: ok ? `已保存到「${slot.label}」` : '保存失败，请重试' });
    await this.refresh();
  }

  private async onLoad(slot: SaveSlotView): Promise<void> {
    if (this.busy) {
      return;
    }
    if (!slot.exists) {
      promptAction.showToast({ message: '这个存档位还是空的' });
      return;
    }
    this.busy = true;
    const ok: boolean = await game.loadFrom(slot.slot);
    this.busy = false;
    if (!ok) {
      promptAction.showToast({ message: '存档已损坏，无法读取' });
      return;
    }
    this.stack.pop();
    this.stack.pushPathByName('Story', null);
  }

  private confirmDelete(slot: SaveSlotView): void {
    AlertDialog.show({
      title: '删除存档',
      message: `确定要删除「${slot.label}」吗？删除后无法恢复。`,
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: C.RED,
        action: () => {
          this.removeSlot(slot);
        }
      }
    });
  }

  private async removeSlot(slot: SaveSlotView): Promise<void> {
    await game.deleteSlot(slot.slot);
    await this.refresh();
    promptAction.showToast({ message: '已删除' });
  }

  private subtitle(): string {
    return this.mode === 'save'
      ? '选择一个位置写入当前进度，自动存档会同步更新'
      : '读取后从该决策点继续，进度会写入自动存档';
  }

  @Builder
  SlotCard(slot: SaveSlotView) {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text(slot.label)
          .fontSize(12)
          .fontColor(slot.auto ? C.TEAL : C.GOLD)
          .letterSpacing(1)
        if (slot.auto) {
          Text('AUTO')
            .fontSize(9)
            .fontColor(C.DIM)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(6)
            .backgroundColor(C.CARD_HI)
        }
        Blank()
        Text(slot.exists ? slot.savedAt : '空')
          .fontSize(11)
          .fontColor(C.DIM)
      }
      .width('100%')

      if (slot.exists) {
        Column({ space: 4 }) {
          Text(slot.chapter)
            .fontSize(11)
            .fontColor(C.SUB)
            .width('100%')
            .textAlign(TextAlign.Start)
          Text(slot.title)
            .fontSize(17)
            .fontColor(C.TEXT)
            .width('100%')
            .textAlign(TextAlign.Start)
        }
        .width('100%')

        Row({ space: 14 }) {
          Text(`线索 ${slot.clue}`).fontSize(11).fontColor(C.GOLD)
          Text(`信任 ${slot.trust}`).fontSize(11).fontColor(C.TEAL)
          Text(`理智 ${slot.sanity}`).fontSize(11).fontColor(C.BLUE)
        }
        .width('100%')
      } else {
        Text(this.mode === 'save' ? '点击保存当前进度' : '暂无进度')
          .fontSize(13)
          .fontColor(C.DIM)
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ top: 4, bottom: 4 })
      }

      Row({ space: 10 }) {
        if (this.mode === 'save') {
          Button(slot.exists ? '覆盖保存' : '保存到此')
            .layoutWeight(1)
            .height(38)
            .fontSize(13)
            .fontColor('#171208')
            .backgroundColor(C.GOLD)
            .borderRadius(12)
            .enabled(!slot.auto && !this.busy)
            .opacity(slot.auto ? 0.35 : 1)
            .onClick(() => this.onSave(slot))
        } else {
          Button(slot.exists ? '读取' : '空存档')
            .layoutWeight(1)
            .height(38)
            .fontSize(13)
            .fontColor(slot.exists ? '#171208' : C.DIM)
            .backgroundColor(slot.exists ? C.GOLD : C.CARD_HI)
            .borderRadius(12)
            .enabled(slot.exists && !this.busy)
            .onClick(() => this.onLoad(slot))
        }
        if (slot.exists && !slot.auto) {
          Button('删除')
            .width(72)
            .height(38)
            .fontSize(13)
            .fontColor(C.RED)
            .backgroundColor('transparent')
            .border({ width: 1, color: '#3A2A2A' })
            .borderRadius(12)
            .onClick(() => this.confirmDelete(slot))
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor(slot.auto ? '#101821' : C.CARD)
    .border({ width: 1, color: slot.auto ? '#20303D' : '#232E3A' })
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
            Text(this.mode === 'save' ? '保存进度' : '读取进度')
              .fontSize(20)
              .fontColor(C.TEXT)
              .width('100%')
              .textAlign(TextAlign.Start)
            Text(this.subtitle())
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

        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.slots, (item: SaveSlotView) => {
              this.SlotCard(item)
            }, (item: SaveSlotView) => `${item.slot}-${item.exists}-${item.savedAt}`)

            Text('提示：应用被关闭或杀死后重新打开，会自动恢复到最近的进度。')
              .fontSize(11)
              .fontColor(C.DIM)
              .lineHeight(20)
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ top: 6, bottom: 20 })
          }
          .width('100%')
          .padding({ left: 18, right: 18, bottom: 20 })
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
