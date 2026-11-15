import 'package:flutter/material.dart';

import '../core/tema/warna_sidik.dart';

/// Nada status. Lima saja, dan tiap nada punya ARTI tetap di seluruh aplikasi,
/// jadi status yang sama tidak bisa tampil beda di dua layar.
enum NadaStatus {
  /// Berlaku, selesai, aktif.
  lulus,

  /// Segera jatuh tempo, perlu perhatian.
  awas,

  /// Lewat jadwal, dibatalkan, tidak memenuhi toleransi.
  gagal,

  /// Sedang di tangan pihak lain (diproses, diperiksa).
  tunggu,

  /// Tidak aktif, riwayat, belum ada data.
  netral,
}

/// Satu status yang siap ditampilkan: kata, nada, dan ikon. Selalu tampil
/// sebagai ikon + teks ([ChipStatus]), tidak pernah warna saja, supaya tetap
/// terbaca oleh pengguna buta warna dan di cetakan hitam-putih.
@immutable
class StatusTampil {
  const StatusTampil(this.label, this.nada, this.ikon);

  final String label;
  final NadaStatus nada;
  final IconData ikon;

  /// Pasangan (tinta, latar) untuk nada ini pada tema aktif. Untuk teks yang
  /// duduk di HALAMAN: di tema gelap tintanya pastel dan latarnya gelap.
  (Color, Color) warna(BuildContext context) {
    final w = context.warna;
    final s = context.skema;
    return switch (nada) {
      NadaStatus.lulus => (w.lulus, w.lulusLatar),
      NadaStatus.awas => (w.awas, w.awasLatar),
      NadaStatus.gagal => (w.gagal, w.gagalLatar),
      NadaStatus.tunggu => (w.tunggu, w.tungguLatar),
      NadaStatus.netral => (s.onSurfaceVariant, s.surfaceContainerHigh),
    };
  }

  /// Pasangan (tinta, latar) UBIN untuk [nada]: pastel bertinta navy yang sama
  /// di terang dan gelap (ubin Bento tetap terang di mode gelap). Netral
  /// (tanpa jadwal) = permukaan putih tema, bukan pastel.
  static (Color, Color) ubinDari(BuildContext context, NadaStatus nada) {
    final w = context.warna;
    final s = context.skema;
    return switch (nada) {
      NadaStatus.lulus => (w.tintaUbin, w.ubinLulus),
      NadaStatus.awas => (w.tintaUbin, w.ubinAwas),
      NadaStatus.gagal => (w.tintaUbin, w.ubinGagal),
      NadaStatus.tunggu => (w.tintaUbin, w.ubinTunggu),
      NadaStatus.netral => (s.onSurface, s.surface),
    };
  }

  /// [ubinDari] untuk nada status ini.
  (Color, Color) ubin(BuildContext context) => ubinDari(context, nada);

  /// Pasangan (tinta, latar) stempel yang ditaruh DI ATAS ubin berwarna:
  /// gagal (koral) = tinta putih di latar navy; awas, lulus, tunggu = tinta
  /// navy di latar putih. Netral (ubin putih tema) memakai pasangan [warna]
  /// netral: tinta kedua di atas latar halaman.
  (Color, Color) diAtasUbin(BuildContext context) {
    final w = context.warna;
    return switch (nada) {
      NadaStatus.gagal => (w.kertasUbin, w.tintaUbin),
      NadaStatus.netral => warna(context),
      _ => (w.tintaUbin, w.kertasUbin),
    };
  }
}
