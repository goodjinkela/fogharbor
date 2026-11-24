import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AppSettings, SaveSlotView, StoryNode } from '../model/Types';
import { GameState } from '../model/GameState';
import { findNode } from '../model/StoryData';

const STORE_NAME: string = 'fog_harbor_save';
const KEY_SETTINGS: string = 'settings';
const KEY_ENDINGS: string = 'unlocked_endings';

export const AUTO_SLOT: number = 0;
export const MANUAL_SLOTS: number[] = [1, 2, 3];

const DEFAULT_SETTINGS: AppSettings = { textSpeed: 24, motion: true };

/** 落盘的存档结构：state 再序列化一次，读取时统一交给 GameState 校验 */
interface StoredSave {
  savedAt: number;
  chapter: string;
  title: string;
  state: string;
}

function pad2(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

export function formatSaveTime(ts: number): string {
  if (ts <= 0) {
    return '--';
  }
  const date: Date = new Date(ts);
  return `${pad2(date.getMonth() + 1)}-${pad2(date.getDate())} ${pad2(date.getHours())}:${pad2(date.getMinutes())}`;
}

/**
 * 存档仓库：所有业务数据都通过 preferences 落盘，
 * 应用被杀死后重新启动可以完整恢复。
 */
export class SaveRepository {
  private store: preferences.Preferences | null = null;

  async init(context: common.Context): Promise<void> {
    const options: preferences.Options = { name: STORE_NAME };
    this.store = await preferences.getPreferences(context, options);
  }

  isReady(): boolean {
    return this.store !== null;
  }

  private async putString(key: string, value: string): Promise<void> {
    if (this.store === null) {
      return;
    }
    await this.store.put(key, value);
    await this.store.flush();
  }

  private async getString(key: string): Promise<string> {
    if (this.store === null) {
      return '';
    }
    const value = await this.store.get(key, '');
    return value as string;
  }

  private slotKey(slot: number): string {
    return `slot_${slot}`;
  }

  async writeSlot(slot: number, state: GameState): Promise<void> {
    const node: StoryNode | null = findNode(state.nodeId);
    const record: StoredSave = {
      savedAt: Date.now(),
      chapter: node === null ? '未知章节' : node.chapter,
      title: node === null ? '未知场景' : node.title,
      state: state.toJson()
    };
    await this.putString(this.slotKey(slot), JSON.stringify(record));
  }

  async readSlot(slot: number): Promise<GameState | null> {
    const text: string = await this.getString(this.slotKey(slot));
    if (text.length === 0) {
      return null;
    }
    try {
      const record = JSON.parse(text) as StoredSave;
      return GameState.fromJson(record.state);
    } catch (err) {
      return null;
    }
  }

  async deleteSlot(slot: number): Promise<void> {
    if (this.store === null) {
      return;
    }
    await this.store.delete(this.slotKey(slot));
    await this.store.flush();
  }

  /** 自动存档 + 3 个手动槽位，统一生成列表视图 */
  async listSlots(): Promise<SaveSlotView[]> {
    const result: SaveSlotView[] = [];
    const slots: number[] = [AUTO_SLOT, ...MANUAL_SLOTS];
    for (let i = 0; i < slots.length; i++) {
      const slot: number = slots[i];
      const text: string = await this.getString(this.slotKey(slot));
      let view: SaveSlotView = {
        slot: slot,
        label: slot === AUTO_SLOT ? '自动存档' : `存档位 ${slot}`,
        auto: slot === AUTO_SLOT,
        exists: false,
        chapter: '',
        title: '',
        savedAt: '--',
        clue: 0,
        trust: 0,
        sanity: 0
      };
      if (text.length > 0) {
        try {
          const record = JSON.parse(text) as StoredSave;
          const state: GameState | null = GameState.fromJson(record.state);
          if (state !== null) {
            view.exists = true;
            view.chapter = record.chapter;
            view.title = record.title;
            view.savedAt = formatSaveTime(record.savedAt);
            view.clue = state.stats.clue;
            view.trust = state.stats.trust;
            view.sanity = state.stats.sanity;
          }
        } catch (err) {
          view.exists = false;
        }
      }
      result.push(view);
    }
    return result;
  }

  async loadSettings(): Promise<AppSettings> {
    const raw: string = await this.getString(KEY_SETTINGS);
    if (raw.length === 0) {
      return { textSpeed: DEFAULT_SETTINGS.textSpeed, motion: DEFAULT_SETTINGS.motion };
    }
    try {
      const parsed = JSON.parse(raw) as AppSettings;
      return {
        textSpeed: Number(parsed.textSpeed ?? DEFAULT_SETTINGS.textSpeed),
        motion: parsed.motion ?? DEFAULT_SETTINGS.motion
      };
    } catch (err) {
      return { textSpeed: DEFAULT_SETTINGS.textSpeed, motion: DEFAULT_SETTINGS.motion };
    }
  }

  async saveSettings(settings: AppSettings): Promise<void> {
    await this.putString(KEY_SETTINGS, JSON.stringify(settings));
  }

  async loadUnlocked(): Promise<string[]> {
    const raw: string = await this.getString(KEY_ENDINGS);
    if (raw.length === 0) {
      return [];
    }
    try {
      const list = JSON.parse(raw) as string[];
      return list === null ? [] : list;
    } catch (err) {
      return [];
    }
  }

  async unlockEnding(endingId: string): Promise<string[]> {
    const list: string[] = await this.loadUnlocked();
    if (!list.includes(endingId)) {
      list.push(endingId);
      await this.putString(KEY_ENDINGS, JSON.stringify(list));
    }
    return list;
  }

  async clearAll(): Promise<void> {
    if (this.store === null) {
      return;
    }
    const slots: number[] = [AUTO_SLOT, ...MANUAL_SLOTS];
    for (let i = 0; i < slots.length; i++) {
      await this.store.delete(this.slotKey(slots[i]));
    }
    await this.store.delete(KEY_SETTINGS);
    await this.store.delete(KEY_ENDINGS);
    await this.store.flush();
  }
}
