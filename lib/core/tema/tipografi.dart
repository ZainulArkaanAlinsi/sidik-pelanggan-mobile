import 'package:flutter/material.dart';

/// Skala tipografi SIDIK Pelanggan, arah "Bento Lab": satu keluarga huruf
/// (Inter, sudah dibundel di `pubspec.yaml`; tidak ada font baru), sepuluh
/// ukuran. Daftar izin ukuran ada di `test/tema/tema_sidik_test.dart`; minimum
/// 12 sp. Sumber: `docs/desain-ulang/DESIGN.md` §Huruf dan `tokens.json`.
///
/// | Tingkat      | Ukuran/baris | Berat    | Spasi    | Slot `TextTheme`                       |
/// |--------------|--------------|----------|----------|----------------------------------------|
/// | angka sorot  | 64/60        | tebal*   | -0,04 em | BUKAN slot: [TipografiSidik.angkaSorot] |
/// | angka kartu  | 44/48        | tebal*   | -0,04 em | displayLarge                           |
/// | kalimat      | 32/38        | tebal*   | -0,03 em | displayMedium                          |
/// | judul layar  | 28/34        | tebal*   | -0,03 em | displaySmall                           |
/// | nama         | 22/28        | tebal*   | -0,02 em | headline*                              |
/// | judul bar    | 20/26        | tebal*   | -0,02 em | titleLarge                             |
/// | judul bagian | 17/24        | tebal*   | -0,01 em | titleMedium                            |
/// | label        | 16/24        | 700      | 0        | titleSmall, labelLarge                 |
/// | isi bacaan   | 16/24        | 400      | 0        | bodyLarge, bodyMedium                  |
/// | keterangan   | 14/20        | 500      | 0        | bodySmall                              |
/// | stempel      | 12/16        | 700      | 0        | labelMedium, labelSmall                |
///
/// *tebal = [beratTebal]. Bento Lab meminta 800 (ExtraBold), tetapi Inter yang
/// dibundel hanya punya 400/500/600/700 dan aturan proyek melarang font baru.
/// Sampai pemilik menambah `Inter-ExtraBold.ttf` (UTANG DESAIN), tingkat ini
/// tampil 700. `tema_sidik_test.dart` menjaga agar tak ada berat yang tak
/// punya berkasnya (tanpa itu mesin huruf diam-diam memakai 700 juga).
///
/// Spasi huruf di tabel dalam em; Flutter memakainya dalam dp, jadi tiap nilai
/// di bawah = ukuran x em.
///
/// Angka yang perlu lurus di kolom (jumlah, tanggal) memakai
/// [GayaAngka.tabular]; nomor sertifikat, order, dan seri memakai
/// [GayaAngka.nomor] (selebar tetap + nol bergaris).
abstract final class TipografiSidik {
  static const String keluarga = 'Inter';

  /// Berat "tebal" Bento Lab (judul, angka, nama). Seharusnya 800; lihat
  /// catatan utang di atas. Satu-satunya tempat yang diubah saat
  /// `Inter-ExtraBold.ttf` masuk `pubspec.yaml`.
  static const FontWeight beratTebal = FontWeight.w700;

  /// Label tombol/baris dan stempel.
  static const FontWeight beratLabel = FontWeight.w700;

  /// Keterangan (merk, tanggal, bantuan).
  static const FontWeight beratKeterangan = FontWeight.w500;

  /// Angka sorot (64/60): sisa hari di ubin alat Beranda. BUKAN slot
  /// `TextTheme` (Material tidak punya slot sebesar itu tanpa menggeser yang
  /// lain); komponen memanggil ini langsung dengan warna tinta ubinnya.
  /// Selalu selebar tetap. Teks 28 sp ke atas dijepit [SkalaHuruf.batasBesar]
  /// oleh pemakainya, sama seperti angka kartu.
  static TextStyle angkaSorot({required Color teks}) => TextStyle(
    fontFamily: keluarga,
    fontSize: 64,
    height: 60 / 64,
    fontWeight: beratTebal,
    letterSpacing: -2.56,
    color: teks,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Menyusun `TextTheme` dari warna teks utama dan teks kedua tema aktif.
  static TextTheme skala({required Color teks, required Color teksKedua}) {
    // Angka kartu: sisa hari di detail alat dan ubin alat. Selalu selebar tetap.
    final angka = TextStyle(
      fontSize: 44,
      height: 48 / 44,
      fontWeight: beratTebal,
      letterSpacing: -1.76,
      color: teks,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Kalimat utama Beranda dan paket.
    final kalimat = TextStyle(
      fontSize: 32,
      height: 38 / 32,
      fontWeight: beratTebal,
      letterSpacing: -0.96,
      color: teks,
    );
    // Judul layar tab, angka KPI, sambutan.
    final tampilan = TextStyle(
      fontSize: 28,
      height: 34 / 28,
      fontWeight: beratTebal,
      letterSpacing: -0.84,
      color: teks,
    );
    // Nama alat/akun.
    final nama = TextStyle(
      fontSize: 22,
      height: 28 / 22,
      fontWeight: beratTebal,
      letterSpacing: -0.44,
      color: teks,
    );
    final judulBar = TextStyle(
      fontSize: 20,
      height: 26 / 20,
      fontWeight: beratTebal,
      letterSpacing: -0.4,
      color: teks,
    );
    // Judul bagian dan ubin.
    final subjudul = TextStyle(
      fontSize: 17,
      height: 24 / 17,
      fontWeight: beratTebal,
      letterSpacing: -0.17,
      color: teks,
    );
    final isi = TextStyle(fontSize: 16, height: 24 / 16, color: teks);
    // Label tombol dan baris.
    final label = isi.copyWith(fontWeight: beratLabel);
    final keterangan = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: beratKeterangan,
      color: teksKedua,
    );
    // Stempel dan label kecil.
    final stempel = TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: beratLabel,
      color: teksKedua,
    );

    return TextTheme(
      displayLarge: angka,
      displayMedium: kalimat,
      displaySmall: tampilan,
      headlineLarge: nama,
      headlineMedium: nama,
      headlineSmall: nama,
      titleLarge: judulBar,
      titleMedium: subjudul,
      titleSmall: label,
      bodyLarge: isi,
      bodyMedium: isi,
      bodySmall: keterangan,
      labelLarge: label,
      labelMedium: stempel,
      labelSmall: stempel,
    ).apply(fontFamily: keluarga);
  }
}

/// Angka selebar tetap supaya kolom lurus dan tidak bergoyang tiap digit.
extension GayaAngka on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Nomor sertifikat, order, dan seri: selebar tetap + nol bergaris (0 tidak
  /// tertukar dengan O). Fitur OpenType dari Inter yang sudah dibundel; tanpa
  /// font baru.
  TextStyle get nomor => copyWith(
    fontFeatures: const [
      FontFeature.tabularFigures(),
      FontFeature.slashedZero(),
    ],
  );
}
