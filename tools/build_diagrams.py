# -*- coding: utf-8 -*-
"""生成架构图与页面导航图（PNG），供 README / 需求说明书 / 报告使用。"""

import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "images")
FONT = "C:/Windows/Fonts/msyh.ttc"
FONT_BOLD = "C:/Windows/Fonts/msyhbd.ttc"

INK = "#1F2933"
SUB = "#5B6774"


def font(size, bold=False):
    return ImageFont.truetype(FONT_BOLD if bold else FONT, size, index=0)


def rounded(draw, box, fill, outline, width=2, radius=14):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def arrow(draw, x1, y1, x2, y2, color="#8A97A6", width=3):
    draw.line((x1, y1, x2, y2), fill=color, width=width)
    head = 9
    draw.polygon([(x2, y2), (x2 - head, y2 - head * 1.6), (x2 + head, y2 - head * 1.6)], fill=color)


def centered(draw, box, text, f, fill=INK):
    cx = (box[0] + box[2]) / 2
    cy = (box[1] + box[3]) / 2
    draw.text((cx, cy), text, font=f, fill=fill, anchor="mm")


def build_architecture():
    W, H = 1600, 1120
    img = Image.new("RGB", (W, H), "#FFFFFF")
    d = ImageDraw.Draw(img)

    d.text((W / 2, 46), "《雾港回声》系统分层架构", font=font(40, True), fill=INK, anchor="mm")
    d.text((W / 2, 96), "上层依赖下层，领域层不依赖 UI 与存储，可独立单元测试",
           font=font(20), fill=SUB, anchor="mm")

    left, right = 60, W - 60
    label_w = 150
    top = 140
    layer_h = 168
    gap = 18

    layers = [
        ("表现层", "#E9F0FA", "#3C6E9F",
         ["Index 首页\nNavigation 路由", "StoryPage 故事页", "SavesPage 存档页",
          "GalleryPage 图鉴", "HistoryPage 回顾", "SettingsPage 设置"]),
        ("组件层", "#EAF6F3", "#2F7D72",
         ["Common.ets\nStatBar / ChoiceCard / MenuRow", "Theme.ets\n深色雾金视觉规范"]),
        ("服务层", "#FDF4E4", "#B8860B",
         ["GameService（单例）\n对局状态 · 编排引擎与仓库"]),
        ("领域层", "#F3EEFA", "#6A4C93",
         ["StoryEngine\n条件判定 / 属性结算 / 结局裁定", "StoryData\n11 节点 · 5 结局",
          "Types / GameState\n模型与序列化"]),
        ("数据层", "#EFF1F4", "#5A6675",
         ["SaveRepository\n槽位 / 设置 / 图鉴", "preferences\nslot_0..3 · settings · endings"]),
    ]

    y = top
    boxes_centers = []
    for name, fill, outline, items in layers:
        rounded(d, (left, y, right, y + layer_h), fill, outline, width=2, radius=16)
        d.text((left + 24, y + layer_h / 2), name, font=font(26, True), fill=outline, anchor="lm")

        x0 = left + label_w
        x1 = right - 18
        n = len(items)
        inner_gap = 12
        box_w = (x1 - x0 - inner_gap * (n - 1)) / n
        centers = []
        for i, text in enumerate(items):
            bx0 = x0 + i * (box_w + inner_gap)
            bx1 = bx0 + box_w
            rounded(d, (bx0, y + 20, bx1, y + layer_h - 20), "#FFFFFF", outline, width=1, radius=10)
            lines = text.split("\n")
            cy = (y + layer_h / 2) if len(lines) == 1 else (y + 20 + (layer_h - 40) / 2 - 8)
            for j, line in enumerate(lines):
                d.text(((bx0 + bx1) / 2, cy + j * 22), line, font=font(17), fill=INK, anchor="mm")
            centers.append((bx0 + bx1) / 2)
        boxes_centers.append((y + layer_h, centers))
        y += layer_h + gap

    # 层间箭头
    for i in range(len(layers) - 1):
        y_from = boxes_centers[i][0]
        y_to = y_from + gap
        for cx in boxes_centers[i][1][:3]:
            arrow(d, cx, y_from, cx, y_to - 2)

    d.text((W / 2, H - 34), "数据流：用户选择 → GameService → StoryEngine → SaveRepository → StoryView → 页面刷新",
           font=font(18), fill=SUB, anchor="mm")

    path = os.path.join(OUT, "architecture.png")
    os.makedirs(OUT, exist_ok=True)
    img.save(path)
    return path


