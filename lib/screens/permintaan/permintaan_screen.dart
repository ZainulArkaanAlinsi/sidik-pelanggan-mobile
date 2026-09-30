import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/data_provider.dart';
import '../../widgets/permintaan.dart';
import '../../widgets/umum.dart';
import '../paket/paket_screen.dart';
import 'ajukan_screen.dart';
import 'permintaan_detail_screen.dart';

/// Daftar permintaan kalibrasi: Aktif / Selesai / Semua dengan angkanya.
///
/// Angka tab datang dari `meta.jumlah` milik server (terlepas dari tab yang
/// dibuka), jadi "Aktif 3 · Selesai 4" tidak berubah waktu pindah tab.
class PermintaanScreen extends ConsumerStatefulWidget {
  const PermintaanScreen({super.key});

  @override
  ConsumerState<PermintaanScreen> createState() => _PermintaanScreenState();
}

class _PermintaanScreenState extends ConsumerState<PermintaanScreen> {
  String _saring = 'aktif';

  Future<void> _ajukan() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const AjukanScreen()));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(daftarPermintaanProvider(_saring));
    final d = async.value;

    String label(String nama, int? n) => n == null ? nama : '$nama $n';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permintaan'),
        actions: [
          // Paket dulunya tab sendiri. Permintaan yang diterima berujung ke
          // paket, jadi pelacakannya dijangkau dari sini.
          IconButton(
            tooltip: 'Paket di lab',
            icon: const Icon(Icons.local_shipping_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PaketScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 8),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'aktif',
                  label: Text(label('Aktif', d?.jumlahAktif)),
                ),
                ButtonSegment(
                  value: 'selesai',
                  label: Text(label('Selesai', d?.jumlahSelesai)),
                ),
                const ButtonSegment(value: 'semua', label: Text('Semua')),
              ],
              selected: {_saring},
              onSelectionChanged: (s) => setState(() => _saring = s.first),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(daftarPermintaanProvider(_saring));
                await ref.read(daftarPermintaanProvider(_saring).future);
              },
              child: async.when(
                loading: () => const Memuat(),
                error: (e, _) => KeadaanGalat(
                  galat: e,
                  cobaLagi: () =>
                      ref.invalidate(daftarPermintaanProvider(_saring)),
                ),
                data: (h) => h.isi.isEmpty
                    // KeadaanKosong sudah berupa ListView (supaya tarik-untuk-
                    // muat-ulang tetap jalan); jangan dibungkus ListView lagi.
                    ? KeadaanKosong(
                        ikon: Icons.assignment_outlined,
                        judul: switch (_saring) {
                          'aktif' => 'Belum ada permintaan yang berjalan',
                          'selesai' => 'Belum ada permintaan selesai',
                          _ => 'Belum ada permintaan',
                        },
                        keterangan: _saring == 'selesai'
                            ? 'Permintaan yang sudah selesai akan muncul di sini.'
                            : 'Ajukan kalibrasi kalau ada alat yang mendekati jadwal.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(jarak, 4, jarak, 96),
                        itemCount: h.isi.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => KartuPermintaan(
                          permintaan: h.isi[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PermintaanDetailScreen(id: h.isi[i].id),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      // Satu pintu ke formulir. Dulu ada juga tombol di keadaan kosong; dua
      // tombol "Ajukan kalibrasi" di satu layar cuma membingungkan.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajukan,
        icon: const Icon(Icons.add),
        label: const Text('Ajukan kalibrasi'),
      ),
    );
  }
}
