> **DIGANTI 16 Nov 2026.** Arah "Bento Lab" di paket ini (bidang kuning/koral
> besar, sudut ekstrem, dock navy melayang) digantikan arah tenang, formal, dan
> ringkas. Yang berlaku: `REVISI-16NOV.md` (penerapan di kode) dan `tokens.json`
> (sudah diselaraskan). `DESIGN.md`, `KOMPONEN.md`, `LAYAR.md`, `UKURAN.md`,
> `ELEMEN.md`, dan `VISUAL.md` di bawah adalah ARSIP: bila bertentangan,
> `REVISI-16NOV.md` menang.

# SIDIK — arah desain "Bento Lab" (paket handoff)

Paket ini untuk dikerjakan Claude Code di `sidik-pelanggan-mobile` (utama) dan
layar teknisi di `sidik-calibration-mobile`. Baca berurutan (plus `PETA-LAYAR.md`, `ELEMEN.md`, `VISUAL.md`, `skill/`):

1. `DESIGN.md` — arah, warna, huruf, sudut, gerak.
2. `KOMPONEN.md` — ukuran tiap komponen + padanannya di `lib/widgets/`.
3. `LAYAR.md` — susunan dan ukuran per layar.
4. `UKURAN.md` — satu tabel lebar/tinggi/sudut/padding/huruf semua komponen.
5. `GERAK.md` — animasi (durasi, kurva, tunda) + `flutter/gerak_bento.dart`.
6. `tokens.json` — semua angka dalam satu berkas.
7. `flutter/` — potongan Dart siap tempel ke `lib/core/tema/`.
8. `aset/visual/` — visual alat (SVG sumber). `referensi-html/` — markup mockup,
   semua nilai gaya tertulis inline; pakai sebagai rujukan angka, bukan disalin.

## Yang HARUS diputuskan pemilik dulu

Arah ini sengaja menabrak `docs/standar-kualitas-desain.md` (arah "Jejak"):

| Aturan Jejak sekarang | Bento Lab |
|---|---|
| Kobalt `#043EA1` warna utama | Navy `#0B1F4B` utama, kobalt hanya di logo |
| Stempel persegi radius 4 | Stempel pil radius 15 |
| Datar, satu aksi 56 dp, radius 16 | Ubin radius 28–32, tombol pil |
| "Lima warna aksen bersaing" dihindari | 4 warna ubin, masing-masing terikat ke satu makna status |
| "Ilustrasi stok / ubin ikon dekoratif" dihindari | Visual alat per jenis (bukan stok: milik sendiri, satu gaya) |
| Skala huruf `{44,32,28,22,20,17,16,14,12}` | Sama, plus SATU ukuran baru: 64 (angka sorot) |

Jadi langkah pertama PR adalah memperbarui dokumen standar itu dan gerbangnya,
bukan mengakalinya:

- `docs/standar-kualitas-desain.md` §3 dan §4: tulis ulang ke Bento Lab.
- `test/tema/tema_sidik_test.dart`: tambah 64 ke daftar izin ukuran huruf.
- `test/tema/kontras_tema_test.dart`: pasangan baru (lihat DESIGN.md §Kontras).
- `test/tema/anti_slop_test.dart`: ratchet dua arah — tiap berkas yang berubah,
  angkanya ikut disesuaikan di PR yang sama.
- `test/tema/token_only_test.dart` tetap berlaku: tidak ada `Color(0x…)` atau
  angka mentah di layar. Semua nilai baru masuk `lib/core/tema/` dulu.

Yang TIDAK berubah: aplikasi tetap baca-saja (`test/guard_tulis_test.dart`),
tanpa paket baru, tanpa font baru (tetap Inter yang sudah dibundel), status
selalu ikon + kata, area sentuh minimum 48 dp, `AppMotion` dan "kurangi gerak".

## Urutan kerja yang disarankan (satu PR per langkah, CI hijau)

1. Token: `palet_sidik.dart`, `warna_sidik.dart`, `bentuk.dart`, `ukuran.dart`,
   `tipografi.dart`, `tema_sidik.dart` + tes tema. Belum ada layar berubah.
2. Komponen baru di `lib/widgets/` (daftar di KOMPONEN.md) + tes widget +
   galeri render `test/tampilan/render_komponen_test.dart`.
3. `NavigasiUtama` → dock melayang (HP); rel samping ≥ 600 dp tetap.
4. Layar: Beranda → Alat → Sertifikat → Akun → Anggota → Paket.
5. Visual alat: `VisualAlat` (lihat KOMPONEN.md §Visual).
6. Gerak (DESIGN.md §Gerak).
7. Repo Lab: layar `kalibrasi_teknisi_screen.dart` saja, dengan token Lab.

## Prompt untuk Claude Code

Lihat `../PROMPT.md` (pembuka sesi Pelanggan + P1–P5).
