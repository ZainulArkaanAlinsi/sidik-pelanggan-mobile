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

  /// "12 hari lagi" / "Kalibrasi ulang hari ini" / "Lewat 3 hari".
  /// Istilahnya "jadwal kalibrasi ulang", bukan "kadaluarsa" (BR-09).
  static String sisaHari(int? hari) {
    if (hari == null) return 'Belum ada jadwal kalibrasi ulang';
    if (hari == 0) return 'Kalibrasi ulang hari ini';
    if (hari > 0) return '$hari hari lagi';
    return 'Lewat ${-hari} hari';
  }

  static final _jam = DateFormat('HH.mm', 'id_ID');
  static final _tanggalPendekJam = DateFormat('d MMM, HH.mm', 'id_ID');

  /// "08.12" kalau hari ini, "12 Okt, 08.12" kalau bukan — untuk penanda
  /// waktu data terakhir (banner offline).
  static String jamAtauTanggal(DateTime t, {DateTime? sekarang}) {
    final n = sekarang ?? DateTime.now();
    final hariIni = t.year == n.year && t.month == n.month && t.day == n.day;
    return hariIni ? _jam.format(t) : _tanggalPendekJam.format(t);
  }
}
