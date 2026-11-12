import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import '../models/data_pelanggan.dart';
import 'chip_status.dart';
import 'kartu_sidik.dart';
import 'pemetaan_status.dart';

/// Kartu satu sertifikat di daftar: nomor, alat, tanggal terbit dan masa
/// berlaku, serta chip status dokumen dan keputusan bila perlu dibaca.
class KartuSertifikat extends StatelessWidget {
  const KartuSertifikat({
    super.key,
    required this.sertifikat,
    required this.onTap,
  });

  final Sertifikat sertifikat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final sr = sertifikat;
    final vonis = statusKeputusan(sr.keputusan);
    final tampilStatus = sr.status != StatusDokumen.berlaku;
    final tampilVonis = vonis != null && !sr.dibatalkan;
    return KartuSidik(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AreaSentuh.minimum - Spasi.sm,
            height: AreaSentuh.minimum - Spasi.sm,
            decoration: BoxDecoration(
              color: s.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: UkuranIkon.sedang,
              color: s.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: Spasi.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sr.nomor, style: t.titleSmall?.tabular),
                const SizedBox(height: Spasi.xs / 2),
                Text(
                  [
                    sr.namaAlat ?? '-',
                    if (sr.serial != null) 'SN ${sr.serial}',
                  ].join(' · '),
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Terbit ${Format.tanggal(sr.diterbitkan)}'
                  '${sr.berlakuSampai == null ? '' : ' · berlaku s.d. ${Format.tanggal(sr.berlakuSampai)}'}',
                  style: t.bodySmall,
                ),
                if (tampilStatus || tampilVonis) ...[
                  const SizedBox(height: Spasi.sm),
                  Wrap(
                    spacing: Spasi.sm,
                    runSpacing: Spasi.sm,
                    children: [
                      if (tampilStatus) ChipStatus(statusDokumen(sr.status)),
                      if (tampilVonis) ChipStatus(vonis),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
