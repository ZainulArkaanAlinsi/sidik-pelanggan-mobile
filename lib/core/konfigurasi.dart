/// Konfigurasi yang ditetapkan waktu BUILD, bukan disimpan di HP.
///
/// Alamat server dipasang lewat `--dart-define`, persis seperti aplikasi lab:
///
///     flutter run --dart-define=API_BASE_URL=https://api.contoh.id
///
/// Tidak ada layar "ganti server" di aplikasi pelanggan. Layar itu masuk akal
/// di HP teknisi yang dites di LAN lab; di HP pelanggan dia cuma pintu untuk
/// diarahkan ke server palsu yang meminta sandinya.
abstract final class Konfigurasi {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Semua rute pelanggan hidup di bawah prefix ini (routes/api_pelanggan.php).
  /// v1 tidak boleh berubah merusak — kalau harus, server membuka /v2.
  static const String prefix = '/api/pelanggan/v1';

  static const Duration batasWaktu = Duration(seconds: 20);
}
