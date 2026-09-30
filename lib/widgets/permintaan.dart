import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/permintaan.dart';
import 'sidik/sidik_permukaan.dart';
import 'sidik/sidik_status.dart';

/// Satu-satunya pemetaan status permintaan → lencana, supaya daftar dan
/// detail tidak bisa berbeda warna untuk status yang sama.
StatusSidik statusPermintaan(StatusPermintaan s) => switch (s) {
  StatusPermintaan.baru => StatusSidik(
    s.label,
    NadaStatus.tunggu,
    Icons.hourglass_empty,
  ),
  StatusPermintaan.diterima => StatusSidik(
    s.label,
    NadaStatus.lulus,
    Icons.check_circle_outline,
  ),
  StatusPermintaan.ditolak => StatusSidik(
    s.label,
    NadaStatus.gagal,
    Icons.cancel_outlined,
  ),
  StatusPermintaan.dibatalkan => StatusSidik(
    s.label,
    NadaStatus.draf,
    Icons.block,
  ),
};

/// Kartu satu permintaan di daftar. Seluruh kartu = satu ketukan ke detail.
class KartuPermintaan extends StatelessWidget {
  const KartuPermintaan({
    super.key,
    required this.permintaan,
    required this.onTap,
  });

  final Permintaan permintaan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = permintaan;
    return Kertas(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.nomor,
                  style: t.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SidikLencana(statusPermintaan(p.status)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ['${p.jumlahAlat} alat', ?p.metode?.label].join(' · '),
            style: t.bodySmall,
          ),
          const SizedBox(height: 4),
          Text('Diajukan ${Format.tanggal(p.diajukan)}', style: t.bodySmall),
          if (p.status == StatusPermintaan.ditolak &&
              p.alasanPenolakan != null) ...[
            const SizedBox(height: 6),
            Text(
              p.alasanPenolakan!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
