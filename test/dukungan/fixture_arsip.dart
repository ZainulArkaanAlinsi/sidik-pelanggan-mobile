// Fixture arsip sertifikat (`GET /sertifikat/garis-waktu`) dan layanan palsunya.
// Bentuk JSON mengikuti contoh di kontrak "Arsip & Pencarian" §4 (aplikasi
// Pelanggan); data sintetis, tidak ada nama atau nomor pelanggan sungguhan.
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/konfigurasi.dart';
import 'package:sidik_pelanggan/models/arsip.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';

import 'dukungan.dart';
import 'fixture_fitur.dart';

Map<String, dynamic> kelompokJson(
  String kunci,
  String label,
  int jumlah, {
  required String mulai,
  required String selesai,
  required Map<String, Object> telusuri,
}) => {
  'kunci': kunci,
  'label': label,
  'jumlah': jumlah,
  'mulai': mulai,
  'selesai': selesai,
  'telusuri': telusuri,
};

/// Satu jawaban garis waktu. `meta` bawaan = tanpa halaman lain (tingkat selain
/// hari: `total` 0).
Map<String, dynamic> jawabanArsip({
  required String tingkat,
  Map<String, Object> induk = const {},
  required int total,
  List<Map<String, dynamic>> kelompok = const [],
  List<Map<String, dynamic>> item = const [],
  Map<String, Object>? meta,
}) => {
  'data': {
    'tingkat': tingkat,
    'induk': induk,
    'total_dokumen': total,
    'kelompok': kelompok,
    'item': item,
  },
  'meta':
      meta ?? {'current_page': 1, 'last_page': 1, 'per_page': 20, 'total': 0},
};

/// Baris `item[]` tingkat hari: baris `/sertifikat` + `nomor_order`.
Map<String, dynamic> itemArsipJson(
  int id,
  String nomor, {
  String tanggal = '2026-11-12',
  String nama = 'Busur Derajat',
  String? serial = 'PL-0001',
  String? nomorOrder = 'PO-2026-0042',
  String status = 'berlaku',
}) => {
  'id': id,
  'nomor': nomor,
  'status': status,
  'diterbitkan_pada': tanggal,
  'berlaku_sampai': '2027-11-12',
  'keputusan': null,
  'alat': {
    'id': id,
    'nama': nama,
    'merk': null,
    'model': null,
    'serial': serial,
  },
  'revisi_dari': null,
  'digantikan_oleh': null,
  'dibatalkan_pada': null,
  'catatan_pelanggan': null,
  'bisa_diunduh': false,
  'tautan_verifikasi': 'http://localhost/verify/uji$id',
  'nomor_order': nomorOrder,
};

/// Tingkat tahun: dua tahun, terbaru dulu (kontrak §3, jumlah 5 dan 1).
Map<String, dynamic> arsipTahun() => jawabanArsip(
  tingkat: 'tahun',
  total: 6,
  kelompok: [
    kelompokJson(
      '2026',
      '2026',
      5,
      mulai: '2026-01-01',
      selesai: '2026-12-31',
      telusuri: {'tingkat': 'bulan', 'tahun': 2026},
    ),
    kelompokJson(
      '2025',
      '2025',
      1,
      mulai: '2025-01-01',
      selesai: '2025-12-31',
      telusuri: {'tingkat': 'bulan', 'tahun': 2025},
    ),
  ],
);

/// Tingkat bulan untuk 2026: November (4) dan Oktober (1).
Map<String, dynamic> arsipBulan() => jawabanArsip(
  tingkat: 'bulan',
  induk: {'tahun': 2026},
  total: 5,
  kelompok: [
    kelompokJson(
      '2026-11',
      'November 2026',
      4,
      mulai: '2026-11-01',
      selesai: '2026-11-30',
      telusuri: {'tingkat': 'pekan', 'tahun': 2026, 'bulan': 11},
    ),
    kelompokJson(
      '2026-10',
      'Oktober 2026',
      1,
      mulai: '2026-10-01',
      selesai: '2026-10-31',
      telusuri: {'tingkat': 'pekan', 'tahun': 2026, 'bulan': 10},
    ),
  ],
);

