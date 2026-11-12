import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/konfigurasi.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import '../providers/pembaruan_provider.dart';
import '../providers/sesi_provider.dart';
import 'tombol_sidik.dart';

/// Teks status satu baris untuk [k] — dipakai banner dan dialog.
String teksPembaruan(KeadaanPembaruan k) {
  final r = k.rilis;
  if (r == null) return '';
  return switch (k.tahap) {
    TahapPembaruan.diam => 'Versi ${r.versi} tersedia',
    TahapPembaruan.mengunduh =>
      k.progres == null
          ? 'Mengunduh versi ${r.versi}…'
          : 'Mengunduh versi ${r.versi}… ${(k.progres! * 100).floor()}%',
    TahapPembaruan.siap => 'Versi ${r.versi} siap dipasang',
    TahapPembaruan.memasang => 'Membuka pemasang…',
  };
}

String labelTombolPembaruan(KeadaanPembaruan k) {
  if (k.tahap == TahapPembaruan.siap) return 'Pasang';
  final mb = k.rilis?.ukuranMb;
  return mb == null ? 'Perbarui' : 'Perbarui ($mb)';
}

/// Banner "Versi X tersedia [Perbarui]" di atas navigasi bawah Rangka —
/// tampil di semua tab. Rilis wajib tidak memakai banner (dialog).
class BannerPembaruan extends ConsumerWidget {
  const BannerPembaruan({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = ref.watch(pembaruanProvider);
    if (!k.tersedia || k.wajib || k.disembunyikan) {
      return const SizedBox.shrink();
    }
    final s = context.skema;
    final t = context.teks;
    final pengendali = ref.read(pembaruanProvider.notifier);
    return Material(
      key: const ValueKey('banner-pembaruan'),
      color: s.primaryContainer,
      child: Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spasi.lg,
            Spasi.xs,
            Spasi.xs,
            Spasi.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.system_update_outlined,
                    size: UkuranIkon.sedang - 4,
                    color: s.onPrimaryContainer,
                  ),
                  const SizedBox(width: Spasi.md),
                  Expanded(
                    child: Text(
                      teksPembaruan(k),
                      style: t.bodySmall?.copyWith(
                        color: s.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!k.sibuk) ...[
                    TextButton(
                      onPressed: pengendali.sembunyikan,
                      child: const Text('Nanti'),
                    ),
                    TextButton(
                      onPressed: pengendali.perbarui,
                      child: Text(labelTombolPembaruan(k)),
                    ),
                  ],
                ],
              ),
              if (k.tahap == TahapPembaruan.mengunduh)
                Padding(
                  padding: const EdgeInsets.only(
                    top: Spasi.xs,
                    right: Spasi.md,
                  ),
                  child: LinearProgressIndicator(value: k.progres),
                ),
              if (k.pesan != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: Spasi.xs,
                    right: Spasi.md,
                  ),
                  child: Text(
                    k.pesan!,
                    style: t.bodySmall?.copyWith(color: s.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol + progres + pesan untuk pembaruan WAJIB — isi dialog wajib di
/// Rangka dan layar `LayarWajibPerbarui` di gerbang.
class PanelPerbarui extends ConsumerWidget {
  const PanelPerbarui({super.key});

  static Future<void> bukaHalamanRilis() async {
    try {
      await launchUrl(
        Konfigurasi.halamanRilis,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = ref.watch(pembaruanProvider);
    final t = context.teks;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (k.tersedia && k.tahap != TahapPembaruan.diam) ...[
          Text(
            teksPembaruan(k),
            style: t.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spasi.sm),
        ],
        if (k.tahap == TahapPembaruan.mengunduh) ...[
          LinearProgressIndicator(value: k.progres),
          const SizedBox(height: Spasi.md),
        ],
        TombolSidik(
          label: k.tersedia ? labelTombolPembaruan(k) : 'Perbarui sekarang',
          ikon: Icons.system_update_outlined,
          ragam: RagamTombol.utama,
          penuh: true,
          sibuk: k.sibuk,
          onPressed: k.sibuk
              ? null
              : () => ref.read(pembaruanProvider.notifier).perbarui(),
        ),
        if (k.pesan != null) ...[
          const SizedBox(height: Spasi.sm),
          Text(
            k.pesan!,
            style: t.bodySmall?.copyWith(color: context.skema.error),
            textAlign: TextAlign.center,
          ),
        ],
        // Selalu terlihat: kalau pemasangan di aplikasi gagal berulang,
        // pelanggan tidak terkunci — APK bisa diunduh dan dipasang manual.
        TombolSidik(
          label: 'Buka halaman unduhan',
          ragam: RagamTombol.teks,
          onPressed: bukaHalamanRilis,
        ),
      ],
    );
  }
}

/// Dialog pembaruan wajib: tidak bisa ditutup (tombol kembali dan ketuk di
/// luar diabaikan). Hilang hanya kalau aplikasinya diganti versi baru.
class DialogPembaruanWajib extends ConsumerWidget {
  const DialogPembaruanWajib({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(pembaruanProvider).rilis;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(Icons.system_update_outlined),
        title: const Text('Pembaruan wajib'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                r == null
                    ? 'Perbarui SIDIK Pelanggan untuk melanjutkan.'
                    : 'Versi ${r.versi} wajib dipasang untuk melanjutkan '
                          'memakai SIDIK Pelanggan.',
              ),
              if (r?.catatan != null) ...[
                const SizedBox(height: Spasi.sm),
                Text(r!.catatan!, style: context.teks.bodySmall),
              ],
              const SizedBox(height: Spasi.lg),
              const PanelPerbarui(),
              // Dialog ini menutupi seluruh aplikasi: tanpa jalan keluar,
              // HP yang dipinjamkan atau dijual tetap terbuka di akun lama.
              // Dialognya ditutup sendiri sesudah keluar: induknya (Rangka)
              // sudah dilepas Gerbang, tapi rute dialog hidup di navigator
              // akar dan tidak ikut hilang.
              TombolKeluarAkun(
                sesudahKeluar: () {
                  final rute = ModalRoute.of(context);
                  if (rute != null && rute.isActive) {
                    rute.navigator?.removeRoute(rute);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Keluar dari akun" untuk layar yang tidak bisa ditutup. Minta konfirmasi
/// dulu, lalu memakai jalur keluar yang SAMA dengan tab Akun
/// ([SesiController.keluar]): token push dicabut, token sesi dicabut di server
/// (gagal jaringan tidak menahan), cache akun ini dihapus dari HP.
class TombolKeluarAkun extends ConsumerStatefulWidget {
  const TombolKeluarAkun({super.key, this.sesudahKeluar});

  /// Dipanggil sesudah sesi lokal dibuang.
  final VoidCallback? sesudahKeluar;

  @override
  ConsumerState<TombolKeluarAkun> createState() => _TombolKeluarAkunState();
}

class _TombolKeluarAkunState extends ConsumerState<TombolKeluarAkun> {
  bool _sibuk = false;

  Future<void> _keluar() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Pembaruan tetap wajib dipasang sebelum aplikasi bisa dipakai '
          'lagi. Anda perlu masuk kembali setelahnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;
    setState(() => _sibuk = true);
    try {
      // Di layar gerbang versi minimum sesi belum pernah disentuh, dan
      // membaca `.notifier` memulai pemulihannya (`GET /saya`, yang untuk
      // versi usang dijawab 426). Beri kesempatan singkat supaya pemulihan itu
      // selesai SEBELUM sesi dibuang, dan batasi: Riverpod mengulang build yang
      // gagal sampai 10 kali, jadi `.future` bisa menggantung puluhan detik.
      final pengendali = ref.read(sesiProvider.notifier);
      try {
        await ref.read(sesiProvider.future).timeout(const Duration(seconds: 3));
      } catch (_) {}
      await pengendali.keluar();
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
    if (mounted) widget.sesudahKeluar?.call();
  }

  @override
  Widget build(BuildContext context) => TombolSidik(
    label: 'Keluar dari akun',
    ikon: Icons.logout,
    ragam: RagamTombol.teks,
    sibuk: _sibuk,
    onPressed: _sibuk ? null : _keluar,
  );
}
