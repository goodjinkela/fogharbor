# -*- coding: utf-8 -*-
"""生成《软件需求说明书》与期末大作业报告模板（DOCX）。"""

import os
from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

OUT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BODY_FONT = "宋体"
HEAD_FONT = "黑体"
MONO_FONT = "Consolas"


def set_run_font(run, name=BODY_FONT, size=10.5, bold=False, color=None, italic=False):
    run.font.name = name
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic
    if color is not None:
        run.font.color.rgb = color
    r_pr = run._element.get_or_add_rPr()
    r_fonts = r_pr.find(qn("w:rFonts"))
    if r_fonts is None:
        r_fonts = OxmlElement("w:rFonts")
        r_pr.append(r_fonts)
    r_fonts.set(qn("w:ascii"), name)
    r_fonts.set(qn("w:hAnsi"), name)
    r_fonts.set(qn("w:eastAsia"), name)


def init_document():
    doc = Document()
    section = doc.sections[0]
    section.top_margin = Cm(2.5)
    section.bottom_margin = Cm(2.5)
    section.left_margin = Cm(2.8)
    section.right_margin = Cm(2.6)

    normal = doc.styles["Normal"]
    normal.font.name = BODY_FONT
    normal.font.size = Pt(10.5)
    normal.element.rPr.rFonts.set(qn("w:eastAsia"), BODY_FONT)
    normal.paragraph_format.line_spacing = 1.5
    normal.paragraph_format.space_after = Pt(0)

    for name, size in (("Heading 1", 16), ("Heading 2", 14), ("Heading 3", 12)):
        style = doc.styles[name]
        style.font.name = HEAD_FONT
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor(0, 0, 0)
        style.element.rPr.rFonts.set(qn("w:eastAsia"), HEAD_FONT)
        style.paragraph_format.space_before = Pt(14 if name == "Heading 1" else 10)
        style.paragraph_format.space_after = Pt(8)
        style.paragraph_format.keep_with_next = True
        style.paragraph_format.line_spacing = 1.3

    add_page_number(doc)
    return doc


def add_page_number(doc):
    footer = doc.sections[0].footer
    p = footer.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run()
    set_run_font(run, BODY_FONT, 9, color=RGBColor(0x66, 0x66, 0x66))
    fld_begin = OxmlElement("w:fldChar")
    fld_begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = "PAGE"
    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")
    run._r.append(fld_begin)
    run._r.append(instr)
    run._r.append(fld_end)


def body(doc, text, indent=True, size=10.5, bold=False, color=None, space_after=4):
    p = doc.add_paragraph()
    p.paragraph_format.line_spacing = 1.5
    p.paragraph_format.space_after = Pt(space_after)
    if indent:
        p.paragraph_format.first_line_indent = Pt(size * 2)
    r = p.add_run(text)
    set_run_font(r, BODY_FONT, size, bold, color)
    return p


def bullet(doc, text, size=10.5):
    p = doc.add_paragraph(style="List Bullet")
    p.paragraph_format.line_spacing = 1.5
    p.paragraph_format.space_after = Pt(2)
    r = p.add_run(text)
    set_run_font(r, BODY_FONT, size)
    return p


def note(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(8)
    p.paragraph_format.left_indent = Cm(0.3)
    r = p.add_run(text)
    set_run_font(r, "楷体", 9.5, color=RGBColor(0x88, 0x44, 0x00), italic=True)
    return p


def shade(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)
    tc_pr.append(shd)


def cell_text(cell, text, bold=False, size=9, align=WD_ALIGN_PARAGRAPH.LEFT, font=BODY_FONT,
              color=None):
    cell.text = ""
    p = cell.paragraphs[0]
    p.alignment = align
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(0)
    p.paragraph_format.line_spacing = 1.15
    lines = str(text).split("\n")
    for i, line in enumerate(lines):
        if i > 0:
            p.add_run().add_break()
        r = p.add_run(line)
        set_run_font(r, font, size, bold, color)
    cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER


def add_table(doc, headers, rows, widths=None, size=9, header_fill="2F3A46", caption=None):
    if caption:
        cap = doc.add_paragraph()
        cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        cap.paragraph_format.space_before = Pt(6)
        cap.paragraph_format.space_after = Pt(3)
        r = cap.add_run(caption)
        set_run_font(r, HEAD_FONT, 9, color=RGBColor(0x44, 0x44, 0x44))

    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False

    header_cells = table.rows[0].cells
    for i, h in enumerate(headers):
        cell_text(header_cells[i], h, bold=True, size=size,
                  align=WD_ALIGN_PARAGRAPH.CENTER, color=RGBColor(0xFF, 0xFF, 0xFF))
        shade(header_cells[i], header_fill)

    tr_pr = table.rows[0]._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)

    for row in rows:
        cells = table.add_row().cells
        for i, value in enumerate(row):
            cell_text(cells[i], value, size=size)

    if widths:
        for j, w in enumerate(widths):
            table.columns[j].width = Cm(w)
            for cell in table.columns[j].cells:
                cell.width = Cm(w)

    doc.add_paragraph().paragraph_format.space_after = Pt(2)
    return table


