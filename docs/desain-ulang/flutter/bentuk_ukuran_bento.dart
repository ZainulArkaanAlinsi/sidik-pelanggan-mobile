// Tambahan untuk lib/core/tema/bentuk.dart dan ukuran.dart.

abstract final class BentukBento {
  static const double ikon = 16;
  static const double kapsul = 22;
  static const double panel = 28;
  static const double ubin = 32;
  static const double dock = 36;
  static const double pil = 999;
}

abstract final class UkuranBento {
  // Kontrol
  static const double tombolUtama = 56; // sama dengan UkuranBaris.tombolUtama
  static const double tombolBulatKecil = 44; // di dalam kolom cari
  static const double tombolBulat = 48; // kepala layar
  static const double tombolBulatBesar = 52; // aksi di ubin
  static const double saringan = 44;
  static const double segmenLuar = 56;
  static const double segmenDalam = 44;
  static const double kolomCari = 56;
  static const double sakelarLebar = 56;
  static const double sakelarTinggi = 36;
  static const double sakelarTombol = 28;
  static const double stempel = 30;

  // Baris dan ubin
  static const double barisMenu = 64;
  static const double barisDaftar = 72;
  static const double ubinIkon = 44;
  static const double ubinAlat = 196;
  static const double ubinAlatBeranda = 232;
  static const double ubinPasangan = 188;
  static const double ubinMenu = 140;
  static const double kapsulRel = 124;
  static const double kapsulMin = 44;

  // Dock
  static const double dock = 64;
  static const double butirDock = 48;
  static const double dockDariBawah = 16;

  // Visual alat
  static const double visualAlat = 160;
  static const double visualAlatBeranda = 176;
  static const double visualUbinKecil = 112;
}

// Tinggi ubin adalah MINIMUM (ConstrainedBox(minHeight)), bukan tinggi mati:
// di huruf sistem 1,3x isi boleh mendorong ubin lebih tinggi.
