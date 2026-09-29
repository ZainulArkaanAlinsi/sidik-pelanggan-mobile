import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/umum.dart';
import '../sertifikat/sertifikat_detail_screen.dart';

/// Detail paket: garis waktu (tahap paket = tahap alat yang PALING
/// tertinggal), lalu tiap alat dengan tahapnya sendiri.
class PaketDetailScreen extends ConsumerWidget {
  const PaketDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detailPaketProvider(id));
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(async.value?.nomor ?? 'Paket')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(detailPaketProvider(id));
          await ref.read(detailPaketProvider(id).future);
        },
        child: async.when(
          loading: () => const Memuat(),
          error: (e, _) => KeadaanGalat(
            galat: e,
            cobaLagi: () => ref.invalidate(detailPaketProvider(id)),
          ),
          data: (p) => ListView(
            padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
            children: [
              Kertas(
                padding: const EdgeInsets.all(jarak),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.tahapLabel, style: t.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${p.jumlahSelesai} dari ${p.jumlahAlat} alat selesai',
                      style: t.bodyMedium,
                    ),
                    const Divider(height: 24),
                    BarisInfo('Diterima lab', Format.tanggal(p.masuk)),
                    BarisInfo(
                      'Janji selesai',
                      Format.tanggal(
                        p.janjiSelesai,
                        kosong: 'Belum ditentukan',
                      ),
                    ),
                    if (p.terlambat)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Melewati tanggal janji selesai. Hubungi laboratorium bila perlu kepastian jadwal.',
                          style: t.bodySmall?.copyWith(
                            color: SidikMaterial.of(context).awas,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const JudulSeksi('Perjalanan paket'),
              Kertas(
                padding: const EdgeInsets.symmetric(
                  horizontal: jarak,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    for (final l in p.garisWaktu) _Langkah(langkah: l),
                  ],
                ),
              ),
              JudulSeksi('Alat dalam paket (${p.alat.length})'),
              for (final a in p.alat)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _KartuAlatPaket(alat: a),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Langkah extends StatelessWidget {
  const _Langkah({required this.langkah});

  final LangkahWaktu langkah;

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    final (ikon, warna) = langkah.lewat
        ? (Icons.check_circle, m.lulus)
        : langkah.sekarang
        ? (Icons.radio_button_checked, m.biruTinta)
        : (Icons.radio_button_unchecked, m.pensil);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(ikon, color: warna, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              langkah.label,
              style: t.bodyMedium?.copyWith(
                fontWeight: langkah.sekarang
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: langkah.lewat || langkah.sekarang ? m.tinta : m.tinta2,
              ),
            ),
          ),
          if (langkah.sekarang)
            Text('SEKARANG', style: m.gayaEtsa(ukuran: 10.5)),
        ],
      ),
    );
  }
}

class _KartuAlatPaket extends StatelessWidget {
  const _KartuAlatPaket({required this.alat});

  final AlatPaket alat;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bukaSertifikat = alat.sertifikatId == null
        ? null
        : () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SertifikatDetailScreen(id: alat.sertifikatId!),
            ),
          );
    return Kertas(
      padding: const EdgeInsets.all(14),
      onTap: bukaSertifikat,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alat.nama, style: t.titleSmall),
                Text(
                  [
                    if (alat.merk != null) alat.merk!,
                    if (alat.serial != null) 'SN ${alat.serial}',
                  ].join(' · '),
                  style: t.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  alat.tahapLabel,
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (alat.diserahkanKepada != null)
                  Text(
                    'Diterima oleh ${alat.diserahkanKepada}',
                    style: t.bodySmall,
                  ),
              ],
            ),
          ),
          if (bukaSertifikat != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.description_outlined),
            const Icon(Icons.chevron_right),
          ],
        ],
      ),
    );
  }
}
