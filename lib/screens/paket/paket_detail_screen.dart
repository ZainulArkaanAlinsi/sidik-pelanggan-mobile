import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/tipografi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/paket.dart';
import '../../providers/data_provider.dart';
import '../../widgets/bagian_sidik.dart';
import '../../widgets/baris_info.dart';
import '../../widgets/chip_status.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kartu_sidik.dart';
import '../../widgets/keadaan_galat.dart';
import '../../widgets/kerangka.dart';
import '../../widgets/pemetaan_status.dart';
import '../../widgets/status_tampil.dart';
import '../../widgets/tombol_sidik.dart';
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
    return HalamanSidik(
      judul: 'Detail paket',
      isi: async.when(
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
    final t = context.teks;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Spasi.daftar(context),
      children: [
        KartuSidik(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nomor order', style: t.bodySmall),
              const SizedBox(height: Spasi.xs),
              Text(p.nomor, style: t.headlineSmall?.tabular),
              const SizedBox(height: Spasi.md),
              ChipStatus(statusPaket(p.tahap, p.tahapLabel)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Spasi.md),
                child: Divider(),
              ),
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
                  padding: EdgeInsets.only(top: Spasi.sm),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ChipStatus(
                      StatusTampil(
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
          const BagianSidik('Perkembangan'),
          KartuSidik(
            child: Column(
              children: [for (final l in detail.garisWaktu) _Langkah(l)],
            ),
          ),
        ],
        const BagianSidik('Alat dalam paket'),
        if (p.alat.isEmpty)
          Text(
            'Belum ada alat yang tercatat di paket ini.',
            style: t.bodyMedium,
          )
        else
          for (final a in p.alat)
            Padding(
              padding: const EdgeInsets.only(bottom: Spasi.md),
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
    final t = context.teks;
    final skema = context.skema;
    final (ikon, warna) = langkah.lewat
        ? (Icons.check_circle, context.warna.lulus)
        : langkah.sekarang
        ? (Icons.radio_button_checked, skema.primary)
        : (Icons.radio_button_unchecked, skema.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spasi.xs * 1.5),
      child: Row(
        children: [
          Icon(ikon, size: UkuranIkon.sedang, color: warna),
          const SizedBox(width: Spasi.md),
          Expanded(
            child: Text(
              langkah.label,
              style: t.bodyMedium?.copyWith(
                fontWeight: langkah.sekarang ? FontWeight.w700 : null,
              ),
            ),
          ),
          if (langkah.sekarang)
            Text(
              'Sekarang',
              style: t.bodySmall?.copyWith(color: skema.primary),
            ),
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
    final t = context.teks;
    return KartuSidik(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alat.nama, style: t.titleSmall),
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
          const SizedBox(height: Spasi.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: ChipStatus(statusPaket(alat.tahap, alat.tahapLabel)),
          ),
          if (alat.sertifikatId != null) ...[
            const SizedBox(height: Spasi.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TombolSidik(
                label: 'Lihat sertifikat',
                ikon: Icons.description_outlined,
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
