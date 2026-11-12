/// Token ukuran ikon dan area sentuh (dp).
abstract final class UkuranIkon {
  /// Ikon di dalam chip dan baris keterangan.
  static const double kecil = 16;

  /// Ikon standar di baris, tombol, dan navigasi.
  static const double sedang = 24;

  /// Ikon di ubin kartu dan kepala layar.
  static const double besar = 32;

  /// Ilustrasi keadaan kosong dan galat.
  static const double ilustrasi = 48;
}

/// Ukuran minimum area sentuh (pedoman Material dan WCAG 2.5.8: 48 dp).
abstract final class AreaSentuh {
  static const double minimum = 48;
}
