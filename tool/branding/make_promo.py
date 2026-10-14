"""Tanıtım görselleri (İngilizce): X gönderileri, GitHub önizlemesi, README ekranları.

Önce ekranlar: flutter test test_screens/promo_test.dart  (build/promo/*.png)
Sonra:         python tool/branding/make_promo.py
Üretilenler:
- docs/promo/x_1_all_chats.png … x_4_languages.png   (1600×900, X için)
- docs/promo/github_social_preview.png                (1280×640, depo ayarlarındaki sosyal önizleme)
- docs/screenshots/*.png                              (çerçeveli tek ekranlar, README)
Ekranlardaki kişiler ve mesajlar uydurmadır.
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SHOTS = os.path.join(ROOT, "build", "promo")
PROMO = os.path.join(ROOT, "docs", "promo")
README_SHOTS = os.path.join(ROOT, "docs", "screenshots")
LOGO = os.path.join(ROOT, "assets", "branding", "mesa_play_512.png")
FONTS = r"C:\Windows\Fonts"

BRAND_A, BRAND_B = (0x3D, 0x5A, 0xFE), (0x7C, 0x4D, 0xFF)
INK, INK_SOFT = (20, 20, 43), (74, 74, 104)
# Ekran görüntüsünde üstteki durum çubuğu ve alttaki hareket çubuğu payı (px, 1080 genişlikte).
STATUS_H, GESTURE_H = 63, 42


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), size)


BOLD = lambda s: font("segoeuib.ttf", s)  # noqa: E731
SEMI = lambda s: font("seguisb.ttf", s)  # noqa: E731
REG = lambda s: font("segoeui.ttf", s)  # noqa: E731


def gradient(w, h, a, b):
    yy, xx = np.mgrid[0:h, 0:w]
    t = ((xx / max(w - 1, 1) + yy / max(h - 1, 1)) / 2)[..., None]
    a, b = np.array(a, float), np.array(b, float)
    return Image.fromarray((a + (b - a) * t).astype("uint8"), "RGB")


def rounded_mask(size, radius, ss=3):
    w, h = size
    m = Image.new("L", (w * ss, h * ss), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w * ss - 1, h * ss - 1], radius=radius * ss, fill=255)
    return m.resize((w, h), Image.LANCZOS)


def luminance(img, box):
    region = np.asarray(img.crop(box).convert("RGB"), float)
    return float((region @ [0.299, 0.587, 0.114]).mean())


def status_bar(screen):
    """Ekranın üstüne 9:41, sinyal ve pil; altına hareket çubuğu."""
    w, h = screen.size
    s = w / 1080
    d = ImageDraw.Draw(screen)
    dark_top = luminance(screen, (0, 0, w, int(STATUS_H * s))) < 128
    fg = (255, 255, 255, 235) if dark_top else (27, 27, 31, 235)
    d.text((int(54 * s), int(31 * s)), "9:41", font=SEMI(int(30 * s)), fill=fg, anchor="lm")
    # Sinyal: dört çubuk.
    x = w - int(190 * s)
    for i in range(4):
        bh = int((10 + i * 6) * s)
        d.rounded_rectangle([x + i * int(10 * s), int(44 * s) - bh, x + i * int(10 * s) + int(6 * s), int(44 * s)],
                            radius=int(2 * s), fill=fg)
    # Pil.
    bx, by = w - int(120 * s), int(20 * s)
    d.rounded_rectangle([bx, by, bx + int(56 * s), by + int(26 * s)], radius=int(7 * s), outline=fg, width=max(2, int(3 * s)))
    d.rounded_rectangle([bx + int(5 * s), by + int(5 * s), bx + int(42 * s), by + int(21 * s)], radius=int(4 * s), fill=fg)
    d.rounded_rectangle([bx + int(58 * s), by + int(8 * s), bx + int(63 * s), by + int(18 * s)], radius=int(2 * s), fill=fg)
    # Ön kamera deliği.
    cx, cy, r = w // 2, int(31 * s), int(13 * s)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(10, 10, 14, 255))
    # Hareket çubuğu.
    dark_bottom = luminance(screen, (0, h - int(GESTURE_H * s), w, h)) < 128
    pill = (255, 255, 255, 200) if dark_bottom else (27, 27, 31, 170)
    pw, ph = int(300 * s), int(12 * s)
    d.rounded_rectangle([w // 2 - pw // 2, h - int(GESTURE_H * s) // 2 - ph // 2, w // 2 + pw // 2,
                         h - int(GESTURE_H * s) // 2 + ph // 2], radius=ph // 2, fill=pill)
    return screen


def phone(name, height, shadow=True):
    """Çerçeveli telefon (RGBA) — gölgeli ya da gölgesiz."""
    shot = Image.open(os.path.join(SHOTS, name + ".png")).convert("RGBA")
    bezel_ratio, outer_r, inner_r = 0.034, 0.125, 0.10
    sh = height / (1 + 2 * bezel_ratio * 1080 / 2340)
    sw = int(sh * 1080 / 2340)
    sh = int(sw * 2340 / 1080)
    b = int(sw * bezel_ratio)
    screen = status_bar(shot.resize((sw, sh), Image.LANCZOS))
    fw, fh = sw + 2 * b, sh + 2 * b
    frame = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    body = Image.new("RGBA", (fw, fh), (14, 14, 18, 255))
    frame.paste(body, (0, 0), rounded_mask((fw, fh), int(sw * outer_r)))
    # İnce kenar parlaması.
    ImageDraw.Draw(frame).rounded_rectangle([1, 1, fw - 2, fh - 2], radius=int(sw * outer_r), outline=(70, 70, 84, 255), width=2)
    frame.paste(screen, (b, b), rounded_mask((sw, sh), int(sw * inner_r)))
    if not shadow:
        return frame
    pad = int(fw * 0.22)
    out = Image.new("RGBA", (fw + 2 * pad, fh + 2 * pad), (0, 0, 0, 0))
    sh_mask = Image.new("L", out.size, 0)
    sh_mask.paste(rounded_mask((fw, fh), int(sw * outer_r)), (pad, pad + int(fh * 0.03)))
    sh_mask = sh_mask.filter(ImageFilter.GaussianBlur(fw * 0.07)).point(lambda v: int(v * 0.45))
    out.paste(Image.new("RGBA", out.size, (30, 26, 77, 255)), (0, 0), sh_mask)
    out.alpha_composite(frame, (pad, pad))
    out.info["pad"] = pad
    return out


def place(canvas, ph, x, y):
    """Telefonu çerçevesinin sol üstü (x, y) olacak şekilde yerleştirir (gölge payı düşülür)."""
    pad = ph.info.get("pad", 0)
    canvas.paste(ph, (x - pad, y - pad), ph)


def wrap(draw, text, fnt, width):
    lines = []
    for para in text.split("\n"):
        line = ""
        for word in para.split(" "):
            test = (line + " " + word).strip()
            if draw.textlength(test, font=fnt) <= width:
                line = test
            else:
                lines.append(line)
                line = word
        lines.append(line)
    return lines


def text_block(draw, x, y, text, fnt, fill, width, spacing=1.18):
    for line in wrap(draw, text, fnt, width):
        draw.text((x, y), line, font=fnt, fill=fill)
        y += int(fnt.size * spacing)
    return y


def logo(size):
    img = Image.open(LOGO).convert("RGBA").resize((size, size), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img, (0, 0), rounded_mask((size, size), int(size * 0.28)))
    return out


def brand_row(canvas, x, y, size, color):
    lg = logo(size)
    canvas.paste(lg, (x, y), lg)
    ImageDraw.Draw(canvas, "RGBA").text((x + size + int(size * 0.28), y + size // 2), "Mesa", font=BOLD(int(size * 0.62)),
                                fill=color, anchor="lm")


def pills(canvas, x, y, items, fnt, fg, bg):
    d = ImageDraw.Draw(canvas, "RGBA")
    for item in items:
        w = int(d.textlength(item, font=fnt)) + 2 * int(fnt.size * 0.9)
        h = int(fnt.size * 2.0)
        d.rounded_rectangle([x, y, x + w, y + h], radius=h // 2, fill=bg)
        d.text((x + w // 2, y + h // 2), item, font=fnt, fill=fg, anchor="mm")
        x += w + int(fnt.size * 0.6)
    return y + int(fnt.size * 2.0)


def light_canvas(w, h):
    return gradient(w, h, (246, 244, 255), (236, 240, 255))


def save(img, folder, name):
    os.makedirs(folder, exist_ok=True)
    img.convert("RGB").save(os.path.join(folder, name), optimize=True)
    print(name)


# ---- X 1: tek gelen kutusu (marka zemin) ----
def hero(w, h, scale):
    c = gradient(w, h, BRAND_A, BRAND_B)
    d = ImageDraw.Draw(c, "RGBA")
    x = int(110 * scale)
    brand_row(c, x, int(100 * scale), int(84 * scale), (255, 255, 255, 255))
    y = text_block(d, x, int(240 * scale), "All your chats.\nOne inbox.", BOLD(int(86 * scale)), (255, 255, 255, 255),
                   int(720 * scale), 1.12)
    y = text_block(d, x, y + int(26 * scale),
                   "WhatsApp, Telegram, Instagram, Discord and more, together in one Android app.",
                   REG(int(33 * scale)), (255, 255, 255, 225), int(640 * scale), 1.3)
    pills(c, x, y + int(40 * scale), ["Read without \u201cseen\u201d", "Stays on your phone", "8 languages"],
          SEMI(int(24 * scale)), (255, 255, 255, 255), (255, 255, 255, 46))
    # Telefonlar sağ kenara göre: 1600 genişlikte arka 1200, ön 890.
    place(c, phone("chat", int(700 * scale)), w - int(400 * scale), int(150 * scale))
    place(c, phone("inbox", int(790 * scale)), w - int(710 * scale), int(70 * scale))
    return c


save(hero(1600, 900, 1.0), PROMO, "x_1_all_chats.png")

# ---- GitHub sosyal önizleme (1280×640) ----
save(hero(1280, 640, 640 / 900), PROMO, "github_social_preview.png")


def feature(headline, body, extra, phones):
    c = light_canvas(1600, 900)
    d = ImageDraw.Draw(c, "RGBA")
    brand_row(c, 110, 96, 56, INK + (255,))
    y = text_block(d, 110, 210, headline, BOLD(72), INK + (255,), 640, 1.12)
    y = text_block(d, 110, y + 24, body, REG(31), INK_SOFT + (255,), 600, 1.35)
    if extra:
        pills(c, 110, y + 36, extra, SEMI(23), (61, 90, 254, 255), (61, 90, 254, 30))
    for name, height, x, y0 in phones:
        place(c, phone(name, height), x, y0)
    return c


save(feature("Read without sending \u201cseen\u201d",
             "Open WhatsApp and Instagram messages in Mesa. The sender sees no read receipt until you reply. "
             "Optional ghost mode for Telegram, too.",
             ["No servers", "No account", "On-device"],
             [("chat", 790, 960, 70)]),
         PROMO, "x_2_read_without_seen.png")

save(feature("Stay on top of every chat",
             "People waiting for your reply come first. Snooze chats, schedule messages, set automatic "
             "replies and see your week at a glance.",
             ["Auto-replies", "Scheduled messages", "Weekly summary"],
             [("rules", 700, 1190, 150), ("summary", 790, 880, 70)]),
         PROMO, "x_3_organized.png")

save(feature("Speaks your language",
             "English, Spanish, Portuguese, German, French, Turkish, Russian and Arabic, "
             "with full right-to-left support.",
             ["8 languages", "Right-to-left"],
             [("inbox_ru", 660, 1230, 170), ("inbox_es", 660, 760, 170), ("inbox_ar", 760, 980, 70)]),
         PROMO, "x_4_languages.png")

# ---- README için çerçeveli tek ekranlar (şeffaf zemin) ----
for name in ["inbox", "chat", "services", "rules", "summary", "inbox_dark", "group_dark", "language", "inbox_ar"]:
    ph = phone(name, 1100)
    ph.save(os.path.join(README_SHOTS, name + ".png") if os.path.isdir(README_SHOTS) else
            (os.makedirs(README_SHOTS, exist_ok=True) or os.path.join(README_SHOTS, name + ".png")), optimize=True)
print("README ekranları:", README_SHOTS)
