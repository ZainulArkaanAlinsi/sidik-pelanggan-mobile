/// Token elevasi (dp). Tampilan datar: kedalaman dibangun dari garis halus
/// dan perbedaan warna permukaan, bukan bayangan tebal.
abstract final class Elevasi {
  /// Kartu, app bar, navigasi: tanpa bayangan (dibatasi garis halus).
  static const double datar = 0;

  /// Snack bar dan menu: sedikit terangkat.
  static const double rendah = 2;

  /// Dialog dan lembar bawah.
  static const double lembar = 3;

  /// Tebal garis halus pembatas kartu dan pemisah.
  static const double garis = 1;
}
