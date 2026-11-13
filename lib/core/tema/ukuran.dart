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

/// Tinggi baris dan tombol. Pelanggan lega: baris daftar 72 dp (Lab 64).
abstract final class UkuranBaris {
  /// Tinggi minimum baris daftar dua sampai empat baris teks.
  static const double minimum = 72;

  /// Tombol utama: satu per layar, dijangkau ibu jari.
  static const double tombolUtama = 56;

  /// Lebar kolom angka-hari di awal baris (diskalakan dengan huruf).
  static const double kolomAngka = 56;
}

/// Tik pada jejak tahap dan peta jatuh tempo (motif skala, dipakai hemat).
abstract final class UkuranTik {
  static const double tinggi = 6;
  static const double tinggiSekarang = 12;
  static const double jarak = 4;
}
