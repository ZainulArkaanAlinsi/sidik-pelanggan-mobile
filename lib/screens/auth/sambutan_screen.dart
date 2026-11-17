import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../providers/perangkat_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/lencana_kan.dart';
import '../../widgets/tombol_sidik.dart';
import '../akun/hubungi_screen.dart';
import 'kerangka_auth.dart';
import 'terima_undangan_screen.dart';

/// Sambutan peluncuran pertama di HP ini (PL_Sambutan). Dua pintu saja, sama
/// dengan layar Masuk: Masuk, atau Pakai kode undangan; tidak ada "Daftar",
/// karena akun pelanggan hanya lahir dari undangan.
///
/// Tidak memuat data apa pun dari server: layar ini tampil sebelum ada akun.
class SambutanScreen extends ConsumerWidget {
  const SambutanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.teks;
    final s = context.skema;
    // "Hubungi PT Sidik" hanya kalau lab mengisi kontaknya (GET /app/info).
    final adaKontak = ref.watch(infoAplikasiProvider).value?.adaKontak ?? false;

    return KerangkaAuth(
      kartu: [
        const JudulAuth('Selamat datang'),
        const SizedBox(height: Spasi.sm),
        Text(
          'Jadwal kalibrasi ulang, riwayat kalibrasi, dan sertifikat '
          'semua alat perusahaan Anda, di satu tempat.',
          style: t.bodyLarge?.copyWith(color: s.onSurfaceVariant),
        ),
        const SizedBox(height: Spasi.xl),
        TombolSidik(
          label: 'Masuk',
          ragam: RagamTombol.utama,
          penuh: true,
          onPressed: () => ref.read(sambutanProvider.notifier).tandai(),
        ),
        const SizedBox(height: Spasi.md),
        TombolSidik(
          label: 'Pakai kode undangan',
          ikon: Icons.mark_email_read_outlined,
          penuh: true,
          onPressed: () {
            // Dorong layarnya DULU: begitu sambutan ditandai, Gerbang
            // berganti ke Masuk, dan layar undangan harus sudah
            // menumpang di atasnya supaya "kembali" mendarat di Masuk.
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TerimaUndanganScreen(),
              ),
            );
            ref.read(sambutanProvider.notifier).tandai();
          },
        ),
        const SizedBox(height: Spasi.lg),
        Text(
          'Akun dibuat lewat undangan dari PT Sidik atau PIC '
          'perusahaan Anda. Belum dapat undangan? Hubungi PT Sidik.',
          style: t.bodySmall,
        ),
        if (adaKontak)
          Align(
            alignment: Alignment.centerLeft,
            child: TombolSidik(
              label: 'Hubungi PT SIDIK',
              ikon: Icons.support_agent,
              ragam: RagamTombol.teks,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HubungiScreen()),
              ),
            ),
          ),
      ],
      bawah: [
        Text(
          'PT Sistem Dirgantara Inovasi Teknologi',
          style: t.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spasi.sm),
        const Center(child: LencanaKan()),
      ],
    );
  }
}
