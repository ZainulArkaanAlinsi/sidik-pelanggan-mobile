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

  /// Bayangan dock navigasi, SATU-SATUNYA bayangan Bento Lab (tokens.json
  /// `bayanganDock`): geser ke bawah 16, blur 32, navy 28 %. Warnanya diambil
  /// pemakai dari tinta navy tema (`WarnaSidik.tintaUbin`).
  static const double dockGeser = 16;
  static const double dockBlur = 32;
  static const double dockOpasitas = 0.28;
}
