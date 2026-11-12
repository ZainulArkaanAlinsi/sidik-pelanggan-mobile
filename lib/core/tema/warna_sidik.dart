import 'package:flutter/material.dart';

import 'palet_sidik.dart';

/// Warna status dan akreditasi yang tidak punya padanan di `ColorScheme`.
///
/// Dibaca lewat `WarnaSidik.of(context)` (atau `context.warna`). Mengikuti tema
/// terang/gelap otomatis, jadi layar tidak pernah menulis `if (gelap)`.
///
/// Setiap status punya pasangan [tinta] (teks, ikon, garis) dan [latar]
/// (isi tipis di belakangnya). Maknanya tetap di seluruh aplikasi:
/// - lulus: berlaku, selesai, aktif
/// - awas: segera jatuh tempo, perlu perhatian
/// - gagal: lewat jadwal, dibatalkan, tidak memenuhi toleransi
/// - tunggu: sedang diproses pihak lain
/// - netral: tidak aktif, riwayat
@immutable
class WarnaSidik extends ThemeExtension<WarnaSidik> {
  const WarnaSidik({
    required this.lulus,
    required this.lulusLatar,
    required this.awas,
    required this.awasLatar,
    required this.gagal,
    required this.gagalLatar,
    required this.tunggu,
    required this.tungguLatar,
    required this.kanMerah,
  });

  final Color lulus;
  final Color lulusLatar;
  final Color awas;
  final Color awasLatar;
  final Color gagal;
  final Color gagalLatar;
  final Color tunggu;
  final Color tungguLatar;

  /// Merah check mark KAN. Hanya untuk `LencanaKan`, bukan tanda galat.
  final Color kanMerah;

  static const WarnaSidik terang = WarnaSidik(
    lulus: PaletSidik.lulusTerang,
    lulusLatar: PaletSidik.lulusLatarTerang,
    awas: PaletSidik.awasTerang,
    awasLatar: PaletSidik.awasLatarTerang,
    gagal: PaletSidik.gagalTerang,
    gagalLatar: PaletSidik.gagalLatarTerang,
    tunggu: PaletSidik.tungguTerang,
    tungguLatar: PaletSidik.tungguLatarTerang,
    kanMerah: PaletSidik.kanMerah,
  );

  static const WarnaSidik gelap = WarnaSidik(
    lulus: PaletSidik.lulusGelap,
    lulusLatar: PaletSidik.lulusLatarGelap,
    awas: PaletSidik.awasGelap,
    awasLatar: PaletSidik.awasLatarGelap,
    gagal: PaletSidik.gagalGelap,
    gagalLatar: PaletSidik.gagalLatarGelap,
    tunggu: PaletSidik.tungguGelap,
    tungguLatar: PaletSidik.tungguLatarGelap,
    kanMerah: PaletSidik.kanMerahGelap,
  );

  /// Ambil dari tema aktif; cadangan tema terang bila ekstensi belum dipasang.
  static WarnaSidik of(BuildContext context) =>
      Theme.of(context).extension<WarnaSidik>() ?? terang;

  @override
  WarnaSidik copyWith({
    Color? lulus,
    Color? lulusLatar,
    Color? awas,
    Color? awasLatar,
    Color? gagal,
    Color? gagalLatar,
    Color? tunggu,
    Color? tungguLatar,
    Color? kanMerah,
  }) => WarnaSidik(
    lulus: lulus ?? this.lulus,
    lulusLatar: lulusLatar ?? this.lulusLatar,
    awas: awas ?? this.awas,
    awasLatar: awasLatar ?? this.awasLatar,
    gagal: gagal ?? this.gagal,
    gagalLatar: gagalLatar ?? this.gagalLatar,
    tunggu: tunggu ?? this.tunggu,
    tungguLatar: tungguLatar ?? this.tungguLatar,
    kanMerah: kanMerah ?? this.kanMerah,
  );

  @override
  WarnaSidik lerp(ThemeExtension<WarnaSidik>? other, double t) {
    if (other is! WarnaSidik) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return WarnaSidik(
      lulus: c(lulus, other.lulus),
      lulusLatar: c(lulusLatar, other.lulusLatar),
      awas: c(awas, other.awas),
      awasLatar: c(awasLatar, other.awasLatar),
      gagal: c(gagal, other.gagal),
      gagalLatar: c(gagalLatar, other.gagalLatar),
      tunggu: c(tunggu, other.tunggu),
      tungguLatar: c(tungguLatar, other.tungguLatar),
      kanMerah: c(kanMerah, other.kanMerah),
    );
  }
}

/// Pintasan `context.warna` dan `context.skema`.
extension KonteksTema on BuildContext {
  /// Warna status dan akreditasi ([WarnaSidik]).
  WarnaSidik get warna => WarnaSidik.of(this);

  /// `ColorScheme` tema aktif.
  ColorScheme get skema => Theme.of(this).colorScheme;

  /// `TextTheme` tema aktif.
  TextTheme get teks => Theme.of(this).textTheme;
}
