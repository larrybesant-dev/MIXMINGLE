#!/usr/bin/env python3
"""MIXVY Brand Asset Generator — generates all icon/logo PNGs and deploys them."""

import math, shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# ── Paths ──────────────────────────────────────────────────────────────────────
BASE = Path(r'C:/Users/LARRY/MIXMINGLE/assets/brand')
APP  = Path(r'C:/Users/LARRY/MIXMINGLE')

FONTS = [
    r'C:/Windows/Fonts/ariblk.ttf',   # Arial Black  (preferred)
    r'C:/Windows/Fonts/impact.ttf',   # Impact
    r'C:/Windows/Fonts/arialbd.ttf',  # Arial Bold
]

# ── Brand palette ──────────────────────────────────────────────────────────────
BG_INNER   = (13, 10, 35, 255)
BG_OUTER   = (6,  5,  18, 255)
RING_CORE  = (110, 65, 240, 255)   # purple-blue
RING_GLOW  = (59, 130, 246, 255)   # electric blue
PURPLE_LT  = (167, 139, 250, 255)

TEXT_STOPS_COLOR = [
    (255, 255, 255, 255),
    (220, 200, 255, 255),
    (147, 100, 250, 255),
    (59,  130, 246, 255),
]
TEXT_STOPS_BW = [
    (255, 255, 255, 255),
    (190, 190, 190, 255),
    (130, 130, 130, 255),
]


# ── Helpers ────────────────────────────────────────────────────────────────────

def load_font(size):
    for path in FONTS:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            pass
    return ImageFont.load_default()


def radial_gradient(w, h, inner, outer):
    ys, xs = np.mgrid[0:h, 0:w]
    cx, cy = w / 2.0, h / 2.0
    r = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2)
    t = np.clip(r / math.sqrt(cx ** 2 + cy ** 2), 0, 1)[..., np.newaxis]
    arr = (np.array(inner) * (1 - t) + np.array(outer) * t).astype(np.uint8)
    return Image.fromarray(arr, 'RGBA')


def linear_gradient_h(w, h, stops):
    n = len(stops) - 1
    xs = np.linspace(0, 1, w) * n
    seg = np.floor(xs).astype(int).clip(0, n - 1)
    lt = (xs - seg)[..., np.newaxis]
    ca = np.array(stops, dtype=np.float32)
    row = ca[seg] * (1 - lt) + ca[np.minimum(seg + 1, n)] * lt
    row = row.astype(np.uint8)
    return Image.fromarray(np.tile(row[np.newaxis], (h, 1, 1)), 'RGBA')


def _text_origin(font, text, cx, cy):
    try:
        bb = font.getbbox(text)
        return int(cx - (bb[2] - bb[0]) / 2 - bb[0]), int(cy - (bb[3] - bb[1]) / 2 - bb[1])
    except AttributeError:
        w, h = font.getsize(text)
        return int(cx - w / 2), int(cy - h / 2)


def paste_gradient_text(canvas, text, cx, cy, font, stops, glow_col=None, glow_r=16):
    W, H = canvas.size
    tx, ty = _text_origin(font, text, cx, cy)

    if glow_col and glow_r > 0:
        for blur, alpha in [(glow_r, 130), (glow_r // 2, 90), (glow_r // 4, 60)]:
            gl = Image.new('RGBA', (W, H), (0, 0, 0, 0))
            ImageDraw.Draw(gl).text((tx, ty), text, font=font, fill=glow_col[:3] + (alpha,))
            gl = gl.filter(ImageFilter.GaussianBlur(max(blur, 1)))
            canvas.alpha_composite(gl)

    mask = Image.new('L', (W, H), 0)
    ImageDraw.Draw(mask).text((tx, ty), text, font=font, fill=255)
    grad = linear_gradient_h(W, H, stops)
    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    layer.paste(grad, mask=mask)
    canvas.alpha_composite(layer)


def draw_ring(canvas, cx, cy, rx, ry, color, thickness=8, glow=True):
    W, H = canvas.size
    if glow:
        for blur, alpha, exp in [(30, 22, 22), (18, 40, 12), (8, 65, 5)]:
            gl = Image.new('RGBA', (W, H), (0, 0, 0, 0))
            ImageDraw.Draw(gl).ellipse(
                [cx - rx - exp, cy - ry - exp, cx + rx + exp, cy + ry + exp],
                outline=color[:3] + (alpha,), width=thickness)
            gl = gl.filter(ImageFilter.GaussianBlur(blur))
            canvas.alpha_composite(gl)
    rl = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rl)
    rd.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=color, width=thickness)
    rd.ellipse([cx - rx + 3, cy - ry + 2, cx + rx - 3, cy + ry - 2],
               outline=(230, 200, 255, 70), width=2)
    canvas.alpha_composite(rl)


