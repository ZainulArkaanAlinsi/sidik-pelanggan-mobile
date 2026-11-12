# Pustaka PDF untuk pratinjau sertifikat

Dipilih 12 Nov 2026 untuk fitur 4 rencana §14.1 (pratinjau PDF di dalam
aplikasi: zoom, geser, putar, pindah halaman). Dokumen ini mencatat pilihan,
lisensi, dampak ukuran APK, dan hal yang belum terbukti.

## Keputusan

**`pdfx` 2.11.0**, lisensi **MIT**. Seluruh pemakaiannya ada di satu berkas,
`lib/widgets/penampil_pdf.dart`; `test/pratinjau_pdf_test.dart` gagal bila
paket itu diimpor dari berkas lain. Mengganti pustaka = mengganti satu berkas
(layar dan tes lain hanya mengenal `KontrolPenampilPdf`).

Lisensi `pdfx`, `pdfrx`, dan `flutter_pdfview` = MIT menurut tag `license:mit` di
pub.dev (dicek 12 Nov 2026) dan berkas LICENSE paket yang terpasang.

Alasan utama: di Android `pdfx` memakai `android.graphics.pdf.PdfRenderer`
bawaan sistem. Tidak ada pustaka native (`.so`) yang ikut APK, jadi:

- **tidak menambah ukuran per ABI**, dan pustaka ini tidak punya urusan dengan
  ARM32 atau ARM64: keduanya dilayani mesin PDF milik sistem Android;
- tidak ada masalah ukuran halaman memori 16 KB pada Android 15+ yang lazim
  menimpa pustaka native;
- cocok dengan sasaran HP murah ARM32/RAM 2 GB (`tool/rilis.ps1` membangun
  `android-arm,android-arm64`).

## Perbandingan singkat

| Pustaka | Lisensi | Mesin | Perkiraan tambahan APK (ARM32+ARM64) | Catatan |
|---|---|---|---|---|
| **`pdfx` 2.11.0** (dipilih) | MIT | `PdfRenderer` sistem | **tanpa native**; kode Dart + Kotlin ≈ 0,3–0,8 MB per ABI (perkiraan, lihat bawah) | `PdfViewPinch`: cubit/geser, render ulang pada ukuran sebenarnya saat diperbesar |
| `pdfrx` 2.12.0 | MIT (PDFium: BSD-3/Apache-2.0) | PDFium dibawa sendiri | **+ ± 6,5 MB** (arsip PDFium resmi `chromium/8152`: arm 2,9 MB + arm64 3,5 MB, terkompresi) | Fitur paling lengkap, tapi mahal di HP murah |
| `flutter_pdfview` 1.4.5 | MIT | PDFium via pustaka Android pihak ketiga | beberapa MB per ABI | Tanpa kendali putar/zoom dari Dart |
| `syncfusion_flutter_pdfviewer` | Lisensi khusus (pub.dev: `license:unknown`) | PDFium | besar | Dihindari: lisensi bukan permisif |

Angka `pdfrx` adalah ukuran arsip unduhan PDFium (termasuk header), bukan hasil
membangun APK; arahnya benar, nilai pastinya tidak. Pilihan `pdfx` tidak
bergantung pada selisih persisnya.

## Paket yang ikut masuk (`pubspec.lock`: +40 baris, 5 paket, nol versi berubah)

| Paket | Peran | Lisensi |
|---|---|---|
| `pdfx` 2.11.0 | penampil | MIT |
| `photo_view` 0.15.0 | dibawa `pdfx` | MIT |
| `synchronized` 3.6.1+1 | dibawa `pdfx` | MIT |
| `extension` 1.0.0 | dibawa `pdfx` | MIT |
| `universal_platform` 1.1.0 | dibawa `pdfx` | MIT |

Dependensi lain `pdfx` (`uuid`, `vector_math`, `web`, `meta`,
`plugin_platform_interface`) sudah ada di `pubspec.lock` dan tidak berubah.
Lisensi MIT hanya mewajibkan notis hak cipta ikut disertakan; Flutter
mengumpulkan berkas LICENSE paket pub secara otomatis ke `LicenseRegistry`.

## Dampak ukuran APK: perkiraan, BELUM diukur

Build APK tidak dijalankan di laptop kerja (aturan tugas). Perkiraan dari isi
paket:

- Sumber Dart yang ditambahkan ≈ 565 KB (`pdfx` 304 KB, `photo_view` 145 KB,
  `synchronized` 73 KB, `extension` 37 KB, `universal_platform` 6 KB); hasil
  kompilasi AOT dan tree-shaking jauh di bawah itu.
