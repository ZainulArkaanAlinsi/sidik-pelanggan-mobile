import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../models/status_berlaku.dart';
import '../../providers/data_provider.dart';
import '../../providers/koneksi_provider.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/keadaan_galat.dart';
import '../../widgets/kolom_cari_utuh.dart';
import '../../widgets/saringan_pil.dart';
import '../../widgets/status_tampil.dart';
import 'alat_detail_screen.dart';
import 'daftar_alat_bagian.dart';

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

/// Semua alat perusahaan, satu layar ("Alat saya"), dengan status masa
/// berlakunya (Berlaku, Segera jatuh tempo, Lewat jadwal, …). Yang paling
/// mendesak di atas (urutan dari server). Cari nama, merk, atau nomor seri;
/// saring menurut kelompok jatuh tempo; tarik layar untuk memuat ulang.
///
/// Susunan: kepala (judul + lencana "N alat") → [KolomCariUtuh] →
/// [SaringanPil] (tetap di atas daftar) → daftar [KartuAlat] (kartu ringkas:
/// nama, merk dan seri, lokasi, status, "Lihat detail"; alat nonaktif tanpa
/// hitung mundur). Empat keadaan: memuat (kerangka statis), kosong (kartu
/// kosong; "belum ada alat" dan hasil cari kosong berbeda kata dan ikon; satu
/// tombol "Tampilkan semua alat" bila saringan yang menyempitkan), galat
/// (`KeadaanGalat` + "Coba lagi"), tanpa koneksi (catatan di atas daftar yang
/// tersimpan).
///
/// Jumlah di layar hanya dari data yang terbaca: pil kepala dari daftar yang
/// sedang tampil, bulatan saringan dari ringkasan Beranda (`berandaProvider`)
/// dan hitungan jatuh tempo (`jatuhTempoProvider`; "Semua" tanpa bulatan,
/// alasannya di `_jumlahPil`). Bagian yang masih memuat atau gagal tidak
/// digambar, bukan terbaca "0". Tarik-untuk-muat-ulang menyegarkan daftar DAN
/// kedua sumber bulatan itu.
class DaftarAlatScreen extends ConsumerStatefulWidget {
  const DaftarAlatScreen({super.key, this.filterAwal = FilterAlat.semua});

  final FilterAlat filterAwal;

  @override
  ConsumerState<DaftarAlatScreen> createState() => _DaftarAlatScreenState();
}

class _DaftarAlatScreenState extends ConsumerState<DaftarAlatScreen> {
  String _kata = '';
  late FilterAlat _filter = widget.filterAwal;

  /// Baris saringan boleh digeser dengan mouse, stylus, dan trackpad juga
  /// (bawaan Flutter hanya sentuh): di layar lebar dan desktop tanpanya
  /// pilihan di luar layar tidak terjangkau.
  static const _perangkatGeser = {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };

  KunciAlat get _kunci => (cari: _kata, saring: _filter.saringServer);

  bool get _tanpaAlat => _kata.isEmpty && _filter == FilterAlat.semua;

  String get _judulKosong =>
      _kata.isNotEmpty ? 'Tidak ada yang cocok' : _filter.judulKosong;

  String get _keteranganKosong => _tanpaAlat
      ? 'Alat yang pernah dikalibrasi di PT Sidik muncul di sini.'
      : 'Coba kata lain atau pilih "Semua".';

  IconData get _ikonKosong => _tanpaAlat
      ? Icons.straighten_outlined
      : (_kata.isNotEmpty
            ? Icons.search_off_outlined
            : Icons.event_available_outlined);

