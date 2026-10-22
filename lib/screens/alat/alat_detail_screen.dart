import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../providers/data_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_status.dart';
import '../../widgets/umum.dart';
import '../sertifikat/sertifikat_detail_screen.dart';

/// Detail satu alat (S09): identitas, status & jadwal kalibrasi ulang
/// (hitung mundur), dan riwayat kalibrasi (sertifikat terbaru di atas).
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
        loading: () => const Memuat.detail(),
        error: (e, _) => KeadaanGalat(
          galat: e,
          cobaLagi: () => ref.invalidate(detailAlatProvider(id)),
        ),
        data: (a) => ListView(
          padding: denganTepiBawah(
            context,
            const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
          ),
          children: [
            Kertas(
              padding: const EdgeInsets.all(jarak),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(a.nama, style: t.titleMedium)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: SidikLencana(
                          statusAlat(a.status, a.hariKeJatuhTempo),
                        ),
                      ),
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
                    a.jatuhTempo == null
                        ? 'Belum ada jadwal kalibrasi ulang'
                        : 'Jadwal kalibrasi ulang ${Format.tanggal(a.jatuhTempo)}',
                    style: t.bodySmall,
                  ),
                  const Divider(height: 24),
                  BarisInfo('Merk / model', a.merkModel),
                  BarisInfo('Nomor seri', a.serial),
                  BarisInfo('No. identifikasi', a.noIdentifikasi),
                  BarisInfo('Rentang ukur', a.rentang),
                  BarisInfo('Lokasi', a.lokasi),
                  BarisInfo('Catatan', a.catatan),
                  BarisInfo(
                    'Kalibrasi terakhir',
                    Format.tanggal(a.kalibrasiTerakhir),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const JudulSeksi('Riwayat kalibrasi'),
            if (a.riwayat.isEmpty)
              Text('Belum pernah dikalibrasi di PT Sidik', style: t.bodyMedium)
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
