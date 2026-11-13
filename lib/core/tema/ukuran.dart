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

  /// Simpul persegi pada garis waktu tegak (`GarisWaktuTahap`).
  static const double simpul = 14;

  /// Simpul tahap "sekarang": simpul 14 + lingkar 4 di tiap sisi = 22.
  static const double simpulSekarang = 22;

  /// Tebal batang penghubung simpul, tik jadwal, dan bingkai simpul belum.
  static const double batang = 2;

  /// Tebal lingkar simpul "sekarang".
  static const double lingkar = 4;

  /// Tebal garis bawah pilihan terpilih pada `SaringanTeks`.
  static const double garisBawah = 3;

  /// Tinggi tik jadwal yang memotong batang pada `SkalaTempo`.
  static const double penanda = 24;

  /// Jumlah tik per alat paling banyak; di atasnya `TikPaket` jatuh ke satu
  /// batang bersegmen supaya tik tidak lebih sempit dari jaraknya.
  static const int tikPaketMaksimum = 24;
}

/// Batas skala huruf sistem untuk teks besar dan nomor.
abstract final class SkalaHuruf {
  /// Teks 28 sp ke atas (kalimat utama, angka-hari) dijepit sampai kali ini
  /// terhadap skala huruf sistem; teks bacaan menskala penuh. 32 sp x 1,3 =
  /// 42 sp memakan empat baris di 320 dp.
  static const double batasBesar = 1.15;

  /// Nomor (order, sertifikat, seri) boleh mengecil agar satu baris, tetapi
  /// tidak di bawah ukuran efektif ini (sp); di bawahnya nomor membungkus di
  /// garis miring atau strip, tidak pernah putus di tengah angka.
  static const double nomorMinimum = 12;
}