/// Tingkat pekan untuk November 2026: pekan 44 hanya berisi 1 Nov (dipotong di
/// batas bulan oleh server).
Map<String, dynamic> arsipPekanNovember() => jawabanArsip(
  tingkat: 'pekan',
  induk: {'tahun': 2026, 'bulan': 11},
  total: 4,
  kelompok: [
    kelompokJson(
      '2026-W46',
      'Pekan 46 (9–15 Nov 2026)',
      3,
      mulai: '2026-11-09',
      selesai: '2026-11-15',
      telusuri: {'tingkat': 'hari', 'tahun': 2026, 'bulan': 11, 'pekan': 46},
    ),
    kelompokJson(
      '2026-W44',
      'Pekan 44 (1 Nov 2026)',
      1,
      mulai: '2026-11-01',
      selesai: '2026-11-01',
      telusuri: {'tingkat': 'hari', 'tahun': 2026, 'bulan': 11, 'pekan': 44},
    ),
  ],
);

/// Tingkat hari untuk pekan 46: tiga sertifikat di dua hari. [meta] untuk
/// memaginasi `item`.
Map<String, dynamic> arsipHari({
  List<Map<String, dynamic>>? item,
  Map<String, Object>? meta,
}) {
  final isi =
      item ??
      [
        itemArsipJson(7, 'ISO/CNT/0003', tanggal: '2026-11-12'),
        itemArsipJson(
          6,
          'ISO/CNT/0002',
          tanggal: '2026-11-12',
          nama: 'Micrometer',
          serial: 'SN-0205',
          nomorOrder: null,
        ),
        itemArsipJson(
          5,
          'ISO/CNT/0001',
          tanggal: '2026-11-09',
          nama: 'Jangka Sorong',
          serial: 'SN-0204',
        ),
      ];
  return jawabanArsip(
    tingkat: 'hari',
    induk: {'tahun': 2026, 'bulan': 11, 'pekan': 46},
    total: 3,
    kelompok: [
      kelompokJson(
        '2026-11-12',
        'Kamis, 12 Nov 2026',
        2,
        mulai: '2026-11-12',
        selesai: '2026-11-12',
        telusuri: {
          'tahun': 2026,
          'bulan': 11,
          'pekan': 46,
          'tingkat': 'hari',
          'tanggal': '2026-11-12',
        },
      ),
      kelompokJson(
        '2026-11-09',
        'Senin, 9 Nov 2026',
        1,
        mulai: '2026-11-09',
        selesai: '2026-11-09',
        telusuri: {
          'tahun': 2026,
          'bulan': 11,
          'pekan': 46,
          'tingkat': 'hari',
          'tanggal': '2026-11-09',
        },
      ),
    ],
    item: isi,
    meta:
        meta ??
        {
          'current_page': 1,
          'last_page': 1,
          'per_page': 20,
          'total': isi.length,
        },
  );
}

/// Layanan palsu untuk layar arsip: mencatat tiap permintaan garis waktu dan
/// pencarian (daftar sertifikat), lalu menjawab lewat [jawab] dan [jawabCari].
/// Selebihnya jawaban aman bawaan [LayananUji].
class LayananArsipPalsu extends LayananUji {
  LayananArsipPalsu(this.jawab, {this.jawabCari});

  /// Isi jawaban menurut penelusuran; boleh melempar [GalatApi].
  final Future<HasilArsip> Function(ParameterArsip parameter, int halaman)
  jawab;

  final panggilan = <({ParameterArsip parameter, int halaman})>[];

