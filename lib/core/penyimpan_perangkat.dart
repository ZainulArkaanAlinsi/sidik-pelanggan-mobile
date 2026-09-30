import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Setelan yang HANYA berlaku untuk HP ini: sudah lihat sambutan atau belum,
/// dan pilihan tema.
///
/// Sengaja di `flutter_secure_storage` yang sudah jadi dependensi, bukan
/// `shared_preferences` baru: dua nilai kecil tidak sepadan dengan satu paket
/// native tambahan. Isinya bukan rahasia — yang penting HP ini yang menyimpan.
/// Setelan per AKUN (mis. notifikasi) tidak boleh masuk sini: akun yang sama
/// dipakai di beberapa HP dan harus berperilaku sama di semuanya.
class PenyimpanPerangkat {
  PenyimpanPerangkat([FlutterSecureStorage? penyimpan])
    : _s = penyimpan ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  static const _kunciSambutan = 'perangkat.sudah_lihat_sambutan';
  static const _kunciTema = 'perangkat.tema';

  Future<bool> sudahLihatSambutan() async =>
      await _s.read(key: _kunciSambutan) == '1';

  Future<void> tandaiSambutan() => _s.write(key: _kunciSambutan, value: '1');

  /// `sistem` | `terang` | `gelap`; nilai lain dianggap `sistem`.
  Future<String?> tema() => _s.read(key: _kunciTema);

  Future<void> simpanTema(String nilai) =>
      _s.write(key: _kunciTema, value: nilai);
}
