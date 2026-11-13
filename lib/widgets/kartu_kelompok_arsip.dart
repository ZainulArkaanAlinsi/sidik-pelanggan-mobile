import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import '../models/arsip.dart';
import 'kartu_sidik.dart';

/// Kartu satu kelompok arsip (tahun, bulan, atau pekan): label dari server,
/// jumlah sertifikat, dan panah tanda bisa dibuka. Mengetuknya membuka tingkat
/// berikutnya ([onTap]).
///
/// Label boleh membungkus dua baris ("Pekan 46 (9–15 Nov 2026)" di layar
/// sempit atau huruf besar); jumlah selalu di baris sendiri, jadi tidak ada
/// yang terjepit.
class KartuKelompokArsip extends StatelessWidget {
  const KartuKelompokArsip({
    super.key,
    required this.kelompok,
    required this.tingkat,
    required this.onTap,
  });

  final KelompokArsip kelompok;

  /// Tingkat kelompok ini, untuk memilih ikon.
  final TingkatArsip tingkat;
  final VoidCallback onTap;

  static IconData ikonUntuk(TingkatArsip tingkat) => switch (tingkat) {
    TingkatArsip.tahun => Icons.folder_outlined,
    TingkatArsip.bulan => Icons.calendar_month_outlined,
    TingkatArsip.pekan => Icons.date_range_outlined,
    TingkatArsip.hari => Icons.today_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final jumlah = '${kelompok.jumlah} sertifikat';
    return KartuSidik(
      onTap: onTap,
      labelSemantik: '${kelompok.label}, $jumlah',
      child: Row(
        children: [
          Container(
            width: AreaSentuh.minimum - Spasi.sm,
            height: AreaSentuh.minimum - Spasi.sm,
            decoration: BoxDecoration(
              color: s.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ikonUntuk(tingkat),
              size: UkuranIkon.sedang,
              color: s.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: Spasi.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kelompok.label, style: t.titleSmall),
                const SizedBox(height: Spasi.xs / 2),
                Text(jumlah, style: t.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: Spasi.sm),
          Icon(Icons.chevron_right, color: s.onSurfaceVariant),
        ],
      ),
    );
  }
}
