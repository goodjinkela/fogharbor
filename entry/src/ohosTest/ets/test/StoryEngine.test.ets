import { describe, it, expect } from '@ohos/hypium';
import { applyDelta, meetsRequirement, StoryEngine } from '../../../main/ets/domain/StoryEngine';
import { GameState } from '../../../main/ets/model/GameState';
import { STORY, findNode } from '../../../main/ets/model/StoryData';
import { Choice, CompareOp, Ending, StatKey, StoryNode, StoryView } from '../../../main/ets/model/Types';

const engine: StoryEngine = new StoryEngine(STORY);

export default function storyEngineTest() {
  describe('StoryEngineTest', () => {
    // ---------- 正常场景 ----------
    it('normal_choice_moves_to_next_node', 0, () => {
      const state: GameState = engine.start();
      expect(state.nodeId).assertEqual('n1');

      const result = engine.choose(state, 'a_read');
      expect(result.ok).assertTrue();
      expect(state.nodeId).assertEqual('n2');
      expect(state.stats.clue).assertEqual(1);
      expect(state.logs.length).assertEqual(1);
      expect(state.turns).assertEqual(1);
    });

    it('normal_view_contains_stats_and_choices', 0, () => {
      const state: GameState = engine.start();
      const view: StoryView = engine.viewOf(state);
      expect(view.chapter.length > 0).assertTrue();
      expect(view.stats.length).assertEqual(3);
      expect(view.choices.length).assertEqual(3);
      expect(view.ending === null).assertTrue();
    });

    // ---------- 边界场景 ----------
    it('boundary_requirement_exactly_met', 0, () => {
      const state: GameState = engine.start();
      const node: StoryNode | null = findNode('n2');
      expect(node !== null).assertTrue();
      if (node === null) {
        return;
      }
      state.stats.clue = 2;
      const choice: Choice | null = engine.findChoice(node, 'b_direct');
      expect(choice !== null).assertTrue();
      if (choice === null) {
        return;
      }
      // 恰好等于阈值 2 时应解锁
      expect(engine.canChoose(state, choice)).assertTrue();
      state.stats.clue = 1;
      expect(engine.canChoose(state, choice)).assertFalse();
    });

    it('boundary_stats_are_clamped', 0, () => {
      const state: GameState = engine.start();
      state.stats.clue = 10;
      applyDelta(state.stats, StatKey.CLUE, 5);
      expect(state.stats.clue).assertEqual(10);

      state.stats.sanity = 0;
      applyDelta(state.stats, StatKey.SANITY, -3);
      expect(state.stats.sanity).assertEqual(0);
    });

    it('boundary_compare_operators', 0, () => {
      const state: GameState = engine.start();
      state.stats.trust = 3;
      expect(meetsRequirement(state.stats, { stat: StatKey.TRUST, op: CompareOp.GTE, value: 3 })).assertTrue();
      expect(meetsRequirement(state.stats, { stat: StatKey.TRUST, op: CompareOp.GT, value: 3 })).assertFalse();
      expect(meetsRequirement(state.stats, { stat: StatKey.TRUST, op: CompareOp.LTE, value: 3 })).assertTrue();
      expect(meetsRequirement(state.stats, { stat: StatKey.TRUST, op: CompareOp.LT, value: 3 })).assertFalse();
    });

    // ---------- 异常场景 ----------
    it('abnormal_unknown_choice_keeps_state', 0, () => {
      const state: GameState = engine.start();
      const result = engine.choose(state, 'choice_not_exists');
      expect(result.ok).assertFalse();
      expect(state.nodeId).assertEqual('n1');
      expect(state.logs.length).assertEqual(0);
    });

    it('abnormal_locked_choice_is_rejected', 0, () => {
      const state: GameState = engine.start();
      state.stats.clue = 0;
      // b_direct 需要线索 >= 2，此时应被拒绝
      const result = engine.choose(state, 'b_direct');
      expect(result.ok).assertFalse();
      expect(state.nodeId).assertEqual('n1');
    });

    it('abnormal_broken_save_returns_null', 0, () => {
      expect(GameState.fromJson('') === null).assertTrue();
      expect(GameState.fromJson('{not json}') === null).assertTrue();
      expect(GameState.fromJson('{"nodeId":""}') === null).assertTrue();
    });

    // ---------- 结局裁定 ----------
    it('ending_rules_match_priority', 0, () => {
      const state: GameState = engine.start();
      state.nodeId = 'n11';

      state.stats = { clue: 1, trust: 1, sanity: 1 };
      const lost: Ending | null = engine.resolveEnding(state);
      expect(lost !== null).assertTrue();
      if (lost !== null) {
        expect(lost.id).assertEqual('e_lost');
      }

      state.stats = { clue: 9, trust: 6, sanity: 8 };
      const truth: Ending | null = engine.resolveEnding(state);
      expect(truth !== null).assertTrue();
      if (truth !== null) {
        expect(truth.id).assertEqual('e_true');
      }

      state.stats = { clue: 8, trust: 2, sanity: 8 };
      const deal: Ending | null = engine.resolveEnding(state);
      expect(deal !== null).assertTrue();
      if (deal !== null) {
        expect(deal.id).assertEqual('e_deal');
      }

      state.stats = { clue: 7, trust: 4, sanity: 8 };
      const ash: Ending | null = engine.resolveEnding(state);
      expect(ash !== null).assertTrue();
      if (ash !== null) {
        expect(ash.id).assertEqual('e_ash');
      }

      state.stats = { clue: 2, trust: 4, sanity: 8 };
      const leave: Ending | null = engine.resolveEnding(state);
      expect(leave !== null).assertTrue();
      if (leave !== null) {
        expect(leave.id).assertEqual('e_leave');
      }
    });
  });
}