def code_block(doc, text, size=8.5):
    p = doc.add_paragraph()
    p.paragraph_format.left_indent = Cm(0.4)
    p.paragraph_format.right_indent = Cm(0.4)
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(8)
    p.paragraph_format.line_spacing = 1.05
    p_pr = p._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), "F4F5F7")
    p_pr.append(shd)
    borders = OxmlElement("w:pBdr")
    for edge in ("top", "left", "bottom", "right"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), "4")
        el.set(qn("w:space"), "4")
        el.set(qn("w:color"), "D8DCE2")
        borders.append(el)
    p_pr.append(borders)
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if i > 0:
            p.add_run().add_break()
        r = p.add_run(line)
        set_run_font(r, MONO_FONT, size, color=RGBColor(0x1F, 0x29, 0x33))
    return p


def placeholder_box(doc, text, height_cm=6.0):
    table = doc.add_table(rows=1, cols=1)
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = table.rows[0].cells[0]
    cell.width = Cm(15.5)
    cell.height = Cm(height_cm)
    p = cell.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(height_cm * 28.35 / 2 - 10)
    r = p.add_run(text)
    set_run_font(r, "楷体", 9.5, color=RGBColor(0x99, 0x99, 0x99))
    doc.add_paragraph().paragraph_format.space_after = Pt(2)


def add_image(doc, filename, width_cm=15.5, caption=None):
    path = os.path.join(OUT_DIR, "docs", "images", filename)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.space_after = Pt(4)
    p.add_run().add_picture(path, width=Cm(width_cm))
    if caption:
        cap = doc.add_paragraph()
        cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        cap.paragraph_format.space_after = Pt(10)
        r = cap.add_run(caption)
        set_run_font(r, "楷体", 9, color=RGBColor(0x55, 0x55, 0x55))


def cover(doc, title, subtitle, meta_rows):
    for _ in range(3):
        doc.add_paragraph()

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(title)
    set_run_font(r, HEAD_FONT, 26, bold=True)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(10)
    r = p.add_run(subtitle)
    set_run_font(r, HEAD_FONT, 16, color=RGBColor(0x44, 0x44, 0x44))

    for _ in range(4):
        doc.add_paragraph()

    table = doc.add_table(rows=0, cols=2)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for key, value in meta_rows:
        cells = table.add_row().cells
        cell_text(cells[0], key, size=11, align=WD_ALIGN_PARAGRAPH.RIGHT, bold=True)
        cell_text(cells[1], value, size=11)
        cells[0].width = Cm(4.2)
        cells[1].width = Cm(9.0)

    for _ in range(2):
        doc.add_paragraph()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("2026 年 12 月")
    set_run_font(r, BODY_FONT, 11)

    doc.add_page_break()


# ---------------------------------------------------------------------------
# 软件需求说明书
# ---------------------------------------------------------------------------

