import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/koreksi.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/foto_pelat.dart';
import '../../widgets/koreksi.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_status.dart';
import '../../widgets/umum.dart';
import '../alat/alat_detail_screen.dart';
import '../sertifikat/sertifikat_detail_screen.dart';

/// Detail satu koreksi: apa yang diminta diganti (lama → baru), catatan,
/// foto, status, dan jawaban lab. Selagi `menunggu`, foto pendukung masih bisa
/// ditambah; sesudah diputus, hanya dibaca.
class KoreksiDetailScreen extends ConsumerWidget {
  const KoreksiDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detailKoreksiProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Koreksi')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(detailKoreksiProvider(id));
          await ref.read(detailKoreksiProvider(id).future);
        },
        child: async.when(
          skipLoadingOnReload: true,
          loading: () => const Memuat(),
          error: (e, _) => KeadaanGalat(
            galat: e,
            cobaLagi: () => ref.invalidate(detailKoreksiProvider(id)),
          ),
          data: (k) => _Isi(koreksi: k),
        ),
      ),
    );
  }
}

class _Isi extends ConsumerWidget {
  const _Isi({required this.koreksi});

  final Koreksi koreksi;

  Widget _tautan(
    BuildContext context, {
    required IconData ikon,
    required String teks,
    required Widget Function() tujuan,
    bool tebal = false,
  }) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Kertas(
        padding: const EdgeInsets.all(12),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => tujuan())),
        child: Row(
          children: [
            Icon(ikon),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                teks,
                style: t.bodyMedium?.copyWith(
                  fontWeight: tebal ? FontWeight.w600 : null,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = koreksi;
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
      children: [
        Kertas(
          padding: const EdgeInsets.all(jarak),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(k.judul, style: t.titleMedium)),
                  SidikLencana(statusKoreksi(k.status)),
                ],
              ),
              const Divider(height: 24),
              BarisInfo(
                'Jenis',
                k.untukSertifikat ? 'Koreksi sertifikat' : 'Koreksi data alat',
              ),
              if (k.untukSertifikat && k.namaAlat != null)
                BarisInfo('Alat', k.namaAlat),
              BarisInfo('Diajukan oleh', k.diajukanOleh),
              BarisInfo('Diajukan', Format.tanggalJam(k.diajukanPada)),
              if (k.ditinjauPada != null)
                BarisInfo('Ditinjau', Format.tanggalJam(k.ditinjauPada)),
            ],
          ),
        ),
        const JudulSeksi('Yang diminta diganti'),
        Kertas(
          padding: const EdgeInsets.all(jarak),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (k.perubahan.isEmpty)
                Text('Tidak ada rincian.', style: t.bodyMedium),
              for (final p in k.perubahan)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.label, style: t.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        p.lama ?? '—',
                        style: t.bodyMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: m.tinta2,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.arrow_forward, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p.baru ?? '—',
                              style: t.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (k.catatan != null) ...[
                const Divider(height: 20),
                Text('Catatan Anda', style: t.bodySmall),
                const SizedBox(height: 2),
                Text(k.catatan!, style: t.bodyMedium),
              ],
            ],
          ),
        ),
        if (k.menunggu || k.foto.isNotEmpty) ...[
          const JudulSeksi('Foto pendukung'),
          if (k.menunggu)
            GridFotoPelat(
              awal: k.foto,
              unggah: (b) =>
                  ref.read(layananProvider).unggahFotoKoreksi(k.id, b),
              onBerubah: () => ref.invalidate(detailKoreksiProvider(k.id)),
            )
          else
            DeretanFoto(foto: k.foto),
        ],
        if (k.menunggu) ...[
          const SizedBox(height: 12),
          Text(
            'Koreksi sedang ditinjau lab. Kabar jawabannya masuk ke '
            'notifikasi.',
            style: t.bodySmall,
          ),
        ] else ...[
          const JudulSeksi('Jawaban lab'),
          Kertas(
            warna: k.status == StatusKoreksi.ditolak
                ? m.gagalTipis
                : m.lulusTipis,
            padding: const EdgeInsets.all(jarak),
            child: Text(
              k.tanggapan ?? 'Lab tidak mencantumkan tanggapan.',
              style: t.bodyMedium,
            ),
          ),
        ],
        if (k.revisiId != null)
          _tautan(
            context,
            ikon: Icons.description_outlined,
            teks: 'Buka sertifikat revisi ${k.nomorRevisi ?? ''}'.trim(),
            tebal: true,
            tujuan: () => SertifikatDetailScreen(id: k.revisiId!),
          ),
        if (k.untukSertifikat && k.sertifikatId != null)
          _tautan(
            context,
            ikon: Icons.description_outlined,
            teks: 'Lihat sertifikat ${k.nomorSertifikat ?? ''}'.trim(),
            tujuan: () => SertifikatDetailScreen(id: k.sertifikatId!),
          )
        else if (!k.untukSertifikat && k.alatId != null)
          _tautan(
            context,
            ikon: Icons.straighten_outlined,
            teks: 'Lihat alat ${k.namaAlat ?? ''}'.trim(),
            tujuan: () => AlatDetailScreen(id: k.alatId!),
          ),
      ],
    );
  }
}
