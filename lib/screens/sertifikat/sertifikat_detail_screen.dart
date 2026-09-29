import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_pelanggan.dart';
import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_status.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';

/// Detail sertifikat — isinya CERMIN dari yang tercetak di PDF (dibaca dari
/// snapshot di server), jadi layar ini tidak pernah berbeda dengan kertasnya.
class SertifikatDetailScreen extends ConsumerStatefulWidget {
  const SertifikatDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<SertifikatDetailScreen> createState() =>
      _SertifikatDetailScreenState();
}

class _SertifikatDetailScreenState
    extends ConsumerState<SertifikatDetailScreen> {
  bool _mengunduh = false;

  Future<void> _unduh(Sertifikat s) async {
    setState(() => _mengunduh = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(layananProvider).unduhDanBukaPdf(s);
    } on GalatApi catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.pesan)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'PDF terunduh, tapi tidak ada aplikasi pembuka PDF di HP ini.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _mengunduh = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(detailSertifikatProvider(widget.id));
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sertifikat')),
      body: async.when(
        loading: () => const Memuat(),
        error: (e, _) => KeadaanGalat(
          galat: e,
          cobaLagi: () => ref.invalidate(detailSertifikatProvider(widget.id)),
        ),
        data: (s) {
          final vonis = statusKeputusan(s.keputusan);
          return ListView(
            padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
            children: [
              if (s.digantikan)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Kertas(
                    warna: m.awasTipis,
                    padding: const EdgeInsets.all(12),
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SertifikatDetailScreen(id: s.digantikanOleh!.id),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: m.awas),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sertifikat ini sudah direvisi. Gunakan ${s.digantikanOleh!.nomor}.',
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              Kertas(
                padding: const EdgeInsets.all(jarak),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOMOR SERTIFIKAT', style: m.gayaEtsa(ukuran: 11)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.nomor,
                            style: t.titleLarge?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        if (vonis != null) SidikLencana(vonis),
                      ],
                    ),
                    const Divider(height: 24),
                    BarisInfo('Alat', s.namaAlat),
                    BarisInfo(
                      'Merk / model',
                      [
                        s.merk,
                        s.model,
                      ].where((x) => x != null && x.isNotEmpty).join(' · '),
                    ),
                    BarisInfo('Nomor seri', s.serial),
                    BarisInfo('Diterbitkan', Format.tanggal(s.diterbitkan)),
                    BarisInfo(
                      'Berlaku sampai',
                      Format.tanggal(s.berlakuSampai),
                    ),
                    for (final e in s.rincian.entries)
                      BarisInfo(e.key, e.value),
                    if (s.penandaTangan != null)
                      BarisInfo('Disahkan oleh', s.penandaTangan),
                    if (s.revisiDari != null)
                      BarisInfo('Merevisi', s.revisiDari),
                  ],
                ),
              ),
              const SizedBox(height: jarak),
              SidikTombol(
                label: 'Unduh PDF',
                ikon: Icons.download_outlined,
                ragam: RagamTombol.utama,
                penuh: true,
                sibuk: _mengunduh,
                onPressed: s.bisaDiunduh ? () => _unduh(s) : null,
              ),
              if (!s.bisaDiunduh)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'PDF sedang disiapkan laboratorium. Coba lagi nanti.',
                    style: t.bodySmall,
                  ),
                ),
              if (s.tautanVerifikasi != null) ...[
                const SizedBox(height: 8),
                SidikTombol(
                  label: 'Buka halaman verifikasi',
                  ikon: Icons.verified_outlined,
                  penuh: true,
                  onPressed: () => launchUrl(
                    Uri.parse(s.tautanVerifikasi!),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Halaman yang sama dengan QR di PDF — boleh dibagikan ke auditor untuk memeriksa keaslian.',
                  style: t.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