  void _bukaAlat(Alat a) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => AlatDetailScreen(id: a.id)));

  /// Alat di rentang yang dihitung di HP (31–60 / 61–90 hari), sesudah dicari.
  List<Alat> _saringLokal(RingkasanJatuhTempo r) {
    final kata = _kata.toLowerCase();
    return [
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
  }

  /// Jumlah alat di daftar yang sedang tampil; null bila belum terbaca
  /// (memuat, gagal, atau halaman server belum memberi total yang bisa
  /// dipercaya).
  int? _jumlahTampil() {
    if (_filter.dariServer) {
      final d = ref.watch(daftarAlatProvider(_kunci)).value;
      return d == null ? null : jumlahTerbaca(d);
    }
    final r = ref.watch(jatuhTempoProvider).value;
    return r == null ? null : _saringLokal(r).length;
  }

  /// Bulatan jumlah di saringan. Lewat jadwal / Dalam 30 hari dari ringkasan
  /// server di Beranda, 31–60 dan 61–90 dari hitungan jatuh tempo yang sama
  /// dengan daftarnya. Saringan yang sedang dipilih (tanpa kata cari) memakai
  /// jumlah daftar yang tampil, supaya bulatannya tidak berbeda dari daftar di
  /// bawahnya. Sumber yang belum terbaca = null (tanpa bulatan).
  ///
  /// "Semua" TIDAK punya bulatan: `jumlah_alat` di ringkasan Beranda hanya
  /// menghitung alat aktif, sedangkan `GET /alat` tanpa saringan memuat semua
  /// status, jadi dua sumber itu memberi dua angka untuk satu kata dan bulatan
  /// berganti angka begitu pilnya dipilih. Jumlah seluruh alat tetap terbaca di
  /// pil kepala ("N alat") yang berasal dari daftar yang tampil.
  int? _jumlahPil(
    FilterAlat f,
    Beranda? beranda,
    RingkasanJatuhTempo? jatuhTempo,
    int? jumlahTampil,
  ) {
    if (f == FilterAlat.semua) return null;
    if (f == _filter && _kata.isEmpty && jumlahTampil != null) {
      return jumlahTampil;
    }
    return switch (f) {
      FilterAlat.semua => null,
      FilterAlat.lewatJadwal => beranda?.lewatJatuhTempo,
      FilterAlat.hari30 => beranda?.segeraJatuhTempo,
      FilterAlat.hari60 => jatuhTempo?.kelompok2.length,
      FilterAlat.hari90 => jatuhTempo?.kelompok3.length,
    };
  }

  List<PilihanPil> _pilihan(int? jumlahTampil) {
    final beranda = ref.watch(berandaProvider).value;
    final jatuhTempo = ref.watch(jatuhTempoProvider).value;
    return [
      for (final f in FilterAlat.values)
        PilihanPil(
          f.label,
          jumlah: _jumlahPil(f, beranda, jatuhTempo, jumlahTampil),
          nada: switch (f) {
            FilterAlat.lewatJadwal => NadaStatus.gagal,
            FilterAlat.hari30 => NadaStatus.awas,
            _ => null,
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final jumlah = _jumlahTampil();
    return HalamanSidik(
      judulKustom: const _JudulLayar(),
      aksi: [if (jumlah != null) PilJumlahAlat(jumlah: jumlah)],
      isi: Column(
        children: [
          KolomCariUtuh(
            petunjuk: 'Cari nama, merk, atau nomor seri',
            onCari: (kata) => setState(() => _kata = kata),
          ),
          Semantics(
            container: true,
            explicitChildNodes: true,
            label: 'Saring alat',
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false, dragDevices: _perangkatGeser),
              child: Scrollbar(
                child: SaringanPil(
                  pilihan: _pilihan(jumlah),
                  terpilih: FilterAlat.values.indexOf(_filter),
                  onPilih: (i) =>
                      setState(() => _filter = FilterAlat.values[i]),
                ),
              ),
            ),
          ),
          Expanded(child: _filter.dariServer ? _dariServer() : _dariAplikasi()),
        ],
      ),
    );
  }

  /// Catatan "tanpa koneksi" di atas daftar yang tersimpan (kosong bila
  /// tersambung atau bila tidak ada waktu data terakhir).
  List<Widget> _kepalaLuring(KeadaanKoneksi koneksi) => [
    if (koneksi.offline && koneksi.dataTerakhir != null)
      CatatanLuring(
        teks:
            'Tanpa koneksi. Terakhir diperbarui '
            '${Format.jamAtauTanggal(koneksi.dataTerakhir!)}',
      ),
  ];

  /// Ubin kosong di dalam daftar bergulir (tarik-untuk-muat-ulang tetap jalan).
  Widget _kosong(List<Widget> kepala, {String? keterangan}) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: Spasi.daftar(context),
    children: [
      ...kepala,
      UbinKosongAlat(
        ikon: _ikonKosong,
        judul: _judulKosong,
        keterangan: keterangan ?? _keteranganKosong,
        // Saringan yang menyempitkan daftar (tanpa kata cari): satu ketukan
        // kembali ke "Semua". Dengan kata cari, kata itu milik kolom cari.
        aksi: _kata.isEmpty && _filter != FilterAlat.semua
            ? 'Tampilkan semua alat'
            : null,
        onAksi: _kata.isEmpty && _filter != FilterAlat.semua
            ? () => setState(() => _filter = FilterAlat.semua)
            : null,
      ),
    ],
  );

  /// Tarik-untuk-muat-ulang: bulatan saringan membaca ringkasan Beranda dan
  /// hitungan jatuh tempo, jadi keduanya ikut disegarkan (cara yang sama dengan
  /// Beranda). Tanpa ini daftarnya baru sedangkan bulatannya tetap angka lama.
  void _segarkanHitungan() {
    ref.invalidate(berandaProvider);
    ref.invalidate(jatuhTempoProvider);
  }

  /// Semua / Lewat jadwal / Dalam 30 hari: disaring dan dicari SERVER, 20 per
  /// halaman, halaman berikut dimuat saat daftar digulir.
  Widget _dariServer() {
    final kunci = _kunci;
    final async = ref.watch(daftarAlatProvider(kunci));
    final koneksi = ref.watch(koneksiProvider);
    return RefreshIndicator(
      onRefresh: () async {
        _segarkanHitungan();
        ref.invalidate(daftarAlatProvider(kunci));
        await ref.read(daftarAlatProvider(kunci).future);
      },
      child: async.when(
        loading: () => const KerangkaAlat(),
        error: (e, _) => KeadaanGalat(
          galat: e,
          cobaLagi: () => ref.invalidate(daftarAlatProvider(kunci)),
        ),
        data: (d) {
          final kepala = _kepalaLuring(koneksi);
          if (d.isi.isEmpty) return _kosong(kepala);
          return DaftarUbinAlat(
            alat: d.isi,
            onBuka: _bukaAlat,
            kepala: kepala,
            ujung: UjungDaftarAlat(
              data: d,
              muatLagi: ({ulangiGalat = false}) => ref
                  .read(daftarAlatProvider(kunci).notifier)
                  .muatLagi(ulangiGalat: ulangiGalat),
            ),
          );
        },
      ),
    );
  }

  /// Dalam 31–60 / 61–90 hari: belum ada saringannya di server, jadi daftar
  /// diambil dari hitungan Beranda ([jatuhTempoProvider]) dan dicari di HP.
  Widget _dariAplikasi() {
    final async = ref.watch(jatuhTempoProvider);
    final koneksi = ref.watch(koneksiProvider);
    return RefreshIndicator(
      onRefresh: () async {
        _segarkanHitungan();
        await ref.read(jatuhTempoProvider.future);
      },
      child: async.when(
        loading: () => const KerangkaAlat(),
        error: (e, _) => KeadaanGalat(
          galat: e,
          cobaLagi: () => ref.invalidate(jatuhTempoProvider),
        ),
        data: (r) {
          final kepala = _kepalaLuring(koneksi);
          final alat = _saringLokal(r);
          if (alat.isEmpty) {
            return _kosong(
              kepala,
              keterangan: _kata.isEmpty
                  ? 'Tidak ada alat yang perlu dikalibrasi ulang pada rentang '
                        'ini.'
                  : _keteranganKosong,
            );
          }
          return DaftarUbinAlat(alat: alat, onBuka: _bukaAlat, kepala: kepala);
        },
      ),
    );
  }
}

/// Judul kepala: "Alat saya" 24/30, satu baris, dijepit pada huruf besar
/// ([SkalaHuruf.batasBesar]); pembaca layar menerimanya sebagai judul.
class _JudulLayar extends StatelessWidget {
  const _JudulLayar();

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: MediaQuery.withClampedTextScaling(
      maxScaleFactor: SkalaHuruf.batasBesar,
      child: Text(
        'Alat saya',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.teks.displaySmall,
      ),
    ),
  );
}
