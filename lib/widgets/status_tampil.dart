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

  /// Pasangan (tinta, latar) untuk nada ini pada tema aktif.
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
}
