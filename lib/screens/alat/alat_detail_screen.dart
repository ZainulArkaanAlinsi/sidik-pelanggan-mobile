import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../providers/data_provider.dart';
import '../../widgets/garis_waktu_sertifikat.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_status.dart';
import '../../widgets/umum.dart';
import '../sertifikat/sertifikat_detail_screen.dart';

/// Detail satu alat (S09): identitas, status & jadwal kalibrasi ulang
/// (hitung mundur), dan riwayat sertifikat sebagai garis waktu (terbaru di
/// atas). Tarik layar untuk memuat ulang.
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
        data: (a) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(detailAlatProvider(id));
            await ref.read(detailAlatProvider(id).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                        Flexible(child: SidikLencana(statusAlat(a.status))),
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
                const Kertas(
                  padding: EdgeInsets.all(jarak),
                  child: KeadaanKosongIsi(
                    ikon: Icons.history,
                    judul: 'Belum ada sertifikat',
                    keterangan:
                        'Sertifikat alat ini muncul di sini setelah alat '
                        'dikalibrasi di PT Sidik.',
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${a.riwayat.length} sertifikat, yang terbaru di atas. '
                    'Ketuk untuk membuka.',
                    style: t.bodySmall,
                  ),
                ),
                GarisWaktuSertifikat(
                  riwayat: a.riwayat,
                  // "Hari ini" menurut server (jatuh tempo − sisa hari); jam HP
                  // hanya cadangan. Lihat `Alat.hariIniServer`.
                  sekarang: a.hariIniServer ?? ref.read(jamHpProvider)(),
                  onBuka: (s) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SertifikatDetailScreen(id: s.id),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
