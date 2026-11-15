---
name: sidik-ui-pelanggan
description: Patokan UI app SIDIK Pelanggan (Bento Lab). Pakai SETIAP kali membuat, mengubah, atau meninjau tampilan Flutter di sidik-pelanggan-mobile — layar, widget, dialog, toast, keadaan, warna, ukuran, animasi, ikon, atau gambar alat.
---

# Patokan UI SIDIK Pelanggan — "Bento Lab"

Rujukan lengkap: `docs/desain-ulang/` (README, DESIGN, KOMPONEN, UKURAN, GERAK,
LAYAR, ELEMEN, PETA-LAYAR, tokens.json, referensi-html/). Tidak tercakup: tanya
pemilik, jangan mengarang gaya baru.

## 0. Sebelum menyentuh UI
App baca-saja (`test/guard_tulis_test.dart` tidak dilonggarkan). Tanpa paket dan
font baru. Semua nilai lewat `lib/core/tema/` (`token_only_test`, `anti_slop_test`).
Cek komponen di `lib/widgets/` dan `lib/widgets/README.md` sebelum membuat baru.

## 1. Warna
Navy #0B1F4B (tinta, aksi, dock) · kuning #F6D36B (aksen, butir dock aktif, awas)
· koral #F2957A (lewat jadwal) · hijau #CBE7B8 (berlaku/selesai) · langit #BCE0F0
(diproses/info) · latar #EEF0F3 · kartu putih · teks kedua #4A5672. Warna ubin alat
= status alat. Kobalt #043EA1 hanya di logo; merah KAN hanya di `LencanaKan`.
Tanpa gradien di UI, tanpa ungu. Kontras teks ≥ 4,5:1 — hitung.

## 2. Huruf
Inter saja; angka `.tabular`, nomor `.nomor`. 64/60 angka sorot · 44 angka kartu
· 32/38 kalimat utama · 28/34 judul layar · 22/28 nama alat · 17/24 judul bagian
(semua 800) · 16/24·700 label · 14/20·500 keterangan · 12/16·700 stempel. Min 12.

## 3. Bentuk dan ukuran
Ubin 32 · ubin kecil/panel 28 · kapsul 22 · dock 36 · pil untuk tombol/stempel/
cari/saringan. Tombol utama 56, lainnya 48, sentuh min 48, stempel 30. Ukuran
lengkap: `docs/desain-ulang/UKURAN.md`.

## 4. Susunan
Margin 16, jarak antar-ubin 12. Kepala tab (judul 28 + pil putih opsional) atau
kepala anak (kembali bulat 48 + judul 20). Dock navy melayang di HP, rel samping
≥ 600 dp. Ikuti LAYAR.md; layar tanpa artboard ikuti pola terdekat di LAYAR.md.

## 5. Status
Ikon + kata. Istilah dari `pemetaan_status.dart`. "Tidak memenuhi toleransi" tidak dilunakkan.

## 6. Umpan balik
Toast/dialog/lembar bawah/banner/keadaan sama bentuknya dengan app Lab
(`ELEMEN.md`), warna Bento: aksi navy, kosong = ubin kuning + visual.
Bahasa formal "Anda" seperti teks yang ada sekarang.

## 7. Gerak
`AppMotion` (`GERAK.md`): masuk berurutan, tekan 0,97, tanpa gerak berulang.

## 8. Gambar alat
`VisualAlat`; peta dan aturan menggambar sama dengan app Lab (VISUAL.md).

## 9. Selesai jika
`flutter analyze` bersih, `flutter test` hijau, angka ratchet turun/tetap, tes
widget komponen baru, PR menyebut artboard rujukan dan yang belum dikerjakan.