def build_navigation():
    W, H = 1500, 760
    img = Image.new("RGB", (W, H), "#FFFFFF")
    d = ImageDraw.Draw(img)

    d.text((W / 2, 44), "页面导航关系", font=font(38, True), fill=INK, anchor="mm")
    d.text((W / 2, 92), "Navigation + NavPathStack，页面之间最多两层", font=font(19), fill=SUB, anchor="mm")

    nodes = {
        "home": (600, 130, 900, 230, "首页", "Index", "#E9F0FA", "#3C6E9F"),
        "settings": (1070, 120, 1430, 220, "设置", "Settings", "#EFF1F4", "#5A6675"),
        "story": (600, 310, 900, 410, "故事页", "Story", "#FDF4E4", "#B8860B"),
        "saves": (1070, 280, 1430, 380, "存档页", "SaveGame / LoadGame", "#EAF6F3", "#2F7D72"),
        "gallery": (1070, 450, 1430, 550, "结局图鉴", "Gallery", "#F3EEFA", "#6A4C93"),
        "history": (600, 500, 900, 600, "剧情回顾", "History", "#F3EEFA", "#6A4C93"),
    }

    for key, (x0, y0, x1, y1, title, sub, fill, outline) in nodes.items():
        rounded(d, (x0, y0, x1, y1), fill, outline, width=2, radius=14)
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        d.text((cx, cy - 12), title, font=font(21, True), fill=INK, anchor="mm")
        d.text((cx, cy + 16), sub, font=font(14), fill=SUB, anchor="mm")

    def link(a, b, label, side):
        ax0, ay0, ax1, ay1 = nodes[a][:4]
        bx0, by0, bx1, by1 = nodes[b][:4]
        if side == "v":
            x = (ax0 + ax1) / 2
            arrow(d, x, ay1, x, by0 - 3)
            d.text((x + 12, (ay1 + by0) / 2), label, font=font(15), fill=SUB, anchor="lm")
        elif side == "h":
            y = (ay0 + ay1) / 2
            arrow(d, ax1, y, bx0 - 3, y)
            d.text(((ax1 + bx0) / 2, y - 18), label, font=font(15), fill=SUB, anchor="mm")
        elif side == "dr":
            arrow(d, ax1, ay1 - 12, bx0 - 4, by0 + 14)
            d.text(((ax1 + bx0) / 2 + 6, (ay1 + by0) / 2 - 18), label, font=font(15), fill=SUB)
        elif side == "ur":
            arrow(d, ax1, ay0 + 12, bx0 - 4, by1 - 14)
            d.text(((ax1 + bx0) / 2 + 6, (ay0 + by1) / 2 + 10), label, font=font(15), fill=SUB)

    link("home", "story", "开始 / 继续", "v")
    link("home", "settings", "设置", "h")
    link("story", "saves", "存档", "ur")
    link("story", "gallery", "达成结局", "dr")
    link("story", "history", "回顾", "v")

    d.text((W / 2, H - 92), "首页另有「读取存档」入口：读取成功后回到首页并重新进入故事页，",
           font=font(17), fill=SUB, anchor="mm")
    d.text((W / 2, H - 64), "保证导航栈中只有一条对局路径，避免重复进入故事页。",
           font=font(17), fill=SUB, anchor="mm")

    path = os.path.join(OUT, "navigation.png")
    img.save(path)
    return path


if __name__ == "__main__":
    print(build_architecture())
    print(build_navigation())
