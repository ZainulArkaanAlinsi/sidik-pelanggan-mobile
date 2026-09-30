import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/sidik_material.dart';
import '../../providers/perangkat_provider.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import 'terima_undangan_screen.dart';

/// Sambutan peluncuran pertama di HP ini (PL_Sambutan). Dua pintu saja, sama
/// dengan layar Masuk: Masuk, atau Pakai kode undangan — tidak ada "Daftar",
/// karena akun pelanggan hanya lahir dari undangan.
///
/// Tidak memuat data apa pun dari server: layar ini tampil sebelum ada akun.
class SambutanScreen extends ConsumerWidget {
  const SambutanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Text('SIDIK PELANGGAN', style: m.gayaEtsa(ukuran: 12)),
                const SizedBox(height: 8),
                Text('Selamat datang', style: t.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Jadwal kalibrasi ulang, status permintaan, dan sertifikat '
                  'semua alat perusahaan Anda, di satu tempat.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 32),
                SidikTombol(
                  label: 'Masuk',
                  ragam: RagamTombol.utama,
                  penuh: true,
                  onPressed: () => ref.read(sambutanProvider.notifier).tandai(),
                ),
                const SizedBox(height: 12),
                SidikTombol(
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
                const SizedBox(height: 24),
                Text(
                  'Akun dibuat lewat undangan dari PT Sidik atau PIC '
                  'perusahaan Anda. Belum dapat undangan? Hubungi PT Sidik.',
                  style: t.bodySmall,
                ),
                const SizedBox(height: 24),
                Text(
                  'PT Sistem Dirgantara Inovasi Teknologi · KAN LK-285-IDN',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
