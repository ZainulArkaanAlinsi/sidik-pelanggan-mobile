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
import 'sertifikat_detail_screen.dart';

/// Daftar sertifikat terbit (cari + infinite scroll). Dibuka dari Beranda
/// ("Lihat semua") dan tab Alat. Bawaannya cuma yang MASIH BERLAKU sebagai
/// dokumen — yang sudah digantikan revisi disembunyikan supaya nomor lama
/// tidak terkirim ke auditor. Satu sakelar untuk menampilkannya.
class SertifikatScreen extends ConsumerStatefulWidget {
  const SertifikatScreen({super.key});

  @override
  ConsumerState<SertifikatScreen> createState() => _SertifikatScreenState();
}

class _SertifikatScreenState extends ConsumerState<SertifikatScreen> {
  String _kata = '';
  bool _termasukDigantikan = false;

  @override
  Widget build(BuildContext context) {
    final kunci = (cari: _kata, termasukDigantikan: _termasukDigantikan);
    final async = ref.watch(daftarSertifikatProvider(kunci));

    return HalamanSidik(
      judul: 'Sertifikat',
      isi: Column(
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
      ),
    );
  }
}
