import {
  ChooseResult,
  Choice,
  ChoiceView,
  CompareOp,
  Ending,
  LogItem,
  Requirement,
  StatEffect,
  StatKey,
  Stats,
  StatView,
  StoryNode,
  StoryView
} from '../model/Types';
import { GameState, STAT_MAX } from '../model/GameState';
import { findEnding, findNode, StoryBook } from '../model/StoryData';

export const CLUE_COLOR: string = '#C9A227';
export const TRUST_COLOR: string = '#4FD1C5';
export const SANITY_COLOR: string = '#7AA7F0';

/** 属性中文名 */
export function statLabel(key: StatKey): string {
  switch (key) {
    case StatKey.CLUE:
      return '线索';
    case StatKey.TRUST:
      return '信任';
    case StatKey.SANITY:
      return '理智';
    default:
      return key;
  }
}

/** 读取属性值 */
export function statValue(stats: Stats, key: StatKey): number {
  switch (key) {
    case StatKey.CLUE:
      return stats.clue;
    case StatKey.TRUST:
      return stats.trust;
    case StatKey.SANITY:
      return stats.sanity;
    default:
      return 0;
  }
}

/** 修改属性并夹在 0 ~ STAT_MAX 之间 */
export function applyDelta(stats: Stats, key: StatKey, delta: number): void {
  const next: number = Math.max(0, Math.min(STAT_MAX, statValue(stats, key) + delta));
  switch (key) {
    case StatKey.CLUE:
      stats.clue = next;
      break;
    case StatKey.TRUST:
      stats.trust = next;
      break;
    case StatKey.SANITY:
      stats.sanity = next;
      break;
    default:
      break;
  }
}

/** 单条前置条件判定：真实执行比较运算，而不是在 UI 里写死 */
export function meetsRequirement(stats: Stats, req: Requirement): boolean {
  const value: number = statValue(stats, req.stat);
  switch (req.op) {
    case CompareOp.GTE:
      return value >= req.value;
    case CompareOp.GT:
      return value > req.value;
    case CompareOp.LTE:
      return value <= req.value;
    case CompareOp.LT:
      return value < req.value;
    default:
      return false;
  }
}

function fmtDelta(effects: StatEffect[]): string {
  const parts: string[] = [];
  for (let i = 0; i < effects.length; i++) {
    const item = effects[i];
    const sign: string = item.delta > 0 ? '+' : '';
    parts.push(`${statLabel(item.stat)} ${sign}${item.delta}`);
  }
  return parts.join(' · ');
}

/**
 * 剧情引擎：负责条件判断、属性结算、节点跳转、结局裁定。
 * 不依赖 UI 与持久化，可以直接写单元测试。
 */
export class StoryEngine {
  private book: StoryBook;

  constructor(book: StoryBook) {
    this.book = book;
  }

  start(): GameState {
    const state: GameState = GameState.create();
    state.visited = [this.book.startId];
    return state;
  }

  nodeOf(state: GameState): StoryNode | null {
    return findNode(state.nodeId);
  }

  /** 找不到节点时回退到起始节点，保证脏存档不会白屏 */
  normalize(state: GameState): GameState {
    const node: StoryNode | null = this.nodeOf(state);
    if (node === null) {
      state.nodeId = this.book.startId;
      state.visited = [this.book.startId];
    }
    return state;
  }

  findChoice(node: StoryNode, choiceId: string): Choice | null {
    for (let i = 0; i < node.choices.length; i++) {
      if (node.choices[i].id === choiceId) {
        return node.choices[i];
      }
    }
    return null;
  }

  canChoose(state: GameState, choice: Choice): boolean {
    for (let i = 0; i < choice.requires.length; i++) {
      if (!meetsRequirement(state.stats, choice.requires[i])) {
        return false;
      }
    }
    return true;
  }

  lockReason(choice: Choice): string {
    if (choice.lockHint.length > 0) {
      return choice.lockHint;
    }
    return '条件不足';
  }

