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
/// [terbuka] non-null = kelompok yang membuka/menutup isinya DI TEMPAT (tahun di
/// tingkat awal): penunjuknya panah turun/naik (bukan panah kanan) dan pembaca
/// layar menerima status "dibuka"/"ditutup". Null = membuka layar baru.
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
    this.terbuka,
  });

  final KelompokArsip kelompok;

  /// Tingkat kelompok ini, untuk memilih ikon.
  final TingkatArsip tingkat;
  final VoidCallback onTap;

  /// Kelompok ini buka-tutup di tempat: `true` terbuka, `false` tertutup.
  final bool? terbuka;

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
      terbuka: terbuka,
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
          Icon(
            terbuka == null
                ? Icons.chevron_right
                : (terbuka! ? Icons.expand_less : Icons.expand_more),
            color: s.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
