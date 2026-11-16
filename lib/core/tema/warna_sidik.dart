import 'package:flutter/material.dart';

import 'palet_sidik.dart';

/// Warna status dan akreditasi yang tidak punya padanan di `ColorScheme`.
///
/// Dibaca lewat `WarnaSidik.of(context)` (atau `context.warna`). Mengikuti tema
/// terang/gelap otomatis, jadi layar tidak pernah menulis `if (gelap)`.
///
/// Setiap status punya pasangan [tinta] (teks, ikon, garis) dan [latar] (isi
/// lencana atau panel di belakangnya). Maknanya tetap di seluruh aplikasi:
/// - lulus (hijau): berlaku, selesai, aktif
/// - awas (krem/amber): segera jatuh tempo, perlu diperiksa
/// - gagal (merah muda): lewat jadwal, dibatalkan, tidak memenuhi toleransi
/// - tunggu (biru kelabu): sedang diproses pihak lain
/// - netral: tidak aktif, riwayat
///
/// Arah tenang-formal (REVISI 16 Nov 2026), tema terang: tinta GELAP di atas
/// warna MUDA (hijau gelap di hijau muda, amber gelap di krem, merah gelap di
/// merah muda, biru tua di biru kelabu muda). Status tidak pernah warna saja:
/// selalu ikon + kata. Tema gelap memakai tinta pastel di atas latar gelap
/// bernada sama.
///
/// DUA pasang dibedakan: [lulus]/[lulusLatar] dan kawan-kawannya adalah tinta
/// dan latar untuk teks yang duduk di HALAMAN (gelap di tema gelap); warna
/// UBIN ([ubinLulus], ... [tintaUbin]) adalah warna muda bertinta navy yang
/// SAMA di dua tema, dipakai ubin ringkasan yang membawa status. Teks di atas
/// ubin memakai [tintaUbin], bukan [lulus] dan kawannya. Kartu alat, sertifikat,
/// dan paket netral: statusnya hanya di lencana ([Stempel]).
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
    this.ubinBiru = PaletSidik.biruMuda,
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

  /// Latar ubin status (warna muda), sama di terang dan gelap.
  final Color ubinLulus;
  final Color ubinAwas;
  final Color ubinGagal;
  final Color ubinTunggu;

  /// Biru muda (bukan status): kepala layar masuk. Sama di terang dan gelap.
  final Color ubinBiru;

  /// Tinta di atas ubin berwarna muda: navy di dua tema.
  final Color tintaUbin;

  /// Putih di atas ubin: latar lencana status yang ditaruh di atas ubin
  /// berwarna. Sama di dua tema.
  final Color kertasUbin;

  static const WarnaSidik terang = WarnaSidik(
    lulus: PaletSidik.hijauTinta,
    lulusLatar: PaletSidik.hijau,
    awas: PaletSidik.kuningTinta,
    awasLatar: PaletSidik.kuning,
    gagal: PaletSidik.galat,
    gagalLatar: PaletSidik.koral,
    tunggu: PaletSidik.langitTinta,
    tungguLatar: PaletSidik.langit,
    kanMerah: PaletSidik.kanMerah,
  );

  static const WarnaSidik gelap = WarnaSidik(
    lulus: PaletSidik.hijauTintaGelap,
    lulusLatar: PaletSidik.lulusLatarGelap,
    awas: PaletSidik.kuningTintaGelap,
    awasLatar: PaletSidik.awasLatarGelap,
    gagal: PaletSidik.koralTintaGelap,
    gagalLatar: PaletSidik.gagalLatarGelap,
    tunggu: PaletSidik.biruDiGelap,
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
    Color? ubinBiru,
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
    ubinBiru: ubinBiru ?? this.ubinBiru,
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
      ubinBiru: c(ubinBiru, other.ubinBiru),
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
