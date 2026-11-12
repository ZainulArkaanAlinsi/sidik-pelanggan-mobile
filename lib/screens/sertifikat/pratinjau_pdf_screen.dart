import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/tema/bentuk.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../providers/pdf_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../services/layanan_pelanggan.dart';
import '../../widgets/penampil_pdf.dart';
import '../../widgets/tombol_sidik.dart';

/// Pratinjau PDF sertifikat di dalam aplikasi: zoom (cubit atau tombol),
/// geser, putar 90°, dan pindah halaman — tanpa aplikasi PDF lain.
///
/// PDF diunduh lewat jalur yang sama dengan "Unduh PDF" (`LayananPelanggan.
/// unduhPdf`: header Authorization hanya ke host API), disimpan sementara di
/// folder cache aplikasi ([PenyimpanPratinjau]), lalu dibuka dari berkas itu.
/// Setiap membuka pratinjau mengunduh ulang, jadi sertifikat yang baru
/// dibatalkan lab tidak bisa tampil dari salinan lama. Salinan dibuang saat
/// keluar akun atau berganti perusahaan.
class PratinjauPdfScreen extends ConsumerStatefulWidget {
  const PratinjauPdfScreen({super.key, required this.sertifikat});

  final Sertifikat sertifikat;

  @override
  ConsumerState<PratinjauPdfScreen> createState() => _PratinjauPdfScreenState();
}

