import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/theme/sidik_material.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';
import '../gerbang.dart';
import 'anggota_screen.dart';
import 'preferensi_screen.dart';
import 'profil_hapus_screen.dart';

/// Akun: siapa saya, perusahaan aktif, anggota tim, sandi, keluar.
class AkunScreen extends ConsumerWidget {
  const AkunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesi = ref.watch(sesiProvider).value;
    final versi = ref.watch(versiAplikasiProvider).value;
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
          const SizedBox(height: jarak),
          Kertas(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profil saya'),
                  subtitle: const Text('Nama, nomor HP, jabatan'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfilSayaScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('Anggota tim'),
                  subtitle: Text(
                    aktif?.picUtama == true
                        ? 'Lihat, undang, dan nonaktifkan anggota'
                        : 'Lihat siapa saja di tim Anda',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AnggotaScreen(),
                    ),
                  ),
                ),
                if (sesi.akun.lebihDariSatuPerusahaan) ...[
                  const Divider(height: 1, indent: 56),
                  ListTile(
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
                ],
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Preferensi'),
                  subtitle: const Text('Tema tampilan dan notifikasi'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PreferensiScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Ganti sandi'),
                  subtitle: const Text(
                    'Sesi di perangkat lain ikut dikeluarkan',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const _GantiSandiScreen(),
                    ),
                  ),
                ),
              ],
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
            label: 'Hapus akun',
            ragam: RagamTombol.teks,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HapusAkunScreen()),
            ),
          ),
          const SizedBox(height: jarak),
          Text(
            'SIDIK Pelanggan ${versi ?? ''}',
            textAlign: TextAlign.center,
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _GantiSandiScreen extends ConsumerStatefulWidget {
  const _GantiSandiScreen();

  @override
  ConsumerState<_GantiSandiScreen> createState() => _GantiSandiScreenState();
}

class _GantiSandiScreenState extends ConsumerState<_GantiSandiScreen> {
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  bool _sibuk = false;
  Map<String, String> _galatIsian = const {};
  String? _galat;

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    setState(() {
      _sibuk = true;
      _galat = null;
      _galatIsian = const {};
    });
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(layananProvider).gantiSandi(_lama.text, _baru.text);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Sandi diganti. Perangkat lain sudah dikeluarkan.'),
        ),
      );
      navigator.pop();
    } on GalatApi catch (e) {
      if (mounted) {
        setState(() {
          _galat = e.isian.isEmpty ? e.pesan : null;
          _galatIsian = e.isian;
        });
      }
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ganti sandi')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _lama,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Sandi sekarang',
              errorText: _galatIsian['sandi_lama'],
            ),
          ),
          const SizedBox(height: jarak),
          TextField(
            controller: _baru,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Sandi baru',
              helperText: 'Minimal 10 karakter',
              errorText: _galatIsian['sandi'],
            ),
          ),
          if (_galat != null) ...[
            const SizedBox(height: 12),
            Text(_galat!, style: TextStyle(color: m.gagal)),
          ],
          const SizedBox(height: 24),
          SidikTombol(
            label: 'Simpan',
            ragam: RagamTombol.utama,
            penuh: true,
            sibuk: _sibuk,
            onPressed: _simpan,
          ),
        ],
      ),
    );
  }
}
