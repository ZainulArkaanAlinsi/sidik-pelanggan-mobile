# SIDIK Pelanggan (Flutter)

Aplikasi pemilik alat untuk laboratorium kalibrasi PT Sidik: status kalibrasi
alat, sertifikat (unduh PDF + tautan verifikasi), pelacakan paket, notifikasi
jatuh tempo, dan anggota tim perusahaan. Pasangan API-nya
`routes/api_pelanggan.php` di `sidik-calibration-api` (prefix `/api/pelanggan/v1`).

> **Status: kerangka lengkap, BELUM pernah dikompilasi.** Ditulis di lingkungan
> tanpa Flutter SDK (pub.dev diblokir). Sudah diperiksa: sintaks Dart
> (tree-sitter, 0 masalah), semua import relatif ada, semua anggota
> `SidikMaterial` yang dipakai ada. Belum: `flutter analyze`, `flutter test`,
> build di HP. Langkah pertama di mesin berSDK ada di bawah.

## Menjalankan pertama kali

```bash
# 1. Folder platform belum ada di repo ini — buat sekali:
flutter create --org id.ptsidik --project-name sidik_pelanggan --platforms android,ios .

# 2. Paket & pemeriksaan
flutter pub get
flutter analyze
flutter test

# 3. Jalankan ke server lokal (emulator Android → 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Server harus menyalakan modul pelanggan (`FITUR_PELANGGAN=true`).

## Push notification (opsional)

Aplikasi berjalan penuh TANPA push — kotak masuk di aplikasi tetap sumber
kebenaran. Untuk menyalakan push:

1. Di Firebase project yang SAMA dengan aplikasi lab (server hanya punya satu
   `FCM_PROJECT_ID`), tambahkan aplikasi Android `id.ptsidik.sidik_pelanggan`
   (dan iOS bila perlu).
2. Taruh `google-services.json` di `android/app/` dan ikuti langkah plugin
   `firebase_core` untuk Gradle.
3. Server memisahkan tujuan lewat `device_tokens.aplikasi`: token yang
   didaftarkan lewat `POST /pelanggan/v1/perangkat` hanya menerima kabar akun
   pelanggan (dijaga `DataPelangganTest::test_push_pelanggan_tidak_mendarat_di_token_aplikasi_internal`).

## Peta layar → endpoint

| Layar | Endpoint |
|---|---|
| Gerbang (pemeliharaan / versi wajib) | `GET /app/status` |
| Masuk | `POST /auth/masuk` |
| Pakai kode undangan | `POST /auth/terima-undangan` |
| Lupa sandi (OTP 6 digit, 10 menit) | `POST /auth/lupa-sandi`, `POST /auth/atur-ulang-sandi` |
| Akun belum aktif / pilih perusahaan | `GET /saya` |
| Beranda | `GET /beranda` |
| Alat, Detail alat | `GET /alat`, `GET /alat/{id}` |
| Sertifikat, Detail, Unduh PDF | `GET /sertifikat`, `GET /sertifikat/{id}`, `GET /sertifikat/{id}/unduh` |
| Paket, Detail paket | `GET /paket`, `GET /paket/{id}` |
| Notifikasi | `GET /notifikasi`, `POST /notifikasi/{id}/dibaca`, `POST /notifikasi/dibaca-semua` |
| Anggota tim (undang/batal/nonaktifkan: PIC utama) | `GET /anggota`, `POST /anggota/undangan`, `DELETE /anggota/undangan/{id}`, `POST /anggota/{id}/nonaktifkan` |
| Profil saya / Ganti sandi / Hapus akun | `PATCH /saya`, `POST /saya/ganti-sandi`, `DELETE /saya` |
| Keluar | `DELETE /perangkat` lalu `POST /auth/keluar` |

## Aturan yang dipegang kode ini

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
