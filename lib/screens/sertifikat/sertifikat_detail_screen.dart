import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_pelanggan.dart';
import '../../core/format.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/tipografi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../providers/koneksi_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../services/layanan_pelanggan.dart';
import '../../widgets/baris_info.dart';
import '../../widgets/chip_status.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kartu_sidik.dart';
import '../../widgets/keadaan_galat.dart';
import '../../widgets/kerangka.dart';
import '../../widgets/lencana_kan.dart';
import '../../widgets/panel_pemberitahuan.dart';
import '../../widgets/pemetaan_status.dart';
import '../../widgets/status_tampil.dart';
import '../../widgets/tombol_sidik.dart';
import 'pratinjau_pdf_screen.dart';

/// Detail sertifikat. Isinya CERMIN dari yang tercetak di PDF (dibaca dari
/// snapshot di server), jadi layar ini tidak pernah berbeda dengan kertasnya.
///
/// Tiga keadaan dokumen, semuanya keputusan server (`status`):
/// - `berlaku`    : normal; bisa dilihat di aplikasi (pratinjau PDF) dan diunduh.
/// - `digantikan` : panel kuning di atas menunjuk revisinya; PDF lama tetap
///   bisa diunduh sebagai riwayat.
/// - `dibatalkan` : panel merah; unduh dimatikan (server juga menjawab 410).
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
      // 410 = dibatalkan sejak layar ini dimuat: tarik ulang supaya panel
      // merah muncul dan tombolnya mati.
      if (e.status == 410) ref.invalidate(detailSertifikatProvider(widget.id));
      messenger.showSnackBar(SnackBar(content: Text(e.pesan)));
    } on GalatBerkasPdf catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.pesan)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('PDF belum bisa dibuka. Coba lagi sebentar lagi.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _mengunduh = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(detailSertifikatProvider(widget.id));
    final t = context.teks;
    final offline = ref.watch(koneksiProvider).offline;

    return HalamanSidik(
      judul: 'Sertifikat',
      isi: async.when(
        loading: () => const Memuat.detail(),
        error: (e, _) => KeadaanGalat(
          galat: e,
          cobaLagi: () => ref.invalidate(detailSertifikatProvider(widget.id)),
        ),
        data: (s) {
          final vonis = statusKeputusan(s.keputusan);
          final pengganti = s.digantikanOleh;
          final bisaBuka = s.bisaDiunduh && !s.dibatalkan && !offline;
          return ListView(
            padding: Spasi.daftar(context),
            children: [
              if (s.digantikan && pengganti != null) ...[
                PanelPemberitahuan(
                  nada: NadaStatus.awas,
                  ikon: Icons.info_outline,
                  judul: 'Sertifikat ini sudah digantikan',
                  isi:
                      'Yang berlaku sekarang: ${pengganti.nomor}'
                      '${pengganti.diterbitkan == null ? '' : ' (terbit ${Format.tanggal(pengganti.diterbitkan)})'}',
                  catatan: s.catatanPelanggan,
                  aksi: TombolSidik(
                    label: 'Buka yang berlaku',
                    ikon: Icons.open_in_new,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SertifikatDetailScreen(id: pengganti.id),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spasi.md),
              ],
              if (s.dibatalkan) ...[
                PanelPemberitahuan(
                  nada: NadaStatus.gagal,
                  ikon: Icons.block,
                  judul: 'Dibatalkan pada ${Format.tanggal(s.dibatalkanPada)}',
                  isi:
                      'Sertifikat ini tidak berlaku lagi dan PDF-nya tidak '
                      'bisa diunduh.',
                  catatan: s.catatanPelanggan,
                ),
                const SizedBox(height: Spasi.md),
              ],
              KartuSidik(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nomor sertifikat', style: t.bodySmall),
                    const SizedBox(height: Spasi.xs),
                    Text(s.nomor, style: t.headlineSmall?.tabular),
                    if ((vonis != null && !s.dibatalkan) ||
                        s.status != StatusDokumen.berlaku) ...[
                      const SizedBox(height: Spasi.md),
                      Wrap(
                        spacing: Spasi.sm,
                        runSpacing: Spasi.sm,
                        children: [
                          if (s.status != StatusDokumen.berlaku)
                            ChipStatus(statusDokumen(s.status)),
                          if (vonis != null && !s.dibatalkan) ChipStatus(vonis),
                        ],
                      ),
                    ],
                    const SizedBox(height: Spasi.md),
                    const LencanaKan(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: Spasi.md),
                      child: Divider(),
                    ),
                    BarisInfo('Alat', s.namaAlat),
                    BarisInfo(
                      'Merk / model',
                      [
                        s.merk,
                        s.model,
                      ].where((x) => x != null && x.isNotEmpty).join(' · '),
                    ),
                    BarisInfo('Nomor seri', s.serial, angka: true),
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
                      BarisInfo('Merevisi', s.revisiDari, angka: true),
                  ],
                ),
              ),
              // REQ-SRT-04: FAIL tidak disembunyikan dan tidak dilunakkan.
              if (s.keputusan == 'FAIL' && !s.dibatalkan) ...[
                const SizedBox(height: Spasi.md),
                const PanelPemberitahuan(
                  nada: NadaStatus.gagal,
                  ikon: Icons.cancel_outlined,
                  judul: 'Tidak memenuhi toleransi.',
                  isi:
                      'Alat ini berada di luar batas toleransi pada saat '
                      'dikalibrasi. Lihat sertifikat untuk detail atau '
                      'tanyakan ke Tim PT Sidik.',
                ),
              ],
              const SizedBox(height: Spasi.xl),
              // Satu aksi utama per layar: melihat PDF di dalam aplikasi.
              // "Unduh PDF" tetap ada untuk membukanya di aplikasi PDF lain.
              TombolSidik(
                label: 'Lihat PDF',
                ikon: Icons.picture_as_pdf_outlined,
                ragam: RagamTombol.utama,
                penuh: true,
                onPressed: bisaBuka
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PratinjauPdfScreen(sertifikat: s),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: Spasi.sm),
              TombolSidik(
                label: 'Unduh PDF',
                ikon: Icons.download_outlined,
                penuh: true,
                sibuk: _mengunduh,
                onPressed: bisaBuka ? () => _unduh(s) : null,
              ),
              if (offline && s.bisaDiunduh && !s.dibatalkan)
                _Catatan('Sambungkan internet untuk mengunduh PDF.')
              else if (s.dibatalkan)
                _Catatan('Sertifikat yang dibatalkan tidak bisa diunduh.')
              else if (!s.bisaDiunduh)
                _Catatan('PDF sedang disiapkan laboratorium. Coba lagi nanti.')
              else if (s.digantikan)
                _Catatan('PDF lama tetap bisa diunduh sebagai riwayat.'),
              if (s.tautanVerifikasi != null) ...[
                const SizedBox(height: Spasi.sm),
                TombolSidik(
                  label: 'Buka halaman verifikasi',
                  ikon: Icons.verified_outlined,
                  ragam: RagamTombol.teks,
                  penuh: true,
                  onPressed: () => launchUrl(
                    Uri.parse(s.tautanVerifikasi!),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const _Catatan(
                  'Halaman yang sama dengan QR di PDF — boleh dibagikan ke auditor untuk memeriksa keaslian.',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Keterangan kecil di bawah tombol.
class _Catatan extends StatelessWidget {
  const _Catatan(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Spasi.sm),
    child: Text(teks, style: context.teks.bodySmall),
  );
}
