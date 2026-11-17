import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_pelanggan.dart';
import '../../core/format.dart';
import '../../core/pesan_admin.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../providers/koneksi_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../services/layanan_pelanggan.dart';
import '../../widgets/bagian_sidik.dart';
import '../../widgets/baris_info.dart';
import '../../widgets/chip_status.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/keadaan_galat.dart';
import '../../widgets/kerangka.dart';
import '../../widgets/lembar_tanya_admin.dart';
import '../../widgets/lencana_kan.dart';
import '../../widgets/panel_pemberitahuan.dart';
import '../../widgets/panel_sidik.dart';
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

  /// Nama perusahaan aktif untuk pesan "Tanya admin" (tidak dikarang).
  String? _namaPerusahaan() =>
      ref.read(sesiProvider).value?.keanggotaanAktif?.namaPerusahaan;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(detailSertifikatProvider(widget.id));
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
          final vonis = s.dibatalkan ? null : statusKeputusan(s.keputusan);
          final pengganti = s.digantikanOleh;
          final bisaBuka = s.bisaDiunduh && !s.dibatalkan && !offline;
          final merkModel = [
            s.merk,
            s.model,
          ].where((x) => x != null && x.isNotEmpty).join(' ');
          final serial = s.serial?.trim();
          // Penjelasan tindakan, SEBELUM tombolnya (pengguna tahu kenapa tombol
          // mati sebelum mencoba menekannya).
          final catatan = offline && s.bisaDiunduh && !s.dibatalkan
              ? 'Sambungkan internet untuk mengunduh PDF.'
              : s.dibatalkan
              ? 'Sertifikat yang dibatalkan tidak bisa dibuka maupun diunduh.'
              : !s.bisaDiunduh
              ? 'PDF sedang disiapkan laboratorium. Coba lagi nanti.'
              : s.digantikan
              ? 'PDF lama tetap bisa dibuka dan diunduh sebagai riwayat.'
              : null;
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

              // 1. Identitas dokumen.
              const BagianSidik('Identitas dokumen'),
              PanelSidik(
                padding: PanelSidik.paddingIsi,
                anak: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BarisInfoSalin(
                        'Nomor sertifikat',
                        s.nomor,
                        tooltip: 'Salin nomor sertifikat',
                        konfirmasi: 'Nomor sertifikat disalin.',
                      ),
                      BarisInfo('Diterbitkan', Format.tanggal(s.diterbitkan)),
                      if (s.penandaTangan != null)
                        BarisInfo('Disahkan oleh', s.penandaTangan),
                      if (s.revisiDari != null)
                        BarisInfo('Merevisi', s.revisiDari, angka: true),
                      const SizedBox(height: Spasi.sm),
                      const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: LencanaKan(),
                      ),
                    ],
                  ),
                ],
              ),

              // 2. Alat.
              const BagianSidik('Alat'),
              PanelSidik(
                padding: PanelSidik.paddingIsi,
                anak: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BarisInfo(
                        'Nama alat',
                        (s.namaAlat ?? '').trim().isEmpty
                            ? 'Belum tersedia'
                            : s.namaAlat,
                      ),
                      BarisInfo(
                        'Merk / model',
                        merkModel.isEmpty ? 'Belum tersedia' : merkModel,
                      ),
                      if (serial == null || serial.isEmpty)
                        const BarisInfo('Nomor seri', 'Belum tersedia')
                      else
                        BarisInfoSalin(
                          'Nomor seri',
                          serial,
                          tooltip: 'Salin nomor seri',
                          konfirmasi: 'Nomor seri disalin.',
                        ),
                    ],
                  ),
                ],
              ),

              // 3. Status dokumen (berlaku, digantikan, atau dibatalkan) dan
              // jadwal kalibrasi ulang (BUKAN "berlaku sampai": itu tertukar
              // dengan status dokumen).
              const BagianSidik('Status dokumen'),
              PanelSidik(
                padding: PanelSidik.paddingIsi,
                anak: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ChipStatus(statusDokumen(s.status)),
                      ),
                      if (!s.dibatalkan && s.berlakuSampai != null) ...[
                        const SizedBox(height: Spasi.md),
                        BarisInfo(
                          'Jadwal kalibrasi ulang',
                          Format.tanggal(s.berlakuSampai),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // 4. Hasil teknis (memenuhi atau tidak memenuhi toleransi), bila
              // dinyatakan. REQ-SRT-04: FAIL tidak disembunyikan dan tidak
              // dilunakkan.
              if (vonis != null) ...[
                const BagianSidik('Hasil teknis'),
                PanelSidik(
                  padding: PanelSidik.paddingIsi,
                  anak: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ChipStatus(vonis),
                    ),
                  ],
                ),
              ],
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
              if (s.rincian.isNotEmpty) ...[
                const BagianSidik('Rincian kalibrasi'),
                PanelSidik(
                  padding: PanelSidik.paddingIsi,
                  anak: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final e in s.rincian.entries)
                          BarisInfo(e.key, e.value),
                      ],
                    ),
                  ],
                ),
              ],

              // 5. Tindakan. Satu aksi utama: melihat PDF di dalam aplikasi;
              // "Unduh PDF" membukanya di aplikasi PDF lain.
              const BagianSidik('Tindakan'),
              if (catatan != null) _Catatan(catatan),
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
              const SizedBox(height: Spasi.sm),
              TombolTanyaAdmin(
                label: 'Tanya tentang sertifikat ini',
                ragam: RagamTombol.teks,
                pesan: () => PembangunPesanAdmin.tanyaSertifikat(
                  perusahaan: _namaPerusahaan(),
                  nomor: s.nomor,
                  namaAlat: s.namaAlat,
                  serial: s.serial,
                  status: statusDokumen(s.status).label,
                ),
              ),
              TombolTanyaAdmin(
                label: 'Laporkan data yang keliru',
                ikon: Icons.flag_outlined,
                ragam: RagamTombol.teks,
                pesan: () => PembangunPesanAdmin.laporkanDataKeliru(
                  perusahaan: _namaPerusahaan(),
                  nomor: s.nomor,
                  namaAlat: s.namaAlat,
                  serial: s.serial,
                  status: statusDokumen(s.status).label,
                ),
              ),
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
