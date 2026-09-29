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

  Future<String?> token() => _s.read(key: _kunciToken);

  Future<int?> perusahaanId() async =>
      int.tryParse(await _s.read(key: _kunciPerusahaan) ?? '');

  Future<void> simpanToken(String token) =>
      _s.write(key: _kunciToken, value: token);

  Future<void> simpanPerusahaan(int? id) => id == null
      ? _s.delete(key: _kunciPerusahaan)
      : _s.write(key: _kunciPerusahaan, value: '$id');

  Future<void> hapus() async {
    await _s.delete(key: _kunciToken);
    await _s.delete(key: _kunciPerusahaan);
  }
}
