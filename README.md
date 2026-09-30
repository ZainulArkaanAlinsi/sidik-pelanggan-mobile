# SIDIK Pelanggan (Flutter)

Aplikasi pemilik alat untuk laboratorium kalibrasi PT Sidik: status kalibrasi
alat, sertifikat (unduh PDF + tautan verifikasi), pelacakan paket, notifikasi
jatuh tempo, dan anggota tim perusahaan. Pasangan API-nya
`routes/api_pelanggan.php` di `sidik-calibration-api` (prefix `/api/pelanggan/v1`).

> **Status (30 Sep 2026): terkompilasi & teruji, belum dicoba di HP.**
> `flutter analyze` bersih dan `flutter test` hijau (Flutter 3.44), dijaga CI
> `.github/workflows/periksa.yml` di tiap push & PR. Folder `android/` & `ios/`
> sudah ada (`flutter create --org id.ptsidik`). Belum: build & uji di HP
> sungguhan, dan konfigurasi Firebase untuk push.

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
| Paket, Detail paket (dari ikon truk di Permintaan / kartu Beranda) | `GET /paket`, `GET /paket/{id}` |
| Permintaan (tab Aktif/Selesai/Semua) | `GET /permintaan?saring=` |
| Ajukan kalibrasi + Tambah alat | `POST /permintaan` (alat terdaftar dari `GET /alat`) |
| Detail permintaan, batal, pesan ke lab | `GET /permintaan/{id}`, `POST /permintaan/{id}/batal`, `GET/POST /permintaan/{id}/pesan` |
| Preferensi notifikasi (per perusahaan, di server) | `GET/PUT /preferensi-notifikasi` |
| Notifikasi | `GET /notifikasi`, `POST /notifikasi/{id}/dibaca`, `POST /notifikasi/dibaca-semua` |
| Anggota tim (undang/batal/nonaktifkan: PIC utama) | `GET /anggota`, `POST /anggota/undangan`, `DELETE /anggota/undangan/{id}`, `POST /anggota/{id}/nonaktifkan` |
| Profil saya / Ganti sandi / Hapus akun | `PATCH /saya`, `POST /saya/ganti-sandi`, `DELETE /saya` |
| Keluar | `DELETE /perangkat` lalu `POST /auth/keluar` |

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
