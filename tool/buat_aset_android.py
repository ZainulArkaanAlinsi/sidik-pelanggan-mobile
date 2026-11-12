"""Membuat aset peluncur dan splash Android dari logo resmi PT Sidik (Lab).

Pakai: python tool/buat_aset_android.py --lab <folder sidik-calibration-mobile>
Butuh Pillow (pip install pillow). Hasilnya di-commit; skrip ini hanya dijalankan
bila logo berganti.

Sumber: sidik-calibration-mobile/assets/images/logo_pt_sidik.png (lencana
308x430, latar putih) dan assets/icon/app_icon.png (1024x1024, lencana di
kanvas putih persegi, dipakai ikon Lab).

Keluaran (ke res/ Android Pelanggan):
- mipmap-*/ic_launcher.png            ikon lawas (API 24-25), dari app_icon.png
- mipmap-*/ic_launcher_foreground.png lapisan depan ikon adaptif (108dp)
- mipmap-*/ic_launcher_monochrome.png lapisan monokrom Android 13+ (108dp)
- drawable-*/splash_logo.png          logo splash (kanvas 144dp)
"""
import argparse
import os
from collections import deque

from PIL import Image

_arg = argparse.ArgumentParser(description="Aset peluncur dan splash Android.")
_arg.add_argument("--lab", required=True, help="folder repo sidik-calibration-mobile")
_arg.add_argument("--res", default="android/app/src/main/res", help="folder res Android")
_a = _arg.parse_args()
SUMBER_LOGO = f"{_a.lab}/assets/images/logo_pt_sidik.png"
SUMBER_IKON = f"{_a.lab}/assets/icon/app_icon.png"
RES = _a.res

KEPADATAN = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}


def logo_transparan():
    """Buang latar putih di LUAR lencana (flood fill dari tepi)."""
    im = Image.open(SUMBER_LOGO).convert("RGB")
    w, h = im.size
    px = im.load()
    putih = lambda p: min(p) >= 235
    terisi = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if putih(px[x, y]):
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if putih(px[x, y]):
                q.append((x, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or terisi[y][x] or not putih(px[x, y]):
            continue
        terisi[y][x] = True
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    out = Image.new("RGBA", (w, h))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            op[x, y] = (r, g, b, 0 if terisi[y][x] else 255)
    return out


def monokrom(logo):
    """Siluet satu warna: gelap (biru/hitam/merah) = pekat, putih = bening."""
    w, h = logo.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    lp, op = logo.load(), out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = lp[x, y]
            if a == 0:
                continue
            lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
            # 200 ke atas = bening, 120 ke bawah = pekat, mulus di antaranya.
            t = min(1.0, max(0.0, (200 - lum) / 80))
            op[x, y] = (0, 0, 0, int(round(255 * t)))
    return out


def tempel(kanvas_px, logo, tinggi_px):
    """Logo diskalakan ke tinggi_px dan dipusatkan di kanvas transparan."""
    k = Image.new("RGBA", (kanvas_px, kanvas_px), (0, 0, 0, 0))
    rasio = logo.width / logo.height
    l = logo.resize((max(1, round(tinggi_px * rasio)), tinggi_px), Image.LANCZOS)
    k.alpha_composite(l, ((kanvas_px - l.width) // 2, (kanvas_px - l.height) // 2))
    return k


def simpan(img, jalur, palet=True):
    os.makedirs(os.path.dirname(jalur), exist_ok=True)
    if palet and img.mode == "RGBA":
        img = img.quantize(colors=128, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    img.save(jalur, optimize=True)
    return os.path.getsize(jalur)


def main():
    logo = logo_transparan()
    mono = monokrom(logo)
    ikon = Image.open(SUMBER_IKON).convert("RGB")
    total = 0
    for nama, k in KEPADATAN.items():
        # Ikon lawas 48dp.
        px = round(48 * k)
        total += simpan(ikon.resize((px, px), Image.LANCZOS), f"{RES}/mipmap-{nama}/ic_launcher.png", palet=False)
        # Ikon adaptif: kanvas 108dp; lencana setinggi 58dp (aman di topeng bulat).
        kanvas = round(108 * k)
        tinggi = round(58 * k)
        total += simpan(tempel(kanvas, logo, tinggi), f"{RES}/mipmap-{nama}/ic_launcher_foreground.png")
        total += simpan(tempel(kanvas, mono, tinggi), f"{RES}/mipmap-{nama}/ic_launcher_monochrome.png")
        # Splash: kanvas 144dp; lencana setinggi 75dp (muat di lingkaran 2/3 kanvas).
        kanvas = round(144 * k)
        tinggi = round(75 * k)
        total += simpan(tempel(kanvas, logo, tinggi), f"{RES}/drawable-{nama}/splash_logo.png")
    print("total byte aset ikon+splash:", total)


main()
