# -*- coding: utf-8 -*-
"""生成《期末大作业报告》模板（含架构图、代码片段与测试表）。"""

import os

from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Cm, Pt, RGBColor

from build_srs import (OUT_DIR, add_image, add_table, body, bullet, code_block, cover,
                       init_document, note, screenshot_grid, set_run_font)


def build_report():
    doc = init_document()

    cover(doc, "移动应用开发基础", "期末大作业报告", [
        ("项目名称", "雾港回声 · 交互式剧情探索与多分支决策系统"),
        ("选题方向", "主题一：交互式剧情探索与多分支决策系统"),
        ("学号姓名", "【填写学号 姓名】"),
        ("班　　级", "【填写班级】"),
        ("指导教师", "【填写教师姓名】"),
        ("GitHub 账号", "goodjinkela"),
        ("仓库地址", "https://github.com/goodjinkela/fogharbor"),
        ("开发环境", "DevEco Studio 5.0.13 / HarmonyOS SDK 5.0.5 (API 17)"),
    ])

    note(doc, "填写说明：把文中所有【】替换为你的真实信息；截图已从模拟器实机截取并嵌入 6.1，"
              "如需替换直接覆盖 docs/screenshots 下的同名文件后重新生成即可。")

    doc.add_heading("一、项目基本信息", level=1)
    add_table(doc,
              ["项目", "内容"],
              [
                  ["项目名称", "雾港回声（FogHarbor）"],
                  ["选题方向", "主题一：交互式剧情探索与多分支决策系统"],
                  ["GitHub 仓库", "https://github.com/goodjinkela/fogharbor"],
                  ["本人 GitHub 账号", "goodjinkela"],
                  ["开发形式", "独立完成（未组队）"],
                  ["代码规模", "16 个 ArkTS 源文件，主代码 2759 行，测试代码 160 行"],
                  ["运行环境", "HarmonyOS 5.0.5（API 17）模拟器 Huawei_Phone"],
                  ["最终提交", "【填写最终 commit 哈希】"],
              ],
              widths=[3.8, 11.7], size=9)

    doc.add_heading("二、系统整体架构", level=1)

    doc.add_heading("2.1 架构图", level=2)
    body(doc, "系统按职责分为五层：表现层、组件层、服务层、领域层、数据层。依赖方向自上而下，"
              "下层不感知上层的存在，因此领域层可以在没有任何 UI 与设备环境的情况下被单元测试。")
    add_image(doc, "architecture.png", 15.6, "图 2-1 系统分层架构（本人负责全部模块）")

    doc.add_heading("2.2 各层职责", level=2)
    add_table(doc,
              ["层次", "职责", "关键文件"],
              [
                  ["表现层", "页面渲染、导航、用户事件", "pages/Index、StoryPage、SavesPage 等 6 个页面"],
                  ["组件层", "可复用的属性条、选项卡、菜单行", "component/Common.ets、common/Theme.ets"],
                  ["服务层", "持有当前对局，编排引擎与仓库，对页面暴露 API", "service/GameService.ets"],
                  ["领域层", "条件判定、属性结算、节点跳转、结局裁定、视图生成", "domain/StoryEngine.ets、model/"],
                  ["数据层", "存档槽、设置、图鉴的序列化与落盘", "data/SaveRepository.ets → preferences"],
              ],
              widths=[3.0, 7.0, 5.5], size=9)

    doc.add_heading("2.3 数据流", level=2)
    body(doc, "一次选择的完整链路为：页面点击选项 → GameService.choose() → StoryEngine 校验并结算 → "
              "写入自动存档 → 生成 StoryView → 页面用 @State 重新渲染。页面始终不直接修改状态，"
              "只消费引擎产出的只读视图，从结构上避免了「界面与数据不一致」。")

    doc.add_heading("2.4 本人负责部分", level=2)
    body(doc, "本项目由本人独立完成，架构图中的五层均由本人实现。其中投入最多的是领域层 StoryEngine："
              "把剧情分支从页面代码中抽离为数据 + 规则，使 11 个节点、8 个条件选项、5 个结局的判断"
              "都可以被单元测试覆盖。")

    doc.add_heading("三、个人模块设计", level=1)

    doc.add_heading("3.1 剧情数据模型", level=2)
    body(doc, "剧情不使用 if-else 硬编码，而是用一组纯数据类型描述。新增剧情只需往 StoryData.ets 追加节点，"
              "页面与引擎代码都不用改。")
    add_table(doc,
              ["类型", "关键字段", "设计意图"],
              [
                  ["StoryNode", "id、chapter、scene、lines、choices、endingId", "一个剧情节点，lines 为段落数组"],
                  ["Choice", "id、text、nextId、effects、requires、flags", "一次决策；requires 为空表示无条件"],
                  ["Requirement", "stat、op、value", "形如「线索 ≥ 4」的前置条件"],
                  ["StatEffect", "stat、delta", "属性增减，结算时统一夹取 0–10"],
                  ["Ending", "id、title、rank、description", "结局定义与评级"],
                  ["GameState", "nodeId、stats、flags、visited、logs、turns", "可整体序列化的对局快照"],
              ],
              widths=[3.0, 7.4, 5.1], size=8.5)

    doc.add_heading("3.2 规则引擎设计", level=2)
    body(doc, "引擎负责三件事：条件判定、属性结算、结局裁定。条件判定支持 >=、>、<=、< 四种比较，"
              "多个条件之间是 AND 关系；属性结算后统一夹取到 0–10，避免出现负数或溢出；"
              "结局在终局节点按固定优先级裁定，优先级顺序保证「精神崩溃」不会同时被判成「真相」。")
    add_table(doc,
              ["优先级", "条件", "结局"],
              [
                  ["1", "理智 ≤ 1", "失踪者（C）"],
                  ["2", "线索 ≥ 8 且 信任 ≥ 5", "雾散（S）"],
                  ["3", "线索 ≥ 7 且 信任 < 3", "共谋（B）"],
                  ["4", "线索 ≥ 7", "余烬（A）"],
                  ["5", "其余情况", "离岸（C）"],
              ],
              widths=[2.2, 8.4, 4.9], size=9)
    body(doc, "节点查找为线性扫描，节点数 11，单次选择耗时可以忽略；引擎不持有任何全局状态，"
              "同一个 GameState 传入即可得到确定结果，因此测试不需要 mock 数据库或设备。")

    doc.add_heading("3.3 持久化设计", level=2)
    body(doc, "所有业务数据通过 preferences 以 JSON 形式落盘，单存档约 1–3 KB。写入时机有三处："
              "每次选择成功后写自动存档、应用切后台时兜底保存、用户在存档页手动保存。")
    add_table(doc,
              ["Key", "内容", "说明"],
              [
                  ["slot_0", "自动存档 JSON", "每次选择后覆盖，只读"],
                  ["slot_1 ~ slot_3", "手动存档 JSON", "可覆盖、可删除"],
                  ["settings", "文字速度、动效开关", "设置页读写"],
                  ["unlocked_endings", "已解锁结局 ID 数组", "跨周目保留"],
              ],
              widths=[4.2, 7.2, 4.1], size=8.5)

    doc.add_heading("3.4 模块接口", level=2)
    add_table(doc,
              ["接口", "签名", "说明"],
              [
                  ["StoryEngine.choose", "choose(state, choiceId): ChooseResult", "校验、结算、跳转、裁定结局"],
                  ["StoryEngine.resolveEnding", "resolveEnding(state): Ending | null", "非终局节点返回 null"],
                  ["StoryEngine.viewOf", "viewOf(state): StoryView", "生成页面只读视图"],
                  ["GameService.choose", "choose(choiceId): Promise<ChooseResult>", "调用引擎并持久化"],
                  ["GameService.loadFrom", "loadFrom(slot): Promise<boolean>", "读档并同步自动存档"],
                  ["SaveRepository.writeSlot", "writeSlot(slot, state): Promise<void>", "序列化 + flush"],
              ],
              widths=[4.4, 7.6, 3.5], size=8.5)

    doc.add_heading("3.5 与其他模块的交互", level=2)
    body(doc, "服务层是唯一同时认识引擎与仓库的模块：它把页面传入的 choiceId 交给引擎，拿到结果后立即落盘，"
              "再把最新视图交回页面。数据层只认识 GameState 与 JSON，不认识任何 UI 概念。"
              "这样的边界让三部分可以分别修改：换存储方案不影响引擎，改页面不影响存档格式。")

    doc.add_heading("四、关键代码实现", level=1)

    doc.add_heading("4.1 选择执行：先校验，再结算", level=2)
    code_block(doc,
               "choose(state: GameState, choiceId: string): ChooseResult {\n"
               "  const node = this.nodeOf(state);\n"
               "  if (node === null) { return { ok: false, message: '剧情节点丢失', ending: null }; }\n"
               "  const choice = this.findChoice(node, choiceId);\n"
               "  if (choice === null) { return { ok: false, message: '选项不存在', ending: null }; }\n"
               "  if (!this.canChoose(state, choice)) {\n"
               "    return { ok: false, message: this.lockReason(choice), ending: null };\n"
               "  }\n"
               "  for (let i = 0; i < choice.effects.length; i++) {\n"
               "    applyDelta(state.stats, choice.effects[i].stat, choice.effects[i].delta);\n"
               "  }\n"
               "  // 记录日志、跳转节点、裁定结局（略）\n"
               "}")
    body(doc, "条件校验放在属性结算之前，因此即使有人绕过界面直接调用被锁定的选项，状态也不会被改写。"
              "这既是业务规则，也是防止状态被篡改的一道保险。")

    doc.add_heading("4.2 结局裁定：用优先级代替散落的 if", level=2)
    code_block(doc,
               "resolveEnding(state: GameState): Ending | null {\n"
               "  const node = this.nodeOf(state);\n"
               "  if (node === null || node.endingId.length === 0) { return null; }\n"
               "  const stats = state.stats;\n"
               "  if (stats.sanity <= 1) { return findEnding('e_lost'); }\n"
               "  if (stats.clue >= 8 && stats.trust >= 5) { return findEnding('e_true'); }\n"
               "  if (stats.clue >= 7 && stats.trust < 3) { return findEnding('e_deal'); }\n"
               "  if (stats.clue >= 7) { return findEnding('e_ash'); }\n"
               "  return findEnding('e_leave');\n"
               "}")
    body(doc, "结局是一个有序规则表：理智崩溃优先于真相，真相优先于共谋，共谋优先于半真相。"
              "把顺序写进代码而不是散落在页面里，测试时只要构造不同的 Stats 就能验证五个结局。")

    doc.add_heading("4.3 存档落盘：flush 才是真的写完", level=2)
    code_block(doc,
               "async writeSlot(slot: number, state: GameState): Promise<void> {\n"
               "  const node = findNode(state.nodeId);\n"
               "  const record: StoredSave = {\n"
               "    savedAt: Date.now(),\n"
               "    chapter: node === null ? '未知章节' : node.chapter,\n"
               "    title: node === null ? '未知场景' : node.title,\n"
               "    state: state.toJson()\n"
               "  };\n"
               "  await this.putString(this.slotKey(slot), JSON.stringify(record));\n"
               "}\n"
               "// putString 内部：await store.put(key, value); await store.flush();")
    body(doc, "只调用 put 不调用 flush 时，数据可能仍停留在内存缓冲中，进程被杀就会丢档。"
              "因此所有写入都集中在 putString 一处，并在其中强制 flush。")

    doc.add_heading("4.4 状态驱动界面", level=2)
    body(doc, "页面不再保存业务状态，只保存引擎生成的 StoryView。每次选择后重新取一次视图并赋给 @State，"
              "ArkUI 自动完成差量刷新，这样「属性条、选项锁定状态、结局面板」永远与数据一致。")
    code_block(doc,
               "// StoryPage\n"
               "const result = await game.choose(choiceId);\n"
               "if (!result.ok) { promptAction.showToast({ message: result.message }); return; }\n"
               "this.view = game.view();   // 重新生成视图，@State 触发刷新\n"
               "this.applyEndingState();  // 打字机 / 结局面板")

    doc.add_heading("4.5 Commit 记录", level=2)
    body(doc, "下表为仓库真实提交，可用 git log 核对；后续开发请按功能继续拆分提交。")
    add_table(doc,
              ["日期", "哈希", "说明", "涉及文件"],
              [
                  ["2026-11-24", "bfca1ee", "feat(core): 初始化《雾港回声》工程与剧情引擎", "全部工程文件"],
                  ["2026-11-24", "688c243", "docs: 补充需求说明书、报告模板、架构图与开发指南", "docs/、tools/"],
                  ["2026-11-24", "7727528", "feat(ui): 替换为《雾港回声》应用图标", "media/background.png、foreground.png"],
                  ["2026-11-24", "6941ca0", "docs: 补充仓库信息并整理 README 截图占位", "README.md"],
                  ["2026-11-24", "03122c7", "fix(ui): 修复属性条不刷新与时间线撑满，补充实机截图", "StoryPage、SavesPage、HistoryPage 等"],
              ],
              widths=[2.8, 2.4, 7.6, 4.7], size=8.5)

    doc.add_heading("五、模块测试", level=1)

    doc.add_heading("5.1 测试环境", level=2)
    add_table(doc,
              ["项目", "内容"],
              [
                  ["测试框架", "Hypium（@ohos/hypium），工程自带 ohosTest 模块"],
                  ["运行设备", "本地模拟器 Huawei_Phone，HarmonyOS 5.0.5（API 17），x86_64"],
                  ["测试文件", "entry/src/ohosTest/ets/test/StoryEngine.test.ets"],
                  ["运行方式", "DevEco 中右键该文件 Run，或 hvigorw 执行 ohosTest 任务"],
              ],
              widths=[3.4, 12.1], size=9)

    doc.add_heading("5.2 正常场景", level=2)
    add_table(doc,
              ["用例", "输入", "预期结果", "实际结果", "证据"],
              [
                  ["TC-N1", "n1 选择 a_read", "跳转 n2，线索 1，日志 1 条，turns 1", "【填写】", "【截图】"],
                  ["TC-N2", "读取视图", "3 项属性、3 个选项，无结局", "【填写】", "【截图】"],
                  ["TC-N3", "n11 且属性 9/6/8", "结局为「雾散」", "【填写】", "【截图】"],
              ],
              widths=[1.8, 4.6, 5.4, 2.4, 1.8], size=8.5)

    doc.add_heading("5.3 边界场景", level=2)
    add_table(doc,
              ["用例", "输入", "预期结果", "实际结果", "证据"],
              [
                  ["TC-B1", "线索恰好 2，选 b_direct", "选项解锁并可跳转", "【填写】", "【截图】"],
                  ["TC-B2", "线索 10 再 +5", "仍为 10", "【填写】", "【截图】"],
                  ["TC-B3", "四种比较运算符", ">=、>、<=、< 结果正确", "【填写】", "【截图】"],
              ],
              widths=[1.8, 4.6, 5.4, 2.4, 1.8], size=8.5)

    doc.add_heading("5.4 异常场景", level=2)
    add_table(doc,
              ["用例", "输入", "预期结果", "实际结果", "证据"],
              [
                  ["TC-E1", "不存在的选项 ID", "ok=false，节点与日志不变", "【填写】", "【截图】"],
                  ["TC-E2", "线索 0 时选 b_direct", "被拒绝，节点仍为 n1", "【填写】", "【截图】"],
                  ["TC-E3", "空字符串 / 非法 JSON 存档", "fromJson 返回 null，不崩溃", "【填写】", "【截图】"],
              ],
              widths=[1.8, 4.6, 5.4, 2.4, 1.8], size=8.5)

    doc.add_heading("5.5 测试结论", level=2)
    body(doc, "【运行后填写：共 9 条用例，通过 X 条；未通过项的原因与修复情况】。"
              "从设计上，引擎无外部依赖，测试结果可复现；应用重启后的数据恢复需要配合 6.1 的截图验证。")

    doc.add_heading("六、运行结果与总结", level=1)

    doc.add_heading("6.1 主要页面", level=2)
    body(doc, "以下截图均在本地模拟器 Huawei_Phone（HarmonyOS 5.0.5，1260×2720）上实际运行截取，"
              "机型与分辨率信息见 5.1 节。")
    screenshot_grid(doc, [
        ("01-home.png", "图 6-1 首页：开始 / 继续、读档与入口菜单"),
        ("02-story.png", "图 6-2 故事页：章节、属性条、打字机文本"),
        ("03-locked.png", "图 6-3 条件选项：线索不足时置灰并提示"),
        ("04-ending.png", "图 6-4 结局：S 级「雾散」"),
        ("05-saves.png", "图 6-5 存档：自动存档 + 3 个手动位"),
        ("06-gallery.png", "图 6-6 结局图鉴：1 / 5 已解锁")
    ])
    add_image(doc, "07-history.png", 6.4, "图 6-7 剧情回顾：本局 10 次决策与属性变化", "screenshots")

    doc.add_heading("6.2 集成结果", level=2)
    body(doc, "六个页面均通过 Navigation 串联，业务状态由 GameService 统一持有；选择后自动存档、"
              "杀进程重开可恢复到最近决策点，图鉴与设置独立持久化。工程在 DevEco Studio 5.0.13 + "
              "API 17 下可正常构建（assembleHap 通过）。")

    doc.add_heading("6.3 存在的问题与解决", level=2)
    add_table(doc,
              ["问题", "原因", "解决方式"],
              [
                  ["页面之间传递路由参数类型报错", "NavPathStack 的 param 为 object，强转不优雅",
                   "拆成 SaveGame / LoadGame 两个路由，页面用 mode 区分"],
                  ["杀进程后进度丢失", "只 put 未 flush", "写入统一走 putString，内部强制 flush"],
                  ["读档后返回栈出现两份故事页", "load 后直接 push", "先 pop 回首页再 push，保证栈内只有一条对局路径"],
              ],
              widths=[5.2, 5.2, 5.1], size=8.5)

    doc.add_heading("6.4 收获与改进", level=2)
    body(doc, "最大的收获是把「剧情」当成数据、把「分支」当成规则来设计：一旦引擎与界面分离，"
              "新增十段剧情只是多写十个对象，测试也不需要模拟器。后续可以做的改进包括："
              "把结局解锁做成成就系统、增加存档云同步、以及用关系型数据库存储决策日志以支持统计。")

    doc.add_heading("附录 A 提交记录", level=1)
    body(doc, "【粘贴 git log --oneline --graph 的输出；至少 6 条有意义的提交，禁止一次性提交全部代码】")

    doc.add_heading("附录 B 运行录屏", level=1)
    body(doc, "录屏链接：【B 站 / 网盘链接】；时长建议 3–5 分钟，依次演示：开始新游戏 → 做出 2–3 次选择 → "
              "查看属性变化 → 保存到槽位 → 从最近任务划掉应用 → 重新打开恢复 → 达成一个结局 → 图鉴点亮。")

    doc.add_heading("附录 C 评分点对照", level=1)
    add_table(doc,
              ["评分项", "分值", "本报告对应位置"],
              [
                  ["ArkTS 编程与数据建模", "5", "3.1 剧情数据模型、3.2 规则引擎"],
                  ["核心业务逻辑与算法", "10", "3.2、4.1、4.2"],
                  ["Mock 打桩与模块测试", "5", "5.2–5.4 三类用例"],
                  ["需求分析与整体架构", "10", "第二章、图 2-1"],
                  ["页面设计与交互体验", "15", "6.1 截图、8 章交互设计（需求说明书）"],
                  ["个人模块设计与接口约定", "10", "3.3–3.5"],
                  ["创新表现与报告表达", "5", "第六章、附录"],
                  ["ArkUI 组件与 Ability Kit", "15", "4.4、6.1"],
                  ["工程运行与数据持久化", "10", "3.3、4.3、6.2"],
                  ["GitHub 开发与个人贡献", "10", "4.5、附录 A"],
                  ["README 与运行展示", "5", "仓库 README、附录 B"],
              ],
              widths=[7.6, 2.0, 6.0], size=8.5)

    path = os.path.join(OUT_DIR, "docs", "移动应用开发基础-学号-姓名-期末大作业报告.docx")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    doc.save(path)
    return path


if __name__ == "__main__":
    print(build_report())
