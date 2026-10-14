"""Mesa logosunun bütün dosyalarını tek geometriden üretir.

Çalıştırma (depo kökünden): python tool/branding/make_icons.py
Üretilenler:
- android/.../res/drawable/ic_launcher_foreground.xml   (uyarlanabilir simge ön yüzü)
- android/.../res/drawable/ic_launcher_monochrome.xml   (Android 13+ tema simgesi)
- android/.../res/drawable/ic_notification.xml          (bildirim simgesi, tek renk)
- android/.../res/mipmap-*/ic_launcher.png               (Android 8 öncesi)
- assets/branding/mesa_logo.svg, mesa_play_512.png, mesa_onizleme.png
Arka plan (ic_launcher_background.xml) marka geçişidir: #3D5AFE → #7C4DFF.
"""
import os

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
BRANDING = os.path.join(ROOT, "assets", "branding")

# 108 birimlik uyarlanabilir simge tuvali; ortadaki 66 birimlik daire güvenli alan.
BG_START, BG_END = "#3D5AFE", "#7C4DFF"
BUBBLE = (28, 30, 80, 70, 10)          # x0, y0, x1, y1, köşe yarıçapı
TAIL = [(50, 70), (38, 79), (38, 70)]  # sol alttaki kuyruk
BARS = [                               # x, y, uzunluk, renk (yükseklik 6)
    (36, 38, 32, "#34D399"),
    (36, 47, 24, "#60A5FA"),
    (36, 56, 28, "#F472B6"),
]
BAR_H = 6
BUBBLE_PATH = ("M38,30h32a10,10 0,0 1,10 10v20a10,10 0,0 1,-10 10h-20l-12,9v-9"
               "a10,10 0,0 1,-10 -10v-20a10,10 0,0 1,10 -10z")


def bar_path(x, y, w):
    r = BAR_H / 2
    return f"M{x + r:g},{y:g}h{w - 2 * r:g}a{r:g},{r:g} 0,0 1,0 {BAR_H:g}h{-(w - 2 * r):g}a{r:g},{r:g} 0,0 1,0 {-BAR_H:g}z"


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


# ---- Vektörler ----

def vector(comment, body, size=108, viewport=108, translate=None):
    group_open = group_close = ""
    if translate:
        group_open = f'    <group android:translateX="{translate[0]:g}" android:translateY="{translate[1]:g}">\n'
        group_close = "    </group>\n"
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        f"<!-- {comment} Üretildi: tool/branding/make_icons.py -->\n"
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        f'    android:width="{size}dp"\n    android:height="{size}dp"\n'
        f'    android:viewportWidth="{viewport:g}"\n    android:viewportHeight="{viewport:g}">\n'
        + group_open + body + group_close + "</vector>\n"
    )


def path_xml(d, color="#FFFFFFFF", even_odd=False, indent="    "):
    fill_type = f'\n{indent}    android:fillType="evenOdd"' if even_odd else ""
    return f'{indent}<path\n{indent}    android:fillColor="{color}"{fill_type}\n{indent}    android:pathData="{d}" />\n'


def argb(hex_color):
    return "#FF" + hex_color.lstrip("#").upper()


foreground = path_xml(BUBBLE_PATH) + "".join(path_xml(bar_path(x, y, w), argb(c)) for x, y, w, c in BARS)
write(os.path.join(RES, "drawable", "ic_launcher_foreground.xml"),
      vector("Mesa simgesi ön yüzü: tek balonda farklı uygulamalardan sohbetler.", foreground))

cutout = BUBBLE_PATH + "".join(bar_path(x, y, w) for x, y, w, _ in BARS)
write(os.path.join(RES, "drawable", "ic_launcher_monochrome.xml"),
      vector("Mesa tema simgesi (tek renk; çizgiler oyuk).", path_xml(cutout, even_odd=True)))

# Bildirim simgesi: balonun çevresi kırpılmış 58 birimlik tuval, 24dp.
write(os.path.join(RES, "drawable", "ic_notification.xml"),
      vector("Mesa bildirim simgesi (tek renk).", path_xml(cutout, even_odd=True, indent="        "),
             size=24, viewport=58, translate=(-25, -25.5)))

# ---- SVG ana dosya ----
svg = (
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" width="512" height="512">\n'
    '  <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">'
    f'<stop offset="0" stop-color="{BG_START}"/><stop offset="1" stop-color="{BG_END}"/></linearGradient></defs>\n'
    '  <rect width="108" height="108" fill="url(#g)"/>\n'
    f'  <path d="{BUBBLE_PATH}" fill="#FFFFFF"/>\n'
    + "".join(f'  <path d="{bar_path(x, y, w)}" fill="{c}"/>\n' for x, y, w, c in BARS)
    + "</svg>\n"
)
write(os.path.join(BRANDING, "mesa_logo.svg"), svg)


