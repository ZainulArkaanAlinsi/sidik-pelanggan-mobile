import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/konfigurasi.dart';
import '../core/theme/sidik_material.dart';
import '../providers/pembaruan_provider.dart';
import 'sidik/sidik_tombol.dart';

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
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    final pengendali = ref.read(pembaruanProvider.notifier);
    return Material(
      key: const ValueKey('banner-pembaruan'),
      color: m.biruTipis,
      child: Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.system_update_outlined, size: 20, color: m.biru),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      teksPembaruan(k),
                      style: t.bodySmall?.copyWith(
                        color: m.tinta,
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
                  padding: const EdgeInsets.only(top: 4, right: 12),
                  child: LinearProgressIndicator(value: k.progres),
                ),
              if (k.pesan != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 12),
                  child: Text(
                    k.pesan!,
                    style: t.bodySmall?.copyWith(color: m.gagal),
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
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
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
          const SizedBox(height: 6),
        ],
        if (k.tahap == TahapPembaruan.mengunduh) ...[
          LinearProgressIndicator(value: k.progres),
          const SizedBox(height: 12),
        ],
        SidikTombol(
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
          const SizedBox(height: 8),
          Text(
            k.pesan!,
            style: t.bodySmall?.copyWith(color: m.gagal),
            textAlign: TextAlign.center,
          ),
          SidikTombol(
            label: 'Buka halaman unduhan',
            ragam: RagamTombol.teks,
            onPressed: bukaHalamanRilis,
          ),
        ],
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
                const SizedBox(height: 8),
                Text(r!.catatan!, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              const PanelPerbarui(),
            ],
          ),
        ),
      ),
    );
  }
}
