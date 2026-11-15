import 'package:flutter/material.dart';

import 'palet_sidik.dart';

/// Warna status dan akreditasi yang tidak punya padanan di `ColorScheme`.
///
/// Dibaca lewat `WarnaSidik.of(context)` (atau `context.warna`). Mengikuti tema
/// terang/gelap otomatis, jadi layar tidak pernah menulis `if (gelap)`.
///
/// Setiap status punya pasangan [tinta] (teks, ikon, garis) dan [latar] (isi
/// ubin di belakangnya). Maknanya tetap di seluruh aplikasi:
/// - lulus (hijau): berlaku, selesai, aktif
/// - awas (kuning): segera jatuh tempo, perlu perhatian
/// - gagal (koral): lewat jadwal, dibatalkan, tidak memenuhi toleransi
/// - tunggu (langit): sedang diproses pihak lain
/// - netral (putih): tidak aktif, riwayat
///
/// Bento Lab, tema terang: tinta keempat status SAMA (navy). Yang membedakan
/// status adalah LATAR + IKON + KATA, tidak pernah warna saja. Tema gelap
/// memakai tinta pastel di atas latar gelap bernada sama.
///
/// DUA pasang dibedakan (P2): [lulus]/[lulusLatar] dan kawan-kawannya adalah
/// tinta dan latar untuk teks yang duduk di HALAMAN (gelap di tema gelap); warna
/// UBIN ([ubinLulus], ... [tintaUbin]) adalah pastel bertinta navy yang SAMA di
/// dua tema, karena ubin Bento tetap terang di mode gelap (DESIGN.md §Mode
/// gelap). Teks di atas ubin memakai [tintaUbin], bukan [lulus] dan kawannya.
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
    this.ubinLulus = PaletSidik.hijau,
    this.ubinAwas = PaletSidik.kuning,
    this.ubinGagal = PaletSidik.koral,
    this.ubinTunggu = PaletSidik.langit,
    this.tintaUbin = PaletSidik.navy,
    this.kertasUbin = PaletSidik.kartu,
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

  /// Latar ubin status (pastel), sama di terang dan gelap.
  final Color ubinLulus;
  final Color ubinAwas;
  final Color ubinGagal;
  final Color ubinTunggu;

  /// Tinta di atas ubin pastel: navy di dua tema.
  final Color tintaUbin;

  /// Putih di atas ubin: latar stempel "lulus/awas/tunggu" dan tinta stempel
  /// "gagal" (navy) di atas ubin berwarna. Sama di dua tema.
  final Color kertasUbin;

  static const WarnaSidik terang = WarnaSidik(
    lulus: PaletSidik.navy,
    lulusLatar: PaletSidik.hijau,
    awas: PaletSidik.navy,
    awasLatar: PaletSidik.kuning,
    gagal: PaletSidik.navy,
    gagalLatar: PaletSidik.koral,
    tunggu: PaletSidik.navy,
    tungguLatar: PaletSidik.langit,
    kanMerah: PaletSidik.kanMerah,
  );

  static const WarnaSidik gelap = WarnaSidik(
    lulus: PaletSidik.hijau,
    lulusLatar: PaletSidik.lulusLatarGelap,
    awas: PaletSidik.kuning,
    awasLatar: PaletSidik.awasLatarGelap,
    gagal: PaletSidik.koral,
    gagalLatar: PaletSidik.gagalLatarGelap,
    tunggu: PaletSidik.langit,
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
    Color? ubinLulus,
    Color? ubinAwas,
    Color? ubinGagal,
    Color? ubinTunggu,
    Color? tintaUbin,
    Color? kertasUbin,
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
    ubinLulus: ubinLulus ?? this.ubinLulus,
    ubinAwas: ubinAwas ?? this.ubinAwas,
    ubinGagal: ubinGagal ?? this.ubinGagal,
    ubinTunggu: ubinTunggu ?? this.ubinTunggu,
    tintaUbin: tintaUbin ?? this.tintaUbin,
    kertasUbin: kertasUbin ?? this.kertasUbin,
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
      ubinLulus: c(ubinLulus, other.ubinLulus),
      ubinAwas: c(ubinAwas, other.ubinAwas),
      ubinGagal: c(ubinGagal, other.ubinGagal),
      ubinTunggu: c(ubinTunggu, other.ubinTunggu),
      tintaUbin: c(tintaUbin, other.tintaUbin),
      kertasUbin: c(kertasUbin, other.kertasUbin),
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
