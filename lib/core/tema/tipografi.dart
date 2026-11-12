import 'package:flutter/material.dart';

/// Skala tipografi SIDIK Pelanggan: enam tingkat, satu keluarga huruf (Inter,
/// sudah dibundel di `pubspec.yaml`; tidak ada font baru).
///
/// | Tingkat    | Ukuran/baris | Berat | Dipakai untuk                         | Slot `TextTheme`                |
/// |------------|--------------|-------|---------------------------------------|---------------------------------|
/// | tampilan   | 28/34        | 700   | angka KPI, judul sambutan             | display*                        |
/// | judul      | 20/26        | 600   | judul layar dan app bar               | headline*, titleLarge           |
/// | subjudul   | 16/24        | 600   | judul kartu dan bagian                | titleMedium                     |
/// | isi        | 15/22        | 400   | teks bacaan; tebal (600) untuk nama   | body*, titleSmall (tebal), label |
/// | keterangan | 13/18        | 400   | teks pendukung, tanggal, bantuan      | bodySmall                       |
/// | label      | 12/16        | 600   | chip status, label navigasi           | labelMedium, labelSmall         |
///
/// Angka yang perlu lurus di kolom (nomor sertifikat, jumlah, tanggal) memakai
/// [GayaAngka.tabular].
abstract final class TipografiSidik {
  static const String keluarga = 'Inter';

  /// Menyusun `TextTheme` dari warna teks utama dan teks kedua tema aktif.
  static TextTheme skala({required Color teks, required Color teksKedua}) {
    final tampilan = TextStyle(
      fontSize: 28,
      height: 34 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: teks,
    );
    final judul = TextStyle(
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: teks,
    );
    final subjudul = TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
      color: teks,
    );
    final isi = TextStyle(fontSize: 15, height: 22 / 15, color: teks);
    final isiTebal = isi.copyWith(fontWeight: FontWeight.w600);
    final keterangan = TextStyle(
      fontSize: 13,
      height: 18 / 13,
      color: teksKedua,
    );
    final label = TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: teksKedua,
    );

    return TextTheme(
      displayLarge: tampilan,
      displayMedium: tampilan,
      displaySmall: tampilan,
      headlineLarge: judul,
      headlineMedium: judul,
      headlineSmall: judul,
      titleLarge: judul,
      titleMedium: subjudul,
      titleSmall: isiTebal,
      bodyLarge: isi,
      bodyMedium: isi,
      bodySmall: keterangan,
      labelLarge: isiTebal.copyWith(height: 20 / 15),
      labelMedium: label,
      labelSmall: label,
    ).apply(fontFamily: keluarga);
  }
}

/// Angka selebar tetap supaya kolom lurus dan tidak bergoyang tiap digit.
extension GayaAngka on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
