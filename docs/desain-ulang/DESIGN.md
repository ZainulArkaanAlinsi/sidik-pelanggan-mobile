# DESIGN — Bento Lab

Satu kalimat: **navy korporat + ubin pastel bermakna + visual alat**. Kesan
formal dijaga oleh navy (teks, aksi, dock), huruf Inter tebal, dan disiplin
grid; kesan segar datang dari ubin besar membulat dan visual alat.

## Prinsip
1. Satu ubin = satu hal. Tidak ada kartu di dalam kartu.
2. Warna ubin BUKAN hiasan: koral = lewat jadwal/gagal, kuning = awas/aksen,
   hijau = berlaku/selesai, langit = info/diproses, putih = netral.
3. Angka memimpin: sisa hari ditulis besar, kata menjelaskan di sebelahnya.
4. Satu aksi utama per layar (pil navy 56 dp).
5. Visual alat duduk di sudut kanan bawah ubin, tidak pernah menimpa teks.

## Warna (tema terang)
| Token | Hex | Pakai |
|---|---|---|
| navy | #0B1F4B | teks utama, tombol utama, dock, stempel di atas ubin koral |
| navyLembut | #2B4380 | rel/jejak di atas navy |
| navyTeks | #C9D3EA | teks kedua di atas navy |
| kuning | #F6D36B | aksen, butir dock aktif, lencana jumlah, status awas |
| koral | #F2957A | status gagal / lewat jadwal |
| hijau | #CBE7B8 | status lulus / berlaku |
| langit | #BCE0F0 | status tunggu / info |
| latar | #EEF0F3 | halaman, rel kapsul, pemisah |
| kartu | #FFFFFF | panel, kontrol |
| teksKedua | #4A5672 | keterangan |
| garis | #D5DAE3 | garis kontrol di atas putih |
| kobalt (logo) | #043EA1 | hanya `LogoSidik` |

Pemetaan ke `WarnaSidik`: `gagalLatar=koral`, `awasLatar=kuning`,
`lulusLatar=hijau`, `tungguLatar=langit`; tinta keempatnya = navy.
Karena tinta status sekarang sama, pembeda status adalah LATAR + IKON + KATA.
Luminans latar: hijau ≈ 0,74 · kuning ≈ 0,68 · langit ≈ 0,70 · koral ≈ 0,42.
Hijau/kuning/langit berdekatan terangnya → aturan "beda terang > 0,02" di tes
lama hanya lolos tipis untuk kuning↔langit; ikon + kata wajib, tidak boleh
warna saja. Laporkan hasil tes apa adanya.

### Kontras (hitung ulang di `kontras_tema_test.dart`)
navy di atas: putih, latar, kuning, hijau, langit, koral → semua > 7:1.
teksKedua di atas putih/latar ≈ 6:1; di atas kuning/langit/hijau ≈ 5:1.
**teksKedua tidak dipakai di atas koral** (pakai navy).
Putih di atas navy 15:1. navyTeks di atas navy ≈ 10:1.

### Mode gelap (titik awal, belum final)
latar #0A1226, kartu #131E3A, teks #E8ECF6, ubin status memakai warna yang
sama dengan teks navy di atasnya (ubin tetap terang). Perlu desain sendiri.

## Huruf (Inter, sudah dibundel)
| Tingkat | Ukuran/baris | Berat | Spasi | Slot |
|---|---|---|---|---|
| angka sorot | 64/60 | 800 | −0,04em | BARU: `TipografiSidik.angkaSorot` |
| angka kartu | 44/48 | 800 | −0,04em | displayLarge |
| kalimat utama | 32/38 | 800 | −0,03em | displayMedium |
| judul layar | 28/34 | 800 | −0,03em | displaySmall |
| nama alat/akun | 22/28 | 800 | −0,02em | headline* |
| judul app bar (anak layar) | 20/26 | 800 | −0,02em | titleLarge |
| judul bagian/ubin | 17/24 | 800 | −0,01em | titleMedium |
| label tombol/baris | 16/24 | 700 | 0 | titleSmall, labelLarge |
| keterangan | 14/20 | 500 | 0 | bodySmall |
| stempel/label | 12/16 | 700 | 0 | labelMedium/Small |

Mockup memakai beberapa ukuran antara (34, 30, 26, 15, 13, 11) karena digambar
bebas; **di Flutter bulatkan ke tabel ini** (34→32, 30→28, 26→28, 20→22 untuk
nama alat, 15→16, 13→14, 11→12). Berat naik dari 700 ke 800: tambahkan
`Inter-ExtraBold.ttf` ke `assets/fonts/` (keluarga sama, bukan font baru) atau
tetap 700 bila pemilik tidak mau menambah berkas. Angka tetap `.tabular`,
nomor tetap `.nomor`.

## Sudut (`Bentuk`)
| Token | dp | Pakai |
|---|---|---|
| ikon | 16 | ubin ikon persegi |
| kapsul | 22 | kapsul grafik, segmen, saringan |
| panel | 28 | panel putih, ubin kecil (≤ 188 tinggi) |
| ubin | 32 | ubin besar |
| dock | 36 | dock |
| pil | 999 | tombol, stempel, kolom cari, avatar |

## Jarak (`Spasi`) — tetap 4/8/12/16/24/32
Margin layar 16 (`Spasi.sisi` 20 → 16), antar-ubin 12, dalam ubin 16–22,
antar-bagian 24, judul bagian ke isinya 10.

## Elevasi
Tetap datar. Satu-satunya bayangan: dock (0, 16, blur 32, navy 28%).

## Gerak — pakai `AppMotion` yang ada, tanpa durasi baru
| Apa | Bagaimana | Durasi/kurva |
|---|---|---|
| Tekan tombol/ubin | skala 1 → 0,97 | kilat 120 |
| Ubin masuk layar | opasitas 0→1 + geser naik 12 dp | sedang 240, masuk; `AppMotion.tunda(context, i)` |
| Visual alat | skala 0,92→1 + opasitas, mulai setelah ubinnya | sedang 240, masuk |
| Kapsul jatuh tempo | tinggi isi 0 → nilai | sedang 240, masuk, berurutan |
| Angka sorot | hitung 0 → nilai (`TweenAnimationBuilder<int>`) | sedang 240, sekali per buka layar |
| Pil dock/segmen | `AnimatedAlign`/`AnimatedPositioned` ke butir baru | sedang 240 |
| Sakelar, stempel | `AnimatedContainer` | kilat 120 |
| Pindah halaman | `transisi_halaman.dart` yang ada | halaman 280 |

Semua lewat `AppMotion.hormati`. Tidak ada gerak berulang (denyut, kilau),
tidak ada pegas memantul: ini aplikasi perusahaan, gerak hanya menandai
"ini baru datang" dan "ini yang kamu tekan".
