import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import '../providers/koneksi_provider.dart';
import '../providers/push_provider.dart';
import '../providers/sinkron_provider.dart';

/// Teks banner offline (04-UI-UX §6).
String teksOffline(KeadaanKoneksi k, {DateTime? sekarang}) =>
    k.dataTerakhir == null
    ? 'Anda sedang offline. Periksa koneksi internet Anda.'
    : 'Anda sedang offline. Menampilkan data terakhir '
          '(${Format.jamAtauTanggal(k.dataTerakhir!, sekarang: sekarang)}).';

/// Bingkai di atas SEMUA layar (dipasang di `MaterialApp.builder`): banner
/// offline menempel di atas, layar di bawahnya.
///
/// Pohonnya SELALU sama (Column + MediaQuery), banner hanya tampil/hilang —
/// membungkus Navigator secara bersyarat akan memindahkannya di pohon dan
/// membuang seluruh tumpukan layar setiap kali sinyal naik-turun.
class BingkaiAplikasi extends ConsumerWidget {
  const BingkaiAplikasi({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = ref.watch(koneksiProvider);
    return Column(
      children: [
        if (k.offline) _BannerOffline(keadaan: k),
        Expanded(
          // Berkunci: banner yang muncul di atasnya tidak boleh membuat
          // Flutter mengira ini anak yang berbeda.
          key: const ValueKey('layar-aplikasi'),
          child: MediaQuery.removePadding(
            context: context,
            // Banner sudah memakan ruang status bar; layar di bawahnya tidak
            // perlu menambahkan jarak atasnya sendiri lagi.
            removeTop: k.offline,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _BannerOffline extends ConsumerWidget {
  const _BannerOffline({required this.keadaan});

  final KeadaanKoneksi keadaan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = context.warna;
    final t = context.teks;
    return Material(
      color: w.awasLatar,
      child: SafeArea(
        bottom: false,
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spasi.lg,
              Spasi.xs,
              Spasi.sm,
              Spasi.xs,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: UkuranIkon.sedang - 4,
                  color: w.awas,
                ),
                const SizedBox(width: Spasi.md),
                Expanded(
                  child: Text(
                    teksOffline(keadaan),
                    style: t.bodySmall?.copyWith(
                      color: context.skema.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => segarkanSemua(ref.invalidate),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner beranda saat notifikasi mati (REQ-NTF-08, 04 §6).
class BannerIzinNotifikasi extends ConsumerWidget {
  const BannerIzinNotifikasi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(bannerIzinProvider)) return const SizedBox.shrink();
    final w = context.warna;
    final t = context.teks;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spasi.md),
      child: Material(
        color: w.awasLatar,
        borderRadius: Bentuk.sudutKartu,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spasi.lg,
            Spasi.sm,
            Spasi.sm,
            Spasi.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_off_outlined,
                color: w.awas,
                size: UkuranIkon.sedang,
              ),
              const SizedBox(width: Spasi.md),
              Expanded(
                child: Text(
                  'Notifikasi mati. Anda bisa melewatkan pengingat jadwal '
                  'kalibrasi ulang.',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => nyalakanNotifikasi(ref),
                child: const Text('Nyalakan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