- Sumber Kotlin plugin ≈ 116 KB, menjadi DEX di bawah 0,1 MB.
- Tidak ada `.so`, tidak ada aset.

Cara mengukurnya sebelum rilis: bangun `flutter build apk --release
--target-platform android-arm,android-arm64 --analyze-size` di cabang ini dan
di `main`, lalu bandingkan ukuran APK dan laporan `--analyze-size`.

## Dukungan arm64 dan versi Android

- arm64 (dan ARM32, x86): ditangani `PdfRenderer` di sistem; tidak ada berkas
  per-ABI yang harus ada. Pustaka native-nya tidak ada, jadi tidak ada ABI yang
  bisa "tidak didukung".
- `PdfRenderer` butuh API 21; `minSdk` aplikasi = `flutter.minSdkVersion` = 24
  (Flutter 3.44.8), jadi aman.

## Yang belum terbukti (perlu HP nyata)

1. **Gradle**: plugin `pdfx` belum dikompilasi di laptop kerja (aturan tugas:
   tanpa build APK lokal). Sejak tinjauan 12 Nov CI punya job
   `Build Android (debug)` (`.github/workflows/periksa.yml`, `flutter build apk
   --debug`, Flutter 3.44.6, Java 17, tanpa secret) yang menjalankan Gradle
   di setiap PR, jadi kegagalan plugin ketahuan sebelum rilis. Job itu SENDIRI
   belum pernah dijalankan; hasil pertamanya di PR adalah buktinya. Bukti tidak langsung:
   `package_info_plus` 8.3.1 (sudah dalam rilis 0.2.2) memakai pola
   `build.gradle` yang sama (classpath Kotlin lama + `kotlinOptions`) dan
   terbangun di AGP 9.0.1 dengan `android.builtInKotlin=false`; `pdfx` 2.10.0
   menambah dukungan AGP 9. Tetap: jalankan sekali `flutter build apk --debug`
   (atau build rilis) sebelum PR digabung.
2. **Tampilan PDF di perangkat**: test memakai penampil palsu. Belum ada bukti
   cubit-zoom, geser, putar 90°, tombol Perbesar/Perkecil, dan pindah halaman
   pada HP sungguhan, terutama ARM32/RAM 2 GB. Tombol Perbesar/Perkecil dan
   Putar adalah kode sendiri di atas `PdfControllerPinch` (matriks tampilan),
   bukan fitur bawaan `pdfx`.
3. Kecepatan dan memori render halaman A4 pada Android 7–9 dengan RAM 2 GB.

## Privasi: di mana berkasnya

- PDF diunduh lewat `ApiPelanggan.unduh` (header `Authorization` dan
  `X-Perusahaan-Id` hanya ke host API; tidak ada permintaan ke host lain).
- Disimpan sementara di folder **cache aplikasi** `sidik_pratinjau/`
  (`lib/core/penyimpan_pratinjau.dart`): bukan folder Download atau Dokumen,
  tidak ikut cadangan. Nama berkas `sertifikat-<id>.pdf`; nomor sertifikat dan
  nama alat tidak ada di nama berkas. Paling banyak 12 berkas.
- Dibuang saat **keluar akun**, **sesi berakhir** (401, juga saat pemulihan
  sesi di awal aplikasi), **berganti perusahaan**, **masuk**, dan setiap
  aplikasi dibuka dengan sesi tersimpan (sisa dari proses yang dimatikan paksa).
- Tombol **Unduh PDF** (buka di aplikasi PDF lain) memakai folder cache yang
  sama. Dulu (≤ 0.2.2) menyimpannya sebagai `Sertifikat-<nomor>.pdf` di folder
  Dokumen aplikasi dan tidak pernah membersihkannya; sisa itu sekarang ikut
  dibuang (hanya berkas bernama `Sertifikat-*.pdf`).
- Unduhan hanya diterima bila `Content-Type` PDF (atau biner umum) DAN isinya
  diawali `%PDF-`, paling besar 25 MB (`ApiPelanggan.unduh`). Berkas yang
  ditolak tidak pernah disimpan.
- Setiap membuka pratinjau mengunduh ulang. Akibatnya sertifikat yang baru
  dibatalkan lab tidak bisa tampil dari salinan lama, tetapi tiap pratinjau
  tercatat server sebagai unduhan; lihat `docs/kebutuhan-api-pelanggan.md` §5.
