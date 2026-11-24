# -*- coding: utf-8 -*-
"""生成应用图标（分层图标的前景 / 背景），输出到 AppScope 与 entry 的 media 目录。"""

import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGETS = [
    os.path.join(ROOT, "AppScope", "resources", "base", "media"),
    os.path.join(ROOT, "entry", "src", "main", "resources", "base", "media"),
]

GOLD = (201, 162, 39)
GOLD_LIGHT = (232, 214, 160)


def vertical_gradient(size, top, bottom):
    img = Image.new("RGB", (1, size), top)
    d = ImageDraw.Draw(img)
    for y in range(size):
        t = y / max(1, size - 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        d.point((0, y), fill=color)
    return img.resize((size, size))


def build_background(size=1024):
    img = vertical_gradient(size, (6, 9, 13), (20, 34, 48)).convert("RGBA")
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    # 中心微光，让前景的金环有依托
    d.ellipse([size * 0.18, size * 0.18, size * 0.82, size * 0.82],
              fill=(36, 56, 74, 40))

    # 雾层：低透明度弧线，整体再高斯模糊，避免出现彩虹感
    for i, radius in enumerate((640, 540, 450)):
        alpha = 9 + i * 5
        d.arc([size / 2 - radius, size / 2 - radius * 0.55,
               size / 2 + radius, size / 2 + radius * 1.45],
              start=200, end=340, fill=(130, 170, 200, alpha), width=44)

    overlay = overlay.filter(ImageFilter.GaussianBlur(26))

    # 地平线微光
    line = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    dl = ImageDraw.Draw(line)
    dl.line([(0, int(size * 0.73)), (size, int(size * 0.73))],
            fill=(201, 162, 39, 40), width=4)
    line = line.filter(ImageFilter.GaussianBlur(6))

    return Image.alpha_composite(Image.alpha_composite(img, overlay), line).convert("RGB")


def build_foreground(size=1024):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = size / 2, size / 2

    # 细金环
    ring = 300
    d.ellipse([cx - ring, cy - ring, cx + ring, cy + ring],
              outline=(201, 162, 39, 210), width=10)
    d.ellipse([cx - ring + 26, cy - ring + 26, cx + ring - 26, cy + ring - 26],
              outline=(201, 162, 39, 80), width=3)

    # 中央「雾」字
    font = ImageFont.truetype("C:/Windows/Fonts/msyhbd.ttc", 360, index=0)
    d.text((cx, cy + 6), "雾", font=font, fill=GOLD_LIGHT + (255,), anchor="mm")

    # 底部一条短光带，呼应「回声」
    d.rounded_rectangle([cx - 90, cy + 205, cx + 90, cy + 219], radius=7,
                        fill=(201, 162, 39, 120))
    return img


def main():
    bg = build_background()
    fg = build_foreground()
    for target in TARGETS:
        os.makedirs(target, exist_ok=True)
        bg.save(os.path.join(target, "background.png"))
        fg.save(os.path.join(target, "foreground.png"))
        print(os.path.join(target, "background.png"))
        print(os.path.join(target, "foreground.png"))


if __name__ == "__main__":
    main()
