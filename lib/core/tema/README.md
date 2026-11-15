# lib/core/tema — token dan tema

Satu-satunya tempat warna, spasi, sudut, elevasi, ukuran ikon, dan huruf
ditentukan. Layar dan widget **tidak** menulis `Color(0x...)`, `Colors.*`,
`SizedBox(height: 12)`, atau `fontSize: 14`; semuanya lewat token di bawah.
Gerbang desain menjaga aturan ini: `test/tema/token_only_test.dart` (ratchet),
`kontras_tema_test.dart`, `token_tema_test.dart`, `tema_sidik_test.dart`,
`token_bento_test.dart`, `anti_slop_test.dart`. Standar lengkap:
`docs/standar-kualitas-desain.md`.

Arah desain "Bento Lab" (menggantikan "Jejak", paket di `docs/desain-ulang/`):
navy korporat `#0B1F4B` sebagai warna utama, empat ubin pastel yang masing-masing
terikat ke satu makna status (koral gagal, kuning awas, hijau lulus, langit
tunggu), Material 3 datar, tombol pil, panel 28 dan ubin 32, status selalu ikon
+ kata. Kobalt `#043EA1` (warna logo PT Sidik) hanya untuk aset merek. Mode
terang dan gelap (gelap: titik awal, belum final).

| Berkas | Isi |
|---|---|
| `palet_sidik.dart` | Warna mentah. SATU-SATUNYA berkas boleh `Color(0x...)`. Navy, ubin status, netral terang/gelap, `garisTegas` (tepi kontrol 3:1), `galat` (merah tua), `kobaltLogo`. |
| `warna_sidik.dart` | `WarnaSidik` (ThemeExtension): warna status (lulus/awas/gagal/tunggu) + merah KAN; pintasan `context.warna`, `context.skema`, `context.teks`. Terang: tinta keempat status navy di atas ubin pastel. Gelap: tinta pastel di atas latar gelap. Sejak P2 tinta UBIN dipisah dari tinta HALAMAN: `ubinLulus/Awas/Gagal/Tunggu` (pastel), `tintaUbin` (navy), `kertasUbin` (putih) sama di dua tema (ubin Bento tetap terang di mode gelap); teks di atas ubin memakai `tintaUbin`, teks di halaman memakai `lulus` dan kawan-kawannya. Pasangannya: `StatusTampil.ubin`, `ubinDari`, `diAtasUbin`. |
| `spasi.dart` | `Spasi.xs/sm/md/lg/xl/xxl` (4/8/12/16/24/32), `Spasi.sisi` (margin halaman 16), `Spasi.antarUbin` (12), `Spasi.bagian` (32), `Spasi.batasKompak` (340 dp), `Spasi.daftar(context)`, batas tablet (600 dp), lebar isi (720 dp), dan `lebarLebar` (1040 dp, layar dua kolom: Beranda). |
| `bentuk.dart` | `Bentuk.ikon/kapsul/panel/ubin/dock/pil` (16/22/28/32/36/999) dan `stempel` (15). Nama lama dipertahankan: `kontrol` = ikon, `kartu` = panel, `utama` = pil, `lembar` = panel; `kecil` tetap 4 (tik, tooltip). |
| `elevasi.dart` | `Elevasi.datar/rendah/lembar/garis`. Kedalaman dari garis halus, bukan bayangan tebal. (Bayangan dock: P4.) |
| `ukuran.dart` | `UkuranIkon` (16/24/32/48), `AreaSentuh.minimum` (48 dp), `UkuranBaris` (baris 72, tombol utama 56, kolom angka 56), `UkuranTik` (motif jejak), `SkalaHuruf` (teks besar dijepit 1,15x; nomor tidak di bawah 12 sp efektif). Bento Lab: `UkuranKontrol` (tombol bulat, saringan, segmen, kolom cari, sakelar, stempel), `UkuranUbin` (baris menu, ubin alat/pasangan/menu, kapsul, avatar), `UkuranDock`, `UkuranVisual`; P2 menambah ikon (`UkuranIkon.stempel/tombol/tombolBesar`), padding komponen, keluar visual, dan `UkuranFokus` (cincin fokus papan ketik: celah 2 + tebal 2, di luar isi). P3a: `UkuranAuth` (layar auth: hero 330, kartu menumpang 36, plat logo 104/80; dipakai `lib/screens/auth/kerangka_auth.dart`). |
| `tipografi.dart` | Skala Inter sepuluh ukuran (sembilan di `TextTheme`, 64 di `TipografiSidik.angkaSorot`), `.tabular` untuk angka selebar tetap, `.nomor` untuk nomor (selebar tetap + nol bergaris). `beratTebal` = 700 (utang: desain meminta 800). |
| `tema_sidik.dart` | `TemaSidik.terang` / `TemaSidik.gelap`: `ThemeData` yang menema semua komponen Material. |

