import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/paket.dart';
import '../../providers/data_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_status.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';
import '../sertifikat/sertifikat_detail_screen.dart';

/// Detail satu paket: ringkasan, garis waktu (urutan & penanda dari server),
/// dan tahap tiap alat. Paket milik perusahaan lain dijawab server dengan 404
/// yang sama dengan paket yang tidak ada, dan layar ini menampilkannya sebagai
/// kalimat umum — tidak pernah "akses ditolak".
class PaketDetailScreen extends ConsumerWidget {
  const PaketDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detailPaketProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail paket')),
      body: async.when(
        loading: () => const Memuat.detail(),
        error: (e, _) => KeadaanGalat(
          galat: e,
          cobaLagi: () => ref.invalidate(detailPaketProvider(id)),
        ),
        data: (d) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(detailPaketProvider(id));
            await ref.read(detailPaketProvider(id).future);
          },
          child: _Isi(detail: d),
        ),
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.detail});

  final DetailPaket detail;

  @override
  Widget build(BuildContext context) {
    final p = detail.paket;
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);
    return ListView(
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
              Text('NOMOR ORDER', style: m.gayaEtsa(ukuran: 11)),
              const SizedBox(height: 4),
              Text(p.nomor, style: t.titleLarge),
              const SizedBox(height: 8),
              SidikLencana(statusPaket(p.tahap, p.tahapLabel)),
              const Divider(height: 24),
              BarisInfo('Tanggal masuk', Format.tanggal(p.tanggalMasuk)),
              BarisInfo(
                'Target selesai',
                Format.tanggal(p.tanggalJanjiSelesai),
              ),
              BarisInfo(
                'Alat selesai',
                '${p.jumlahSelesai} dari ${p.jumlahAlat}',
              ),
              if (p.terlambat)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SidikLencana(
                      StatusSidik(
                        'Melewati target selesai',
                        NadaStatus.awas,
                        Icons.schedule,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (detail.garisWaktu.isNotEmpty) ...[
          const JudulSeksi('Perkembangan'),
          Kertas(
            padding: const EdgeInsets.all(jarak),
            child: Column(
              children: [for (final l in detail.garisWaktu) _Langkah(l)],
            ),
          ),
        ],
        const JudulSeksi('Alat dalam paket'),
        if (p.alat.isEmpty)
          Text(
            'Belum ada alat yang tercatat di paket ini.',
            style: t.bodyMedium,
          )
        else
          for (final a in p.alat)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _KartuAlat(alat: a),
            ),
      ],
    );
  }
}

class _Langkah extends StatelessWidget {
  const _Langkah(this.langkah);

  final LangkahPaket langkah;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);
    final (ikon, warna) = langkah.lewat
        ? (Icons.check_circle, m.lulus)
        : langkah.sekarang
        ? (Icons.radio_button_checked, m.biru)
        : (Icons.radio_button_unchecked, m.tinta2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(ikon, size: 20, color: warna),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              langkah.label,
              style: t.bodyMedium?.copyWith(
                fontWeight: langkah.sekarang ? FontWeight.w700 : null,
              ),
            ),
          ),
          if (langkah.sekarang)
            Text('Sekarang', style: t.bodySmall?.copyWith(color: m.biru)),
        ],
      ),
    );
  }
}

class _KartuAlat extends StatelessWidget {
  const _KartuAlat({required this.alat});

  final AlatPaket alat;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Kertas(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(alat.nama, style: t.titleSmall)),
              const SizedBox(width: 8),
              Flexible(
                child: SidikLencana(statusPaket(alat.tahap, alat.tahapLabel)),
              ),
            ],
          ),
          if (alat.merk != null || alat.serial != null)
            Text(
              [
                ?alat.merk,
                if (alat.serial != null) 'SN ${alat.serial}',
              ].join(' · '),
              style: t.bodySmall,
            ),
          if (alat.diserahkanKepada != null)
            Text(
              'Diserahkan kepada ${alat.diserahkanKepada}',
              style: t.bodySmall,
            ),
          if (alat.sertifikatId != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: SidikTombol(
                label: 'Lihat sertifikat',
                ikon: Icons.description_outlined,
                kecil: true,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        SertifikatDetailScreen(id: alat.sertifikatId!),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
