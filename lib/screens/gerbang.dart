import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/sidik_material.dart';
import '../providers/pembaruan_provider.dart';
import '../providers/perangkat_provider.dart';
import '../providers/sesi_provider.dart';
import '../widgets/sidik/sidik_permukaan.dart';
import '../widgets/sidik/sidik_tombol.dart';
import '../widgets/pembaruan.dart';
import '../widgets/umum.dart';
import 'akun/bantuan_screen.dart';
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
      return LayarPemeliharaan(pesan: s.pesanPemeliharaan);
    }
    if (s != null && versi != null && s.wajibPerbarui(versi)) {
      return LayarWajibPerbarui(terpasang: versi, terbaru: s.versiTerbaru);
    }

    final sesi = ref.watch(sesiProvider);
    return sesi.when(
      loading: () => const _Pembuka(),
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
          // S06: status, kontak PT Sidik (kalau server memberikannya),
          // periksa lagi, keluar.
          final adaKontak =
              ref.watch(infoAplikasiProvider).value?.adaKontak ?? false;
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
            aksiTengah: adaKontak ? 'Hubungi PT Sidik' : null,
            onAksiTengah: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BantuanScreen()),
            ),
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

/// Layar pembuka selagi sesi dipulihkan — nama aplikasi + bilah tipis,
/// bukan pemutar kosong. Server gratis bisa tidur dan butuh 30-90 detik untuk
/// bangun; sesudah beberapa detik keterangannya muncul supaya layar tidak
/// terlihat macet.
class _Pembuka extends StatefulWidget {
  const _Pembuka();

  /// Lama menunggu sebelum keterangan "server sedang dinyalakan" muncul.
  static const jedaKeterangan = Duration(seconds: 5);

  @override
  State<_Pembuka> createState() => _PembukaState();
}

class _PembukaState extends State<_Pembuka> {
  Timer? _timer;
  bool _lama = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_Pembuka.jedaKeterangan, () {
      if (mounted) setState(() => _lama = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    final teks = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Memuat SIDIK Pelanggan',
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SIDIK PELANGGAN', style: m.gayaEtsa(ukuran: 14)),
                const SizedBox(height: 16),
                const SizedBox(width: 120, child: LinearProgressIndicator()),
                if (_lama) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Server sedang dinyalakan.\nBiasanya 30–60 detik, mohon tunggu.',
                    textAlign: TextAlign.center,
                    style: teks.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// S22 — server sedang pemeliharaan. Memeriksa ulang sendiri tiap 60 detik
/// (dan lewat tombol), jadi pelanggan tidak perlu menutup-buka aplikasi.
class LayarPemeliharaan extends ConsumerStatefulWidget {
  const LayarPemeliharaan({
    super.key,
    required this.pesan,
    this.selang = const Duration(seconds: 60),
  });

  final String pesan;
  final Duration selang;

  @override
  ConsumerState<LayarPemeliharaan> createState() => _LayarPemeliharaanState();
}

class _LayarPemeliharaanState extends ConsumerState<LayarPemeliharaan> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      widget.selang,
      (_) => ref.invalidate(statusAplikasiProvider),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pesan = widget.pesan.trim();
    return _LayarInfo(
      ikon: Icons.build_circle_outlined,
      judul: 'Sedang dalam perbaikan',
      isi: pesan.isEmpty ? 'Layanan sedang diperbarui.' : pesan,
      catatan: 'Aplikasi memeriksa ulang sendiri setiap menit.',
      aksi: 'Periksa lagi',
      onAksi: () => ref.invalidate(statusAplikasiProvider),
    );
  }
}

/// S21 — versi terpasang di bawah versi minimum. Tidak bisa ditutup: satu-
/// satunya jalan keluar adalah memasang versi baru. Aplikasi ini tidak ada di
/// Play Store; APK diunduh dari GitHub Releases, diverifikasi SHA-256-nya,
/// lalu diserahkan ke pemasang Android ([PanelPerbarui]).
class LayarWajibPerbarui extends ConsumerStatefulWidget {
  const LayarWajibPerbarui({
    super.key,
    required this.terpasang,
    required this.terbaru,
  });

  final String terpasang;
  final String terbaru;

  @override
  ConsumerState<LayarWajibPerbarui> createState() => _LayarWajibPerbaruiState();
}

class _LayarWajibPerbaruiState extends ConsumerState<LayarWajibPerbarui> {
  @override
  void initState() {
    super.initState();
    // Gerbang ini muncul sebelum sesi; manifes rilis dibaca langsung supaya
    // tombolnya sudah tahu ukuran unduhan.
    Future.microtask(
      () => ref.read(pembaruanProvider.notifier).periksa(paksa: true),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: _LayarInfo(
      ikon: Icons.system_update_outlined,
      judul: 'Perbarui aplikasi',
      isi:
          'Versi ${widget.terpasang} sudah tidak didukung. Perbarui SIDIK '
          'Pelanggan ke versi ${widget.terbaru} untuk melanjutkan.',
      isiBawah: const PanelPerbarui(),
    ),
  );
}

class _LayarInfo extends StatelessWidget {
  const _LayarInfo({
    required this.ikon,
    required this.judul,
    required this.isi,
    this.catatan,
    this.aksi,
    this.onAksi,
    this.aksiTengah,
    this.onAksiTengah,
    this.aksiKedua,
    this.onAksiKedua,
    this.isiBawah,
  });

  final IconData ikon;
  final String judul;
  final String isi;
  final String? catatan;
  final String? aksi;
  final VoidCallback? onAksi;
  final String? aksiTengah;
  final VoidCallback? onAksiTengah;
  final String? aksiKedua;
  final VoidCallback? onAksiKedua;

  /// Pengganti tombol aksi utama (mis. panel unduh pembaruan).
  final Widget? isiBawah;

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
                  if (catatan != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      catatan!,
                      style: t.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ?isiBawah,
                  if (aksi != null)
                    SidikTombol(
                      label: aksi!,
                      ragam: RagamTombol.utama,
                      penuh: true,
                      onPressed: onAksi,
                    ),
                  if (aksiTengah != null) ...[
                    const SizedBox(height: 10),
                    SidikTombol(
                      label: aksiTengah!,
                      ikon: Icons.support_agent,
                      penuh: true,
                      onPressed: onAksiTengah,
                    ),
                  ],
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
