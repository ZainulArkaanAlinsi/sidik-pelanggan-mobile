import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/warna_sidik.dart';
import '../models/paket.dart';
import 'chip_status.dart';
import 'kartu_sidik.dart';
import 'pemetaan_status.dart';
import 'status_tampil.dart';

/// Kartu satu paket (order) di daftar pelacakan dan di Beranda: nomor, tahap,
/// kemajuan alat, tanggal masuk dan target selesai.
class KartuPaket extends StatelessWidget {
  const KartuPaket({super.key, required this.paket, required this.onTap});

  final Paket paket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    return KartuSidik(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(paket.nomor, style: t.titleSmall?.tabular),
          const SizedBox(height: Spasi.xs / 2),
          Text(
            '${paket.jumlahSelesai} dari ${paket.jumlahAlat} alat selesai',
            style: t.bodySmall,
          ),
          Text(
            'Masuk ${Format.tanggal(paket.tanggalMasuk)}'
            '${paket.tanggalJanjiSelesai == null ? '' : ' · target selesai ${Format.tanggal(paket.tanggalJanjiSelesai)}'}',
            style: t.bodySmall,
          ),
          const SizedBox(height: Spasi.sm),
          Wrap(
            spacing: Spasi.sm,
            runSpacing: Spasi.sm,
            children: [
              ChipStatus(statusPaket(paket.tahap, paket.tahapLabel)),
              if (paket.terlambat)
                const ChipStatus(
                  StatusTampil(
                    'Melewati target selesai',
                    NadaStatus.awas,
                    Icons.schedule,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
