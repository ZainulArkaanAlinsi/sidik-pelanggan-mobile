# lib/core/tema — token dan tema

Satu-satunya tempat warna, spasi, sudut, elevasi, ukuran ikon, dan huruf
ditentukan. Layar dan widget **tidak** menulis `Color(0x...)`, `Colors.*`,
`SizedBox(height: 12)`, atau `fontSize: 14`; semuanya lewat token di bawah.
`test/tema/tema_sidik_test.dart` menjaga aturan ini dan kontras WCAG AA.

Arah desain: Material 3 datar, elevasi rendah, ruang putih lega, satu aksi
utama per layar, status selalu ikon + teks. Kobalt `#043EA1` (warna logo PT
Sidik) sebagai warna utama, netral dingin, mode terang dan gelap.

| Berkas | Isi |
|---|---|
| `palet_sidik.dart` | Warna mentah. SATU-SATUNYA berkas boleh `Color(0x...)`. |
| `warna_sidik.dart` | `WarnaSidik` (ThemeExtension): warna status (lulus/awas/gagal/tunggu) + merah KAN; pintasan `context.warna`, `context.skema`, `context.teks`. |
| `spasi.dart` | `Spasi.xs/sm/md/lg/xl/xxl` (4/8/12/16/24/32), `Spasi.daftar(context)`, batas tablet (600 dp) dan lebar isi (720 dp). |
| `bentuk.dart` | `Bentuk.kecil/kontrol/kartu/lembar/pil` (radius). |
| `elevasi.dart` | `Elevasi.datar/rendah/lembar/garis`. Kedalaman dari garis halus, bukan bayangan tebal. |
| `ukuran.dart` | `UkuranIkon` (16/24/32/48) dan `AreaSentuh.minimum` (48 dp). |
| `tipografi.dart` | Skala enam tingkat (Inter) dan `.tabular` untuk angka selebar tetap. |
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
| tampilan | 28/34 | 700 | angka KPI, judul sambutan |
| judul | 20/26 | 600 | judul layar dan app bar |
| subjudul | 16/24 | 600 | judul kartu dan bagian |
| isi | 15/22 | 400 (600 untuk nama) | teks bacaan, label tombol |
| keterangan | 13/18 | 400 | teks pendukung, tanggal |
| label | 12/16 | 600 | chip status, label navigasi |

## Aturan warna

- Status: `lulus` (berlaku, selesai), `awas` (segera jatuh tempo), `gagal`
  (lewat jadwal, dibatalkan, tidak memenuhi toleransi), `tunggu` (diproses),
  netral (tidak aktif, riwayat). Selalu dengan ikon dan teks.
- Merah KAN (`WarnaSidik.kanMerah`) HANYA untuk `LencanaKan`; bukan warna galat.
- Mengubah satu nilai di `palet_sidik.dart`: jalankan
  `flutter test test/tema/tema_sidik_test.dart`.

Aset terkait di luar Dart: `android/app/src/main/res` (ikon adaptif, splash)
dan `assets/images/logo_sidik.png`.
