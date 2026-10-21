import 'package:flutter/foundation.dart' show kReleaseMode;

/// Konfigurasi yang ditetapkan waktu BUILD, bukan disimpan di HP.
///
/// Dua kunci `--dart-define`, persis seperti aplikasi lab:
///
///     flutter build apk --release --dart-define=APP_ENV=prod
///     flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
///
/// - `APP_ENV` — `prod` | `staging` | `dev`. Bawaannya `prod` untuk build
///   release dan `dev` untuk debug/profile, jadi APK rilis yang dibangun TANPA
///   satu pun `--dart-define` tetap tersambung ke server produksi. Dulu bawaan
///   satu-satunya `http://10.0.2.2:8000` (alamat emulator), dan build rilis
///   polos menampilkan "Tidak bisa terhubung ke server" di semua HP.
/// - `API_BASE_URL` — alamat server TANPA prefix `/api/pelanggan/v1`
///   (prefix ditempel [prefix] di bawah). Mengalahkan bawaan `APP_ENV`.
///
/// Tidak ada layar "ganti server" di aplikasi pelanggan. Layar itu masuk akal
/// di HP teknisi yang dites di LAN lab; di HP pelanggan dia cuma pintu untuk
/// diarahkan ke server palsu yang meminta sandinya.
abstract final class Konfigurasi {
  /// Server produksi (Render). `/api/pelanggan/v1` ditempel oleh [prefix].
  static const String urlProduksi =
      'https://sidik-calibration-api.onrender.com';

  /// Alamat laptop pengembang dilihat dari emulator Android.
  static const String urlEmulator = 'http://10.0.2.2:8000';

  static const String lingkungan = String.fromEnvironment(
    'APP_ENV',
    defaultValue: kReleaseMode ? 'prod' : 'dev',
  );

  static const bool produksi = lingkungan == 'prod';
  static const bool staging = lingkungan == 'staging';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: lingkungan == 'prod' ? urlProduksi : urlEmulator,
  );

  /// Semua rute pelanggan hidup di bawah prefix ini (routes/api_pelanggan.php).
  /// v1 tidak boleh berubah merusak — kalau harus, server membuka /v2.
  static const String prefix = '/api/pelanggan/v1';

  static const Duration batasWaktu = Duration(seconds: 20);

  /// Server gratis yang tidur butuh 30-90 detik untuk bangun.
  static const Duration batasBangun = Duration(seconds: 90);

  /// `applicationId` di `android/app/build.gradle.kts`. Pembaruan hanya bisa
  /// dipasang di atas APK dengan ID dan kunci tanda tangan yang sama.
  static const String idPaket = 'com.ptsidik.pelanggan';

  /// Aplikasi ini TIDAK ada di Play Store: APK dibagikan lewat GitHub
  /// Releases repo ini (`tool/rilis.ps1`). Tiap rilis membawa dua aset,
  /// `sidik-pelanggan.apk` dan manifes `versi-pelanggan.json`.
  static const String repoRilis = 'ZainulArkaanAlinsi/sidik-pelanggan-mobile';

  /// Manifes rilis terbaru. `releases/latest/download/…` dialihkan GitHub ke
  /// aset rilis terakhir — tanpa API, jadi tanpa batas 60 panggilan/jam per IP.
  /// Bisa ditimpa `--dart-define=URL_MANIFES_RILIS=…` untuk uji coba.
  static const String urlManifesRilis = String.fromEnvironment(
    'URL_MANIFES_RILIS',
    defaultValue:
        'https://github.com/$repoRilis/releases/latest/download/versi-pelanggan.json',
  );

  /// Halaman rilis — jalan keluar manual kalau pemasangan di aplikasi gagal.
  static Uri get halamanRilis =>
      Uri.parse('https://github.com/$repoRilis/releases/latest');

  /// Jeda minimum antar-pemeriksaan pembaruan (buka lagi / berkala).
  static const Duration selangCekPembaruan = Duration(hours: 1);
}
