import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_pelanggan.dart';
import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/koreksi.dart';
import '../../widgets/minta_koreksi.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_status.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';
import '../koreksi/koreksi_detail_screen.dart';

/// Detail sertifikat — isinya CERMIN dari yang tercetak di PDF (dibaca dari
/// snapshot di server), jadi layar ini tidak pernah berbeda dengan kertasnya.
///
/// Tiga keadaan dokumen, semuanya keputusan server (`status`):
/// - `berlaku`    — normal; bisa diunduh dan bisa dimintakan koreksi.
/// - `digantikan` — kartu kuning di atas menunjuk revisinya; PDF lama tetap
///   bisa diunduh sebagai riwayat.
/// - `dibatalkan` — kartu merah; unduh dimatikan (server juga menjawab 410).
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
      // 410 = dibatalkan sejak layar ini dimuat: tarik ulang supaya kartu
      // merah muncul dan tombolnya mati.
      if (e.status == 410) ref.invalidate(detailSertifikatProvider(widget.id));
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

  /// Isian yang tercetak (kontrak §B1). Nilai sekarang diambil dari
  /// `data_cetak`, jadi pelanggan melihat persis apa yang ada di kertas.
  static const _isianCetak = [
    ('pemilik', 'Nama pemilik'),
    ('alamat', 'Alamat'),
    ('merk', 'Merk'),
    ('tipe', 'Tipe'),
    ('nomor_seri', 'Nomor seri'),
    ('lokasi_kalibrasi', 'Lokasi kalibrasi'),
    ('tanggal_kalibrasi', 'Tanggal kalibrasi (YYYY-MM-DD)'),
  ];

  Future<void> _mintaKoreksi(Sertifikat s) async {
    final hasil = await tampilkanMintaKoreksi(
      context,
      judul: 'Minta koreksi sertifikat',
      keterangan:
          'Pilih isian yang tercetak salah dan tulis nilai yang benar. Lab '
          'akan memeriksanya; kalau diterima, sertifikat diterbitkan ulang '
          'sebagai revisi.',
      field: [
        for (final (kunci, label) in _isianCetak)
          FieldKoreksi(kunci: kunci, label: label, nilai: s.dataCetak?[kunci]),
      ],
      kirim: (perubahan, catatan) => ref
          .read(layananProvider)
          .mintaKoreksiSertifikat(s.id, perubahan, catatan: catatan),
    );
    if (hasil == null || !mounted) return;
    ref.invalidate(detailSertifikatProvider(s.id));
    ref.invalidate(daftarSertifikatProvider);
    ref.invalidate(daftarKoreksiProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Koreksi terkirim ke lab.')));
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KoreksiDetailScreen(id: hasil.id),
      ),
    );
  }

  Widget _kartuPeringatan(
    BuildContext context, {
    required Color warna,
    required IconData ikon,
    required Color warnaIkon,
    required String judul,
    String? isi,
    String? catatan,
    Widget? aksi,
  }) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Kertas(
        warna: warna,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(ikon, color: warnaIkon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        judul,
                        style: t.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isi != null) ...[
                        const SizedBox(height: 2),
                        Text(isi, style: t.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (aksi != null) ...[const SizedBox(height: 10), aksi],
            if (catatan != null) ...[
              const SizedBox(height: 10),
              Text('Catatan dari lab: $catatan', style: t.bodySmall),
            ],
          ],
        ),
      ),
    );
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
          final pengganti = s.digantikanOleh;
          return ListView(
            padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
            children: [
              if (s.digantikan && pengganti != null)
                _kartuPeringatan(
                  context,
                  warna: m.awasTipis,
                  ikon: Icons.info_outline,
                  warnaIkon: m.awas,
                  judul: 'Sertifikat ini sudah digantikan',
                  isi:
                      'Yang berlaku sekarang: ${pengganti.nomor}'
                      '${pengganti.diterbitkan == null ? '' : ' (terbit ${Format.tanggal(pengganti.diterbitkan)})'}',
                  catatan: s.catatanPelanggan,
                  aksi: SidikTombol(
                    label: 'Buka yang berlaku',
                    ikon: Icons.open_in_new,
                    kecil: true,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SertifikatDetailScreen(id: pengganti.id),
                      ),
                    ),
                  ),
                ),
              if (s.dibatalkan)
                _kartuPeringatan(
                  context,
                  warna: m.gagalTipis,
                  ikon: Icons.block,
                  warnaIkon: m.gagal,
                  judul: 'Dibatalkan pada ${Format.tanggal(s.dibatalkanPada)}',
                  isi:
                      'Sertifikat ini tidak berlaku lagi dan PDF-nya tidak '
                      'bisa diunduh.',
                  catatan: s.catatanPelanggan,
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
                        if (vonis != null && !s.dibatalkan) SidikLencana(vonis),
                      ],
                    ),
                    if (s.status != StatusDokumen.berlaku) ...[
                      const SizedBox(height: 8),
                      SidikLencana(statusDokumen(s.status)),
                    ],
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
                onPressed: s.bisaDiunduh && !s.dibatalkan
                    ? () => _unduh(s)
                    : null,
              ),
              if (s.dibatalkan)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Sertifikat yang dibatalkan tidak bisa diunduh.',
                    style: t.bodySmall,
                  ),
                )
              else if (!s.bisaDiunduh)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'PDF sedang disiapkan laboratorium. Coba lagi nanti.',
                    style: t.bodySmall,
                  ),
                )
              else if (s.digantikan)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'PDF lama tetap bisa diunduh sebagai riwayat.',
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
              if (s.koreksiMenungguId != null) ...[
                const SizedBox(height: 12),
                Kertas(
                  warna: m.awasTipis,
                  padding: const EdgeInsets.all(12),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          KoreksiDetailScreen(id: s.koreksiMenungguId!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty, color: m.awas),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Koreksi sedang ditinjau lab',
                          style: t.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ] else if (s.bisaMintaKoreksi) ...[
                const SizedBox(height: 8),
                SidikTombol(
                  label: 'Minta koreksi sertifikat',
                  ikon: Icons.edit_note_outlined,
                  penuh: true,
                  onPressed: () => _mintaKoreksi(s),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