def build_srs():
    doc = init_document()

    cover(doc, "雾港回声", "软件需求说明书", [
        ("课　　程", "移动应用开发基础"),
        ("项目名称", "雾港回声 · 交互式剧情探索与多分支决策系统"),
        ("选题方向", "主题一：交互式剧情探索与多分支决策系统"),
        ("开发形式", "独立完成"),
        ("学号姓名", "【填写学号 姓名】"),
        ("GitHub 账号", "goodjinkela"),
        ("仓库地址", "https://github.com/goodjinkela/fogharbor"),
        ("开发环境", "DevEco Studio 5.0.13 / HarmonyOS SDK 5.0.5 (API 17)"),
    ])

    doc.add_heading("修订记录", level=1)
    add_table(doc,
              ["版本", "日期", "修订内容", "作者"],
              [["V1.0", "2026-11-24", "首次编写，确定功能范围、架构与数据结构", "【姓名】"]],
              widths=[2.0, 3.0, 8.5, 3.0], size=9)

    doc.add_heading("1 引言", level=1)

    doc.add_heading("1.1 编写目的", level=2)
    body(doc, "本文档定义《雾港回声》的功能需求、系统架构、模块接口、数据结构与数据存储方案，作为后续编码、单元测试、验收与课程答辩的依据。文档同时满足课程期末大作业对《软件需求说明书》的内容要求：说明功能模块、整体架构、成员分工、模块接口、数据结构和存储方式。")

    doc.add_heading("1.2 项目背景", level=2)
    body(doc, "课程要求从交互式剧情、可视化编辑、智能场景三个主题中任选其一，完成一款具有真实业务逻辑与数据持久化能力的 HarmonyOS 应用。本项目选择主题一，围绕「剧情探索、条件判断、状态变化、多分支决策」设计一款文字悬疑冒险应用。")
    body(doc, "常见的文字冒险应用往往把分支写成界面层的大量 if-else，导致三个问题：剧情无法扩展、状态无法保存、逻辑无法测试。本项目把剧情抽象为数据（节点、选项、条件、效果、结局），由独立的 StoryEngine 解释执行，使分支逻辑与界面解耦，既便于扩充剧情，也便于编写单元测试。")

    doc.add_heading("1.3 术语与缩写", level=2)
    add_table(doc,
              ["术语", "说明"],
              [
                  ["剧情节点（StoryNode）", "一段可阅读的剧情文本与一组待选选项，是剧情图的最小单位"],
                  ["选项（Choice）", "玩家的一次决策，包含前置条件、属性效果、标记与跳转目标"],
                  ["条件（Requirement）", "形如「线索 ≥ 4」的判定式，用于锁定 / 解锁选项"],
                  ["属性（Stats）", "线索 clue、信任 trust、理智 sanity，取值 0–10"],
                  ["结局（Ending）", "终局节点按属性优先级裁定的结果，共 5 个"],
                  ["存档槽（Slot）", "一份完整 GameState 的 JSON 快照，自动 1 个 + 手动 3 个"],
                  ["ViewModel", "由引擎生成、只读的页面展示数据（StoryView）"],
              ],
              widths=[4.2, 11.3], size=9)

    doc.add_heading("2 项目概述", level=1)

    doc.add_heading("2.1 产品定位", level=2)
    body(doc, "《雾港回声》是一款单机、离线、叙事驱动的交互式剧情应用。玩家扮演 1937 年上海的记者沈砚，通过一次次选择推进调查，三项属性随之变化，最终走向 5 个不同结局。应用强调「选择有代价、结局可收集、进度可恢复」。")

    doc.add_heading("2.2 目标用户与使用场景", level=2)
    bullet(doc, "喜爱悬疑、推理、文字冒险类内容的移动端用户；")
    bullet(doc, "碎片时间游玩：单局 10–20 分钟，随时退出，下次从最近决策点继续；")
    bullet(doc, "重复通关：通过不同属性组合解锁其余结局，图鉴长期保留；")
    bullet(doc, "课程演示：教师可现场验证条件判断、状态变化与持久化是否真实生效。")

    doc.add_heading("2.3 运行环境", level=2)
    add_table(doc,
              ["项目", "要求"],
              [
                  ["设备类型", "phone / tablet / 2in1"],
                  ["操作系统", "HarmonyOS 5.0.5 及以上（API 17+）"],
                  ["开发工具", "DevEco Studio 5.0.13"],
                  ["SDK", "HarmonyOS SDK 5.0.5（API 17）"],
                  ["屏幕方向", "竖屏"],
                  ["网络", "不需要联网，无网络权限要求"],
                  ["存储占用", "安装包约 0.5 MB，单存档小于 4 KB"],
              ],
              widths=[4.2, 11.3], size=9)

    doc.add_heading("2.4 设计约束", level=2)
    bullet(doc, "全部业务数据本地存储，不依赖服务端，断网可完整游玩；")
    bullet(doc, "首屏在本地读取完成前展示加载态，读取失败不白屏；")
    bullet(doc, "剧情数据与界面代码分离，新增节点不需要修改页面；")
    bullet(doc, "核心判定逻辑必须可被单元测试直接调用，不依赖 UI 上下文。")

    doc.add_heading("3 功能需求", level=1)

    doc.add_heading("3.1 功能结构", level=2)
    code_block(doc,
               "雾港回声\n"
               "├── 剧情探索\n"
               "│   ├── 开始 / 继续游戏\n"
               "│   ├── 打字机文本与跳过\n"
               "│   └── 选项展示与条件锁定\n"
               "├── 决策判定\n"
               "│   ├── 属性结算（0–10 夹取）\n"
               "│   ├── 标记与日志记录\n"
               "│   └── 结局裁定（5 个结局）\n"
               "├── 存档\n"
               "│   ├── 自动存档\n"
               "│   └── 手动存档 ×3（覆盖 / 删除）\n"
               "├── 收集与回顾\n"
               "│   ├── 结局图鉴\n"
               "│   └── 本局决策时间线\n"
               "└── 设置\n"
               "    ├── 文字速度 / 动效开关\n"
               "    └── 清除全部数据")

    doc.add_heading("3.2 功能列表", level=2)
    add_table(doc,
              ["编号", "功能", "说明", "优先级"],
              [
                  ["FR-01", "开始新游戏", "重置对局状态，写入自动存档并进入首个节点", "高"],
                  ["FR-02", "继续游戏", "读取自动存档，恢复到最近决策点", "高"],
                  ["FR-03", "剧情阅读", "逐字显示文本，轻触可跳过打字动画", "高"],
                  ["FR-04", "选项与条件锁定", "展示 2–3 个选项，条件不满足时置灰并提示原因", "高"],
                  ["FR-05", "属性结算", "按选项效果增减属性，越界夹取到 0–10", "高"],
                  ["FR-06", "结局裁定", "终局节点按属性优先级计算结局并解锁图鉴", "高"],
                  ["FR-07", "自动存档", "每次选择后写入 slot_0", "高"],
                  ["FR-08", "手动存档", "3 个槽位，可覆盖、可删除（自动槽只读）", "中"],
                  ["FR-09", "读档", "读取指定槽位并跳转故事页", "高"],
                  ["FR-10", "结局图鉴", "展示 5 个结局的解锁状态，跨周目保留", "中"],
                  ["FR-11", "剧情回顾", "按时间线展示本局决策与属性变化", "中"],
                  ["FR-12", "设置", "文字速度 8–60ms、动效开关、清除数据", "低"],
              ],
              widths=[1.6, 3.2, 8.9, 1.8], size=9)

    doc.add_heading("3.3 核心用例", level=2)

    body(doc, "用例 UC-01：做出一次选择", bold=True, indent=False)
    add_table(doc,
              ["项目", "内容"],
              [
                  ["参与者", "玩家"],
                  ["前置条件", "已进入故事页，当前节点存在至少一个可选项"],
                  ["基本流程", "1. 玩家点击选项卡片；2. 页面调用 GameService.choose()；3. 引擎校验前置条件；"
                             "4. 结算属性与标记；5. 写入决策日志；6. 跳转下一节点；7. 页面刷新文本与选项；"
                             "8. 自动存档落盘"],
                  ["异常流程", "选项不存在或条件不满足：返回 ok=false，状态不变，Toast 提示原因"],
                  ["后置条件", "当前节点已更新，自动存档与新状态一致"],
              ],
              widths=[3.2, 12.3], size=9)

    body(doc, "用例 UC-02：保存并在重启后恢复进度", bold=True, indent=False)
    add_table(doc,
              ["项目", "内容"],
              [
                  ["参与者", "玩家"],
                  ["前置条件", "对局进行中"],
                  ["基本流程", "1. 玩家进入存档页；2. 选择手动槽位保存，或直接退出应用；"
                             "3. 系统将 GameState 序列化为 JSON 写入 preferences 并 flush；"
                             "4. 重新启动应用；5. 首页读取自动存档；6. 展示「继续调查」卡片；"
                             "7. 点击后恢复到保存时的节点与属性"],
                  ["异常流程", "JSON 解析失败或节点丢失：视为空存档，normalize 回退到起始节点"],
                  ["后置条件", "界面展示的章节、属性与存档记录一致"],
              ],
              widths=[3.2, 12.3], size=9)

    body(doc, "用例 UC-03：条件选项的解锁与拒绝", bold=True, indent=False)
    add_table(doc,
              ["项目", "内容"],
              [
                  ["参与者", "玩家"],
                  ["前置条件", "选项声明了 requires，例如「线索 ≥ 4」"],
                  ["基本流程", "1. 引擎计算 canChoose；2. 未满足时选项置灰并显示 lockHint；"
                             "3. 属性达标后同一选项自动变为可选；4. 玩家选择后正常跳转"],
                  ["异常流程", "绕过界面直接调用被锁选项：引擎再次校验并拒绝，防止状态被篡改"],
                  ["后置条件", "锁定状态与当前属性严格一致"],
              ],
              widths=[3.2, 12.3], size=9)

    body(doc, "用例 UC-04：达成结局并解锁图鉴", bold=True, indent=False)
    add_table(doc,
              ["项目", "内容"],
              [
                  ["参与者", "玩家"],
                  ["前置条件", "进入终局节点 n11"],
                  ["基本流程", "1. 引擎按优先级裁定结局；2. 页面展示结局面板（评级、标题、描述）；"
                             "3. 结局 ID 写入 unlocked_endings；4. 图鉴对应卡片点亮"],
                  ["异常流程", "结局 ID 不存在：resolveEnding 返回 null，页面保留普通剧情视图"],
                  ["后置条件", "图鉴计数增加，重开新游戏仍保留"],
              ],
              widths=[3.2, 12.3], size=9)

    doc.add_heading("3.4 业务规则", level=2)
    add_table(doc,
              ["编号", "规则"],
              [
                  ["BR-01", "属性取值 0–10，任何增减后越界一律夹取，不出现负数或超过上限"],
                  ["BR-02", "一个选项的全部 requires 必须同时满足（AND 语义）才可执行"],
                  ["BR-03", "选项执行后立即跳转，不提供回退；回退只能通过读取旧存档实现"],
                  ["BR-04", "结局裁定优先级：理智 ≤ 1 → 失踪者；线索 ≥ 8 且信任 ≥ 5 → 雾散；"
                            "线索 ≥ 7 且信任 < 3 → 共谋；线索 ≥ 7 → 余烬；其余 → 离岸"],
                  ["BR-05", "每次成功选择后立即写入自动存档，应用切后台时再兜底保存一次"],
                  ["BR-06", "结局解锁记录独立存储，只有「清除全部数据」才会重置"],
                  ["BR-07", "自动存档槽只读，不允许手动覆盖或删除"],
              ],
              widths=[2.0, 13.5], size=9)

    doc.add_heading("4 系统架构设计", level=1)

    doc.add_heading("4.1 分层架构", level=2)
    body(doc, "系统采用五层结构，上层依赖下层，下层不感知上层，保证业务逻辑可独立测试。")
    add_image(doc, "architecture.png", 15.6, "图 4-1 系统分层架构（本人负责全部模块）")

    doc.add_heading("4.2 模块职责", level=2)
    add_table(doc,
              ["模块", "文件", "职责"],
              [
                  ["入口", "entryability/EntryAbility.ets", "设置深色主题与状态栏，切后台兜底存档"],
                  ["路由与首页", "pages/Index.ets", "Navigation 路由表、继续/新游戏、入口菜单"],
                  ["故事页", "pages/StoryPage.ets", "打字机、选项渲染、结局面板、自动存档触发"],
                  ["存档页", "pages/SavesPage.ets", "存档槽列表、保存/读取/删除"],
                  ["图鉴", "pages/GalleryPage.ets", "结局卡片与收集进度"],
                  ["回顾", "pages/HistoryPage.ets", "决策时间线"],
                  ["设置", "pages/SettingsPage.ets", "阅读速度、动效、清除数据"],
                  ["组件", "component/Common.ets", "属性条、选项卡、菜单行"],
                  ["领域模型", "model/Types.ets", "Stats/Choice/StoryNode/Ending 等类型"],
                  ["剧情数据", "model/StoryData.ets", "11 个节点、5 个结局、节点查找"],
                  ["引擎", "domain/StoryEngine.ets", "条件判定、属性结算、跳转、结局裁定、视图生成"],
                  ["服务", "service/GameService.ets", "对局状态、调用引擎与仓库、对外 API"],
                  ["仓库", "data/SaveRepository.ets", "preferences 读写、槽位管理、设置与图鉴"],
              ],
              widths=[2.8, 5.4, 7.3], size=8.5)

    doc.add_heading("4.3 数据流", level=2)
    body(doc, "一次选择的完整数据流如下：")
    code_block(doc,
               "用户点击选项\n"
               "   ↓\n"
               "StoryPage.pick(choiceId)\n"
               "   ↓  await\n"
               "GameService.choose(choiceId)\n"
               "   ↓\n"
               "StoryEngine.choose(state, choiceId)\n"
               "   ├─ findChoice        选项是否存在\n"
               "   ├─ canChoose         全部 requires 是否满足\n"
               "   ├─ applyDelta        属性结算并夹取 0–10\n"
               "   ├─ push(logs)        记录决策\n"
               "   ├─ nodeId = nextId   跳转\n"
               "   └─ resolveEnding     终局节点裁定结局\n"
               "   ↓\n"
               "SaveRepository.writeSlot(0, state)  →  preferences.flush()\n"
               "   ↓\n"
               "StoryEngine.viewOf(state)  →  StoryView  →  @State 刷新 UI")
    body(doc, "页面不直接修改状态，只消费引擎生成的只读 StoryView，从而避免「界面与数据不一致」的问题。")

    doc.add_heading("4.4 关键设计决策", level=2)
    add_table(doc,
              ["决策", "备选方案", "选择理由"],
              [
                  ["单向数据流（Engine → ViewModel → UI）", "页面直接读写 GameState",
                   "状态来源唯一，便于排查与测试；页面代码只负责渲染"],
                  ["引擎与 UI / 存储解耦", "在页面里写 if-else 分支",
                   "分支逻辑可被 Hypium 直接测试，也便于后续扩充剧情"],
                  ["preferences 存 JSON", "relationalStore / 文件",
                   "数据量小（单存档 < 4 KB）、结构整体读写，preferences 的 KV + flush 更直接；"
                   "日志随对局整体保存，无需关系查询"],
                  ["Navigation + NavPathStack", "router",
                   "API 17 推荐方案，支持返回栈与页面生命周期回调"],
              ],
              widths=[5.2, 4.6, 5.7], size=8.5)

    doc.add_heading("5 模块接口设计", level=1)

    doc.add_heading("5.1 StoryEngine（领域层）", level=2)
    add_table(doc,
              ["方法", "签名", "说明"],
              [
                  ["start", "start(): GameState", "创建初始对局，属性 0/0/8，节点 n1"],
                  ["nodeOf", "nodeOf(state): StoryNode | null", "按 nodeId 查找节点，找不到返回 null"],
                  ["normalize", "normalize(state): GameState", "脏存档回退到起始节点"],
                  ["canChoose", "canChoose(state, choice): boolean", "全部 requires 满足才返回 true"],
                  ["choose", "choose(state, choiceId): ChooseResult", "校验 → 结算 → 记录 → 跳转 → 裁定结局"],
                  ["resolveEnding", "resolveEnding(state): Ending | null", "非终局节点返回 null，否则按优先级裁定"],
                  ["viewOf", "viewOf(state): StoryView", "生成页面所需的只读视图"],
              ],
              widths=[2.6, 7.2, 5.7], size=8.5)

    doc.add_heading("5.2 GameService（服务层）", level=2)
    add_table(doc,
              ["方法", "签名", "说明"],
              [
                  ["init", "init(context): Promise<boolean>", "初始化仓库，加载设置、图鉴与自动存档"],
                  ["startNew", "startNew(): void", "重置对局并立即写入自动存档"],
                  ["choose", "choose(choiceId): Promise<ChooseResult>", "调用引擎并持久化，返回结果"],
                  ["saveTo", "saveTo(slot): Promise<boolean>", "写入手动存档，失败返回 false"],
                  ["loadFrom", "loadFrom(slot): Promise<boolean>", "读取存档并同步自动存档"],
                  ["slots", "slots(): Promise<SaveSlotView[]>", "自动槽 + 3 手动槽的列表视图"],
                  ["resetAll", "resetAll(): Promise<void>", "清空存档、图鉴与设置"],
              ],
              widths=[2.4, 8.0, 5.1], size=8.5)

    doc.add_heading("5.3 SaveRepository（数据层）", level=2)
    add_table(doc,
              ["方法", "签名", "说明"],
              [
                  ["init", "init(context): Promise<void>", "获取 preferences 实例"],
                  ["writeSlot", "writeSlot(slot, state): Promise<void>", "序列化并 flush"],
                  ["readSlot", "readSlot(slot): Promise<GameState | null>", "解析并校验，失败返回 null"],
                  ["listSlots", "listSlots(): Promise<SaveSlotView[]>", "读取 4 个槽位的摘要"],
                  ["deleteSlot", "deleteSlot(slot): Promise<void>", "删除指定槽位"],
                  ["loadUnlocked / unlockEnding", "Promise<string[]>", "图鉴读取与解锁"],
                  ["saveSettings / loadSettings", "Promise<void> / Promise<AppSettings>", "设置读写"],
                  ["clearAll", "clearAll(): Promise<void>", "删除全部业务键"],
              ],
              widths=[3.6, 8.0, 3.9], size=8.5)

    doc.add_heading("5.4 接口约定", level=2)
    bullet(doc, "所有写操作必须 await 并在最后调用 flush()，否则进程被杀时可能丢失；")
    bullet(doc, "读取接口不抛异常，解析失败返回 null，由上层决定回退策略；")
    bullet(doc, "UI 不直接依赖 StoryData 的节点数组，只消费 StoryView；")
    bullet(doc, "存档 JSON 中 nodeId、stats 为必填，缺失视为无效存档。")

    doc.add_heading("6 数据结构设计", level=1)

    doc.add_heading("6.1 领域模型", level=2)
    add_table(doc,
              ["类型", "字段", "说明"],
              [
                  ["Stats", "clue, trust, sanity", "三项属性，int，0–10"],
                  ["Requirement", "stat, op, value", "判定式，op ∈ {>=, >, <=, <}"],
                  ["StatEffect", "stat, delta", "属性增减量"],
                  ["Choice", "id, text, tag, nextId, effects, flags, requires, lockHint",
                   "一个选项；requires 为空表示无条件"],
                  ["StoryNode", "id, chapter, scene, title, speaker, lines, choices, endingId",
                   "一个剧情节点；endingId 非空表示终局"],
                  ["Ending", "id, title, rank, caption, description", "结局定义，rank 为 S/A/B/C"],
                  ["LogItem", "nodeId, nodeTitle, choiceText, deltaText, at", "决策日志"],
              ],
              widths=[3.0, 7.4, 5.1], size=8.5)

    doc.add_heading("6.2 GameState 字段", level=2)
    add_table(doc,
              ["字段", "类型", "说明"],
              [
                  ["nodeId", "string", "当前节点 ID"],
                  ["stats", "Stats", "三项属性当前值"],
                  ["flags", "string[]", "剧情标记，如 letter_read、gu_ally"],
                  ["visited", "string[]", "已访问节点，用于进度追溯"],
                  ["logs", "LogItem[]", "决策日志，回顾页数据源"],
                  ["startedAt / updatedAt", "number", "时间戳（毫秒）"],
                  ["turns", "number", "决策次数"],
              ],
              widths=[3.6, 3.4, 8.5], size=8.5)

    doc.add_heading("6.3 存档 JSON 示例", level=2)
    code_block(doc,
               '{\n'
               '  "savedAt": 1764000000000,\n'
               '  "chapter": "第二章 · 旧账",\n'
               '  "title": "探长顾长风",\n'
               '  "state": "{\\"nodeId\\":\\"n6\\",\\"stats\\":{\\"clue\\":5,\\"trust\\":2,'
               '\\"sanity\\":7},\\"flags\\":[\\"told_gu\\"],\\"logs\\":[...],\\"turns\\":5}"\n'
               '}')

    doc.add_heading("6.4 规模与复杂度", level=2)
    bullet(doc, "剧情节点 11 个，条件选项 8 个，结局 5 个；")
    bullet(doc, "节点查找为线性扫描 O(n)，n = 11，单次选择开销可忽略；")
    bullet(doc, "单存档 JSON 约 1–3 KB，读取在毫秒级完成。")

    doc.add_heading("7 数据存储设计", level=1)

    doc.add_heading("7.1 方案选型", level=2)
    add_table(doc,
              ["方案", "优点", "缺点", "结论"],
              [
                  ["preferences（KV）", "API 简单、整体读写、flush 可控、适合小对象", "不适合复杂查询", "采用"],
                  ["relationalStore（SQLite）", "适合日志检索与统计", "建表与迁移成本高，本项目数据量小", "不采用"],
                  ["应用沙箱文件", "格式自由", "需自行处理并发与路径", "不采用"],
              ],
              widths=[4.4, 5.4, 4.4, 1.8], size=8.5)

    doc.add_heading("7.2 Key 设计", level=2)
    add_table(doc,
              ["Key", "Value", "说明"],
              [
                  ["slot_0", "StoredSave JSON", "自动存档，只读"],
                  ["slot_1 / slot_2 / slot_3", "StoredSave JSON", "手动存档位"],
                  ["settings", "{\"textSpeed\":24,\"motion\":true}", "阅读设置"],
                  ["unlocked_endings", "[\"e_true\", ...]", "已解锁结局 ID"],
              ],
              widths=[4.6, 7.2, 3.7], size=8.5)

    doc.add_heading("7.3 生命周期", level=2)
    code_block(doc,
               "启动\n"
               " └─ Index.aboutToAppear → GameService.init\n"
               "      ├─ Load settings / unlocked_endings\n"
               "      └─ Read slot_0 → 有存档则恢复为当前对局\n"
               "选择\n"
               " └─ choose → 写 slot_0（await + flush）\n"
               "切后台 / 销毁\n"
               " └─ EntryAbility.onBackground / onDestroy → persist()\n"
               "清除数据\n"
               " └─ SettingsPage → clearAll() → 删除全部 Key 并 flush")

    doc.add_heading("7.4 异常与兼容", level=2)
    add_table(doc,
              ["异常", "处理"],
              [
                  ["JSON 解析失败", "readSlot 返回 null，按空存档处理，不崩溃"],
                  ["nodeId 不存在", "normalize 回退到起始节点 n1"],
                  ["preferences 初始化失败", "首页保持加载态并提示，业务操作不写盘"],
                  ["旧版本缺少字段", "GameState.fromJson 对缺失字段给默认值"],
              ],
              widths=[5.0, 10.5], size=8.5)

    doc.add_heading("8 交互与视觉设计", level=1)

    doc.add_heading("8.1 页面清单", level=2)
    add_table(doc,
              ["页面", "路由", "主要内容"],
              [
                  ["首页", "Navigation 内容", "标题、继续/新游戏、读档、图鉴、设置入口"],
                  ["故事页", "Story", "章节与场景、三项属性、剧情文本、选项、结局面板、底部工具条"],
                  ["存档页", "SaveGame / LoadGame", "自动槽 + 3 手动槽，保存/读取/删除"],
                  ["结局图鉴", "Gallery", "5 张结局卡片与收集进度"],
                  ["剧情回顾", "History", "决策时间线"],
                  ["设置", "Settings", "文字速度、动效、清除数据、关于"],
              ],
              widths=[3.0, 5.2, 7.3], size=8.5)

    doc.add_heading("8.2 导航关系", level=2)
    add_image(doc, "navigation.png", 15.2, "图 8-1 页面导航关系")

    doc.add_heading("8.3 视觉规范", level=2)
    add_table(doc,
              ["元素", "取值", "用途"],
              [
                  ["背景", "#080B10 → #101A26 渐变", "雾夜氛围"],
                  ["卡片", "#121A24 / #18222E", "信息容器"],
                  ["主色", "#C9A227（雾金）", "主按钮、强调、序号"],
                  ["辅色", "#4FD1C5（雾青）", "信任属性、正向反馈"],
                  ["文字", "#E9EFF5 / #93A2B3 / #5F6E7E", "主文 / 次文 / 弱化"],
                  ["圆角", "14–22 vp", "卡片与按钮"],
              ],
              widths=[3.4, 7.2, 4.9], size=8.5)

    doc.add_heading("8.4 反馈设计", level=2)
    bullet(doc, "选项按下缩放至 0.98，120ms 回弹，提供即时触感；")
    bullet(doc, "文本逐字显示，轻触跳过；选项在打字结束后淡入（260ms）；")
    bullet(doc, "保存、读取、删除、清除均有 Toast 结果提示；")
    bullet(doc, "结局页使用大字号评级与标题，形成明确的情感落点。")

    doc.add_heading("9 测试计划", level=1)

    doc.add_heading("9.1 测试范围与方法", level=2)
    body(doc, "测试分为两层：领域层使用 Hypium 编写单元测试，在模拟器上运行，覆盖正常、边界、异常三类；界面与持久化使用模拟器手工验证，重点验证杀进程后能否恢复。")

    doc.add_heading("9.2 测试用例", level=2)
    add_table(doc,
              ["编号", "类型", "输入", "预期结果", "实际结果"],
              [
                  ["TC-01", "正常", "在 n1 选择 a_read", "跳转 n2，线索 1，日志 1 条", "【执行后填写】"],
                  ["TC-02", "正常", "进入 n11，属性 9/6/8", "结局为「雾散」", "【执行后填写】"],
                  ["TC-03", "正常", "保存到槽位 1 后重启应用", "自动存档与槽位 1 均可读取", "【执行后填写】"],
                  ["TC-04", "边界", "线索恰好为 2，选择 b_direct", "选项可点击并跳转", "【执行后填写】"],
                  ["TC-05", "边界", "线索为 1，选择 b_direct", "选项置灰，提示「需要 线索 ≥ 2」", "【执行后填写】"],
                  ["TC-06", "边界", "线索 10 再 +5；理智 0 再 -3", "结果仍为 10 与 0", "【执行后填写】"],
                  ["TC-07", "异常", "调用不存在的选项 ID", "ok=false，节点与日志不变", "【执行后填写】"],
                  ["TC-08", "异常", "读入损坏的存档 JSON", "按空存档处理，不崩溃", "【执行后填写】"],
                  ["TC-09", "异常", "存档 nodeId 被改为不存在值", "回退到 n1，页面正常显示", "【执行后填写】"],
              ],
              widths=[1.6, 1.6, 5.0, 5.2, 2.1], size=8.5)

    doc.add_heading("9.3 通过标准", level=2)
    bullet(doc, "全部单元测试用例通过，无崩溃；")
    bullet(doc, "杀进程重启后，节点、属性、日志、图鉴均可恢复；")
    bullet(doc, "条件选项的锁定 / 解锁与属性严格一致；")
    bullet(doc, "5 个结局均可通过合理路径达成。")

    doc.add_heading("10 成员分工与进度", level=1)

    doc.add_heading("10.1 成员分工", level=2)
    add_table(doc,
              ["成员", "角色", "负责内容"],
              [
                  ["【姓名】", "独立完成", "需求分析、架构设计、剧情数据、引擎、页面、持久化、测试、报告"],
              ],
              widths=[3.6, 3.4, 8.5], size=8.5)

    doc.add_heading("10.2 里程碑", level=2)
    add_table(doc,
              ["阶段", "时间", "交付物"],
              [
                  ["需求与设计", "第 1 周", "需求说明书、架构图、数据结构定义"],
                  ["工程骨架", "第 1 周", "Stage 工程、首页、Navigation 路由"],
                  ["核心逻辑", "第 2–3 周", "剧情数据、引擎、属性与结局、单元测试"],
                  ["页面与持久化", "第 3–4 周", "故事页、存档页、图鉴、回顾、设置"],
                  ["打磨与交付", "第 4–5 周", "动效、三类测试、录屏、报告、README"],
              ],
              widths=[3.6, 3.0, 8.9], size=8.5)

    doc.add_heading("10.3 风险与对策", level=2)
    add_table(doc,
              ["风险", "影响", "对策"],
              [
                  ["模拟器启动慢或签名失败", "无法运行与录屏", "提前完成华为账号实名与自动签名；保留真机备选"],
                  ["剧情分支过多导致状态难以维护", "出现死节点或属性失衡", "用数据描述分支，先跑通主路径再补条件选项"],
                  ["持久化时序问题", "杀进程丢档", "每次选择 await + flush，切后台兜底保存"],
              ],
              widths=[5.4, 4.4, 5.7], size=8.5)

    path = os.path.join(OUT_DIR, "docs", "软件需求说明书.docx")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    doc.save(path)
    return path


if __name__ == '__main__':
    print(build_srs())
