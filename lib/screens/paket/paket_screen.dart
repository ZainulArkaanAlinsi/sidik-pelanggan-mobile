import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../models/paket.dart';
import '../../providers/data_provider.dart';
import '../../widgets/daftar_berhalaman.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_status.dart';
import '../../widgets/umum.dart';
import 'paket_detail_screen.dart';

/// Pelacakan paket (order): "alat saya sudah sampai mana?". Hanya membaca.
/// Bawaannya paket yang masih berjalan; riwayat lewat sakelar "Selesai".
class PaketScreen extends ConsumerStatefulWidget {
  const PaketScreen({super.key});

  @override
  ConsumerState<PaketScreen> createState() => _PaketScreenState();
}

class _PaketScreenState extends ConsumerState<PaketScreen> {
  final _cari = TextEditingController();
  String _kata = '';
  bool _selesai = false;
  Timer? _tunda;

  @override
  void dispose() {
    _tunda?.cancel();
    _cari.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kunci = (cari: _kata, selesai: _selesai);
    final async = ref.watch(daftarPaketProvider(kunci));

    return Scaffold(
      appBar: AppBar(title: const Text('Pelacakan paket')),
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
                hintText: 'Cari nomor order',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 0),
            child: Wrap(
              spacing: 8,
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
                butir: (context, p) => _KartuPaket(
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

class _KartuPaket extends StatelessWidget {
  const _KartuPaket({required this.paket, required this.onTap});

  final Paket paket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Kertas(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(paket.nomor, style: t.titleSmall)),
              const SizedBox(width: 8),
              Flexible(
                child: SidikLencana(statusPaket(paket.tahap, paket.tahapLabel)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${paket.jumlahSelesai} dari ${paket.jumlahAlat} alat selesai',
            style: t.bodySmall,
          ),
          Text(
            'Masuk ${Format.tanggal(paket.tanggalMasuk)}'
            '${paket.tanggalJanjiSelesai == null ? '' : ' · target selesai ${Format.tanggal(paket.tanggalJanjiSelesai)}'}',
            style: t.bodySmall,
          ),
          if (paket.terlambat) ...[
            const SizedBox(height: 6),
            const SidikLencana(
              StatusSidik(
                'Melewati target selesai',
                NadaStatus.awas,
                Icons.schedule,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
