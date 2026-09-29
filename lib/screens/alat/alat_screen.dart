import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/data_provider.dart';
import '../../widgets/umum.dart';
import '../rangka.dart';
import 'alat_detail_screen.dart';

/// Daftar alat perusahaan: cari + tiga saringan (Semua / Segera / Lewat).
/// Urutannya dari server: yang paling mendesak di atas.
class AlatScreen extends ConsumerStatefulWidget {
  const AlatScreen({super.key});

  @override
  ConsumerState<AlatScreen> createState() => _AlatScreenState();
}

class _AlatScreenState extends ConsumerState<AlatScreen> {
  final _cari = TextEditingController();
  String _kata = '';
  String? _saring;
  Timer? _tunda;

  @override
  void dispose() {
    _tunda?.cancel();
    _cari.dispose();
    super.dispose();
  }

  void _ketik(String v) {
    _tunda?.cancel();
    // Tunggu jeda mengetik — satu permintaan per kata, bukan per huruf.
    _tunda = Timer(
      const Duration(milliseconds: 350),
      () => setState(() => _kata = v.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Beranda bisa membuka tab ini dengan saringan tertentu.
    ref.listen(saringanAlatAwalProvider, (_, s) {
      setState(() => _saring = s.saring);
    });

    final kunci = (cari: _kata, saring: _saring);
    final async = ref.watch(daftarAlatProvider(kunci));

    return Scaffold(
      appBar: AppBar(title: const Text('Alat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 0),
            child: TextField(
              controller: _cari,
              onChanged: _ketik,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari nama, merk, atau nomor seri',
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: jarak, vertical: 8),
            child: Row(
              children: [
                for (final (nilai, label) in const [
                  (null, 'Semua'),
                  ('segera', 'Segera jatuh tempo'),
                  ('lewat', 'Lewat jatuh tempo'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _saring == nilai,
                      onSelected: (_) => setState(() => _saring = nilai),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(daftarAlatProvider(kunci));
                await ref.read(daftarAlatProvider(kunci).future);
              },
              child: async.when(
                loading: () => const Memuat(),
                error: (e, _) => KeadaanGalat(
                  galat: e,
                  cobaLagi: () => ref.invalidate(daftarAlatProvider(kunci)),
                ),
                data: (h) => h.isi.isEmpty
                    ? KeadaanKosong(
                        ikon: Icons.straighten_outlined,
                        judul: _saring == null && _kata.isEmpty
                            ? 'Belum ada alat'
                            : 'Tidak ada yang cocok',
                        keterangan: _saring == null && _kata.isEmpty
                            ? 'Alat Anda muncul di sini setelah pertama kali dikalibrasi di laboratorium PT Sidik.'
                            : 'Coba kata lain atau pilih saringan "Semua".',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(jarak, 4, jarak, 32),
                        itemCount: h.isi.length + (h.adaLagi ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i == h.isi.length) {
                            return Text(
                              'Menampilkan ${h.isi.length} dari ${h.total} alat. Persempit dengan pencarian.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }
                          final a = h.isi[i];
                          return KartuAlat(
                            alat: a,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AlatDetailScreen(id: a.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