  /** 执行一次选择：条件校验 -> 属性结算 -> 记录日志 -> 跳转 */
  choose(state: GameState, choiceId: string): ChooseResult {
    const node: StoryNode | null = this.nodeOf(state);
    if (node === null) {
      return { ok: false, message: '剧情节点丢失，已回到开头', ending: null };
    }
    const choice: Choice | null = this.findChoice(node, choiceId);
    if (choice === null) {
      return { ok: false, message: '选项不存在', ending: null };
    }
    if (!this.canChoose(state, choice)) {
      return { ok: false, message: this.lockReason(choice), ending: null };
    }

    for (let i = 0; i < choice.effects.length; i++) {
      applyDelta(state.stats, choice.effects[i].stat, choice.effects[i].delta);
    }
    for (let i = 0; i < choice.flags.length; i++) {
      if (!state.flags.includes(choice.flags[i])) {
        state.flags.push(choice.flags[i]);
      }
    }

    const log: LogItem = {
      nodeId: node.id,
      nodeTitle: node.title,
      choiceText: choice.text,
      deltaText: fmtDelta(choice.effects),
      at: Date.now()
    };
    state.logs.push(log);
    state.visited.push(choice.nextId);
    state.nodeId = choice.nextId;
    state.turns += 1;
    state.updatedAt = Date.now();

    const ending: Ending | null = this.resolveEnding(state);
    return { ok: true, message: `线索 ${state.stats.clue} · 信任 ${state.stats.trust} · 理智 ${state.stats.sanity}`, ending: ending };
  }

  /** 结局裁定：条件有优先级，先判「失踪」，再判真相与共谋 */
  resolveEnding(state: GameState): Ending | null {
    const node: StoryNode | null = this.nodeOf(state);
    if (node === null || node.endingId.length === 0) {
      return null;
    }
    const stats: Stats = state.stats;
    if (stats.sanity <= 1) {
      return findEnding('e_lost');
    }
    if (stats.clue >= 8 && stats.trust >= 5) {
      return findEnding('e_true');
    }
    if (stats.clue >= 7 && stats.trust < 3) {
      return findEnding('e_deal');
    }
    if (stats.clue >= 7) {
      return findEnding('e_ash');
    }
    return findEnding('e_leave');
  }

  /** 生成 UI 需要的不可变视图，页面只负责渲染 */
  viewOf(state: GameState): StoryView {
    const node: StoryNode | null = this.nodeOf(state);
    const choices: ChoiceView[] = [];
    let chapter: string = '';
    let scene: string = '';
    let title: string = '';
    let speaker: string = '';
    let lines: string[] = [];
    let nodeId: string = '';

    if (node !== null) {
      nodeId = node.id;
      chapter = node.chapter;
      scene = node.scene;
      title = node.title;
      speaker = node.speaker;
      lines = node.lines;
      for (let i = 0; i < node.choices.length; i++) {
        const choice: Choice = node.choices[i];
        const unlocked: boolean = this.canChoose(state, choice);
        choices.push({
          id: choice.id,
          text: choice.text,
          tag: choice.tag,
          locked: !unlocked,
          hint: unlocked ? '' : this.lockReason(choice)
        });
      }
    }

    const stats: StatView[] = [
      { key: 'clue', label: '线索', value: state.stats.clue, max: STAT_MAX, accent: CLUE_COLOR },
      { key: 'trust', label: '信任', value: state.stats.trust, max: STAT_MAX, accent: TRUST_COLOR },
      { key: 'sanity', label: '理智', value: state.stats.sanity, max: STAT_MAX, accent: SANITY_COLOR }
    ];

    return {
      nodeId: nodeId,
      chapter: chapter,
      scene: scene,
      title: title,
      speaker: speaker,
      lines: lines,
      choices: choices,
      stats: stats,
      ending: this.resolveEnding(state),
      turn: state.turns
    };
  }
}
