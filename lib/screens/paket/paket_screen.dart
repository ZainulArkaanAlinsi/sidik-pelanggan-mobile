import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tema/spasi.dart';
import '../../models/paket.dart';
import '../../providers/data_provider.dart';
import '../../widgets/daftar_berhalaman.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kartu_paket.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/kolom_cari.dart';
import 'paket_detail_screen.dart';

/// Pelacakan paket (order): "alat saya sudah sampai mana?". Hanya membaca.
/// Bawaannya paket yang masih berjalan; riwayat lewat sakelar "Selesai".
class PaketScreen extends ConsumerStatefulWidget {
  const PaketScreen({super.key});

  @override
  ConsumerState<PaketScreen> createState() => _PaketScreenState();
}

class _PaketScreenState extends ConsumerState<PaketScreen> {
  String _kata = '';
  bool _selesai = false;

  @override
  Widget build(BuildContext context) {
    final kunci = (cari: _kata, selesai: _selesai);
    final async = ref.watch(daftarPaketProvider(kunci));

    return HalamanSidik(
      judul: 'Pelacakan paket',
      isi: Column(
        children: [
          KolomCari(
            petunjuk: 'Cari nomor order',
            onCari: (kata) => setState(() => _kata = kata),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spasi.lg,
              Spasi.sm,
              Spasi.lg,
              Spasi.sm,
            ),
            child: Wrap(
              spacing: Spasi.sm,
              children: [
                ChoiceChip(
                  label: const Text('Berjalan'),
                  selected: !_selesai,
                  onSelected: (_) => setState(() => _selesai = false),
                ),
                ChoiceChip(
                  label: const Text('Selesai'),
                  selected: _selesai,
                  onSelected: (_) => setState(() => _selesai = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(daftarPaketProvider(kunci));
                await ref.read(daftarPaketProvider(kunci).future);
              },
              child: DaftarBerhalaman<Paket>(
                async: async,
                namaButir: 'paket',
                padding: Spasi.daftar(context),
                muatLagi: ({ulangiGalat = false}) => ref
                    .read(daftarPaketProvider(kunci).notifier)
                    .muatLagi(ulangiGalat: ulangiGalat),
                cobaLagi: () => ref.invalidate(daftarPaketProvider(kunci)),
                kosong: KeadaanKosong(
                  ikon: Icons.inventory_2_outlined,
                  judul: _kata.isNotEmpty
                      ? 'Tidak ada yang cocok'
                      : _selesai
                      ? 'Belum ada paket yang selesai'
                      : 'Tidak ada paket yang sedang berjalan',
                  keterangan: _kata.isNotEmpty
                      ? 'Coba nomor order yang lain.'
                      : 'Paket yang Anda serahkan ke laboratorium muncul di '
                            'sini beserta tahap pengerjaannya.',
                ),
                butir: (context, p) => KartuPaket(
                  paket: p,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PaketDetailScreen(id: p.id),
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