class _PratinjauPdfScreenState extends ConsumerState<PratinjauPdfScreen> {
  final _kontrol = KontrolPenampilPdf();
  String? _path;
  Object? _galat;
  int _putaran = 0;
  bool _membukaLuar = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    if (_path != null || _galat != null) {
      setState(() {
        _path = null;
        _galat = null;
      });
    }
    try {
      final byte = await ref.read(layananProvider).unduhPdf(widget.sertifikat);
      // Layar sudah ditutup selagi mengunduh (atau keluar akun): jangan menulis
      // PDF ke cache untuk layar yang tidak ada lagi.
      if (!mounted) return;
      String path;
      try {
        path =
            (await ref
                    .read(penyimpanPratinjauProvider)
                    .simpan(widget.sertifikat.id, byte))
                .path;
      } on Object {
        throw const GalatBerkasPdf(JenisGagalPdf.simpan);
      }
      if (!mounted) return;
      setState(() => _path = path);
    } catch (e) {
      // 410 = dibatalkan sejak layar detail dimuat: tarik ulang supaya kartu
      // merah muncul dan tombolnya mati.
      if (e is GalatApi && e.status == 410) {
        ref.invalidate(detailSertifikatProvider(widget.sertifikat.id));
      }
      if (!mounted) return;
      setState(() => _galat = e);
    }
  }

  String _pesan(Object e) => switch (e) {
    GalatApi() => e.pesan,
    GalatBerkasPdf() => e.pesan,
    _ => 'PDF belum bisa ditampilkan. Coba lagi sebentar lagi.',
  };

  /// Jalan keluar bila PDF tidak bisa ditampilkan di sini: aplikasi PDF lain.
  Future<void> _bukaDiLuar() async {
    setState(() => _membukaLuar = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(layananProvider).unduhDanBukaPdf(widget.sertifikat);
    } on GalatApi catch (e) {
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
      if (mounted) setState(() => _membukaLuar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sertifikat;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.nomor, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _isi(context),
    );
  }

  Widget _isi(BuildContext context) {
    final t = context.teks;
    final galat = _galat;
    if (galat != null) {
      return _GalatPratinjau(
        pesan: _pesan(galat),
        // Sertifikat batal / belum ada PDF: mengulang tidak ada gunanya.
        bisaUlang: !(galat is GalatApi && (galat.status == 410)),
        onUlang: _muat,
      );
    }
    final path = _path;
    if (path == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spasi.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: Spasi.lg),
              Text(
                'Menyiapkan PDF…',
                textAlign: TextAlign.center,
                style: t.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    final bangun = ref.watch(penampilPdfProvider);
    return ListenableBuilder(
      listenable: _kontrol,
      builder: (context, _) {
        if (_kontrol.galat != null) {
          return _GalatPratinjau(
            pesan:
                'PDF ini tidak bisa ditampilkan di aplikasi. Buka dengan '
                'aplikasi PDF lain.',
            bisaUlang: false,
            onUlang: _muat,
            onBukaLuar: _membukaLuar ? null : _bukaDiLuar,
          );
        }
        return Column(
          children: [
            Expanded(
              child: ColoredBox(
                color: context.skema.surfaceContainerHigh,
                child: bangun(context, (
                  path: path,
                  putaran: _putaran,
                  kontrol: _kontrol,
                )),
              ),
            ),
            _BilahAlat(
              kontrol: _kontrol,
              onPutar: () => setState(() => _putaran = (_putaran + 1) % 4),
            ),
          ],
        );
      },
    );
  }
}

/// Bilah bawah: halaman di baris atas, tiga alat di baris bawah. Di bawah
/// supaya terjangkau jempol; dua baris supaya tetap muat di 320 dp dengan huruf
/// 1,3×. Semua target sentuh ≥ 48 dp.
class _BilahAlat extends StatelessWidget {
  const _BilahAlat({required this.kontrol, required this.onPutar});

  final KontrolPenampilPdf kontrol;
  final VoidCallback onPutar;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final t = context.teks;
    final jumlah = kontrol.jumlahHalaman;
    final siap = kontrol.siap;
    return Material(
      color: s.surface,
      shape: Border(top: BorderSide(color: s.outlineVariant)),
      child: Padding(
        padding: Spasi.denganTepiBawah(
          context,
          const EdgeInsets.fromLTRB(Spasi.sm, Spasi.xs, Spasi.sm, Spasi.sm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Halaman sebelumnya',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: kontrol.adaSebelumnya ? kontrol.sebelumnya : null,
                ),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      siap
                          ? 'Halaman ${kontrol.halaman} dari $jumlah'
                          : 'Membuka halaman…',
                      textAlign: TextAlign.center,
                      style: t.titleSmall,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Halaman berikutnya',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: kontrol.adaBerikutnya ? kontrol.berikutnya : null,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AlatPdf(
                  ikon: Icons.zoom_out,
                  label: 'Perkecil',
                  onTap: siap ? kontrol.perkecil : null,
                ),
                _AlatPdf(
                  ikon: Icons.zoom_in,
                  label: 'Perbesar',
                  onTap: siap ? kontrol.perbesar : null,
                ),
                _AlatPdf(
                  ikon: Icons.rotate_right,
                  label: 'Putar',
                  onTap: siap ? onPutar : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlatPdf extends StatelessWidget {
  const _AlatPdf({required this.ikon, required this.label, this.onTap});

  final IconData ikon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final t = context.teks;
    final warna = onTap == null
        ? s.onSurface.withValues(alpha: 0.38)
        : s.onSurface;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: Bentuk.sudutKontrol,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AreaSentuh.minimum + Spasi.xl,
            minHeight: AreaSentuh.minimum + Spasi.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(ikon, color: warna),
              Text(label, style: t.bodySmall?.copyWith(color: warna)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalatPratinjau extends StatelessWidget {
  const _GalatPratinjau({
    required this.pesan,
    required this.bisaUlang,
    required this.onUlang,
    this.onBukaLuar,
  });

  final String pesan;
  final bool bisaUlang;
  final VoidCallback onUlang;
  final VoidCallback? onBukaLuar;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    return ListView(
      padding: Spasi.denganTepiBawah(context, const EdgeInsets.all(Spasi.xl)),
      children: [
        Icon(
          Icons.picture_as_pdf_outlined,
          size: UkuranIkon.ilustrasi,
          color: context.skema.onSurfaceVariant,
        ),
        const SizedBox(height: Spasi.lg),
        Text(pesan, textAlign: TextAlign.center, style: t.bodyLarge),
        const SizedBox(height: Spasi.lg),
        if (bisaUlang)
          Center(
            child: TombolSidik(
              label: 'Coba lagi',
              ikon: Icons.refresh,
              ragam: RagamTombol.utama,
              onPressed: onUlang,
            ),
          ),
        if (onBukaLuar != null)
          Center(
            child: TombolSidik(
              label: 'Buka di aplikasi PDF lain',
              ikon: Icons.open_in_new,
              onPressed: onBukaLuar,
            ),
          ),
      ],
    );
  }
}
