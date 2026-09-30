import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/sidik_material.dart';
import '../../providers/perangkat_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/umum.dart';

/// Preferensi (PL_Preferensi): tema per HP, dan keterangan soal notifikasi.
///
/// Sakelar notifikasi SENGAJA belum aktif. Setelan itu milik akun per
/// perusahaan (tabel `preferensi_notifikasi_anggota` di rancangan), jadi harus
/// tinggal di server supaya sama di semua HP — menyimpannya lokal berarti dua
/// HP satu akun berperilaku beda. Endpoint `GET/PUT /preferensi-notifikasi`
/// belum ada di `routes/api_pelanggan.php`; sakelar dihidupkan begitu ada.
class PreferensiScreen extends ConsumerWidget {
  const PreferensiScreen({super.key});

  static const _jenisNotifikasi = [
    (
      'Pengingat jadwal kalibrasi',
      'Alat yang mendekati atau sudah lewat jadwal kalibrasi ulang.',
    ),
    (
      'Status permintaan',
      'Dikonfirmasi, teknisi dijadwalkan, alat diterima, sertifikat terbit.',
    ),
    ('Pesan dari lab', 'Balasan tim PT Sidik di permintaan Anda.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    final mode = ref.watch(temaProvider).value ?? ThemeMode.system;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (judul, isi) in _jenisNotifikasi)
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: true,
                      onChanged: null,
                      title: Text(judul),
                      subtitle: Text(isi),
                    ),
                  ),
                const Divider(height: 24),
                Text(
                  'Setelan notifikasi belum bisa diubah dari aplikasi. Untuk '
                  'sementara semua kabar tetap masuk, dan selalu tersimpan di '
                  'kotak Notifikasi di dalam aplikasi.',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
