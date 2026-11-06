#!/usr/bin/env python3
"""Генерирует иконки приложения, launch-картинки и иконку Cydia-репозитория (нужен Pillow)."""
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOP, BOTTOM = (40, 52, 70), (22, 28, 38)
CARDS = [(211, 47, 47), (251, 192, 45), (2, 136, 209)]


def gradient(w, h):
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(1, h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3)))
    return img


def icon(size):
    s = 4  # supersampling
    S = size * s
    img = gradient(S, S)
    d = ImageDraw.Draw(img)
    cw, ch = int(S * 0.66), int(S * 0.40)
    x = (S - cw) // 2
    for i, color in enumerate(CARDS):
        y = int(S * 0.18) + i * int(S * 0.15)
        d.rounded_rectangle([x, y, x + cw, y + ch], radius=int(S * 0.06), fill=color)
    # штрихкод на верхней карте
    y = int(S * 0.18) + 2 * int(S * 0.15)
    bx, by, bh = x + int(cw * 0.12), y + int(ch * 0.45), int(ch * 0.35)
    d.rectangle([x + int(cw * 0.08), by - int(ch * 0.08), x + int(cw * 0.92), by + bh + int(ch * 0.08)], fill="white")
    pattern = "1011001010011101011001101010111001011"
    mw = int(cw * 0.76) / len(pattern)
    for i, c in enumerate(pattern):
        if c == "1":
            d.rectangle([bx + i * mw, by, bx + (i + 1) * mw - 1, by + bh], fill="black")
    return img.resize((size, size), Image.LANCZOS)


def launch(w, h):
    img = gradient(w, h)
    ic = icon(w // 3)
    img.paste(ic, ((w - ic.width) // 2, (h - ic.height) // 2 - h // 10))
    return img


def main():
    res = os.path.join(ROOT, "Resources")
    for name, size in [("Icon.png", 57), ("Icon@2x.png", 114)]:
        icon(size).save(os.path.join(res, name))
    for name, (w, h) in [("Default.png", (320, 480)), ("Default@2x.png", (640, 960)), ("Default-568h@2x.png", (640, 1136))]:
        launch(w, h).save(os.path.join(res, name))
    icon(64).save(os.path.join(ROOT, "repo", "CydiaIcon.png"))
    icon(29).save(os.path.join(ROOT, "repo", "icon.png"))


if __name__ == "__main__":
    main()
