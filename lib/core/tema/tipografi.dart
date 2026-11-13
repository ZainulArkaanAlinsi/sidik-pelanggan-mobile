import 'package:flutter/material.dart';

/// Skala tipografi SIDIK Pelanggan: satu keluarga huruf (Inter, sudah dibundel
/// di `pubspec.yaml`; tidak ada font baru), sembilan ukuran. Daftar izin ukuran
/// ada di `test/tema/tema_sidik_test.dart`; minimum 12 sp.
///
/// | Tingkat     | Ukuran/baris | Berat | Dipakai untuk                          | Slot `TextTheme`        |
/// |-------------|--------------|-------|----------------------------------------|-------------------------|
/// | angka       | 44/48        | 700   | angka bintang (sisa hari), selebar tetap | displayLarge          |
/// | kalimat     | 32/38        | 700   | kalimat utama Beranda dan paket        | displayMedium           |
/// | tampilan    | 28/34        | 700   | nama alat/akun, angka KPI, sambutan    | displaySmall            |
/// | judul       | 22/28        | 600   | judul layar, nomor order, judul keadaan | headline*              |
/// | app bar     | 20/26        | 600   | judul app bar dan dialog               | titleLarge              |
/// | subjudul    | 17/24        | 600   | judul baris dan bagian                 | titleMedium             |
/// | isi         | 16/24        | 400   | teks bacaan; tebal (600) untuk nama    | body*, titleSmall (tebal), labelLarge |
/// | keterangan  | 14/20        | 400   | merk, tanggal, nomor seri, bantuan     | bodySmall               |
/// | label       | 12/16        | 600   | stempel status, label navigasi         | labelMedium, labelSmall |
///
/// Angka yang perlu lurus di kolom (jumlah, tanggal) memakai
/// [GayaAngka.tabular]; nomor sertifikat, order, dan seri memakai
/// [GayaAngka.nomor] (selebar tetap + nol bergaris).
abstract final class TipografiSidik {
  static const String keluarga = 'Inter';

  /// Menyusun `TextTheme` dari warna teks utama dan teks kedua tema aktif.
  static TextTheme skala({required Color teks, required Color teksKedua}) {
    // Angka bintang: sisa hari di detail alat. Selalu selebar tetap.
    final angka = TextStyle(
      fontSize: 44,
      height: 48 / 44,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: teks,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Kalimat utama Beranda.
    final kalimat = TextStyle(
      fontSize: 32,
      height: 38 / 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: teks,
    );
    final tampilan = TextStyle(
      fontSize: 28,
      height: 34 / 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: teks,
    );
    final judul = TextStyle(
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: teks,
    );
    final judulBar = TextStyle(
      fontSize: 20,
      height: 26 / 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: teks,
    );
    final subjudul = TextStyle(
      fontSize: 17,
      height: 24 / 17,
      fontWeight: FontWeight.w600,
      color: teks,
    );
    final isi = TextStyle(fontSize: 16, height: 24 / 16, color: teks);
    final isiTebal = isi.copyWith(fontWeight: FontWeight.w600);
    final keterangan = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      color: teksKedua,
    );
    final label = TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: teksKedua,
    );

    return TextTheme(
      displayLarge: angka,
      displayMedium: kalimat,
      displaySmall: tampilan,
      headlineLarge: judul,
      headlineMedium: judul,
      headlineSmall: judul,
      titleLarge: judulBar,
      titleMedium: subjudul,
      titleSmall: isiTebal,
      bodyLarge: isi,
      bodyMedium: isi,
      bodySmall: keterangan,
      labelLarge: isiTebal.copyWith(height: 20 / 16),
      labelMedium: label,
      labelSmall: label,
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
