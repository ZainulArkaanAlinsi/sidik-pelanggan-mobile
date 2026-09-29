import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/data_provider.dart';
import '../../widgets/umum.dart';
import 'paket_detail_screen.dart';

/// Paket (order) di laboratorium: "Berjalan" dan "Selesai".
class PaketScreen extends ConsumerStatefulWidget {
  const PaketScreen({super.key});

  @override
  ConsumerState<PaketScreen> createState() => _PaketScreenState();
}

class _PaketScreenState extends ConsumerState<PaketScreen> {
  bool _selesai = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(daftarPaketProvider(_selesai));

    return Scaffold(
      appBar: AppBar(title: const Text('Paket')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Berjalan')),
                ButtonSegment(value: true, label: Text('Selesai')),
              ],
              selected: {_selesai},
              onSelectionChanged: (s) => setState(() => _selesai = s.first),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(daftarPaketProvider(_selesai));
                await ref.read(daftarPaketProvider(_selesai).future);
              },
              child: async.when(
                loading: () => const Memuat(),
                error: (e, _) => KeadaanGalat(
                  galat: e,
                  cobaLagi: () => ref.invalidate(daftarPaketProvider(_selesai)),
                ),
                data: (h) => h.isi.isEmpty
                    ? KeadaanKosong(
                        ikon: Icons.local_shipping_outlined,
                        judul: _selesai
                            ? 'Belum ada paket selesai'
                            : 'Tidak ada paket di lab',
                        keterangan: _selesai
                            ? 'Paket yang sudah diserahkan kembali akan tercatat di sini.'
                            : 'Begitu alat Anda diterima laboratorium, perjalanannya bisa dilacak di sini.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(jarak, 4, jarak, 32),
                        itemCount: h.isi.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => KartuPaket(
                          paket: h.isi[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PaketDetailScreen(id: h.isi[i].id),
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
