import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'status_tampil.dart';

/// Panel pemberitahuan di dalam isi layar: ikon, judul tebal, isi, dan satu
/// [aksi] opsional, pada latar tipis nadanya. Dipakai untuk keadaan yang perlu
/// dibaca sebelum isi lain (sertifikat digantikan atau dibatalkan, sesi
/// berakhir). Nada selalu disertai ikon dan teks, tidak hanya warna.
class PanelPemberitahuan extends StatelessWidget {
  const PanelPemberitahuan({
    super.key,
    required this.nada,
    required this.ikon,
    required this.judul,
    this.isi,
    this.catatan,
    this.aksi,
  });

  final NadaStatus nada;
  final IconData ikon;
  final String judul;
  final String? isi;

  /// Keterangan kecil di dasar panel.
  final String? catatan;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final (tinta, latar) = StatusTampil('', nada, ikon).warna(context);
    return Container(
      padding: Spasi.kartu,
      decoration: BoxDecoration(color: latar, borderRadius: Bentuk.sudutKartu),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ikon, color: tinta, size: UkuranIkon.sedang),
              const SizedBox(width: Spasi.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(judul, style: t.titleSmall),
                    if (isi != null) ...[
                      const SizedBox(height: Spasi.xs),
                      Text(isi!, style: t.bodyMedium),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (aksi != null) ...[
            const SizedBox(height: Spasi.md),
            Align(alignment: Alignment.centerLeft, child: aksi),
          ],
          if (catatan != null) ...[
            const SizedBox(height: Spasi.md),
            Text('Catatan dari lab: $catatan', style: t.bodySmall),
          ],
        ],
      ),
    );
  }
}
