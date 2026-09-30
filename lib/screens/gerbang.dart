import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/sidik_material.dart';
import '../providers/perangkat_provider.dart';
import '../providers/sesi_provider.dart';
import '../widgets/sidik/sidik_permukaan.dart';
import '../widgets/sidik/sidik_tombol.dart';
import '../widgets/umum.dart';
import 'auth/masuk_screen.dart';
import 'auth/sambutan_screen.dart';
import 'rangka.dart';

/// Akar aplikasi: memutuskan layar pertama dari tiga pertanyaan, berurutan.
///
/// 1. Server sedang pemeliharaan / versi aplikasi terlalu lama? → layar info.
/// 2. Belum masuk? → Sambutan (hanya peluncuran pertama di HP ini), lalu Masuk.
/// 3. Akun belum diverifikasi / belum punya perusahaan / anggota dua PT belum
///    memilih? → layar keadaan yang sesuai.
///
/// Lalu Rangka (navigasi bawah). Tidak ada satu pun layar data yang terbuka
/// sebelum ketiga pertanyaan itu dijawab.
class Gerbang extends ConsumerWidget {
  const Gerbang({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(statusAplikasiProvider);
    final versi = ref.watch(versiAplikasiProvider).value;

    final s = status.value;
    if (s != null && s.pemeliharaan) {
      return _LayarInfo(
        ikon: Icons.build_circle_outlined,
        judul: 'Sedang dalam perbaikan',
        isi: s.pesanPemeliharaan,
        aksi: 'Periksa lagi',
        onAksi: () => ref.invalidate(statusAplikasiProvider),
      );
    }
    if (s != null && versi != null && s.wajibPerbarui(versi)) {
      return _LayarInfo(
        ikon: Icons.system_update_outlined,
        judul: 'Perbarui aplikasi',
        isi:
            'Versi $versi sudah tidak didukung. Perbarui SIDIK Pelanggan ke versi ${s.versiTerbaru} '
            'lewat toko aplikasi, lalu buka lagi.',
      );
    }

    final sesi = ref.watch(sesiProvider);
    return sesi.when(
      loading: () => const Scaffold(body: Memuat()),
      error: (e, _) => Scaffold(
        body: SafeArea(
          child: KeadaanGalat(
            galat: e,
            cobaLagi: () => ref.invalidate(sesiProvider),
          ),
        ),
      ),
      data: (sesi) {
        if (sesi == null) {
          // Sambutan hanya di peluncuran pertama. Selama flag belum terbaca,
          // Masuk lebih baik daripada layar kosong.
          final lihat = ref.watch(sambutanProvider).value;
          return lihat == false ? const SambutanScreen() : const MasukScreen();
        }

        if (sesi.akun.butuhVerifikasi || !sesi.akun.punyaPerusahaan) {
          final ditolak = sesi.akun.pengajuan?.status == 'ditolak';
          return _LayarInfo(
            ikon: ditolak ? Icons.block : Icons.hourglass_top_outlined,
            judul: ditolak ? 'Akun tidak disetujui' : 'Akun belum aktif',
            isi: ditolak
                ? (sesi.akun.pengajuan?.alasanTolak ??
                      'Hubungi admin laboratorium PT Sidik untuk keterangan.')
                : 'Akun Anda belum tertaut ke perusahaan. Admin laboratorium PT Sidik atau PIC perusahaan '
                      'Anda perlu menautkannya dulu. Halaman ini diperbarui otomatis saat Anda membukanya lagi.',
            aksi: 'Periksa lagi',
            onAksi: () => ref.read(sesiProvider.notifier).segarkan(),
            aksiKedua: 'Keluar',
            onAksiKedua: () => ref.read(sesiProvider.notifier).keluar(),
          );
        }

        if (sesi.perluPilihPerusahaan) return const PilihPerusahaanScreen();

        return const Rangka();
      },
    );
  }
}

/// Anggota lebih dari satu perusahaan memilih mana yang dibuka.
class PilihPerusahaanScreen extends ConsumerWidget {
  const PilihPerusahaanScreen({super.key, this.bisaKembali = false});

  final bool bisaKembali;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesi = ref.watch(sesiProvider).value;
    final daftar = sesi?.akun.keanggotaan ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih perusahaan'),
        automaticallyImplyLeading: bisaKembali,
      ),
      body: ListView(
        padding: const EdgeInsets.all(jarak),
        children: [
          Text(
            'Akun Anda terdaftar di beberapa perusahaan. Data yang tampil selalu milik perusahaan yang dipilih.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: jarak),
          for (final k in daftar)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Kertas(
                padding: const EdgeInsets.all(14),
                onTap: () {
                  ref.read(sesiProvider.notifier).pilihPerusahaan(k.customerId);
                  if (bisaKembali) Navigator.of(context).pop();
                },
                child: Row(
                  children: [
                    const Icon(Icons.apartment_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            k.namaPerusahaan,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            k.labelPeran,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (k.customerId == sesi?.perusahaanId)
                      const Icon(Icons.check),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LayarInfo extends StatelessWidget {
  const _LayarInfo({
    required this.ikon,
    required this.judul,
    required this.isi,
    this.aksi,
    this.onAksi,
    this.aksiKedua,
    this.onAksiKedua,
  });

  final IconData ikon;
  final String judul;
  final String isi;
  final String? aksi;
  final VoidCallback? onAksi;
  final String? aksiKedua;
  final VoidCallback? onAksiKedua;

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ikon, size: 52, color: m.tinta2),
                  const SizedBox(height: jarak),
                  Text(
                    judul,
                    style: t.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(isi, style: t.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  if (aksi != null)
                    SidikTombol(
                      label: aksi!,
                      ragam: RagamTombol.utama,
                      penuh: true,
                      onPressed: onAksi,
                    ),
                  if (aksiKedua != null)
                    SidikTombol(
                      label: aksiKedua!,
                      ragam: RagamTombol.teks,
                      onPressed: onAksiKedua,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
