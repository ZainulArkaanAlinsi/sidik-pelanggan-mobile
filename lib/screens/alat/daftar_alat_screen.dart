import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../models/data_pelanggan.dart';
import '../../models/status_berlaku.dart';
import '../../providers/data_provider.dart';
import '../../providers/koneksi_provider.dart';
import '../../widgets/daftar_berhalaman.dart';
import '../../widgets/umum.dart';
import 'alat_detail_screen.dart';

/// Kelompok jatuh tempo pada daftar alat. Dipakai juga oleh kotak ringkasan di
/// Beranda, jadi kotak yang diketuk dan daftar yang terbuka selalu sama.
enum FilterAlat {
  semua,
  lewatJadwal,
  hari30,
  hari60,
  hari90;

  /// Teks chip dan kotak ringkasan. "Lewat jadwal" dari [StatusBerlaku.label]
  /// (satu sumber istilah); rentang hari ditulis di sini.
  String get label => switch (this) {
    semua => 'Semua',
    lewatJadwal => StatusBerlaku.lewatJadwal.label,
    hari30 => 'Dalam 30 hari',
    hari60 => 'Dalam 31–60 hari',
    hari90 => 'Dalam 61–90 hari',
  };

  /// Judul keadaan kosong, sama sumbernya dengan [label].
  String get judulKosong => switch (this) {
    semua => 'Belum ada alat',
    lewatJadwal =>
      'Tidak ada alat yang ${StatusBerlaku.lewatJadwal.label.toLowerCase()}',
    hari30 ||
    hari60 ||
    hari90 => 'Tidak ada alat yang jatuh tempo ${label.toLowerCase()}',
  };

  /// Nilai `saring` di `GET /alat`. Hanya tiga filter pertama yang dikenal
  /// server; `hari60` dan `hari90` dihitung di aplikasi ([dariServer] false).
  String? get saringServer => switch (this) {
    lewatJadwal => 'lewat',
    hari30 => 'segera',
    _ => null,
  };

  bool get dariServer => this != hari60 && this != hari90;

  List<Alat> dari(RingkasanJatuhTempo r) => switch (this) {
    semua => r.urut,
    lewatJadwal => r.lewatJadwal,
    hari30 => r.kelompok1,
    hari60 => r.kelompok2,
    hari90 => r.kelompok3,
  };
}

/// Semua alat perusahaan, satu layar, dengan status masa berlakunya
/// (Berlaku, Segera jatuh tempo, Lewat jadwal, …). Yang paling mendesak di atas
/// (urutan dari server). Cari nama, merk, atau nomor seri; saring menurut
/// kelompok jatuh tempo; tarik layar untuk memuat ulang.
class DaftarAlatScreen extends ConsumerStatefulWidget {
  const DaftarAlatScreen({super.key, this.filterAwal = FilterAlat.semua});

  final FilterAlat filterAwal;

  @override
  ConsumerState<DaftarAlatScreen> createState() => _DaftarAlatScreenState();
}

class _DaftarAlatScreenState extends ConsumerState<DaftarAlatScreen> {
  final _cari = TextEditingController();
  String _kata = '';
  late FilterAlat _filter = widget.filterAwal;
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

  String get _judulKosong => _filter == FilterAlat.semua && _kata.isNotEmpty
      ? 'Tidak ada yang cocok'
      : _filter.judulKosong;

  String get _keteranganKosong => _kata.isEmpty && _filter == FilterAlat.semua
      ? 'Alat yang pernah dikalibrasi di PT Sidik muncul di sini.'
      : 'Coba kata lain atau pilih "Semua".';

  void _bukaAlat(Alat a) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => AlatDetailScreen(id: a.id)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alat saya')),
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
                for (final f in FilterAlat.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.label),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _filter.dariServer ? _dariServer() : _dariAplikasi()),
        ],
      ),
    );
  }

  /// Semua / Lewat jadwal / Dalam 30 hari: disaring dan dicari SERVER, 20 per
  /// halaman, halaman berikut dimuat saat daftar digulir.
  Widget _dariServer() {
    final kunci = (cari: _kata, saring: _filter.saringServer);
    final async = ref.watch(daftarAlatProvider(kunci));
    final koneksi = ref.watch(koneksiProvider);
    final t = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(daftarAlatProvider(kunci));
        await ref.read(daftarAlatProvider(kunci).future);
      },
      child: DaftarBerhalaman<Alat>(
        async: async,
        namaButir: 'alat',
        padding: denganTepiBawah(
          context,
          const EdgeInsets.fromLTRB(jarak, 4, jarak, 32),
        ),
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
        ],
        kosongDiBawahKepala: Text(_judulKosong, style: t.bodyMedium),
        kosong: KeadaanKosong(
          ikon: Icons.straighten_outlined,
          judul: _judulKosong,
          keterangan: _keteranganKosong,
        ),
        butir: (context, a) => KartuAlat(alat: a, onTap: () => _bukaAlat(a)),
      ),
    );
  }

  /// Dalam 31–60 / 61–90 hari: belum ada saringannya di server, jadi daftar
  /// diambil dari hitungan Beranda ([jatuhTempoProvider]) dan dicari di HP.
  Widget _dariAplikasi() {
    final async = ref.watch(jatuhTempoProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(jatuhTempoProvider);
        await ref.read(jatuhTempoProvider.future);
      },
      child: async.when(
        loading: () => const Memuat(),
        error: (e, _) => KeadaanGalat(
          galat: e,
          cobaLagi: () => ref.invalidate(jatuhTempoProvider),
        ),
        data: (r) {
          final kata = _kata.toLowerCase();
          final alat = [
            for (final a in _filter.dari(r))
              if (kata.isEmpty ||
                  [
                    a.nama,
                    a.merk,
                    a.model,
                    a.serial,
                    a.noIdentifikasi,
                  ].any((x) => x != null && x.toLowerCase().contains(kata)))
                a,
          ];
          if (alat.isEmpty) {
            return KeadaanKosong(
              ikon: Icons.event_available_outlined,
              judul: _kata.isEmpty ? _judulKosong : 'Tidak ada yang cocok',
              keterangan: _kata.isEmpty
                  ? 'Tidak ada alat yang perlu dikalibrasi ulang pada rentang '
                        'ini.'
                  : _keteranganKosong,
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: denganTepiBawah(
              context,
              const EdgeInsets.fromLTRB(jarak, 4, jarak, 32),
            ),
            itemCount: alat.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                KartuAlat(alat: alat[i], onTap: () => _bukaAlat(alat[i])),
          );
        },
      ),
    );
  }
}
