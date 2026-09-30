import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/data_pelanggan.dart';
import '../../models/permintaan.dart';
import '../../providers/data_provider.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';

/// Pilih alat terdaftar untuk diajukan. Hasilnya `List<Alat>` lewat
/// `Navigator.pop`. Yang dipilih dipegang per id, jadi pilihan tidak hilang
/// waktu kata cari berganti dan daftarnya dimuat ulang.
class PilihAlatScreen extends ConsumerStatefulWidget {
  const PilihAlatScreen({super.key, this.awal = const []});

  final List<Alat> awal;

  @override
  ConsumerState<PilihAlatScreen> createState() => _PilihAlatScreenState();
}

class _PilihAlatScreenState extends ConsumerState<PilihAlatScreen> {
  final _cari = TextEditingController();
  late final Map<int, Alat> _dipilih = {for (final a in widget.awal) a.id: a};
  String _kata = '';
  Timer? _tunda;

  @override
  void dispose() {
    _tunda?.cancel();
    _cari.dispose();
    super.dispose();
  }

  void _ketik(String v) {
    _tunda?.cancel();
    _tunda = Timer(
      const Duration(milliseconds: 350),
      () => setState(() => _kata = v.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(daftarAlatProvider((cari: _kata, saring: null)));
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pilih alat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 8),
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
          Expanded(
            child: async.when(
              loading: () => const Memuat(),
              error: (e, _) => KeadaanGalat(
                galat: e,
                cobaLagi: () => ref.invalidate(daftarAlatProvider),
              ),
              data: (h) => h.isi.isEmpty
                  ? const KeadaanKosong(
                      ikon: Icons.straighten_outlined,
                      judul: 'Alat tidak ditemukan',
                      keterangan:
                          'Alat yang belum terdaftar bisa ditambahkan sebagai alat baru di formulir permintaan.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: h.isi.length,
                      itemBuilder: (context, i) {
                        final a = h.isi[i];
                        final ada = _dipilih.containsKey(a.id);
                        return Material(
                          type: MaterialType.transparency,
                          child: CheckboxListTile(
                            value: ada,
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _dipilih[a.id] = a;
                              } else {
                                _dipilih.remove(a.id);
                              }
                            }),
                            title: Text(a.nama),
                            subtitle: Text(
                              [
                                a.merkModel,
                                if (a.serial != null) 'SN ${a.serial}',
                              ].where((s) => s.isNotEmpty).join(' · '),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, jarak),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_dipilih.length > DraftPermintaan.maksAlat)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Maksimal ${DraftPermintaan.maksAlat} alat dalam satu permintaan.',
                        style: t.bodySmall,
                      ),
                    ),
                  SidikTombol(
                    label: 'Pilih ${_dipilih.length} alat',
                    ragam: RagamTombol.utama,
                    penuh: true,
                    onPressed: () =>
                        Navigator.of(context).pop(_dipilih.values.toList()),
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
