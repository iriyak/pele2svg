"""Render every raw Pele SVG in Chromium and compare it with the Skia PNG of the converted SVG.
Usage: python3 -I scripts/gallery-compare.py [gallery dir [out dir]]
Defaults: out/gallery and out/gallery/compare (git-ignored). Needs numpy, pillow and playwright with Chromium;
run it after scripts/gallery-svgs.mjs and Pele2svgExamples exportGalleryPngs. Writes compare.json.
Fonts differ between the two machines, so the comparison works on 8x8 pixel blocks (colors and shapes, not glyphs).
"""
import json, sys, math
from pathlib import Path
import numpy as np
from PIL import Image
from playwright.sync_api import sync_playwright

repo = Path(__file__).resolve().parent.parent
root = Path(sys.argv[1]) if len(sys.argv) > 1 else repo / 'out' / 'gallery'
out = Path(sys.argv[2]) if len(sys.argv) > 2 else root / 'compare'
out.mkdir(parents=True, exist_ok=True)
data = json.loads((root / 'data.json').read_text())
BLOCK = 8

def blocks(img):
    a = np.asarray(img.convert('RGB'), dtype=np.float32) / 255.0
    h, w, _ = a.shape
    H, W = math.ceil(h / BLOCK), math.ceil(w / BLOCK)
    pad = np.ones((H * BLOCK, W * BLOCK, 3), np.float32)
    pad[:h, :w] = a
    return pad.reshape(H, BLOCK, W, BLOCK, 3).mean(axis=(1, 3))

rows = []
with sync_playwright() as p:
    browser = p.chromium.launch()
    for e in data:
        name = e['name']
        w, h = math.ceil(e['width']), math.ceil(e['height'])
        page = browser.new_page(viewport={'width': w, 'height': h})
        page.goto((root / 'raw' / f'{name}.svg').resolve().as_uri())
        shot = out / f'{name}.chromium.png'
        page.screenshot(path=str(shot), clip={'x': 0, 'y': 0, 'width': w, 'height': h})
        page.close()
        sk = Image.open(root / 'skia' / f'{name}.png').convert('RGBA')
        if sk.size != (w, h): sk = sk.resize((w, h), Image.LANCZOS)  # the PNGs are written at 2x
        bg = Image.new('RGBA', sk.size, (255, 255, 255, 255))
        sk = Image.alpha_composite(bg, sk)
        ch = Image.open(shot).convert('RGB')
        if ch.size != sk.size:
            rows.append({'name': name, 'corpus': e['corpus'], 'size_mismatch': [ch.size, sk.size]})
            continue
        a, b = blocks(ch), blocks(sk)
        d = np.abs(a - b).mean(axis=2)
        rows.append({'name': name, 'corpus': e['corpus'], 'type': e['type'],
                     'mean': float(d.mean()), 'bad': float((d > 0.25).mean()),
                     'ink_chromium': float((1 - a.mean(axis=2)).mean()), 'ink_skia': float((1 - b.mean(axis=2)).mean())})
    browser.close()
(out / 'compare.json').write_text(json.dumps(rows, indent=1))
print(len(rows), 'compared')
