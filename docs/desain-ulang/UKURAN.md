# UKURAN — satu tabel untuk semua komponen

dp pada layar rujukan 390. "penuh" = lebar layar − 2 × 16 (margin `Spasi.sisi`,
turun dari 20 ke 16). Huruf: ukuran/tinggi baris · berat. Keluarga tetap Inter.

| Komponen | Lebar | Tinggi | Sudut | Padding | Huruf |
|---|---|---|---|---|---|
| Layar | 360–430 | bergulir | — | sisi 16, antar-ubin 12 | Inter |
| Kepala layar tab | penuh | 48 | — | 0 | judul 28/34 · 800 |
| Kepala layar anak | penuh | 48 | — | kembali 48 + jarak 12 | judul 20/26 · 800 |
| Tombol utama | penuh | 56 | pil | 22 kiri, 8 kanan | 16/24 · 700; lencana 40, 16/800 |
| Tombol sekunder | isi | 48 | pil | 0 20 | 16/24 · 700 |
| Tombol teks | isi | 48 | — | — | 14/20 · 700, garis bawah |
| Tombol bulat | 44 / 48 / 52 | = lebar | bulat | ikon 20–22 | — |
| Kolom cari | penuh | 56 | pil | 20 kiri, 6 kanan | 14/20 · 400; tombol 44 |
| Saringan | isi | 44 | 22 | 16 kiri, 6 kanan, jarak 8 | 14/20 · 700; jumlah 32 |
| Segmen dua pilihan | penuh | 56 (dalam 44) | pil / 22 | 6 | 14/20 · 700 |
| Sakelar | 56 | 36 (tombol 28) | pil | 4 | baris 56, 14/20 · 600 |
| Stempel status | isi | 30 | 15 | 0 12; ikon 14, jarak 6 | 12/16 · 700 |
| Ubin alat | penuh | 196 (Beranda 232) | 32 | 18 | nama 22/28 · 800; angka 44 (Beranda 64) · 800 |
| Ubin pasangan | (penuh − 12) ÷ 2 | 188 | 28 | 16 | judul 17/24 · 800; isi 12–14 · 500 |
| Ubin menu | (penuh − 12) ÷ 2 | 140 | 28 | 16 | judul 17/24 · 800; tombol bulat 40 |
| Ubin kosong | penuh | ≥ 420 | 32 | 22 | judul 28/34 · 800; isi 14/20 · 500 |
| Ubin navy | penuh | isi | 32 | 20 | putih; keterangan `navyTeks` |
| Panel | penuh | isi | 28 | 6 (baris) / 18–20 | — |
| Baris menu | penuh | 64 | — | 0 10, jarak 14 | 16/24 · 700; ubin ikon 44 |
| Baris daftar (teknisi) | penuh | ≥ 72 | — | 0 16 | judul 16/24 · 800; nomor 12/16 · 700 |
| Kartu draf (teknisi) | 196 | 132 | 26 | 16 | nama 16/20 · 800; nomor 12/16 · 700 |
| Kapsul jatuh tempo | (penuh − 60) ÷ 4 | rel 124, isi 44–124 | 22 | jarak 8 | angka 28 atau 17 · 800; label 12/16 |
| Avatar | 48 / 88 | = lebar | bulat | — | inisial 16 / 30 · 800 |
| Dock navigasi | isi, di tengah | 64 | 36 | 8, jarak 4, melayang 16 | label aktif 14/20 · 800 |
| Butir dock | 48 (aktif: isi) | 48 | 24 | aktif 0 16 | ikon 22 (aktif 20) |
| Visual alat | 176 / 160 / 112 / 100 / 270 | = lebar | — | keluar 10–20 dari sudut ubin | kanvas 240 × 240 |

Catatan penerapan:
- Tinggi ubin adalah MINIMUM. Pada skala huruf sistem > 1,0 ubin tumbuh; jangan
  dikunci dengan `SizedBox(height:)`, pakai `ConstrainedBox(minHeight:)`.
- Teks 28 sp ke atas tetap dijepit `SkalaHuruf.batasBesar` (1,15).
- Di lebar < 340 dp (`Spasi.batasKompak`): ubin pasangan dan ubin menu jadi satu
  kolom; visual alat di ubin alat mengecil ke 120.
- ≥ 600 dp: isi dipusatkan seperti sekarang (`lebarKonten`), dock diganti rel.
- Semua angka ini masuk `ukuran.dart` / `bentuk.dart` dulu (lihat
  `flutter/bentuk_ukuran_bento.dart`), layar tidak menulis angka sendiri.