def add_sparkles(canvas, pts):
    d = ImageDraw.Draw(canvas)
    for x, y, r in pts:
        r = max(r, 1)
        d.ellipse([x - r, y - r, x + r, y + r], fill=(100, 165, 255, 200))
        d.ellipse([x - r // 2, y - r // 2, x + r // 2, y + r // 2],
                  fill=(255, 255, 255, 220))


# ── Logo builders ──────────────────────────────────────────────────────────────

def make_logo(W=1200, H=500, bg='dark', flat=False, bw=False, transparent=False):
    if transparent:
        img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    elif bg == 'light':
        img = Image.new('RGBA', (W, H), (244, 242, 255, 255))
    else:
        img = radial_gradient(W, H, BG_INNER, BG_OUTER)

    cx, cy = W // 2, H // 2
    rx = int(W * 0.385)
    ry = int(H * 0.330)

    ring_col = (150, 150, 150, 255) if bw else RING_CORE
    draw_ring(img, cx, cy, rx, ry, ring_col, thickness=9, glow=not flat and not bw)

    if not flat and not bw:
        add_sparkles(img, [
            (cx - rx - 22, cy - 16, 5), (cx - rx - 44, cy + 8, 3), (cx - rx - 14, cy + 28, 4),
            (cx + rx + 22, cy - 16, 5), (cx + rx + 44, cy + 8, 3), (cx + rx + 14, cy + 28, 4),
        ])

    font = load_font(int(H * 0.42))
    stops  = TEXT_STOPS_BW if bw else TEXT_STOPS_COLOR
    glow_c = None if (flat or bw) else PURPLE_LT
    glow_r = 0 if (flat or bw) else 18
    paste_gradient_text(img, 'MIXVY', cx, cy, font, stops, glow_c, glow_r)
    return img


def make_icon(S=1024):
    img = radial_gradient(S, S, BG_INNER, BG_OUTER)
    cx = cy = S // 2

    # Soft inner circle tint
    cl = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    pad = max(S // 14, 2)
    ImageDraw.Draw(cl).ellipse([pad, pad, S - pad, S - pad], fill=(16, 12, 42, 210))
    img.alpha_composite(cl)

    rx = int(S * 0.39)
    ry = int(S * 0.255)
    draw_ring(img, cx, cy, rx, ry, RING_CORE, thickness=max(5, S // 90), glow=S >= 64)

    if S >= 96:
        add_sparkles(img, [(cx - rx - 8, cy - 7, 4), (cx + rx + 8, cy - 7, 4)])

    text = 'MIXVY' if S >= 128 else 'MV'
    font = load_font(int(S * 0.29) if S >= 128 else int(S * 0.48))
    glow_r = max(3, S // 60) if S >= 48 else 0
    paste_gradient_text(img, text, cx, cy, font, TEXT_STOPS_COLOR, PURPLE_LT, glow_r)
    return img


# ── Main ───────────────────────────────────────────────────────────────────────

def main():
    for sub in ['svg', 'png/full_logo', 'png/app_icon', 'png/favicon']:
        (BASE / sub).mkdir(parents=True, exist_ok=True)

    print('🎨  Generating MIXVY brand assets...\n')

    # Full logos
    for tag, bg, flat, bw, transp in [
        ('dark',        'dark',  False, False, False),
        ('transparent', 'dark',  False, False, True),
        ('light',       'light', False, False, False),
        ('flat',        'dark',  True,  False, False),
        ('bw',          'dark',  False, True,  False),
        ('gradient',    'dark',  False, False, False),
    ]:
        img = make_logo(bg=bg, flat=flat, bw=bw, transparent=transp)
        out = BASE / f'png/full_logo/mixvy_logo_{tag}.png'
        img.save(str(out))
        print(f'  ✅  {out.name}')

    # App icons
    for sz in [2048, 1024, 512, 256, 192, 96, 48, 32]:
        img = make_icon(sz)
        out = BASE / f'png/app_icon/mixvy_icon_{sz}x{sz}.png'
        img.save(str(out))
        print(f'  ✅  {out.name}')

    # Favicons
    for sz in [32, 48]:
        img = make_icon(sz)
        img.save(str(BASE / f'png/favicon/favicon_{sz}x{sz}.png'))
        print(f'  ✅  favicon_{sz}x{sz}.png')

    # ── Deploy to app ──────────────────────────────────────────────────────────
    print('\n🚀  Deploying to app asset locations...\n')

    def cp(src, dst):
        shutil.copy(str(src), str(dst))
        print(f'  ✅  {Path(dst).relative_to(APP)}')

    # Flutter assets
    cp(BASE / 'png/app_icon/mixvy_icon_512x512.png',   APP / 'assets/images/app_logo.png')
    cp(BASE / 'png/full_logo/mixvy_logo_transparent.png', APP / 'assets/images/logo.png')
    # Keep logo.jpg path alive (convert to RGB for JPEG)
    rgb = Image.open(str(BASE / 'png/full_logo/mixvy_logo_dark.png')).convert('RGB')
    rgb.save(str(APP / 'assets/images/logo.jpg'), quality=95)
    print(f'  ✅  assets/images/logo.jpg')

    # Web icons
    for fname, sz in [('Icon-192.png', 192), ('Icon-512.png', 512),
                      ('Icon-maskable-192.png', 192), ('Icon-maskable-512.png', 512)]:
        cp(BASE / f'png/app_icon/mixvy_icon_{sz}x{sz}.png', APP / f'web/icons/{fname}')
    cp(BASE / 'png/favicon/favicon_32x32.png', APP / 'web/favicon.png')
    # SVG favicon — copy the main SVG
    shutil.copy(str(BASE / 'svg/mixvy_logo_dark.svg'), str(APP / 'web/favicon.svg'))
    print(f'  ✅  web/favicon.svg')

    # Android mipmap (launcher icon)
    for folder, sz in [('mipmap-mdpi', 48), ('mipmap-hdpi', 72),
                       ('mipmap-xhdpi', 96), ('mipmap-xxhdpi', 144),
                       ('mipmap-xxxhdpi', 192)]:
        img = make_icon(sz)
        out = APP / f'android/app/src/main/res/{folder}/ic_launcher.png'
        img.save(str(out))
        print(f'  ✅  android/{folder}/ic_launcher.png')

    # Android drawable foreground
    for folder, sz in [('drawable-mdpi', 108), ('drawable-hdpi', 162),
                       ('drawable-xhdpi', 216), ('drawable-xxhdpi', 324),
                       ('drawable-xxxhdpi', 432)]:
        img = make_icon(sz)
        out = APP / f'android/app/src/main/res/{folder}/ic_launcher_foreground.png'
        img.save(str(out))
        print(f'  ✅  android/{folder}/ic_launcher_foreground.png')

    print('\n✨  All MIXVY brand assets generated and deployed!')
    print(f'📁  Brand folder: {BASE}')


if __name__ == '__main__':
    main()
