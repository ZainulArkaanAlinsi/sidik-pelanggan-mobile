// Perkakas bersama test layar & alur: penyimpan palsu di memori (tanpa
// Keystore/channel platform) dan pembungkus aplikasi dengan override standar.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/penyimpan_cache.dart';
import 'package:sidik_pelanggan/core/penyimpan_pratinjau.dart';
import 'package:sidik_pelanggan/core/penyimpan_perangkat.dart';
import 'package:sidik_pelanggan/core/penyimpan_sesi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/providers/pembaruan_provider.dart';
import 'package:sidik_pelanggan/providers/perangkat_provider.dart';
import 'package:sidik_pelanggan/providers/push_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';
import 'package:sidik_pelanggan/services/pemasang_apk.dart';
import 'package:sidik_pelanggan/services/push_pelanggan.dart';

/// Penyimpan sesi di memori: token & perusahaan yang ditulis aplikasi bisa
/// dibaca balik oleh test.
class PenyimpanSesiMemori extends PenyimpanSesi {
  PenyimpanSesiMemori({this.tokenAwal, this.perusahaanAwal, this.penggunaAwal});

  String? tokenAwal;
  int? perusahaanAwal;
  int? penggunaAwal;

  @override
  Future<String?> token() async => tokenAwal;

  @override
  Future<int?> perusahaanId() async => perusahaanAwal;

  @override
  Future<int?> penggunaId() async => penggunaAwal;

  @override
  Future<void> simpanPengguna(int id) async => penggunaAwal = id;

  @override
  Future<void> simpanToken(String token) async => tokenAwal = token;

  @override
  Future<void> simpanPerusahaan(int? id) async => perusahaanAwal = id;

  @override
  Future<void> hapus() async {
    tokenAwal = null;
    perusahaanAwal = null;
    penggunaAwal = null;
  }
}

/// Penyimpan pratinjau PDF di memori: tanpa `path_provider` (plugin platform)
/// dan tanpa I/O berkas, yang tidak pernah selesai di dalam `testWidgets`
/// (FakeAsync) dan membuat `pumpAndSettle` kehabisan waktu. Mencatat apa yang
/// disimpan dan berapa kali dibersihkan.
class PenyimpanPratinjauMemori extends PenyimpanPratinjau {
  PenyimpanPratinjauMemori() : super(akar: () async => Directory.systemTemp);

  /// ID sertifikat → byte yang disimpan.
  final Map<int, List<int>> isi = {};
  int dibersihkan = 0;

  @override
  Future<File> simpan(int idSertifikat, Uint8List byte) async {
    isi[idSertifikat] = byte;
    return File(
      '${PenyimpanPratinjau.namaFolder}/sertifikat-$idSertifikat.pdf',
    );
  }

  @override
  Future<void> bersihkan() async {
    dibersihkan++;
    isi.clear();
  }
}

/// Perangkat yang sudah melewati layar sambutan.
class PerangkatSudahLihatSambutan extends PenyimpanPerangkat {
  @override
  Future<bool> sudahLihatSambutan() async => true;

  @override
  Future<String?> tema() async => null;
}

/// Override standar yang mematikan semua yang butuh platform (Keystore,
/// Firebase, pemasang APK, cek rilis GitHub, folder cache). [tambahan]
/// dipasang PALING AKHIR; provider yang sudah dioverride di sini tidak boleh
/// diulang di [tambahan] (Riverpod menolak override ganda): pakai parameter
/// bernama untuk yang tersedia, mis. [pratinjau].
List<Override> overrideDasar({
  PenyimpanSesi? sesi,
  bool pembaruanAktif = false,
  PenyimpanPratinjau? pratinjau,
  List<Override> tambahan = const [],
}) => [
  pemasangApkProvider.overrideWithValue(const PemasangApkMati()),
  pembaruanAktifProvider.overrideWithValue(pembaruanAktif),
  penyimpanCacheProvider.overrideWithValue(PenyimpanCacheMemori()),
  penyimpanPratinjauProvider.overrideWithValue(
    pratinjau ?? PenyimpanPratinjauMemori(),
  ),
  penyimpanSesiProvider.overrideWithValue(sesi ?? PenyimpanSesiMemori()),
  penyimpanPerangkatProvider.overrideWithValue(PerangkatSudahLihatSambutan()),
  infoPaketProvider.overrideWith((ref) async => (versi: '1.0.0', build: '1')),
  izinNotifikasiProvider.overrideWith(
    (ref) async => IzinNotifikasi.tidakTersedia,
  ),
  ...tambahan,
];

/// [anak] di dalam `ProviderScope` + `MaterialApp` bertema aplikasi.
Widget bungkus(Widget anak, {List<Override> override = const []}) =>
    ProviderScope(
      overrides: override,
      child: MaterialApp(theme: TemaSidik.terang, home: anak),
    );

/// Halaman kosong untuk daftar berhalaman.
Halaman<T> halamanUji<T>(List<T> isi) =>
    Halaman(isi: isi, halaman: 1, halamanTerakhir: 1, total: isi.length);

/// Layanan palsu dengan jawaban AMAN untuk semua tab Rangka (beranda kosong,
/// daftar kosong), supaya layar yang dipasang tidak menembak jaringan sungguhan.
/// Subkelas menimpa yang ingin diuji.
class LayananUji extends LayananPelanggan {
  LayananUji() : super(ApiPelanggan());

  @override
  Future<Beranda> beranda() async => Beranda.dariJson({
    'data': {
      'perusahaan': {'nama': 'PT Contoh Pelanggan'},
      'ringkasan': {
        'jumlah_alat': 0,
        'lewat_jatuh_tempo': 0,
        'segera_jatuh_tempo': 0,
        'notifikasi_belum_dibaca': 0,
      },
    },
    'meta': {'jendela_segera_hari': 30},
  });

  @override
  Future<Halaman<Alat>> daftarAlat({
    String? cari,
    String? saring,
    int halaman = 1,
  }) async => halamanUji(<Alat>[]);

  @override
  Future<List<Alat>> alatMenujuJatuhTempo({
    int sampaiHari = 90,
    int maksHalaman = 10,
  }) async => <Alat>[];

  @override
  Future<Halaman<Sertifikat>> daftarSertifikat({
    String? cari,
    bool termasukDigantikan = false,
    int halaman = 1,
  }) async => halamanUji(<Sertifikat>[]);

  @override
  Future<Halaman<Notifikasi>> daftarNotifikasi({int halaman = 1}) async =>
      halamanUji(<Notifikasi>[]);

  @override
  Future<int> jumlahNotifikasiBelumDibaca() async => 0;
}

/// Sesi tetap untuk layar yang membaca perusahaan aktif; tidak menyentuh
/// penyimpanan maupun jaringan.
class SesiTetap extends SesiController {
  SesiTetap(this._sesi);

  final Sesi _sesi;

  @override
  Future<Sesi?> build() async => _sesi;
}

/// Anggota PT Contoh Pelanggan (id 3) dengan [peran] di sana.
Sesi sesiUji({String peran = 'staf'}) => Sesi(
  akun: Akun.dariJson({
    'id': 7,
    'nama': 'Budi Anggota',
    'email': 'budi@contoh.test',
    'status': 'aktif',
    'butuh_verifikasi': false,
    'keanggotaan': [
      {
        'customer_id': 3,
        'nama_perusahaan': 'PT Contoh Pelanggan',
        'peran': peran,
      },
    ],
  }),
  perusahaanId: 3,
);

Override sesiTetap(Sesi sesi) =>
    sesiProvider.overrideWith(() => SesiTetap(sesi));
