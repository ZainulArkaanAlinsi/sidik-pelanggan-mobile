import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/permintaan.dart';
import '../../providers/data_provider.dart';
import '../../providers/perangkat_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/umum.dart';

/// Preferensi (PL_Preferensi): tema per HP, dan saklar notifikasi.
///
/// Dua hal yang SENGAJA disimpan di tempat berbeda:
/// - **Tema** per HP (`penyimpanPerangkat`) — selera layar, tidak perlu ikut
///   ke HP lain.
/// - **Saklar notifikasi** di SERVER, per anggota per perusahaan — setelan
///   ini menentukan apa yang dikirim server, jadi dua HP satu akun harus
///   sepakat. Menyimpannya lokal membuat satu HP berbunyi dan HP lain diam
///   untuk akun yang sama.
class PreferensiScreen extends ConsumerWidget {
  const PreferensiScreen({super.key});

  static const _jenisNotifikasi = [
    (
      PreferensiNotifikasi.kunciPengingat,
      'Pengingat jadwal kalibrasi',
      'Alat yang mendekati atau sudah lewat jadwal kalibrasi ulang.',
    ),
    (
      PreferensiNotifikasi.kunciStatus,
      'Status permintaan',
      'Permintaan Anda diterima atau ditolak lab.',
    ),
    (
      PreferensiNotifikasi.kunciPesan,
      'Pesan dari lab',
      'Balasan Tim PT Sidik di permintaan Anda.',
    ),
    (
      PreferensiNotifikasi.kunciEmail,
      'Ringkasan email mingguan',
      'Dikirim tiap Senin pukul 07.15 WIB ke email akun kamu.',
    ),
  ];

  Future<void> _ubah(
    BuildContext context,
    WidgetRef ref,
    String kunci,
    bool nilai,
  ) async {
    final pesan = ScaffoldMessenger.of(context);
    try {
      await ref.read(preferensiProvider.notifier).ubah(kunci, nilai);
    } on GalatApi catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(e.pesan)));
    } catch (_) {
      pesan.showSnackBar(
        const SnackBar(content: Text('Setelan belum tersimpan. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    final mode = ref.watch(temaProvider).value ?? ThemeMode.system;
    final pref = ref.watch(preferensiProvider);
    final perusahaan = ref
        .watch(sesiProvider)
        .value
        ?.keanggotaanAktif
        ?.namaPerusahaan;

    return Scaffold(
      appBar: AppBar(title: const Text('Preferensi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
        children: [
          Text('TAMPILAN DI HP INI', style: m.gayaEtsa(ukuran: 11)),
          const SizedBox(height: 8),
          Kertas(
            padding: const EdgeInsets.symmetric(vertical: 4),
            // Material transparan: ListTile melukis di Material terdekat, dan
            // Kertas berlatar warna akan menutupinya.
            child: Material(
              type: MaterialType.transparency,
              child: RadioGroup<ThemeMode>(
                groupValue: mode,
                onChanged: (v) {
                  if (v != null) ref.read(temaProvider.notifier).atur(v);
                },
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      title: Text('Ikut sistem'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      title: Text('Terang'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      title: Text('Gelap'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Pilihan ini hanya berlaku di HP ini.', style: t.bodySmall),
          const SizedBox(height: 24),
          Text('NOTIFIKASI', style: m.gayaEtsa(ukuran: 11)),
          const SizedBox(height: 8),
          Kertas(
            padding: const EdgeInsets.all(jarak),
            child: pref.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(jarak),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e is GalatApi
                        ? e.pesan
                        : 'Setelan notifikasi belum bisa dimuat.',
                    style: t.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(preferensiProvider),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
              data: (p) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    perusahaan == null
                        ? 'Setelan ini khusus untuk perusahaan yang sedang aktif.'
                        : 'Setelan ini khusus untuk $perusahaan. Perusahaan '
                              'lain yang Anda ikuti punya setelan sendiri.',
                    style: t.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  for (final (kunci, judul, isi) in _jenisNotifikasi)
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: p.nilai(kunci),
                        onChanged: (v) => _ubah(context, ref, kunci, v),
                        title: Text(judul),
                        subtitle: Text(isi),
                      ),
                    ),
                  const Divider(height: 24),
                  Text(
                    'Saklar yang dimatikan berarti kabar itu tidak dikirim '
                    'sama sekali. Kalau notifikasi aplikasi dimatikan di '
                    'pengaturan HP, semua kabar tetap masuk ke kotak '
                    'Notifikasi di dalam aplikasi.',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
