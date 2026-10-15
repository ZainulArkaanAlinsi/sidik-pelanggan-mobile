import 'dart:math';

/// UUID versi 4 (RFC 9562 §5.4) dari `Random.secure()`.
///
/// Dipakai untuk header `X-Request-Id` tiap panggilan API (NFR-11) — ID yang
/// tidak bisa ditebak dan tidak bertabrakan antar-HP; percobaan ulang GET
/// memakai ID yang sama.
///
/// Ditulis sendiri (sepuluh baris) alih-alih menambah dependensi `uuid`.
abstract final class IdUnik {
  static final Random _acak = Random.secure();

  static String uuid4([Random? acak]) {
    final r = acak ?? _acak;
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // versi 4
    b[8] = (b[8] & 0x3f) | 0x80; // varian RFC
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static final _pola = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  static bool sahUuid4(String? s) => s != null && _pola.hasMatch(s);
}
