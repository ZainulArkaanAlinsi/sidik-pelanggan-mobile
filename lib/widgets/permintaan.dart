import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme/sidik_material.dart';
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

/// Lencana untuk permintaan: label tahap dari server kalau ada (`tahap_label`,
/// siap tampil), kalau tidak jatuh ke status lama. Warnanya tetap dari nada
/// status — "perlu tindakan" memakai nada awas, bukan warna sendiri.
StatusSidik lencanaPermintaan(Permintaan p) {
  final label = p.tahapLabel;
  if (label == null) return statusPermintaan(p.status);
  if (p.perluTindakan) {
    return StatusSidik(label, NadaStatus.awas, Icons.priority_high);
  }
  return switch (p.tahap) {
    'selesai' => StatusSidik(label, NadaStatus.lulus, Icons.task_alt),
    'ditolak' => StatusSidik(label, NadaStatus.gagal, Icons.cancel_outlined),
    'dibatalkan' => StatusSidik(label, NadaStatus.draf, Icons.block),
    'diajukan' => StatusSidik(label, NadaStatus.tunggu, Icons.hourglass_empty),
    _ => StatusSidik(label, NadaStatus.tunggu, Icons.autorenew),
  };
}

/// "1 Okt 2026, 09.00 · Lab QC Lantai 2" — baris jadwal teknisi.
String? barisJadwal(JadwalTeknisi? j) {
  if (j == null || (j.pada == null && j.lokasi == null)) return null;
  return [if (j.pada != null) Format.tanggalJam(j.pada), ?j.lokasi].join(' · ');
}

/// Kartu satu permintaan di daftar. Seluruh kartu = satu ketukan ke detail.
/// Yang `perlu_tindakan` diberi latar awas + kalimat tindakannya; server sudah
/// mengurutkannya ke atas.
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
    final m = SidikMaterial.of(context);
    final p = permintaan;
    final jadwal = barisJadwal(p.jadwal);
    final progres = p.progres;
    return Kertas(
      onTap: onTap,
      warna: p.perluTindakan ? m.awasTipis : null,
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
              Flexible(child: SidikLencana(lencanaPermintaan(p))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ['${p.jumlahAlat} alat', ?p.metode?.label].join(' · '),
            style: t.bodySmall,
          ),
          const SizedBox(height: 4),
          Text('Diajukan ${Format.tanggal(p.diajukan)}', style: t.bodySmall),
          if (p.perluTindakan && p.pesanTindakan != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.priority_high, size: 18, color: m.awas),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.pesanTindakan!,
                    style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
          if (jadwal != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    jadwal,
                    style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          if (progres != null && progres.total > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progres.selesai / progres.total,
                minHeight: 6,
                backgroundColor: m.kertas2,
                color: m.lulus,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${progres.selesai}/${progres.total} selesai',
              style: t.bodySmall,
            ),
          ],
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