## Cara pakai

```dart
final t = context.teks;      // TextTheme
final s = context.skema;     // ColorScheme (primary = navy)
final w = context.warna;     // WarnaSidik (status, merah KAN)

Padding(
  padding: Spasi.kartu,
  child: Text('Nomor', style: t.titleSmall?.tabular),
);

// Angka sorot (64/60): bukan slot TextTheme.
Text('12', style: TipografiSidik.angkaSorot(teks: s.onSurface));
```

## Skala tipografi

| Tingkat | Ukuran/baris | Berat desain | Untuk |
|---|---|---|---|
| angka sorot | 64/60 | 800, selebar tetap | sisa hari di ubin alat Beranda (`angkaSorot`) |
| angka kartu | 44/48 | 800, selebar tetap | sisa hari di ubin alat dan detail alat (displayLarge) |
| kalimat utama | 32/38 | 800 | kalimat utama Beranda dan paket (displayMedium) |
| judul layar | 28/34 | 800 | judul layar tab, angka KPI, sambutan (displaySmall) |
| nama | 22/28 | 800 | nama alat/akun, nomor order (headline*) |
| judul app bar | 20/26 | 800 | judul app bar dan dialog (titleLarge) |
| judul bagian | 17/24 | 800 | judul bagian dan ubin (titleMedium) |
| label | 16/24 | 700 | label tombol dan baris (titleSmall, labelLarge) |
| isi bacaan | 16/24 | 400 | teks bacaan (body*) |
| keterangan | 14/20 | 500 | merk, tanggal, nomor seri, bantuan (bodySmall) |
| stempel | 12/16 | 700 | stempel status, label navigasi (labelMedium/Small) |

Berat 800 TIDAK tampil: Inter yang dibundel hanya punya 400/500/600/700 dan font
baru dilarang, jadi `TipografiSidik.beratTebal` = 700 (utang desain; naikkan ke
`FontWeight.w800` saat `Inter-ExtraBold.ttf` ditambahkan). Daftar izin ukuran
`{64, 44, 32, 28, 22, 20, 17, 16, 14, 12}` ada di `tema_sidik_test.dart`;
minimum 12 sp.

## Aturan warna

- Status: `lulus` (berlaku, selesai), `awas` (segera jatuh tempo), `gagal`
  (lewat jadwal, dibatalkan, tidak memenuhi toleransi), `tunggu` (diproses),
  netral (tidak aktif, riwayat). Selalu dengan ikon dan teks: di tema terang
  tinta keempatnya sama (navy), pembedanya latar + ikon + kata.
- Merah KAN (`WarnaSidik.kanMerah`) HANYA untuk `LencanaKan`; bukan warna galat.
  Galat isian dan tombol bahaya: `ColorScheme.error` (`PaletSidik.galat`).
- `teksKedua` tidak di atas koral (3,3:1): pakai navy. `garis` bukan tepi kontrol
  (1,4:1): pakai `garisTegas` (`ColorScheme.outline`).
- Lulus, awas, gagal, dan tunggu harus beda terangnya (luminans > 0,02), bukan
  cuma rona; diukur pada ubin (terang) atau tinta (gelap).
- Mengubah satu nilai di `palet_sidik.dart`: jalankan
  `flutter test test/tema`. `token_bento_test.dart` mencocokkan nilai dengan
  `docs/desain-ulang/tokens.json`; ubah keduanya bersama.

Aset terkait di luar Dart: `android/app/src/main/res` (ikon adaptif, splash)
dan `assets/images/logo_sidik.png`.
