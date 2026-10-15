import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token & perusahaan aktif, disimpan di penyimpanan TERENKRIPSI perangkat
/// (Keystore/Keychain) — bukan SharedPreferences, yang di Android bisa dibaca
/// dari cadangan perangkat.
class PenyimpanSesi {
  PenyimpanSesi([FlutterSecureStorage? penyimpan])
    : _s = penyimpan ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  static const _kunciToken = 'pelanggan.token';
  static const _kunciPerusahaan = 'pelanggan.perusahaan_id';
  static const _kunciPengguna = 'pelanggan.user_id';

  Future<String?> token() => _s.read(key: _kunciToken);

  Future<int?> perusahaanId() async =>
      int.tryParse(await _s.read(key: _kunciPerusahaan) ?? '');

  /// ID akun yang terakhir masuk di HP ini — pemilik cache offline. Dibaca
  /// SEBELUM `GET /saya`, supaya aplikasi yang dibuka tanpa sinyal tetap bisa
  /// memulihkan akun & data terakhirnya dari cache.
  Future<int?> penggunaId() async =>
      int.tryParse(await _s.read(key: _kunciPengguna) ?? '');

  Future<void> simpanPengguna(int id) =>
      _s.write(key: _kunciPengguna, value: '$id');

  Future<void> simpanToken(String token) =>
      _s.write(key: _kunciToken, value: token);

  Future<void> simpanPerusahaan(int? id) => id == null
      ? _s.delete(key: _kunciPerusahaan)
      : _s.write(key: _kunciPerusahaan, value: '$id');

  Future<void> hapus() async {
    await _s.delete(key: _kunciToken);
    await _s.delete(key: _kunciPerusahaan);
    await _s.delete(key: _kunciPengguna);
  }
}
