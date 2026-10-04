"""Draws the Donut app icon and writes it for every platform.

Run from the repo root: python tool/make_icons.py (needs Pillow).
Mirrors the in-app DonutLogo painter in lib/ui/widget/donut_logo.dart.
"""
import math
import random

from PIL import Image, ImageDraw, ImageFilter

SS = 4  # supersampling factor
SIZE = 1024
FROSTING = (240, 98, 146)
SPRINKLES = [(255, 255, 255), (255, 213, 79), (79, 195, 247), (129, 199, 132), (186, 104, 200), (255, 138, 101)]


def ring_mask(size, cx, cy, outer, inner):
    mask = Image.new('L', (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse([cx - outer, cy - outer, cx + outer, cy + outer], fill=255)
    d.ellipse([cx - inner, cy - inner, cx + inner, cy + inner], fill=0)
    return mask


def draw_donut(size, background=None, scale=0.92):
    s = size * SS
    img = Image.new('RGBA', (s, s), background or (0, 0, 0, 0))
    c = s / 2
    r = s / 2 * scale
    hole = r * 0.3

    # Soft shadow
    shadow = Image.new('L', (s, s), 0)
    sd = ImageDraw.Draw(shadow)
    off = r * 0.1
    sd.ellipse([c - r, c - r + off, c + r, c + r + off], fill=90)
    sd.ellipse([c - hole, c - hole + off, c + hole, c + hole + off], fill=0)
    shadow = shadow.filter(ImageFilter.GaussianBlur(r * 0.06))
    img.paste((0, 0, 0, 255), (0, 0), shadow)

    # Dough: radial gradient light to dark
    dough = Image.new('RGBA', (s, s))
    dd = ImageDraw.Draw(dough)
    steps = 60
    for i in range(steps):
        t = i / steps
        rr = r * (1 - t)
        col = (
            int(169 + (232 - 169) * t),
            int(105 + (181 - 105) * t),
            int(47 + (122 - 47) * t),
            255,
        )
        dd.ellipse([c - rr, c - rr, c + rr, c + rr], fill=col)
    img.paste(dough, (0, 0), ring_mask(s, c, c, r, hole))

    # Frosting with wavy edge
    pts = []
    for i in range(720):
        a = i / 720 * 2 * math.pi
        rr = r * 0.84 + r * 0.05 * math.sin(a * 9)
        pts.append((c + math.cos(a) * rr, c + math.sin(a) * rr))
    frost_mask = Image.new('L', (s, s), 0)
    fm = ImageDraw.Draw(frost_mask)
    fm.polygon(pts, fill=255)
    fm.ellipse([c - hole * 1.25, c - hole * 1.25, c + hole * 1.25, c + hole * 1.25], fill=0)
    img.paste(FROSTING + (255,), (0, 0), frost_mask)

    # Shine
    d = ImageDraw.Draw(img)
    rr = r * 0.62
    d.arc([c - rr, c - rr, c + rr, c + rr], start=math.degrees(math.pi * 1.1), end=math.degrees(math.pi * 1.55),
          fill=(255, 255, 255, 110), width=int(r * 0.07))

    # Sprinkles
    rnd = random.Random(7)
    for i in range(22):
        a = rnd.random() * 2 * math.pi
        dist = hole * 1.45 + rnd.random() * (r * 0.72 - hole * 1.45)
        px, py = c + math.cos(a) * dist, c + math.sin(a) * dist
        rot = rnd.random() * math.pi
        w, h = r * 0.13, r * 0.04
        corners = [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)]
        poly = [(px + x * math.cos(rot) - y * math.sin(rot), py + x * math.sin(rot) + y * math.cos(rot))
                for x, y in corners]
        d.polygon(poly, fill=SPRINKLES[i % len(SPRINKLES)] + (255,))

    return img.resize((size, size), Image.LANCZOS)


def main():
    icon = draw_donut(SIZE)

    for n in [16, 32, 64, 128, 256, 512, 1024]:
        icon.resize((n, n), Image.LANCZOS).save(f'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{n}.png')

    icon.save('windows/runner/resources/app_icon.ico', sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64),
                                                               (128, 128), (256, 256)])

    icon.resize((192, 192), Image.LANCZOS).save('web/icons/Icon-192.png')
    icon.resize((512, 512), Image.LANCZOS).save('web/icons/Icon-512.png')
    icon.resize((32, 32), Image.LANCZOS).save('web/favicon.png')
    # Maskable icons need the art inside the safe zone on a solid background
    maskable = draw_donut(SIZE, background=(251, 246, 240, 255), scale=0.62)
    maskable.resize((192, 192), Image.LANCZOS).save('web/icons/Icon-maskable-192.png')
    maskable.resize((512, 512), Image.LANCZOS).save('web/icons/Icon-maskable-512.png')


if __name__ == '__main__':
    main()