# ---- PNG'ler ----

def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def render(px, crop=(18, 90), mask=None, mono=None, background=True):
    """crop: 108'lik tuvalin görünen bölümü (uyarlanabilir simgede ortadaki 72)."""
    ss = 4
    n = px * ss
    k = n / (crop[1] - crop[0])
    off = crop[0]

    def p(x, y):
        return ((x - off) * k, (y - off) * k)

    if background:
        a, b = np.array(hex_rgb(BG_START), float), np.array(hex_rgb(BG_END), float)
        yy, xx = np.mgrid[0:n, 0:n]
        t = ((xx + yy) / (2 * (n - 1)))[..., None]
        img = Image.fromarray((a + (b - a) * t).astype("uint8"), "RGB").convert("RGBA")
    else:
        img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    fg = mono or (255, 255, 255, 255)
    x0, y0, x1, y1, r = BUBBLE
    d.rounded_rectangle([p(x0, y0), p(x1, y1)], radius=r * k, fill=fg)
    d.polygon([p(*pt) for pt in TAIL], fill=fg)
    for x, y, w, c in BARS:
        color = (0, 0, 0, 0) if mono else hex_rgb(c) + (255,)
        d.rounded_rectangle([p(x, y), p(x + w, y + BAR_H)], radius=BAR_H / 2 * k, fill=color)
    img = img.resize((px, px), Image.LANCZOS)
    if mask:
        m = Image.new("L", (px * ss, px * ss), 0)
        md = ImageDraw.Draw(m)
        if mask == "circle":
            md.ellipse([0, 0, px * ss - 1, px * ss - 1], fill=255)
        else:
            md.rounded_rectangle([0, 0, px * ss - 1, px * ss - 1], radius=int(px * ss * mask), fill=255)
        m = m.resize((px, px), Image.LANCZOS)
        out = Image.new("RGBA", (px, px), (0, 0, 0, 0))
        out.paste(img, (0, 0), m)
        img = out
    return img


for folder, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    render(size, mask=0.22).save(os.path.join(RES, f"mipmap-{folder}", "ic_launcher.png"), optimize=True)

os.makedirs(BRANDING, exist_ok=True)
render(512).convert("RGB").save(os.path.join(BRANDING, "mesa_play_512.png"), optimize=True)

# ---- Önizleme: ana ekranda farklı maskeler, tema simgesi, bildirim, açılış ----
W, H = 1200, 560
prev = Image.new("RGB", (W, H), (245, 243, 250))
dark = Image.new("RGB", (W // 2, H), (24, 24, 32))
prev.paste(dark, (W // 2, 0))
size = 150
spots = [(60, 60), (260, 60), (60, 300), (260, 300)]
light_icons = [render(size, mask="circle"), render(size, mask=0.30), render(size, mask=0.12),
               render(size, mask=0.30, mono=(84, 70, 180, 255), background=False)]
# Tema simgesi: açık mor zemin üstünde koyu mor şekil.
themed_bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
ImageDraw.Draw(themed_bg).rounded_rectangle([0, 0, size - 1, size - 1], radius=int(size * 0.30), fill=(226, 221, 255, 255))
themed_bg.alpha_composite(light_icons[3])
light_icons[3] = themed_bg
for (x, y), icon in zip(spots, light_icons):
    prev.paste(icon, (x, y), icon)
for (x, y), icon in zip(spots, light_icons):
    prev.paste(icon, (x + W // 2, y), icon)
# Bildirim çubuğu simgesi (beyaz, küçük) ve açılış ekranı.
bar = Image.new("RGB", (220, 60), (40, 40, 52))
note = render(48, crop=(25, 83), mono=(255, 255, 255, 255), background=False)
bar.paste(note, (16, 6), note)
prev.paste(bar, (470, 60))
ga, gb = np.array(hex_rgb(BG_START), float), np.array(hex_rgb(BG_END), float)
yy, xx = np.mgrid[0:270, 0:150]
tt = ((xx / 149 + yy / 269) / 2)[..., None]
splash = Image.fromarray((ga + (gb - ga) * tt).astype("uint8"), "RGB")
logo = render(110, crop=(18, 90), background=False)
splash.paste(logo, (20, 80), logo)
prev.paste(splash, (470, 160))
prev.save(os.path.join(BRANDING, "mesa_onizleme.png"))
print("simgeler üretildi")
