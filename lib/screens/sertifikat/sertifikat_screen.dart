import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/data_provider.dart';
import '../../widgets/umum.dart';
import 'sertifikat_detail_screen.dart';

/// Daftar sertifikat terbit. Bawaannya cuma yang MASIH BERLAKU sebagai
/// dokumen — yang sudah digantikan revisi disembunyikan supaya nomor lama
/// tidak terkirim ke auditor. Satu sakelar untuk menampilkannya.
class SertifikatScreen extends ConsumerStatefulWidget {
  const SertifikatScreen({super.key});

  @override
  ConsumerState<SertifikatScreen> createState() => _SertifikatScreenState();
}

class _SertifikatScreenState extends ConsumerState<SertifikatScreen> {
  final _cari = TextEditingController();
  String _kata = '';
  bool _termasukDigantikan = false;
  Timer? _tunda;

  @override
  void dispose() {
    _tunda?.cancel();
    _cari.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kunci = (cari: _kata, termasukDigantikan: _termasukDigantikan);
    final async = ref.watch(daftarSertifikatProvider(kunci));

    return Scaffold(
      appBar: AppBar(title: const Text('Sertifikat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 0),
            child: TextField(
              controller: _cari,
              onChanged: (v) {
                _tunda?.cancel();
                _tunda = Timer(
                  const Duration(milliseconds: 350),
                  () => setState(() => _kata = v.trim()),
                );
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari nomor sertifikat, alat, atau nomor seri',
              ),
            ),
          ),
          SwitchListTile(
            value: _termasukDigantikan,
            onChanged: (v) => setState(() => _termasukDigantikan = v),
            title: const Text('Tampilkan juga yang sudah direvisi'),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: jarak),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(daftarSertifikatProvider(kunci));
                await ref.read(daftarSertifikatProvider(kunci).future);
              },
              child: async.when(
                loading: () => const Memuat(),
                error: (e, _) => KeadaanGalat(
                  galat: e,
                  cobaLagi: () =>
                      ref.invalidate(daftarSertifikatProvider(kunci)),
                ),
                data: (h) => h.isi.isEmpty
                    ? KeadaanKosong(
                        ikon: Icons.description_outlined,
                        judul: _kata.isEmpty
                            ? 'Belum ada sertifikat'
                            : 'Tidak ada yang cocok',
                        keterangan: _kata.isEmpty
                            ? 'Sertifikat muncul di sini begitu diterbitkan dan disahkan laboratorium.'
                            : 'Coba nomor atau nama alat yang lain.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(jarak, 4, jarak, 32),
                        itemCount: h.isi.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => KartuSertifikat(
                          sertifikat: h.isi[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  SertifikatDetailScreen(id: h.isi[i].id),
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
