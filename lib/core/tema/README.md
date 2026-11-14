# lib/core/tema — token dan tema

Satu-satunya tempat warna, spasi, sudut, elevasi, ukuran ikon, dan huruf
ditentukan. Layar dan widget **tidak** menulis `Color(0x...)`, `Colors.*`,
`SizedBox(height: 12)`, atau `fontSize: 14`; semuanya lewat token di bawah.
Gerbang desain menjaga aturan ini: `test/tema/token_only_test.dart` (ratchet),
`kontras_tema_test.dart`, `token_tema_test.dart`, `tema_sidik_test.dart`,
`anti_slop_test.dart`. Standar lengkap: `docs/standar-kualitas-desain.md`.

Arah desain "Jejak": Material 3 datar, elevasi rendah, ruang putih lega, satu
aksi utama per layar (56 dp), status selalu ikon + teks, stempel persegi
radius 4. Kobalt `#043EA1` (warna logo PT Sidik) sebagai warna utama, netral
dingin, mode terang dan gelap.

| Berkas | Isi |
|---|---|
| `palet_sidik.dart` | Warna mentah. SATU-SATUNYA berkas boleh `Color(0x...)`. |
| `warna_sidik.dart` | `WarnaSidik` (ThemeExtension): warna status (lulus/awas/gagal/tunggu) + merah KAN; pintasan `context.warna`, `context.skema`, `context.teks`. |
| `spasi.dart` | `Spasi.xs/sm/md/lg/xl/xxl` (4/8/12/16/24/32), `Spasi.sisi` (margin halaman 20), `Spasi.bagian` (32), `Spasi.batasKompak` (340 dp), `Spasi.daftar(context)`, batas tablet (600 dp), lebar isi (720 dp), dan `lebarLebar` (1040 dp, layar dua kolom: Beranda). |
| `bentuk.dart` | `Bentuk.kecil/kontrol/kartu/utama/lembar/pil` (radius 4/10/16/16/20/999). |
| `elevasi.dart` | `Elevasi.datar/rendah/lembar/garis`. Kedalaman dari garis halus, bukan bayangan tebal. |
| `ukuran.dart` | `UkuranIkon` (16/24/32/48), `AreaSentuh.minimum` (48 dp), `UkuranBaris` (baris 72, tombol utama 56, kolom angka 56), `UkuranTik` (jejak: tik 6/12, simpul 14/22, batang 2, lingkar 4, garis bawah 3, penanda 24, tik paket maksimum 24), `SkalaHuruf` (teks besar dijepit 1,15x; nomor tidak di bawah 12 sp efektif). |
| `tipografi.dart` | Skala sembilan ukuran (Inter), `.tabular` untuk angka selebar tetap, `.nomor` untuk nomor (selebar tetap + nol bergaris). |
| `tema_sidik.dart` | `TemaSidik.terang` / `TemaSidik.gelap`: `ThemeData` yang menema semua komponen Material. |

## Cara pakai

```dart
final t = context.teks;      // TextTheme
final s = context.skema;     // ColorScheme (primary = kobalt)
final w = context.warna;     // WarnaSidik (status, merah KAN)

Padding(
  padding: Spasi.kartu,
  child: Text('Nomor', style: t.titleSmall?.tabular),
);
```

## Skala tipografi

| Tingkat | Ukuran/baris | Berat | Untuk |
|---|---|---|---|
| angka bintang | 44/48 | 700, selebar tetap | sisa hari di detail alat |
| kalimat utama | 32/38 | 700 | kalimat utama Beranda dan paket |
| tampilan | 28/34 | 700 | nama alat/akun, angka KPI, sambutan |
| judul | 22/28 | 600 | judul layar, nomor order, judul keadaan |
| app bar | 20/26 | 600 | judul app bar dan dialog |
| subjudul | 17/24 | 600 | judul baris dan bagian |
| isi | 16/24 | 400 (600 untuk nama) | teks bacaan, label tombol |
| keterangan | 14/20 | 400 | merk, tanggal, nomor seri |
| label | 12/16 | 600 | stempel status, label navigasi |

Daftar izin eksplisit `{44, 32, 28, 22, 20, 17, 16, 14, 12}` ada di
`tema_sidik_test.dart`; minimum 12 sp.

## Aturan warna

- Status: `lulus` (berlaku, selesai), `awas` (segera jatuh tempo), `gagal`
  (lewat jadwal, dibatalkan, tidak memenuhi toleransi), `tunggu` (diproses),
  netral (tidak aktif, riwayat). Selalu dengan ikon dan teks.
- Merah KAN (`WarnaSidik.kanMerah`) HANYA untuk `LencanaKan`; bukan warna galat.
- Lulus, awas, dan gagal harus beda terangnya (luminans > 0,02), bukan cuma
  rona; `tunggu` dikecualikan.
- Mengubah satu nilai di `palet_sidik.dart`: jalankan
  `flutter test test/tema`.

Aset terkait di luar Dart: `android/app/src/main/res` (ikon adaptif, splash)
dan `assets/images/logo_sidik.png`.
