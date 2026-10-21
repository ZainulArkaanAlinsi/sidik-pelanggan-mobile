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

  /// ID paket di Play Store (`applicationId` di `android/app/build.gradle.kts`).
  /// Permanen begitu diunggah ke Play — jangan diganti sesudah rilis pertama.
  static const String idPaket = 'com.ptsidik.pelanggan';

  static Uri get tautanPlayStore =>
      Uri.parse('https://play.google.com/store/apps/details?id=$idPaket');

  static Uri get tautanPasar => Uri.parse('market://details?id=$idPaket');
}
