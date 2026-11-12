import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../models/status_berlaku.dart';
import '../../providers/data_provider.dart';
import '../../providers/koneksi_provider.dart';
import '../../widgets/daftar_berhalaman.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kartu_alat.dart';
import '../../widgets/keadaan_galat.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/kolom_cari.dart';
import '../../widgets/kerangka.dart';
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
  String _kata = '';
  late FilterAlat _filter = widget.filterAwal;

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
    return HalamanSidik(
      judul: 'Alat saya',
      isi: Column(
        children: [
          KolomCari(
            petunjuk: 'Cari nama, merk, atau nomor seri',
            onCari: (kata) => setState(() => _kata = kata),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Spasi.lg,
              vertical: Spasi.sm,
            ),
            child: Row(
              children: [
                for (final f in FilterAlat.values)
                  Padding(
                    padding: const EdgeInsets.only(right: Spasi.sm),
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
    final t = context.teks;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(daftarAlatProvider(kunci));
        await ref.read(daftarAlatProvider(kunci).future);
      },
      child: DaftarBerhalaman<Alat>(
        async: async,
        namaButir: 'alat',
        padding: Spasi.daftar(context),
        muatLagi: ({ulangiGalat = false}) => ref
            .read(daftarAlatProvider(kunci).notifier)
            .muatLagi(ulangiGalat: ulangiGalat),
        cobaLagi: () => ref.invalidate(daftarAlatProvider(kunci)),
        kepala: [
          if (koneksi.offline && koneksi.dataTerakhir != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Spasi.sm),
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
            padding: Spasi.daftar(context),
            itemCount: alat.length,
            separatorBuilder: (_, _) => const SizedBox(height: Spasi.md),
            itemBuilder: (context, i) =>
                KartuAlat(alat: alat[i], onTap: () => _bukaAlat(alat[i])),
          );
        },
      ),
    );
  }
}
