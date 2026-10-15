import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../providers/koneksi_provider.dart';
import '../../providers/push_provider.dart';
import '../../widgets/banner.dart';
import '../../widgets/daftar_berhalaman.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/umum.dart';
import '../alat/alat_detail_screen.dart';
import '../rangka.dart';

/// Beranda — alat perusahaan dengan jatuh tempo kalibrasinya.
///
/// Atas: tiga angka (lewat jadwal, mendekati jadwal ≤ 30 hari, aman).
/// Bawah: daftar alat yang paling mendesak di atas (urutan dari server),
/// dengan cari + saringan, infinite scroll. Mengetuk alat membuka riwayat
/// kalibrasinya.
class BerandaScreen extends ConsumerStatefulWidget {
  const BerandaScreen({super.key});

  @override
  ConsumerState<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends ConsumerState<BerandaScreen> {
  final _cari = TextEditingController();
  String _kata = '';
  String? _saring;
  Timer? _tunda;
  bool _izinDitawarkan = false;

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

  String get _judulKosong => switch (_saring) {
    'segera' => 'Tidak ada alat yang mendekati jadwal',
    'lewat' => 'Tidak ada alat yang lewat jadwal',
    _ => _kata.isEmpty ? 'Belum ada alat' : 'Tidak ada yang cocok',
  };

  @override
  Widget build(BuildContext context) {
    // Pengingat jadwal (push / kotak masuk) mengatur saringan dari luar.
    ref.listen(saringanAlatAwalProvider, (_, s) {
      setState(() => _saring = s.saring);
    });

    final kunci = (cari: _kata, saring: _saring);
    final async = ref.watch(daftarAlatProvider(kunci));
    // Momen kontekstual izin notifikasi (REQ-NTF-08): begitu pengguna melihat
    // alatnya untuk pertama kali, pengingat jadwal punya alasan yang jelas.
    // `tawarkanNotifikasi` sendiri sekali per HP dan diam kalau izin sudah ada.
    if (!_izinDitawarkan && (async.value?.isi.isNotEmpty ?? false)) {
      _izinDitawarkan = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) tawarkanNotifikasi(context, ref);
      });
    }
    final beranda = ref.watch(berandaProvider);
    final koneksi = ref.watch(koneksiProvider);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          beranda.value?.namaPerusahaan.isNotEmpty == true
              ? beranda.value!.namaPerusahaan
              : 'Beranda',
        ),
      ),
      body: Column(
        children: [
          const BannerIzinNotifikasi(),
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
                  ('segera', 'Mendekati jadwal'),
                  ('lewat', 'Lewat jadwal'),
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
                ref.invalidate(berandaProvider);
                ref.invalidate(jumlahBelumDibacaProvider);
                ref.invalidate(daftarAlatProvider(kunci));
                await ref.read(daftarAlatProvider(kunci).future);
              },
              child: DaftarBerhalaman<Alat>(
                async: async,
                namaButir: 'alat',
                padding: const EdgeInsets.fromLTRB(jarak, 4, jarak, 32),
                muatLagi: ({ulangiGalat = false}) => ref
                    .read(daftarAlatProvider(kunci).notifier)
                    .muatLagi(ulangiGalat: ulangiGalat),
                cobaLagi: () => ref.invalidate(daftarAlatProvider(kunci)),
                kepala: [
                  if (koneksi.offline && koneksi.dataTerakhir != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Terakhir diperbarui '
                        '${Format.jamAtauTanggal(koneksi.dataTerakhir!)}',
                        style: t.bodySmall,
                      ),
                    ),
                  if (beranda.value != null)
                    _Ringkasan(
                      beranda: beranda.value!,
                      saring: _saring,
                      onPilih: (s) => setState(() => _saring = s),
                    ),
                  const JudulSeksi('Alat'),
                ],
                kosongDiBawahKepala: Text(
                  _judulKosong,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                kosong: KeadaanKosong(
                  ikon: Icons.straighten_outlined,
                  judul: _judulKosong,
                  keterangan: _kata.isEmpty && _saring == null
                      ? 'Alat yang pernah dikalibrasi di PT Sidik muncul di '
                            'sini.'
                      : 'Coba kata lain atau pilih saringan "Semua".',
                ),
                butir: (context, a) => KartuAlat(
                  alat: a,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AlatDetailScreen(id: a.id),
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

class _Ringkasan extends StatelessWidget {
  const _Ringkasan({
    required this.beranda,
    required this.saring,
    required this.onPilih,
  });

  final Beranda beranda;
  final String? saring;
  final void Function(String? saring) onPilih;

  @override
  Widget build(BuildContext context) {
    final b = beranda;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: _Angka(
              angka: b.lewatJatuhTempo,
              label: 'Lewat jadwal',
              nada: b.lewatJatuhTempo > 0 ? _Nada.gagal : _Nada.netral,
              onTap: () => onPilih('lewat'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Angka(
              angka: b.segeraJatuhTempo,
              label: 'Mendekati (≤ ${b.jendelaHari} hari)',
              nada: b.segeraJatuhTempo > 0 ? _Nada.awas : _Nada.netral,
              onTap: () => onPilih('segera'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Angka(
              angka: b.aman,
              label: 'Aman',
              nada: _Nada.lulus,
              onTap: () => onPilih(null),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Nada { netral, awas, gagal, lulus }

/// Satu angka ringkasan. Warna status HANYA kalau angkanya bukan nol — nol
/// alat terlambat itu kabar baik, bukan peringatan merah.
class _Angka extends StatelessWidget {
  const _Angka({
    required this.angka,
    required this.label,
    this.nada = _Nada.netral,
    required this.onTap,
  });

  final int angka;
  final String label;
  final _Nada nada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    final warna = switch (nada) {
      _Nada.gagal => m.gagal,
      _Nada.awas => m.awas,
      _Nada.lulus => angka > 0 ? m.lulus : m.tinta,
      _Nada.netral => m.tinta,
    };
    return Semantics(
      button: true,
      label: '$label: $angka',
      excludeSemantics: true,
      child: Kertas(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$angka',
              style: t.headlineMedium?.copyWith(
                color: warna,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: t.bodySmall, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
