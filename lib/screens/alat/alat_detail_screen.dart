import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../providers/data_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_status.dart';
import '../../widgets/umum.dart';
import '../sertifikat/sertifikat_detail_screen.dart';

/// Detail satu alat: identitas, jadwal, lalu riwayat sertifikatnya.
class AlatDetailScreen extends ConsumerWidget {
  const AlatDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detailAlatProvider(id));
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(async.value?.nama ?? 'Alat')),
      body: async.when(
        loading: () => const Memuat(),
        error: (e, _) => KeadaanGalat(
          galat: e,
          cobaLagi: () => ref.invalidate(detailAlatProvider(id)),
        ),
        data: (a) => ListView(
          padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
          children: [
            Kertas(
              padding: const EdgeInsets.all(jarak),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(a.nama, style: t.titleMedium)),
                      SidikLencana(statusAlat(a.status)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Format.sisaHari(a.hariKeJatuhTempo),
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Jatuh tempo ${Format.tanggal(a.jatuhTempo)}',
                    style: t.bodySmall,
                  ),
                  const Divider(height: 24),
                  BarisInfo('Merk / model', a.merkModel),
                  BarisInfo('Nomor seri', a.serial),
                  BarisInfo('No. identifikasi', a.noIdentifikasi),
                  BarisInfo('Rentang ukur', a.rentang),
                  BarisInfo('Lokasi', a.lokasi),
                  BarisInfo(
                    'Kalibrasi terakhir',
                    Format.tanggal(a.kalibrasiTerakhir),
                  ),
                ],
              ),
            ),
            const JudulSeksi('Riwayat sertifikat'),
            if (a.riwayat.isEmpty)
              Text(
                'Belum ada sertifikat terbit untuk alat ini.',
                style: t.bodyMedium,
              )
            else
              for (final s in a.riwayat)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: KartuSertifikat(
                    sertifikat: s,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SertifikatDetailScreen(id: s.id),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
