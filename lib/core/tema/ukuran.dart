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

// ── Bento Lab: ukuran komponen (docs/desain-ulang/UKURAN.md, tokens.json) ────
// dp pada layar rujukan 390. Tinggi ubin adalah MINIMUM: pada skala huruf
// sistem di atas 1,0 ubin tumbuh. Pakai `ConstrainedBox(minHeight:)`, jangan
// `SizedBox(height:)`. Komponen baru (P2 dst.) membaca angkanya dari sini.

/// Kontrol: tombol bulat, saringan, segmen, kolom cari, sakelar, stempel.
abstract final class UkuranKontrol {
  /// Tombol bulat kecil, di dalam kolom cari (navy).
  static const double tombolBulatKecil = 44;

  /// Tombol bulat di kepala layar (kembali, putih).
  static const double tombolBulat = 48;

  /// Tombol bulat aksi di ubin (kuning/navy).
  static const double tombolBulatBesar = 52;

  /// Saringan pil (tinggi); jumlahnya bulat 32.
  static const double saringan = 44;

  /// Jumlah di dalam saringan (bulat).
  static const double jumlahSaringan = 32;

  /// Segmen dua pilihan: tinggi luar (padding 6) dan tinggi pil dalam.
  static const double segmenLuar = 56;
  static const double segmenDalam = 44;

  /// Kolom cari pil (tombol bulat 44 di kanan).
  static const double kolomCari = 56;

  /// Sakelar: rel 56 x 36, tombol 28, padding 4.
  static const double sakelarLebar = 56;
  static const double sakelarTinggi = 36;
  static const double sakelarTombol = 28;

  /// Stempel status: pil setinggi 30 (radius [Bentuk.stempel]).
  static const double stempel = 30;
}

/// Baris, ubin, dan grafik.
abstract final class UkuranUbin {
  /// Baris menu: tinggi 64, ubin ikon 44.
  static const double barisMenu = 64;
  static const double ubinIkon = 44;

  /// Baris daftar: sama dengan [UkuranBaris.minimum] (72).
  static const double barisDaftar = 72;

  /// Ubin alat: 196 (Beranda 232).
  static const double alat = 196;
  static const double alatBeranda = 232;

  /// Ubin pasangan (2 kolom, 188) dan ubin menu (2 kolom, 140).
  static const double pasangan = 188;
  static const double menu = 140;

  /// Kapsul jatuh tempo: rel 124, isi paling pendek 44.
  static const double kapsulRel = 124;
  static const double kapsulMin = 44;

  /// Avatar inisial: 48 (daftar) dan 88 (profil).
  static const double avatar = 48;
  static const double avatarBesar = 88;
}

/// Dock navigasi melayang (HP, di bawah [Spasi.batasLebar]).
abstract final class UkuranDock {
  static const double tinggi = 64;
  static const double butir = 48;

  /// Jarak dock dari tepi bawah sistem.
  static const double dariBawah = 16;
}

/// Visual alat (gambar milik sendiri, kanvas 240 x 240).
abstract final class UkuranVisual {
  static const double alat = 160;
  static const double alatBeranda = 176;
  static const double ubinKecil = 112;
}
