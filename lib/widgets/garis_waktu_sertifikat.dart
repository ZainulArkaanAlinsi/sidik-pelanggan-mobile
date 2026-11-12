import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/warna_sidik.dart';
import '../models/data_pelanggan.dart';
import '../models/status_berlaku.dart';
import 'chip_status.dart';
import 'kartu_sidik.dart';
import 'pemetaan_status.dart';

/// Riwayat sertifikat satu alat sebagai garis waktu tegak, terbaru di atas.
///
/// Satu simpul = satu sertifikat: tanggal terbit, nomor, status (chip dari
/// pemetaan bersama [statusSertifikat]), masa berlaku, dan hubungan revisi.
/// Mengetuk simpul membuka detail sertifikatnya ([onBuka]). Revisi, yang
/// digantikan, dan yang dibatalkan ikut tampil dengan statusnya: di riwayat,
/// itulah yang dicari ("dulu hasilnya berapa").
///
/// Simpul yang SEKARANG berlaku (sertifikat terbaru yang belum digantikan dan
/// tidak dibatalkan) berbulatan penuh; sisanya berongga. Sertifikat yang
/// tanggal berlakunya sudah lewat bernada netral ([StatusBerlaku.berakhir]),
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

  /// Lebar lajur penanda di kiri kartu.
  static const double _lebarRel = 28;

  /// Garis tengah penanda dan diameter bulatan.
  static const double _garis = 2;
  static const double _bulatan = 14;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final skema = context.skema;
    final s = sertifikat;
    final status = statusSertifikat(
      s,
      sekarang: sekarang,
      jendela: jendela,
      adaPenerus: adaPenerus,
    );
    final vonis = s.dibatalkan ? null : statusKeputusan(s.keputusan);
    final (tinta, _) = status.warna(context);

    final ringkas = [
      'Sertifikat ${s.nomor}',
      'terbit ${Format.tanggal(s.diterbitkan)}',
      'status ${status.label}',
      ?vonis?.label,
    ].join(', ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _lebarRel,
            child: Column(
              children: [
                const SizedBox(height: Spasi.lg),
                // Penuh untuk yang sekarang berlaku, berongga untuk riwayat.
                // Warna ikut nada status, tapi artinya tetap ada di chip.
                Container(
                  width: _bulatan,
                  height: _bulatan,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sekarangBerlaku ? tinta : skema.surface,
                    border: Border.all(color: tinta, width: _garis),
                  ),
                ),
                if (!terakhir)
                  Expanded(
                    child: Container(
                      width: _garis,
                      color: skema.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: terakhir ? 0 : Spasi.md),
              child: KartuSidik(
                onTap: onTap,
                labelSemantik: ringkas,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terbit ${Format.tanggal(s.diterbitkan)}',
                      style: t.titleSmall,
                    ),
                    const SizedBox(height: Spasi.xs / 2),
                    Text(s.nomor, style: t.bodyMedium?.tabular),
                    const SizedBox(height: Spasi.sm),
                    Wrap(
                      spacing: Spasi.sm,
                      runSpacing: Spasi.sm,
                      children: [
                        ChipStatus(status),
                        if (vonis != null) ChipStatus(vonis),
                      ],
                    ),
                    const SizedBox(height: Spasi.sm),
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
        ],
      ),
    );
  }
}
