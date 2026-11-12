# Catatan perubahan P-1 / P-4 / P-5 (belum dirilis)

`version:` di `pubspec.yaml` TIDAK diubah (0.2.2+4); pemilik yang menaikkannya
saat merilis. Teks di bawah siap dipakai untuk `tool/rilis.ps1 -Catatan`.

## Catatan rilis (untuk pengguna)

- Email undangan yang sudah punya akun kini diberi tahu: Anda masuk ke akun
  lama dan sandi yang baru diketik tidak dipakai.
- Dialog pembaruan wajib dan layar "Perbarui aplikasi" kini punya tombol "Keluar dari akun".
- Menu Akun: Ganti sandi, Pengaturan notifikasi, Anggota perusahaan (PIC utama
  bisa menonaktifkan anggota), dan Pelacakan paket.

## Teknis

| Butir | Perubahan | Berkas utama |
|---|---|---|
| P-1a | Terima-undangan untuk email yang sudah punya akun menampilkan dialog penjelasan (tanpa menyebut nama lama atau perusahaan lain). Deteksi dari jawaban server, bukan penanda eksplisit: lihat `docs/kebutuhan-api-pelanggan.md` §3 | `layanan_pelanggan.dart`, `sesi_provider.dart`, `terima_undangan_screen.dart` |
| P-1b | `TombolKeluarAkun` di `DialogPembaruanWajib` dan `LayarWajibPerbarui` (tampil bila ada token tersimpan, bukan `sesiProvider` yang di versi usang gagal 426): konfirmasi, jalur keluar yang sama dengan tab Akun, menunggu pemulihan sesi paling lama 3 detik, lalu menutup dialog. `SesiController.keluar()` kini memastikan klien memegang token tersimpan | `widgets/pembaruan.dart`, `screens/gerbang.dart`, `providers/sesi_provider.dart` |
| P-4 | Layar Ganti sandi, Pengaturan notifikasi, Anggota perusahaan, Pelacakan paket (daftar + detail), dan pintunya di tab Akun | `screens/akun/*`, `screens/paket/*`, `models/anggota.dart`, `models/paket.dart`, `providers/data_provider.dart` |
| P-4 | Allow-list tulis: `POST /saya/ganti-sandi`, `PUT /preferensi-notifikasi`, `POST /anggota/{x}/nonaktifkan`, dasarnya keputusan 20 Okt 2026. Guard sekarang juga gagal bila ada entri allow-list tanpa pemanggil | `test/guard_tulis_test.dart` |
| P-5 | Alur dasar (undangan, sertifikat, unduh, keluar) terhadap server palsu: `test/alur_dasar_test.dart` (jalan di `flutter test`/CI) dan `integration_test/alur_dasar_test.dart` (butuh perangkat) memakai skenario yang sama | `test/dukungan/*`, `integration_test/` |

`pubspec.yaml` mendapat dev dependency `integration_test` (sdk flutter);
`pubspec.lock` hanya bertambah 47 baris (paket dev transitif), tidak ada versi
yang berubah. Bukan bagian APK.

## Belum bisa / butuh keputusan

Lihat `docs/kebutuhan-api-pelanggan.md`: order dari pelanggan (tidak ada rute),
penanda `akun_sudah_ada`, saklar `pesan_lab`, undang/batalkan undangan dan
PATCH/DELETE `/saya` (rute ada, belum ada layar).

## Perlu dicek di HP

Belum ada bukti di perangkat untuk semuanya. Minimal: terima undangan dengan
email yang sudah punya akun, tombol Keluar di dialog wajib (butuh rilis wajib
nyata), ganti sandi (sesi di HP lain berakhir), PIC menonaktifkan anggota
(sesi anggota itu berakhir), huruf maksimum di layar-layar baru.
