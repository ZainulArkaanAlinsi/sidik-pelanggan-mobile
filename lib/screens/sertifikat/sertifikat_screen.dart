import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../core/tema/spasi.dart';
import '../../widgets/daftar_berhalaman.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kartu_sertifikat.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/kolom_cari.dart';
import 'arsip_screen.dart';
import 'sertifikat_detail_screen.dart';

/// Dua tampilan di tab Sertifikat.
enum _Tampilan { daftar, arsip }

/// Tab Sertifikat: pilihan "Daftar | Arsip" di atas, lalu salah satu isinya.
///
/// - Daftar: sertifikat terbit (cari + infinite scroll). Dibuka dari Beranda
///   ("Lihat semua") dan tab Alat. Bawaannya cuma yang MASIH BERLAKU sebagai
///   dokumen — yang sudah digantikan revisi disembunyikan supaya nomor lama
///   tidak terkirim ke auditor. Satu sakelar untuk menampilkannya.
/// - Arsip: sertifikat menurut tanggal terbit ([ArsipIsi]).
///
/// Kedua isi tetap hidup waktu berpindah (kata cari, sakelar, dan posisi
/// penelusuran tidak hilang). Arsip baru dibangun saat pertama dibuka, jadi
/// membuka tab Sertifikat tidak meminta arsip yang belum dilihat.
class SertifikatScreen extends StatefulWidget {
  const SertifikatScreen({super.key});

  @override
  State<SertifikatScreen> createState() => _SertifikatScreenState();
}

class _SertifikatScreenState extends State<SertifikatScreen> {
  _Tampilan _tampilan = _Tampilan.daftar;
  bool _arsipDibuka = false;

  void _pilih(_Tampilan t) => setState(() {
    _tampilan = t;
    if (t == _Tampilan.arsip) _arsipDibuka = true;
  });

  @override
  Widget build(BuildContext context) {
    return HalamanSidik(
      judul: 'Sertifikat',
      isi: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spasi.lg, Spasi.md, Spasi.lg, 0),
            child: Semantics(
              container: true,
              label: 'Tampilan sertifikat',
              child: SegmentedButton<_Tampilan>(
                expandedInsets: EdgeInsets.zero,
                // Penanda NON-warna: segmen terpilih mengganti ikonnya jadi
                // centang (lebar tetap). Beda latarnya cuma ±1,3:1, jadi
                // warna saja tidak cukup membedakan keadaan.
                showSelectedIcon: true,
                segments: const [
                  ButtonSegment(
                    value: _Tampilan.daftar,
                    icon: Icon(Icons.list_alt_outlined),
                    label: Text('Daftar'),
                    tooltip: 'Daftar sertifikat',
                  ),
                  ButtonSegment(
                    value: _Tampilan.arsip,
                    icon: Icon(Icons.folder_open_outlined),
                    label: Text('Arsip'),
                    tooltip: 'Arsip sertifikat menurut tanggal terbit',
                  ),
                ],
                selected: {_tampilan},
                onSelectionChanged: (s) => _pilih(s.single),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tampilan.index,
              children: [
                const _DaftarSertifikat(),
                if (_arsipDibuka) const ArsipIsi() else const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DaftarSertifikat extends ConsumerStatefulWidget {
  const _DaftarSertifikat();

  @override
  ConsumerState<_DaftarSertifikat> createState() => _DaftarSertifikatState();
}

class _DaftarSertifikatState extends ConsumerState<_DaftarSertifikat> {
  String _kata = '';
  bool _termasukDigantikan = false;

  @override
  Widget build(BuildContext context) {
    final kunci = (cari: _kata, termasukDigantikan: _termasukDigantikan);
    final async = ref.watch(daftarSertifikatProvider(kunci));

    return Column(
      children: [
        KolomCari(
          petunjuk: 'Cari nomor sertifikat, alat, atau nomor seri',
          onCari: (kata) => setState(() => _kata = kata),
        ),
        SwitchListTile(
          value: _termasukDigantikan,
          onChanged: (v) => setState(() => _termasukDigantikan = v),
          title: const Text('Tampilkan juga yang sudah direvisi'),
          contentPadding: Spasi.halaman,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(daftarSertifikatProvider(kunci));
              await ref.read(daftarSertifikatProvider(kunci).future);
            },
            child: DaftarBerhalaman<Sertifikat>(
              async: async,
              namaButir: 'sertifikat',
              padding: Spasi.daftar(context),
              muatLagi: ({ulangiGalat = false}) => ref
                  .read(daftarSertifikatProvider(kunci).notifier)
                  .muatLagi(ulangiGalat: ulangiGalat),
              cobaLagi: () => ref.invalidate(daftarSertifikatProvider(kunci)),
              kosong: KeadaanKosong(
                ikon: Icons.description_outlined,
                judul: _kata.isEmpty
                    ? 'Belum ada sertifikat'
                    : 'Tidak ada yang cocok',
                keterangan: _kata.isEmpty
                    ? 'Sertifikat muncul di sini begitu diterbitkan dan disahkan laboratorium.'
                    : 'Coba nomor atau nama alat yang lain.',
              ),
              butir: (context, s) => KartuSertifikat(
                sertifikat: s,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SertifikatDetailScreen(id: s.id),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
