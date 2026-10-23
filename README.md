# SIDIK Pelanggan (Flutter)

Aplikasi pemilik alat untuk laboratorium kalibrasi PT Sidik: lihat data alat
dan jatuh tempo, sertifikat (unduh PDF + tautan verifikasi), notifikasi,
serta profil akun dan pilihan perusahaan. Pasangan API-nya
`routes/api_pelanggan.php` di `sidik-calibration-api` (prefix `/api/pelanggan/v1`).

> **Status (23 Okt 2026): rilis Android `v0.2.1+3` sudah publik.**
> [Rilis](https://github.com/ZainulArkaanAlinsi/sidik-pelanggan-mobile/releases/tag/v0.2.1%2B3)
> dan [CI analyze + test](https://github.com/ZainulArkaanAlinsi/sidik-pelanggan-mobile/actions/runs/39861639145)
> menunjuk commit `21a3b4d`. Metadata manifest cocok dengan aset APK: versi
> `0.2.1`, build `3`, ukuran `36.845.501` byte, dan SHA-256. Target skrip rilis
> adalah ARM32 + ARM64. Konfigurasi Firebase lokal tersedia saat pemeriksaan,
> tetapi push, event Crashlytics, dan alur aplikasi di HP sungguhan belum
> terverifikasi. CI tersebut menjalankan analyze + test, bukan build APK.

## Menjalankan

```bash
flutter pub get
flutter analyze
flutter test

# Jalankan ke server lokal (emulator Android → 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Server harus menyalakan modul pelanggan (`FITUR_PELANGGAN=true`).

## Push notification (opsional)

Aplikasi berjalan penuh TANPA push — kotak masuk di aplikasi tetap sumber
kebenaran. Untuk menyalakan push:

1. Di Firebase project yang SAMA dengan aplikasi lab (server hanya punya satu
   `FCM_PROJECT_ID`), tambahkan aplikasi Android `com.ptsidik.pelanggan`
   (dan iOS bila perlu).
2. Taruh `google-services.json` di `android/app/`. Gradle memasang plugin Google
   Services dan Crashlytics hanya ketika berkas ini ada. Berkas konfigurasi
   tidak masuk repo; keberadaannya belum membuktikan push berhasil diterima.
3. Server memisahkan tujuan lewat `device_tokens.aplikasi`: token yang
   didaftarkan lewat `POST /pelanggan/v1/perangkat` hanya menerima kabar akun
   pelanggan (dijaga `DataPelangganTest::test_push_pelanggan_tidak_mendarat_di_token_aplikasi_internal`).

## Rilis & pembaruan di dalam aplikasi

Aplikasi TIDAK ada di Play Store. APK dibagikan lewat GitHub Releases repo ini;
aplikasi terpasang membaca `releases/latest/download/versi-pelanggan.json`
(saat masuk, saat dibuka lagi, dan tiap jam — paling sering sekali per jam),
menampilkan banner "Versi X tersedia" di atas navigasi bawah, mengunduh APK
(otomatis hanya di Wi-Fi; kapan saja kalau diketuk), mencocokkan SHA-256, lalu
membuka pemasang Android (`PackageInstaller`). Rilis `wajib` dan gerbang versi
minimum server memakai dialog/layar yang tidak bisa ditutup.

1. Naikkan `version:` di `pubspec.yaml` — angka build sesudah `+` WAJIB naik.
2. Pastikan `android/key.properties` + keystore rilis ada (kunci yang sama
   dengan APK yang sudah terpasang di HP pelanggan).
3. `powershell -ExecutionPolicy Bypass -File tool/rilis.ps1 -Catatan "…"`
   (tambah `-Wajib` untuk pembaruan wajib). Skrip membangun APK, menulis
   `versi-pelanggan.json`, dan menjalankan `gh release create`.

Uji ke manifes lain: `--dart-define=URL_MANIFES_RILIS=https://…/versi-pelanggan.json`.

## Verifikasi yang masih perlu HP sungguhan

Perbaikan HP murah sudah merged melalui
[PR #11](https://github.com/ZainulArkaanAlinsi/sidik-pelanggan-mobile/pull/11):
hash APK dan penguraian JSON besar dipindah ke isolate, tampilan diuji pada
320 dp, serta pelaporan galat Crashlytics tersedia. Crashlytics baru dinyalakan
di build release setelah Firebase berhasil diinisialisasi; laporan Dart
mengirim jenis galat dan stack tanpa pesan galat atau identitas akun.

Checklist berikut masih menunggu bukti dari HP ARM32 dengan RAM 2 GB:

- Pembaruan dari versi lama lewat aplikasi: unduh, verifikasi hash, lalu pasang.
- Login, beranda, detail sertifikat dan unduh/buka PDF, serta layar Akun.
- Ukuran huruf sistem maksimum tanpa teks atau tombol terpotong.
- Nonfatal uji diterima di Firebase Crashlytics; periksa bahwa pesan galat dan
  data pelanggan tidak ikut terkirim. Akses console harus dilakukan pemilik
  yang berwenang.

Catat model HP, versi Android, versi aplikasi, hasil tiap langkah dan bukti
tanpa data pelanggan. Uji widget/CI belum menggantikan bukti ini.

## Peta layar → endpoint

Peta ini mengikuti fitur aktif rilis `0.2.1+3` di
`lib/services/layanan_pelanggan.dart` dan `lib/screens/`. Jalur di bawah
relatif terhadap `/api/pelanggan/v1`.

| Layar | Endpoint |
|---|---|
| Gerbang (pemeliharaan / versi wajib) | `GET /app/status` |
| Akun / akun belum aktif / pilih perusahaan | `GET /saya` |
| Beranda: ringkasan jatuh tempo dan daftar alat dengan pencarian/saringan | `GET /beranda`, `GET /alat` |
| Detail alat dan riwayat sertifikatnya | `GET /alat/{id}` |
| Sertifikat, Detail, Unduh PDF | `GET /sertifikat`, `GET /sertifikat/{id}`, `GET /sertifikat/{id}/unduh` |
| Notifikasi dan jumlah belum dibaca | `GET /notifikasi`, `GET /notifikasi/jumlah` |
| Bantuan & kontak / privasi & ketentuan | `GET /app/info` (tautan dibuka di aplikasi luar/peramban) |

Data bisnis di aplikasi bersifat **hanya lihat**. Pengecualian teknis untuk
autentikasi, registrasi perangkat push, dan penandaan notifikasi dibaca dibatasi
oleh `test/guard_tulis_test.dart`:

| Alur teknis yang didukung | Endpoint tulis yang diizinkan |
|---|---|
| Masuk / pakai kode undangan | `POST /auth/masuk`, `POST /auth/terima-undangan` |
| Pemulihan sandi | `POST /auth/lupa-sandi`, `POST /auth/atur-ulang-sandi` |
| Keluar / keluar dari semua perangkat | `POST /auth/keluar`, `POST /auth/keluar-semua` |
| Daftar / cabut token perangkat push | `POST /perangkat`, `DELETE /perangkat` |
| Tandai notifikasi dibaca / semua dibaca | `POST /notifikasi/{id}/dibaca`, `POST /notifikasi/dibaca-semua` |

## Aturan yang dipegang kode ini

- **Data sama di HP mana pun akun ini masuk.** Server satu-satunya sumber
  data; `lib/providers/sinkron_provider.dart` menarik ulang semua layar
  waktu aplikasi kembali ke layar depan dan waktu push masuk.
- **Tidak ada logika bisnis di HP.** Status jatuh tempo, tahap paket, dan
  kepemilikan dihitung server. Aplikasi hanya menampilkan.
- **`customer_id` tidak pernah dikirim.** Perusahaan aktif dipilih lewat
  header `X-Perusahaan-Id`, dan server tetap memeriksa keanggotaannya.
- **Token di penyimpanan terenkripsi** (`flutter_secure_storage`), bukan
  SharedPreferences.
- **Tema = salinan apa adanya** dari `sidik-calibration-mobile`
  (`lib/core/theme/*`, `lib/core/motion/*`, `lib/widgets/sidik/*`). Ubah di
  aplikasi lab dulu, lalu salin — jangan bercabang.
- Teks masih Bahasa Indonesia saja (pelanggan lab ini perusahaan Indonesia).
  Pindah ke ARB/l10n kalau pelanggan berbahasa lain mulai ada.
