import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/data_provider.dart';
import '../../widgets/koreksi.dart';
import '../../widgets/umum.dart';
import 'koreksi_detail_screen.dart';

/// Daftar koreksi yang pernah diajukan pelanggan: Menunggu / Diterima /
/// Ditolak / Semua. Dibuka dari Akun, dan dari alat/sertifikat yang sedang
/// punya koreksi menunggu.
class KoreksiScreen extends ConsumerStatefulWidget {
  const KoreksiScreen({super.key});

  @override
  ConsumerState<KoreksiScreen> createState() => _KoreksiScreenState();
}

class _KoreksiScreenState extends ConsumerState<KoreksiScreen> {
  String _status = 'semua';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(daftarKoreksiProvider(_status));

    return Scaffold(
      appBar: AppBar(title: const Text('Koreksi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 8),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'menunggu', label: Text('Menunggu')),
                ButtonSegment(value: 'diterima', label: Text('Diterima')),
                ButtonSegment(value: 'ditolak', label: Text('Ditolak')),
                ButtonSegment(value: 'semua', label: Text('Semua')),
              ],
              selected: {_status},
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(daftarKoreksiProvider(_status));
                await ref.read(daftarKoreksiProvider(_status).future);
              },
              child: async.when(
                loading: () => const Memuat(),
                error: (e, _) => KeadaanGalat(
                  galat: e,
                  cobaLagi: () =>
                      ref.invalidate(daftarKoreksiProvider(_status)),
                ),
                data: (h) => h.isi.isEmpty
                    ? KeadaanKosong(
                        ikon: Icons.rule_folder_outlined,
                        judul: _status == 'semua'
                            ? 'Belum ada koreksi'
                            : 'Tidak ada koreksi di tab ini',
                        keterangan:
                            'Kalau ada data alat atau sertifikat yang salah, '
                            'ajukan koreksi dari halaman alat atau sertifikatnya.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(jarak, 4, jarak, 32),
                        itemCount: h.isi.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => KartuKoreksi(
                          koreksi: h.isi[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  KoreksiDetailScreen(id: h.isi[i].id),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
