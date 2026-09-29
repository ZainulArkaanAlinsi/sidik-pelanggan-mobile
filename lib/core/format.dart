import 'package:intl/intl.dart';

/// Format tanggal & angka untuk pembaca Indonesia.
///
/// Tanggal dari server berbentuk `YYYY-MM-DD` (tanggal saja) atau ISO 8601
/// (cap waktu). Dua-duanya ditampilkan sebagai "12 Okt 2026" — pelanggan
/// membaca tanggal jatuh tempo, bukan jam.
abstract final class Format {
  static final _tanggal = DateFormat('d MMM yyyy', 'id_ID');
  static final _tanggalJam = DateFormat('d MMM yyyy, HH.mm', 'id_ID');

  static DateTime? baca(String? teks) =>
      teks == null || teks.isEmpty ? null : DateTime.tryParse(teks)?.toLocal();

  static String tanggal(DateTime? t, {String kosong = '—'}) =>
      t == null ? kosong : _tanggal.format(t);

  static String tanggalJam(DateTime? t, {String kosong = '—'}) =>
      t == null ? kosong : _tanggalJam.format(t);

  /// "12 hari lagi" / "hari ini" / "lewat 3 hari".
  static String sisaHari(int? hari) {
    if (hari == null) return 'Belum ada jadwal';
    if (hari == 0) return 'Jatuh tempo hari ini';
    if (hari > 0) return '$hari hari lagi';
    return 'Lewat ${-hari} hari';
  }
}
