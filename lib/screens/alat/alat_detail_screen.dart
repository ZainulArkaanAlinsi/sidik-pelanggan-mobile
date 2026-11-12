import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../providers/data_provider.dart';
import '../../widgets/bagian_sidik.dart';
import '../../widgets/baris_info.dart';
import '../../widgets/chip_status.dart';
import '../../widgets/garis_waktu_sertifikat.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kartu_sidik.dart';
import '../../widgets/keadaan_galat.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/kerangka.dart';
import '../../widgets/pemetaan_status.dart';
import '../sertifikat/sertifikat_detail_screen.dart';

/// Detail satu alat (S09): identitas, status dan jadwal kalibrasi ulang
/// (hitung mundur), dan riwayat sertifikat sebagai garis waktu (terbaru di
/// atas). Tarik layar untuk memuat ulang.
class AlatDetailScreen extends ConsumerWidget {
  const AlatDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detailAlatProvider(id));
    final t = context.teks;

    return HalamanSidik(
      judul: async.value?.nama ?? 'Alat',
      isi: async.when(
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
            padding: Spasi.daftar(context),
            children: [
              KartuSidik(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.nama, style: t.titleMedium),
                    const SizedBox(height: Spasi.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ChipStatus(statusAlat(a.status)),
                    ),
                    const SizedBox(height: Spasi.lg),
                    Text(
                      Format.sisaHari(a.hariKeJatuhTempo),
                      style: t.headlineSmall,
                    ),
                    Text(
                      a.jatuhTempo == null
                          ? 'Belum ada jadwal kalibrasi ulang'
                          : 'Jadwal kalibrasi ulang ${Format.tanggal(a.jatuhTempo)}',
                      style: t.bodySmall,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: Spasi.md),
                      child: Divider(),
                    ),
                    BarisInfo('Merk / model', a.merkModel),
                    BarisInfo('Nomor seri', a.serial, angka: true),
                    BarisInfo(
                      'No. identifikasi',
                      a.noIdentifikasi,
                      angka: true,
                    ),
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
              const BagianSidik('Riwayat kalibrasi'),
              if (a.riwayat.isEmpty)
                const KartuSidik(
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
                  padding: const EdgeInsets.only(bottom: Spasi.md),
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
