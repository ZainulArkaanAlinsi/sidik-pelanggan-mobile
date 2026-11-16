import 'package:flutter/material.dart';

/// Skala tipografi SIDIK Pelanggan, arah tenang-formal (REVISI 16 Nov 2026):
/// Inter untuk teks (sudah dibundel, bobot 400/500/600), IBM Plex Mono untuk
/// angka dan kode yang perlu dibandingkan (sisa hari, nomor sertifikat, nomor
/// order, nomor seri; dibundel di `assets/fonts`, lisensi SIL OFL, tanpa
/// unduhan saat jalan). Daftar izin ukuran ada di
/// `test/tema/tema_sidik_test.dart`; minimum 12 sp. Sumber:
/// `docs/desain-ulang/tokens.json`.
///
/// | Tingkat      | Ukuran/baris | Berat    | Slot `TextTheme`                       |
/// |--------------|--------------|----------|----------------------------------------|
/// | angka sorot  | 32/36 mono   | semibold | BUKAN slot: [TipografiSidik.angkaSorot] |
/// | angka kartu  | 28/32 mono   | semibold | displayLarge                           |
/// | kalimat      | 24/30        | semibold | displayMedium                          |
/// | judul layar  | 24/30        | semibold | displaySmall                           |
/// | nama         | 20/26        | semibold | headline*                              |
/// | judul bar    | 18/24        | semibold | titleLarge                             |
/// | judul bagian | 16/22        | semibold | titleMedium                            |
/// | label        | 14/20        | medium   | titleSmall, labelLarge                 |
/// | isi bacaan   | 16/24        | regular  | bodyLarge                              |
/// | isi          | 14/20        | regular  | bodyMedium                             |
/// | keterangan   | 13/18        | regular  | bodySmall                              |
/// | lencana      | 12/16        | semibold | labelMedium, labelSmall                |
///
/// Tidak ada spasi huruf negatif: judul besar yang dirapatkan menyempit di
/// layar 320 dp dengan huruf diperbesar. Bold (700) tidak dipakai; semibold
/// untuk judul, medium untuk label, regular untuk isi.
///
/// Angka yang perlu lurus di kolom (jumlah, tanggal) memakai
/// [GayaAngka.tabular] (Inter selebar tetap); nomor sertifikat, order, dan seri
/// memakai [GayaAngka.nomor] (IBM Plex Mono).
abstract final class TipografiSidik {
  static const String keluarga = 'Inter';

  /// IBM Plex Mono: angka pengukuran dan kode (nomor sertifikat/order/seri).
  static const String keluargaAngka = 'IBMPlexMono';

  /// Berat judul dan angka: semibold.
  static const FontWeight beratTebal = FontWeight.w600;

  /// Label tombol, baris, dan isian: medium.
  static const FontWeight beratLabel = FontWeight.w500;

  /// Lencana status dan label bilah navigasi aktif: semibold (12 sp kecil).
  static const FontWeight beratLencana = FontWeight.w600;

  /// Keterangan (merk, tanggal, bantuan): regular.
  static const FontWeight beratKeterangan = FontWeight.w400;

  /// Angka sorot (32/36): sisa hari di ubin alat Beranda. BUKAN slot
  /// `TextTheme`; komponen memanggil ini langsung dengan warna teksnya. IBM
  /// Plex Mono selebar tetap. Teks 24 sp ke atas dijepit [SkalaHuruf.batasBesar]
  /// oleh pemakainya.
  static TextStyle angkaSorot({required Color teks}) => TextStyle(
    fontFamily: keluargaAngka,
    fontSize: 32,
    height: 36 / 32,
    fontWeight: beratTebal,
    color: teks,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Menyusun `TextTheme` dari warna teks utama dan teks kedua tema aktif.
  static TextTheme skala({required Color teks, required Color teksKedua}) {
    // Angka kartu: sisa hari di detail alat dan ubin alat. IBM Plex Mono.
    final angka = TextStyle(
      fontFamily: keluargaAngka,
      fontSize: 28,
      height: 32 / 28,
      fontWeight: beratTebal,
      color: teks,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Kalimat utama Beranda dan paket.
    final kalimat = TextStyle(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: beratTebal,
      color: teks,
    );
    // Judul layar tab, angka KPI, sambutan.
    final tampilan = TextStyle(
      fontSize: 24,
      height: 30 / 24,
      fontWeight: beratTebal,
      color: teks,
    );
    // Nama alat/akun.
    final nama = TextStyle(
      fontSize: 20,
      height: 26 / 20,
      fontWeight: beratTebal,
      color: teks,
    );
    final judulBar = TextStyle(
      fontSize: 18,
      height: 24 / 18,
      fontWeight: beratTebal,
      color: teks,
    );
    // Judul bagian dan ubin.
    final subjudul = TextStyle(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: beratTebal,
      color: teks,
    );
    final isiBacaan = TextStyle(fontSize: 16, height: 24 / 16, color: teks);
    final isi = TextStyle(fontSize: 14, height: 20 / 14, color: teks);
    // Label tombol dan baris.
    final label = isi.copyWith(fontWeight: beratLabel);
    final keterangan = TextStyle(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: beratKeterangan,
      color: teksKedua,
    );
    // Lencana dan label kecil.
    final lencana = TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: beratLencana,
      color: teksKedua,
    );

    // `apply(fontFamily:)` menimpa SEMUA slot; slot angka memakai keluarga
    // sendiri, jadi dipasang sesudahnya.
    final dasar = TextTheme(
      displayMedium: kalimat,
      displaySmall: tampilan,
      headlineLarge: nama,
      headlineMedium: nama,
      headlineSmall: nama,
      titleLarge: judulBar,
      titleMedium: subjudul,
      titleSmall: label,
      bodyLarge: isiBacaan,
      bodyMedium: isi,
      bodySmall: keterangan,
      labelLarge: label,
      labelMedium: lencana,
      labelSmall: lencana,
    ).apply(fontFamily: keluarga);
    return dasar.copyWith(displayLarge: angka);
  }
}

/// Angka selebar tetap supaya kolom lurus dan tidak bergoyang tiap digit.
extension GayaAngka on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Nomor sertifikat, order, dan seri: IBM Plex Mono (selebar tetap; nol
  /// bertitik, tidak tertukar dengan O). Berat mengikuti gaya dasar, dijepit
  /// ke 400-600 yang dibundel.
  TextStyle get nomor => copyWith(
    fontFamily: TipografiSidik.keluargaAngka,
    fontWeight: switch (fontWeight?.value ?? 400) {
      < 450 => FontWeight.w400,
      < 550 => FontWeight.w500,
      _ => FontWeight.w600,
    },
    fontFeatures: const [
      FontFeature.tabularFigures(),
      FontFeature.slashedZero(),
    ],
  );
}
