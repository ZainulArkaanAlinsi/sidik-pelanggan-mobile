import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme/sidik_material.dart';
import '../models/data_pelanggan.dart';
import '../models/status_berlaku.dart';
import 'sidik/sidik_permukaan.dart';
import 'sidik/sidik_status.dart';
import 'umum.dart';

/// Riwayat sertifikat satu alat sebagai garis waktu tegak, terbaru di atas.
///
/// Satu simpul = satu sertifikat: tanggal terbit, nomor, status (lencana dari
/// pemetaan bersama [statusSertifikat]), masa berlaku, dan hubungan revisi.
/// Mengetuk simpul membuka detail sertifikatnya ([onBuka]). Revisi, yang
/// digantikan, dan yang dibatalkan ikut tampil dengan statusnya: di riwayat,
/// itulah yang dicari ("dulu hasilnya berapa").
///
/// Simpul yang SEKARANG berlaku (sertifikat terbaru yang belum digantikan dan
/// tidak dibatalkan) berbulatan penuh; sisanya berongga. Sertifikat yang
/// tanggal berlakunya sudah lewat berlencana netral ([StatusBerlaku.berakhir]),
/// bukan merah dan bukan "kedaluwarsa" (K3): peringatan jadwal ada di status
/// ALATNYA ([StatusBerlaku.lewatJadwal]), bukan di tiap sertifikat riwayat.
///
/// [sekarang] = "hari ini" menurut server (`Alat.hariIniServer`), bukan jam HP.
class GarisWaktuSertifikat extends StatelessWidget {
  const GarisWaktuSertifikat({
    super.key,
    required this.riwayat,
    required this.sekarang,
    required this.onBuka,
    this.jendela = 30,
  });

  /// Terbaru di atas (urutan dari server).
  final List<Sertifikat> riwayat;

  /// Waktu HP saat ini, untuk menilai masa berlaku ([statusSertifikat]).
  final DateTime sekarang;

  /// Jendela "segera jatuh tempo" dalam hari.
  final int jendela;

  final void Function(Sertifikat sertifikat) onBuka;

  @override
  Widget build(BuildContext context) {
    final sekarangIdx = riwayat.indexWhere(
      (s) => s.status == StatusDokumen.berlaku,
    );
    return Column(
      children: [
        for (final (i, s) in riwayat.indexed)
          _Simpul(
            sertifikat: s,
            terakhir: i == riwayat.length - 1,
            sekarangBerlaku: i == sekarangIdx,
            // Ada sertifikat berlaku yang lebih baru (indeks lebih kecil).
            adaPenerus: sekarangIdx >= 0 && sekarangIdx < i,
            sekarang: sekarang,
            jendela: jendela,
            onTap: () => onBuka(s),
          ),
      ],
    );
  }
}

class _Simpul extends StatelessWidget {
  const _Simpul({
    required this.sertifikat,
    required this.terakhir,
    required this.sekarangBerlaku,
    required this.adaPenerus,
    required this.sekarang,
    required this.jendela,
    required this.onTap,
  });

  final Sertifikat sertifikat;
  final bool terakhir;
  final bool sekarangBerlaku;
  final bool adaPenerus;
  final DateTime sekarang;
  final int jendela;
  final VoidCallback onTap;

  static const _lebarRel = 28.0;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);
    final s = sertifikat;
    final status = statusSertifikat(
      s,
      sekarang: sekarang,
      jendela: jendela,
      adaPenerus: adaPenerus,
    );
    final vonis = s.dibatalkan ? null : statusKeputusan(s.keputusan);
    final (tinta, _) = status.warna(m);

    final ringkas = [
      'Sertifikat ${s.nomor}',
      'terbit ${Format.tanggal(s.diterbitkan)}',
      'status ${status.label}',
      if (vonis != null) vonis.label,
    ].join(', ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _lebarRel,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Penanda: penuh untuk yang sekarang berlaku, berongga untuk
                // riwayat. Warna ikut nada status, tapi artinya tetap ada di
                // lencana (bukan hanya warna).
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sekarangBerlaku ? tinta : m.kertas,
                    border: Border.all(color: tinta, width: 2),
                  ),
                ),
                if (!terakhir)
                  Expanded(child: Container(width: 2, color: m.kertasTepi)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: terakhir ? 0 : 10),
              child: Semantics(
                button: true,
                label: ringkas,
                excludeSemantics: true,
                child: Kertas(
                  onTap: onTap,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terbit ${Format.tanggal(s.diterbitkan)}',
                        style: t.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.nomor,
                        style: t.bodyMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          SidikLencana(status),
                          if (vonis != null) SidikLencana(vonis),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.berlakuSampai == null
                            ? 'Tanpa tanggal berlaku'
                            : 'Berlaku sampai ${Format.tanggal(s.berlakuSampai)}',
                        style: t.bodySmall,
                      ),
                      if (s.revisiDari != null)
                        Text('Merevisi ${s.revisiDari}', style: t.bodySmall),
                      if (s.digantikanOleh != null)
                        Text(
                          'Digantikan oleh ${s.digantikanOleh!.nomor}',
                          style: t.bodySmall,
                        ),
                      if (s.dibatalkan && s.dibatalkanPada != null)
                        Text(
                          'Dibatalkan ${Format.tanggal(s.dibatalkanPada)}',
                          style: t.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
