import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../providers/data_provider.dart';
import '../../widgets/foto_pelat.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_status.dart';
import '../../widgets/umum.dart';
import '../koreksi/koreksi_detail_screen.dart';
import '../sertifikat/sertifikat_detail_screen.dart';
import 'ubah_alat_screen.dart';

/// Detail satu alat: identitas, jadwal, lalu riwayat sertifikatnya.
class AlatDetailScreen extends ConsumerWidget {
  const AlatDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detailAlatProvider(id));
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(async.value?.nama ?? 'Alat'),
        actions: [
          if (async.value != null)
            IconButton(
              tooltip: 'Ubah alat',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => UbahAlatScreen(id: id)),
              ),
            ),
        ],
      ),
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
                  BarisInfo('Catatan', a.catatan),
                  BarisInfo(
                    'Kalibrasi terakhir',
                    Format.tanggal(a.kalibrasiTerakhir),
                  ),
                ],
              ),
            ),
            if (a.terkunci) ...[
              const SizedBox(height: 10),
              Kertas(
                warna: SidikMaterial.of(context).awasTipis,
                padding: const EdgeInsets.all(12),
                onTap: a.koreksiMenungguId == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              KoreksiDetailScreen(id: a.koreksiMenungguId!),
                        ),
                      ),
                child: Row(
                  children: [
                    Icon(
                      a.koreksiMenungguId == null
                          ? Icons.lock_outline
                          : Icons.hourglass_empty,
                      color: SidikMaterial.of(context).awas,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.koreksiMenungguId == null
                            ? 'Identitas terkunci karena sudah tercetak di '
                                  'sertifikat. Koreksi lewat tombol ubah.'
                            : 'Koreksi sedang ditinjau lab',
                        style: t.bodyMedium,
                      ),
                    ),
                    if (a.koreksiMenungguId != null)
                      const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
            if (a.foto.isNotEmpty) ...[
              const JudulSeksi('Foto pelat nama'),
              DeretanFoto(foto: a.foto),
            ],
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
