"""Traces the Acro Visuals logo PNGs in assets/logos into SVGs.

Run from the repo root with Pillow, numpy and potracer installed:
    pip install pillow numpy potracer
    python tool/trace_logos.py

Writes, alongside the PNGs:
  acro-logo-icon.svg       the icon: white mark on a black square
  acro-logo-tm.svg         the wordmark in black
  acro-logo-tm-white.svg   the wordmark in white
and, for the splash animation, single-colour layers that share the full
logo's viewBox so they stack exactly:
  acro-mark.svg            just the mark from the icon, cropped to it
  acro-wordmark-acro.svg / -bars.svg / -visuals.svg / -tm.svg
"""
import numpy as np
import potrace
from PIL import Image

SCALE = 4  # trace at 4x for smoother curves
PAD = 16  # potrace needs blank space round shapes touching the image edge
DIR = 'assets/logos'


def trace(mask):
    """Returns potrace curves for a boolean mask, in upscaled pixel units.

    potracer traces the background as one big shape with the logo as holes in
    it; with even-odd filling, dropping that outer frame leaves the logo.
    """
    padded = np.pad(mask, PAD)
    h, w = padded.shape
    curves = potrace.Bitmap(padded).trace(turdsize=8, alphamax=1.0, opticurve=True, opttolerance=0.2)
    return [c for c in curves if not _is_frame(c, w, h)]


def _is_frame(curve, w, h):
    x0, y0, x1, y1 = curve_bbox(curve)
    return x0 <= -PAD / SCALE + 1 and y0 <= -PAD / SCALE + 1 and x1 >= (w - PAD) / SCALE - 1 and y1 >= (h - PAD) / SCALE - 1


def fmt(v):
    return f'{v / SCALE:.2f}'.rstrip('0').rstrip('.')


def xy(p):
    x, y = (p.x, p.y) if hasattr(p, 'x') else tuple(p)
    return x - PAD, y - PAD


def curve_d(curve):
    sx, sy = xy(curve.start_point)
    d = [f'M{fmt(sx)} {fmt(sy)}']
    for seg in curve:
        if seg.is_corner:
            cx, cy = xy(seg.c)
            ex, ey = xy(seg.end_point)
            d.append(f'L{fmt(cx)} {fmt(cy)}L{fmt(ex)} {fmt(ey)}')
        else:
            (x1, y1), (x2, y2), (ex, ey) = xy(seg.c1), xy(seg.c2), xy(seg.end_point)
            d.append(f'C{fmt(x1)} {fmt(y1)} {fmt(x2)} {fmt(y2)} {fmt(ex)} {fmt(ey)}')
    d.append('Z')
    return ''.join(d)


def curve_bbox(curve):
    pts = [xy(curve.start_point)]
    for seg in curve:
        pts.append(xy(seg.end_point))
        pts.extend([xy(seg.c)] if seg.is_corner else [xy(seg.c1), xy(seg.c2)])
    xs = [p[0] / SCALE for p in pts]
    ys = [p[1] / SCALE for p in pts]
    return min(xs), min(ys), max(xs), max(ys)


def load_mask(path, white_on_black=False):
    img = Image.open(path).convert('RGBA')
    big = img.resize((img.width * SCALE, img.height * SCALE), Image.LANCZOS)
    a = np.asarray(big).astype(np.float32)
    if white_on_black:
        # Icon: the mark is the bright part
        lum = a[..., :3].mean(axis=2) * (a[..., 3] / 255)
        mask = lum > 128
    else:
        mask = a[..., 3] > 128
    return img.size, mask


def svg(width, height, paths, view_box=None, background=None):
    vb = view_box or f'0 0 {width} {height}'
    body = ''
    if background:
        body += f'<rect width="100%" height="100%" fill="{background}"/>'
    for d, fill in paths:
        body += f'<path fill="{fill}" fill-rule="evenodd" d="{d}"/>'
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
            f'viewBox="{vb}">{body}</svg>\n')


def write(name, text):
    with open(f'{DIR}/{name}', 'w', encoding='utf-8') as f:
        f.write(text)
    print('wrote', name, f'{len(text) // 1024} KB')


def main():
    # Icon
    (w, h), mask = load_mask(f'{DIR}/acro-logo-icon.png', white_on_black=True)
    curves = list(trace(mask))
    d = ''.join(curve_d(c) for c in curves)
    write('acro-logo-icon.svg', svg(w, h, [(d, '#fff')], background='#000'))
    boxes = [curve_bbox(c) for c in curves]
    x0 = min(b[0] for b in boxes)
    y0 = min(b[1] for b in boxes)
    x1 = max(b[2] for b in boxes)
    y1 = max(b[3] for b in boxes)
    mw, mh = x1 - x0, y1 - y0
    write('acro-mark.svg', svg(round(mw), round(mh), [(d, '#000')], view_box=f'{x0:.2f} {y0:.2f} {mw:.2f} {mh:.2f}'))

    # Wordmark
    (w, h), mask = load_mask(f'{DIR}/acro-logo-tm.png')
    curves = list(trace(mask))
    d = ''.join(curve_d(c) for c in curves)
    write('acro-logo-tm.svg', svg(w, h, [(d, '#000')]))
    write('acro-logo-tm-white.svg', svg(w, h, [(d, '#fff')]))

    # Split into layers by where each shape sits
    groups = {'acro': [], 'bars': [], 'visuals': [], 'tm': []}
    for c in curves:
        bx0, by0, bx1, by1 = curve_bbox(c)
        cy = (by0 + by1) / 2
        if bx0 > 900 and by1 < 60:
            groups['tm'].append(c)
        elif by1 - by0 < 40 and bx1 - bx0 > 60 and 120 < cy < 175:
            groups['bars'].append(c)
        elif cy < 130:
            groups['acro'].append(c)
        else:
            groups['visuals'].append(c)
    for name, cs in groups.items():
        print(name, len(cs), 'shapes', [tuple(round(v) for v in curve_bbox(c)) for c in cs][:12])
        write(f'acro-wordmark-{name}.svg', svg(w, h, [(''.join(curve_d(c) for c in cs), '#000')]))


if __name__ == '__main__':
    main()
