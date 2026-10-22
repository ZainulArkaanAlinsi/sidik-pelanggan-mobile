import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/konfigurasi.dart';
import '../../core/theme/sidik_material.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';
import '../gerbang.dart';
import 'bantuan_screen.dart';

/// Teks kaki Akun (S17): versi + build + ID pengguna, untuk dukungan.
String teksVersi({
  required String versi,
  required String build,
  required int idPengguna,
  String lingkungan = Konfigurasi.lingkungan,
}) => [
  'SIDIK Pelanggan $versi (build $build)',
  'ID pengguna $idPengguna',
  if (lingkungan != 'prod') lingkungan.toUpperCase(),
].join(' · ');

/// Akun (S17): siapa saya, perusahaan aktif (ganti kalau anggota lebih dari
/// satu), bantuan & privasi, keluar (HP ini / semua perangkat), dan versi.
class AkunScreen extends ConsumerWidget {
  const AkunScreen({super.key});

  Future<void> _keluarSemua(BuildContext context, WidgetRef ref) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Keluar dari semua perangkat?'),
        content: const Text(
          'Sesi akun Anda di SEMUA HP — termasuk HP ini — langsung berakhir, '
          'dan HP-HP itu berhenti menerima notifikasi. Anda perlu masuk lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Keluar dari semua'),
          ),
        ],
      ),
    );
    if (yakin != true || !context.mounted) return;
    final pesan = ScaffoldMessenger.of(context);
    try {
      final n = await ref.read(sesiProvider.notifier).keluarSemua();
      pesan.showSnackBar(
        SnackBar(content: Text('Anda keluar dari $n sesi perangkat.')),
      );
    } on GalatApi catch (e) {
      // Sesi lokal TIDAK dibuang: token di HP lain belum tentu tercabut.
      pesan.showSnackBar(SnackBar(content: Text(e.pesan)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesi = ref.watch(sesiProvider).value;
    final paket = ref.watch(infoPaketProvider).value;
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    if (sesi == null) return const SizedBox.shrink();
    final aktif = sesi.keanggotaanAktif;

    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
        children: [
          Kertas(
            padding: const EdgeInsets.all(jarak),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sesi.akun.nama, style: t.titleMedium),
                Text(sesi.akun.email, style: t.bodySmall),
                if (sesi.akun.jabatan != null)
                  Text(sesi.akun.jabatan!, style: t.bodySmall),
                const Divider(height: 24),
                Text('PERUSAHAAN AKTIF', style: m.gayaEtsa(ukuran: 11)),
                const SizedBox(height: 4),
                Text(aktif?.namaPerusahaan ?? '—', style: t.titleSmall),
                Text(aktif?.labelPeran ?? '', style: t.bodySmall),
              ],
            ),
          ),
          if (sesi.akun.lebihDariSatuPerusahaan) ...[
            const SizedBox(height: jarak),
            Kertas(
              // Material transparan: percikan tinta ListTile digambar di
              // Material terdekat, yang tanpa ini tertutup warna Kertas.
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text('Ganti perusahaan'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const PilihPerusahaanScreen(bisaKembali: true),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: jarak),
          Kertas(
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: const Text('Bantuan & kontak'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BantuanScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privasi & ketentuan'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivasiScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SidikTombol(
            label: 'Keluar',
            ikon: Icons.logout,
            penuh: true,
            onPressed: () async {
              final yakin = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  title: const Text('Keluar dari aplikasi?'),
                  content: const Text(
                    'HP ini berhenti menerima notifikasi akun Anda sampai Anda masuk lagi.',
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
              if (yakin == true) await ref.read(sesiProvider.notifier).keluar();
            },
          ),
          SidikTombol(
            label: 'Keluar dari semua perangkat',
            ragam: RagamTombol.teks,
            onPressed: () => _keluarSemua(context, ref),
          ),
          const SizedBox(height: jarak),
          SelectableText(
            teksVersi(
              versi: paket?.versi ?? '-',
              build: paket?.build ?? '-',
              idPengguna: sesi.akun.id,
            ),
            textAlign: TextAlign.center,
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}
