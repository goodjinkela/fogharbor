import { common } from '@kit.AbilityKit';
import { AppSettings, ChooseResult, SaveSlotView, StoryView } from '../model/Types';
import { GameState } from '../model/GameState';
import { STORY } from '../model/StoryData';
import { StoryEngine } from '../domain/StoryEngine';
import { AUTO_SLOT, SaveRepository } from '../data/SaveRepository';

/**
 * 应用级单例：把「引擎 / 仓库 / 当前对局」串起来，
 * 页面只和它打交道，避免把业务逻辑写进 UI。
 */
export class GameService {
  readonly engine: StoryEngine = new StoryEngine(STORY);
  readonly repo: SaveRepository = new SaveRepository();
  settings: AppSettings = { textSpeed: 24, motion: true };
  unlocked: string[] = [];
  private state: GameState = GameState.create();
  private ready: boolean = false;
  private initError: string = '';

  async init(context: common.Context): Promise<boolean> {
    if (this.ready) {
      return true;
    }
    try {
      await this.repo.init(context);
      this.settings = await this.repo.loadSettings();
      this.unlocked = await this.repo.loadUnlocked();
      const auto: GameState | null = await this.repo.readSlot(AUTO_SLOT);
      if (auto !== null) {
        this.state = this.engine.normalize(auto);
      }
      this.ready = true;
      return true;
    } catch (err) {
      this.initError = `${err}`;
      return false;
    }
  }

  isReady(): boolean {
    return this.ready;
  }

  errorMessage(): string {
    return this.initError;
  }

  current(): GameState {
    return this.state;
  }

  view(): StoryView {
    return this.engine.viewOf(this.state);
  }

  startNew(): StoryView {
    this.state = this.engine.start();
    this.view();
    this.persist();
    return this.view();
  }

  async choose(choiceId: string): Promise<ChooseResult> {
    const result: ChooseResult = this.engine.choose(this.state, choiceId);
    if (result.ok) {
      await this.repo.writeSlot(AUTO_SLOT, this.state);
      if (result.ending !== null) {
        this.unlocked = await this.repo.unlockEnding(result.ending.id);
      }
    }
    return result;
  }

  async persist(): Promise<void> {
    if (!this.ready) {
      return;
    }
    await this.repo.writeSlot(AUTO_SLOT, this.state);
  }

  async slots(): Promise<SaveSlotView[]> {
    return this.repo.listSlots();
  }

  async saveTo(slot: number): Promise<boolean> {
    try {
      await this.repo.writeSlot(slot, this.state);
      return true;
    } catch (err) {
      return false;
    }
  }

  async loadFrom(slot: number): Promise<boolean> {
    const loaded: GameState | null = await this.repo.readSlot(slot);
    if (loaded === null) {
      return false;
    }
    this.state = this.engine.normalize(loaded);
    await this.repo.writeSlot(AUTO_SLOT, this.state);
    return true;
  }

  async deleteSlot(slot: number): Promise<void> {
    await this.repo.deleteSlot(slot);
  }

  async saveSettings(settings: AppSettings): Promise<void> {
    this.settings = settings;
    await this.repo.saveSettings(settings);
  }

  async resetAll(): Promise<void> {
    await this.repo.clearAll();
    this.state = this.engine.start();
    this.settings = { textSpeed: 24, motion: true };
    this.unlocked = [];
  }

  isUnlocked(endingId: string): boolean {
    return this.unlocked.includes(endingId);
  }
}

export const game: GameService = new GameService();
