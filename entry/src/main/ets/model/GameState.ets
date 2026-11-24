import { LogItem, Stats } from './Types';

/** 初始属性：理智 8 点，满值 10 点 */
export const INITIAL_STATS: Stats = { clue: 0, trust: 0, sanity: 8 };
export const STAT_MAX: number = 10;
export const START_NODE_ID: string = 'n1';

/**
 * 一局游戏的完整状态。
 * 这个类只保存数据，所有规则都在 StoryEngine 中实现，
 * 因此可以整体 JSON 序列化后写入 preferences，重启后原样恢复。
 */
export class GameState {
  nodeId: string = START_NODE_ID;
  stats: Stats = { clue: 0, trust: 0, sanity: 8 };
  flags: string[] = [];
  visited: string[] = [];
  logs: LogItem[] = [];
  startedAt: number = 0;
  updatedAt: number = 0;
  turns: number = 0;

  static create(): GameState {
    const state = new GameState();
    state.nodeId = START_NODE_ID;
    state.stats = { clue: INITIAL_STATS.clue, trust: INITIAL_STATS.trust, sanity: INITIAL_STATS.sanity };
    state.flags = [];
    state.visited = [];
    state.logs = [];
    state.startedAt = Date.now();
    state.updatedAt = state.startedAt;
    state.turns = 0;
    return state;
  }

  clone(): GameState {
    const copy = new GameState();
    copy.nodeId = this.nodeId;
    copy.stats = { clue: this.stats.clue, trust: this.stats.trust, sanity: this.stats.sanity };
    copy.flags = this.flags.slice();
    copy.visited = this.visited.slice();
    copy.logs = this.logs.slice();
    copy.startedAt = this.startedAt;
    copy.updatedAt = this.updatedAt;
    copy.turns = this.turns;
    return copy;
  }

  toJson(): string {
    return JSON.stringify(this);
  }

  /** 反序列化并做字段校验，脏数据直接返回 null，避免崩溃 */
  static fromJson(text: string): GameState | null {
    if (text.length === 0) {
      return null;
    }
    try {
      const raw = JSON.parse(text) as GameState;
      if (raw === null || raw.nodeId === undefined || raw.nodeId.length === 0) {
        return null;
      }
      const state = new GameState();
      state.nodeId = raw.nodeId;
      state.stats = {
        clue: Number(raw.stats?.clue ?? 0),
        trust: Number(raw.stats?.trust ?? 0),
        sanity: Number(raw.stats?.sanity ?? INITIAL_STATS.sanity)
      };
      state.flags = raw.flags ?? [];
      state.visited = raw.visited ?? [];
      state.logs = raw.logs ?? [];
      state.startedAt = Number(raw.startedAt ?? Date.now());
      state.updatedAt = Number(raw.updatedAt ?? Date.now());
      state.turns = Number(raw.turns ?? 0);
      return state;
    } catch (err) {
      return null;
    }
  }
}
