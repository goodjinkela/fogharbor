/**
 * 《雾港回声》领域模型
 * 说明：剧情节点、选项、条件、结局全部用纯数据描述，
 *      业务规则集中在 StoryEngine 中，便于单元测试与 JSON 持久化。
 */

/** 三维属性键 */
export enum StatKey {
  CLUE = 'clue',
  TRUST = 'trust',
  SANITY = 'sanity'
}

/** 条件比较符 */
export enum CompareOp {
  GTE = '>=',
  GT = '>',
  LTE = '<=',
  LT = '<'
}

/** 角色属性 */
export interface Stats {
  clue: number;
  trust: number;
  sanity: number;
}

/** 选项的前置条件：stat op value */
export interface Requirement {
  stat: StatKey;
  op: CompareOp;
  value: number;
}

/** 选项带来的属性变化 */
export interface StatEffect {
  stat: StatKey;
  delta: number;
}

/** 一个可交互选项 */
export interface Choice {
  id: string;
  text: string;
  /** 选项下方的小标签，如「线索 +1」 */
  tag: string;
  nextId: string;
  effects: StatEffect[];
  flags: string[];
  requires: Requirement[];
  /** 条件不满足时展示的原因 */
  lockHint: string;
}

/** 一个剧情节点 */
export interface StoryNode {
  id: string;
  chapter: string;
  scene: string;
  title: string;
  speaker: string;
  lines: string[];
  choices: Choice[];
  /** 非空表示这是一个结局节点，由引擎结算具体结局 */
  endingId: string;
}

/** 一个结局 */
export interface Ending {
  id: string;
  title: string;
  rank: string;
  caption: string;
  description: string;
}

/** 一次选择的记录，用于「剧情回顾」 */
export interface LogItem {
  nodeId: string;
  nodeTitle: string;
  choiceText: string;
  deltaText: string;
  at: number;
}

/** 属性条视图数据 */
export interface StatView {
  key: string;
  label: string;
  value: number;
  max: number;
  accent: string;
}

/** 选项视图数据 */
export interface ChoiceView {
  id: string;
  text: string;
  tag: string;
  locked: boolean;
  hint: string;
}

/** 故事页视图数据（单向数据流：引擎 -> ViewModel -> UI） */
export interface StoryView {
  nodeId: string;
  chapter: string;
  scene: string;
  title: string;
  speaker: string;
  lines: string[];
  choices: ChoiceView[];
  stats: StatView[];
  ending: Ending | null;
  turn: number;
}

/** 存档槽视图数据 */
export interface SaveSlotView {
  slot: number;
  label: string;
  auto: boolean;
  exists: boolean;
  chapter: string;
  title: string;
  savedAt: string;
  clue: number;
  trust: number;
  sanity: number;
}

/** 应用设置 */
export interface AppSettings {
  /** 打字机每个字的间隔（毫秒） */
  textSpeed: number;
  /** 是否开启动效 */
  motion: boolean;
}

/** 选择结果 */
export interface ChooseResult {
  ok: boolean;
  message: string;
  ending: Ending | null;
}
