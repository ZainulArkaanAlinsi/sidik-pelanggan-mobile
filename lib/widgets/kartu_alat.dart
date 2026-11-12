import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import '../models/data_pelanggan.dart';
import 'chip_status.dart';
import 'kartu_sidik.dart';
import 'pemetaan_status.dart';

/// Kartu satu alat di daftar: nama, merk/seri/lokasi, status masa berlaku, dan
/// sisa hari menuju jadwal kalibrasi ulang.
class KartuAlat extends StatelessWidget {
  const KartuAlat({super.key, required this.alat, required this.onTap});

  final Alat alat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final rincian = [
      alat.merkModel,
      if (alat.serial != null) 'SN ${alat.serial}',
      ?alat.lokasi,
    ].where((x) => x.isNotEmpty).join(' · ');
    return KartuSidik(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alat.nama, style: t.titleSmall),
          if (rincian.isNotEmpty) ...[
            const SizedBox(height: Spasi.xs / 2),
            Text(
              rincian,
              style: t.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: Spasi.md),
          Wrap(
            spacing: Spasi.md,
            runSpacing: Spasi.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChipStatus(statusAlat(alat.status)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: UkuranIkon.kecil,
                    color: s.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spasi.xs),
                  Flexible(
                    child: Text(
                      alat.jatuhTempo == null
                          ? 'Belum ada jadwal kalibrasi ulang'
                          : '${Format.sisaHari(alat.hariKeJatuhTempo)} · '
                                '${Format.tanggal(alat.jatuhTempo)}',
                      style: t.bodySmall?.copyWith(
                        color: s.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