  /// Isi jawaban pencarian (`GET /sertifikat?q=`); boleh melempar [GalatApi].
  /// Tanpa ini pencarian dijawab kosong.
  final Future<Halaman<Sertifikat>> Function(String cari, int halaman)?
  jawabCari;

  /// Tiap permintaan daftar sertifikat: kata cari, halaman, dan apakah
  /// `termasuk_digantikan` dikirim.
  final cari = <({String? cari, int halaman, bool termasukDigantikan})>[];

  /// Jawaban detail sertifikat yang diketuk dari daftar arsip.
  final detail = <int>[];

  @override
  Future<HasilArsip> garisWaktuSertifikat(
    ParameterArsip parameter, {
    int halaman = 1,
  }) {
    panggilan.add((parameter: parameter, halaman: halaman));
    return jawab(parameter, halaman);
  }

  @override
  Future<Halaman<Sertifikat>> daftarSertifikat({
    String? cari,
    bool termasukDigantikan = false,
    int halaman = 1,
  }) {
    this.cari.add((
      cari: cari,
      halaman: halaman,
      termasukDigantikan: termasukDigantikan,
    ));
    final jawab = jawabCari;
    if (jawab == null || cari == null || cari.isEmpty) {
      return Future.value(halamanUji(<Sertifikat>[]));
    }
    return jawab(cari, halaman);
  }

  @override
  Future<Sertifikat> sertifikat(int id) async {
    detail.add(id);
    return Sertifikat.dariJson(sertifikatJson(id, 'DETAIL/$id'));
  }
}

/// Server palsu yang juga menjawab `GET /sertifikat/garis-waktu` menurut
/// perusahaan di header `X-Perusahaan-Id`, seperti server sungguhan: perusahaan
/// yang tidak dikenal = 404 bawaan Laravel.
class ServerArsip extends ServerFitur {
  ServerArsip(super.data, this.arsip);

  /// Jawaban per perusahaan, menurut query `tingkat` (kosong = tahun).
  final Map<int, Map<String, Map<String, dynamic>>> arsip;

  @override
  Future<http.Response> tangani(http.Request r) async {
    final jalur = r.url.path.replaceFirst(Konfigurasi.prefix, '');
    final kata = (r.url.queryParameters['q'] ?? '').toLowerCase();
    if (jalur == '/sertifikat' && kata.isNotEmpty) {
      // Pencarian daftar sertifikat: nomor, nama alat, atau nomor seri
      // mengandung kata (pencocokan harfiah, seperti server).
      permintaan.add(r);
      final p = data[int.tryParse(r.headers['X-Perusahaan-Id'] ?? '')];
      if (r.headers['Authorization'] != 'Bearer ${ServerFitur.token}') {
        return http.Response(jsonEncode({'kode': 'sesi_berakhir'}), 401);
      }
      final cocok = [
        for (final s in p?.sertifikat ?? const <Map<String, dynamic>>[])
          if ('${s['nomor']} ${(s['alat'] as Map)['nama']} '
                  '${(s['alat'] as Map)['serial']}'
              .toLowerCase()
              .contains(kata))
            s,
      ];
      return http.Response(
        jsonEncode({
          'data': cocok,
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'total': cocok.length,
            'per_page': 20,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (jalur != '/sertifikat/garis-waktu') return super.tangani(r);
    permintaan.add(r);
    if (r.headers['Authorization'] != 'Bearer ${ServerFitur.token}') {
      return http.Response(jsonEncode({'kode': 'sesi_berakhir'}), 401);
    }
    final milik = arsip[int.tryParse(r.headers['X-Perusahaan-Id'] ?? '')];
    if (milik == null) {
      return http.Response(
        jsonEncode({'message': 'No query results for model [App\\Models\\X].'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    }
    final jawaban = milik[r.url.queryParameters['tingkat'] ?? 'tahun'];
    return http.Response(
      jsonEncode(jawaban ?? jawabanArsip(tingkat: 'tahun', total: 0)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
