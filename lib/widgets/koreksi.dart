import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/data_pelanggan.dart';
import '../models/koreksi.dart';
import 'sidik/sidik_permukaan.dart';
import 'sidik/sidik_status.dart';

/// Satu-satunya pemetaan status koreksi → lencana.
StatusSidik statusKoreksi(StatusKoreksi s) => switch (s) {
  StatusKoreksi.menunggu => StatusSidik(
    s.label,
    NadaStatus.tunggu,
    Icons.hourglass_empty,
  ),
  StatusKoreksi.diterima => StatusSidik(
    s.label,
    NadaStatus.lulus,
    Icons.check_circle_outline,
  ),
  StatusKoreksi.ditolak => StatusSidik(
    s.label,
    NadaStatus.gagal,
    Icons.cancel_outlined,
  ),
};

/// Satu-satunya pemetaan status dokumen sertifikat → lencana.
StatusSidik statusDokumen(StatusDokumen s) => switch (s) {
  StatusDokumen.berlaku => StatusSidik(
    s.label,
    NadaStatus.lulus,
    Icons.verified_outlined,
  ),
  StatusDokumen.digantikan => StatusSidik(
    s.label,
    NadaStatus.awas,
    Icons.swap_horiz,
  ),
  StatusDokumen.dibatalkan => StatusSidik(
    s.label,
    NadaStatus.gagal,
    Icons.block,
  ),
};

/// Kartu satu koreksi di daftar.
class KartuKoreksi extends StatelessWidget {
  const KartuKoreksi({super.key, required this.koreksi, required this.onTap});

  final Koreksi koreksi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final k = koreksi;
    return Kertas(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(k.judul, style: t.titleSmall)),
              const SizedBox(width: 8),
              SidikLencana(statusKoreksi(k.status)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              k.untukSertifikat ? 'Koreksi sertifikat' : 'Koreksi data alat',
              k.perubahan.map((p) => p.label).join(', '),
            ].where((s) => s.isNotEmpty).join(' · '),
            style: t.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Diajukan ${Format.tanggal(k.diajukanPada)}',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}
