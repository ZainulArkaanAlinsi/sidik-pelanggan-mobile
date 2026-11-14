// Fixture dan server palsu untuk fitur Beranda ringkasan, daftar alat dengan
// status, riwayat sertifikat, dan pratinjau PDF. Bentuk JSON mengikuti
// `docs/kontrak-api-pelanggan.md` dan resource `*PelangganResource` di API.
//
// Server palsu memilih data menurut header `X-Perusahaan-Id` — seperti server
// sungguhan — jadi test "ganti perusahaan" membuktikan bahwa yang tampil
// benar-benar mengikuti perusahaan aktif, bukan sekadar mengganti teks.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/konfigurasi.dart';
import 'package:sidik_pelanggan/core/penyimpan_pratinjau.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/providers/data_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';

import 'dukungan.dart';

/// Font asli aplikasi + data tanggal Indonesia. Tanpa font asli, Ahem
/// (bawaan flutter_test) selebar kotak dan lencana "meluap" yang tidak terjadi
/// di HP; dengan font asli, luapan di 320 dp / 1,3× ketahuan di test.
Future<void> siapkanTesFitur() async {
  await initializeDateFormatting('id_ID');
  final inter = FontLoader('Inter');
  for (final f in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    inter.addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/Inter-$f.ttf').readAsBytesSync(),
        ),
      ),
    );
  }
  await inter.load();
}

/// Tanggal "hari ini" yang dipakai semua test fitur ini.
final hariIniUji = DateTime(2026, 11, 12, 9);

/// `YYYY-MM-DD` untuk [hari] hari setelah [hariIniUji] (negatif = sebelum).
String tanggalUji(int hari) {
  final t = DateTime(
    hariIniUji.year,
    hariIniUji.month,
    hariIniUji.day,
  ).add(Duration(days: hari));
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${dua(t.month)}-${dua(t.day)}';
}

Map<String, dynamic> alatJson(
  int id,
  String nama, {
  int? hari,
  String status = 'terkalibrasi',
  String? merk = 'Mitutoyo',
  List<Map<String, dynamic>> riwayat = const [],
  Map<String, dynamic>? terakhir,
  String? model,
  String? serial,
  // `sedang_dikerjakan` (kontrak API §14.2). `null` = kuncinya tidak dikirim
  // (server lama); kirim `{}`-peta untuk objeknya.
  Map<String, dynamic>? sedangDikerjakan,
  bool kunciSedangDikerjakan = false,
}) => {
  'id': id,
  'nama': nama,
  'merk': merk,
  'model': model,
  'serial': serial ?? 'SN-$id',
  'lokasi': 'Gudang $id',
  'tanggal_jatuh_tempo': hari == null ? null : tanggalUji(hari),
  'hari_ke_jatuh_tempo': hari,
  'status_alat': status,
  'sertifikat_terakhir': terakhir,
  if (riwayat.isNotEmpty) 'riwayat_sertifikat': riwayat,
  if (sedangDikerjakan != null || kunciSedangDikerjakan)
    'sedang_dikerjakan': sedangDikerjakan,
};

/// `sedang_dikerjakan` seperti yang dikirim server (lima kunci).
Map<String, dynamic> sedangDikerjakanJson({
  int paketId = 21,
  int itemId = 981,
  String nomorOrder = 'ORD/ALFA/2026/0021',
  String tahap = 'dikalibrasi',
  String label = 'Sedang dikalibrasi',
}) => {
  'paket_id': paketId,
  'order_item_id': itemId,
  'nomor_order': nomorOrder,
  'tahap': tahap,
  'tahap_label': label,
};

/// Item `alat[]` di paket (kunci `equipment_id` ikut bila [equipmentId]).
Map<String, dynamic> alatPaketJson(
  int itemId,
  String nama, {
  String tahap = 'dikalibrasi',
  String label = 'Sedang dikalibrasi',
  int? equipmentId,
  String? merk = 'Mitutoyo',
  String? serial,
}) => {
  'id': itemId,
  'equipment_id': ?equipmentId,
  'nama': nama,
  'merk': merk,
  'serial': serial ?? 'SN-$itemId',
  'tahap': tahap,
  'tahap_label': label,
  'diserahkan_kepada': null,
  'sertifikat_id': null,
};

Map<String, dynamic> sertifikatJson(
  int id,
  String nomor, {
  int alatId = 1,
  String namaAlat = 'Jangka Sorong',
  int diterbitkan = -300,
  int? berlakuSampai = 65,
  String status = 'berlaku',
  String? keputusan = 'PASS',
  Map<String, dynamic>? digantikanOleh,
  String? revisiDari,
  int? dibatalkanPada,
  bool bisaDiunduh = true,
}) => {
  'id': id,
  'nomor': nomor,
  'status': status,
  'diterbitkan_pada': tanggalUji(diterbitkan),
  'berlaku_sampai': berlakuSampai == null ? null : tanggalUji(berlakuSampai),
  'keputusan': keputusan,
  'alat': {
    'id': alatId,
    'nama': namaAlat,
    'merk': 'Mitutoyo',
    'serial': 'SN-1',
  },
  'revisi_dari': revisiDari == null ? null : {'id': 0, 'nomor': revisiDari},
  'digantikan_oleh': digantikanOleh,
  'dibatalkan_pada': dibatalkanPada == null ? null : tanggalUji(dibatalkanPada),
  'bisa_diunduh': bisaDiunduh,
  'tautan_verifikasi': null,
};

Map<String, dynamic> paketJson(
  int id,
  String nomor, {
  String tahap = 'dikalibrasi',
  String label = 'Sedang dikalibrasi',
  List<Map<String, dynamic>> alat = const [],
  int? jumlahAlat,
  int? jumlahSelesai,
  bool terlambat = false,
}) => {
  'id': id,
  'nomor': nomor,
  'tanggal_masuk': tanggalUji(-3),
  'tanggal_janji_selesai': tanggalUji(4),
  'terlambat': terlambat,
  'tahap': tahap,
  'tahap_label': label,
  'jumlah_alat': jumlahAlat ?? (alat.isEmpty ? 3 : alat.length),
  'jumlah_selesai': jumlahSelesai ?? 1,
  'alat': alat,
};

/// Satu perusahaan di server palsu.
class DataPerusahaan {
  DataPerusahaan({
    required this.nama,
    this.alat = const [],
    this.sertifikat = const [],
    this.paket = const [],
    this.jumlahPaketBerjalan,
    this.ringkasanTambahan = const {},
  });

  final String nama;
  final List<Map<String, dynamic>> alat;
  final List<Map<String, dynamic>> sertifikat;
  final List<Map<String, dynamic>> paket;
  final int? jumlahPaketBerjalan;

  /// Kunci tambahan di `data.ringkasan` (mis. `paket_siap_diambil`,
  /// `alat_berlaku`), yang tidak dikirim server lama.
  final Map<String, dynamic> ringkasanTambahan;

  bool _aktif(Map<String, dynamic> a) => a['status_alat'] != 'nonaktif';

  int _hari(Map<String, dynamic> a) =>
      (a['hari_ke_jatuh_tempo'] as int?) ?? 99999;

  /// Urutan server: jatuh tempo menaik, tanpa jadwal terakhir.
  List<Map<String, dynamic>> get terurut {
    final x = [...alat];
    x.sort((a, b) => _hari(a).compareTo(_hari(b)));
    return x;
  }

  int get lewat => alat
      .where((a) => _aktif(a) && ((a['hari_ke_jatuh_tempo'] as int?) ?? 0) < 0)
      .length;

  int get segera => alat.where((a) {
    final h = a['hari_ke_jatuh_tempo'] as int?;
    return _aktif(a) && h != null && h >= 0 && h <= 30;
  }).length;
}

/// Server palsu `/api/pelanggan/v1` untuk data perusahaan. Semua rute data
/// butuh `Authorization: Bearer` dan `X-Perusahaan-Id` milik salah satu
/// perusahaan di [data]; selain itu 404, seperti server (bukan 403).
class ServerFitur {
  ServerFitur(this.data);

  static const token = 'tkn-fitur-bukan-rahasia';

  final Map<int, DataPerusahaan> data;
  final permintaan = <http.Request>[];

  /// Rute (awalan jalur) yang dijawab 500 selama masih ada di sini.
  final gagal = <String>{};

  /// Menggantikan jawaban rute unduh PDF (mis. halaman HTML dari proxy).
  Future<http.Response> Function(http.Request r)? timpaUnduh;

  /// Jawaban ditunda sekian lama (waktu palsu `testWidgets`). Dipakai untuk
  /// memeriksa apa yang tampil SELAMA data perusahaan baru dimuat.
  Duration? jeda;

  /// Isi PDF yang disajikan rute unduh.
  static final pdf = utf8.encode('%PDF-1.4\n% berkas uji pratinjau\n');

  Iterable<http.Request> yang(String metode, Pattern jalur) => permintaan.where(
    (r) =>
        r.method == metode &&
        r.url.path.replaceFirst(Konfigurasi.prefix, '').contains(jalur),
  );

  http.Response _json(Object isi, [int status = 200]) => http.Response(
    jsonEncode(isi),
    status,
    headers: {'content-type': 'application/json'},
  );

  http.Response _tidakAda() =>
      _json({'message': 'No query results for model [App\\Models\\X].'}, 404);

  Map<String, dynamic> _halaman(
    List<Map<String, dynamic>> isi,
    Map<String, String> q,
  ) {
    final per = int.tryParse(q['per_page'] ?? '') ?? 20;
    final hal = int.tryParse(q['page'] ?? '') ?? 1;
    final terakhir = isi.isEmpty ? 1 : (isi.length / per).ceil();
    return {
      'data': isi.skip((hal - 1) * per).take(per).toList(),
      'meta': {
        'current_page': hal,
        'last_page': terakhir,
        'total': isi.length,
        'per_page': per,
        'jendela_segera_hari': 30,
      },
    };
  }

  Future<http.Response> tangani(http.Request r) async {
    permintaan.add(r);
    if (jeda != null) await Future<void>.delayed(jeda!);
    final jalur = r.url.path.replaceFirst(Konfigurasi.prefix, '');
    final q = r.url.queryParameters;

    if (r.headers['Authorization'] != 'Bearer $token') {
      return _json({'kode': 'sesi_berakhir', 'message': 'Sesi berakhir.'}, 401);
    }
    if (gagal.any(jalur.startsWith)) {
      return _json({
        'kode': 'galat_server',
        'message': 'Terjadi kendala di server. Coba lagi sebentar lagi.',
      }, 500);
    }
    final p = data[int.tryParse(r.headers['X-Perusahaan-Id'] ?? '')];
    if (jalur == '/notifikasi/jumlah') {
      return _json({
        'data': {'belum_dibaca': 0},
      });
    }
    if (p == null) return _tidakAda();

    if (jalur == '/beranda') {
      return _json({
        'data': {
          'perusahaan': {'id': 1, 'nama': p.nama},
          'ringkasan': {
            'jumlah_alat': p.alat.length,
            'lewat_jatuh_tempo': p.lewat,
            'segera_jatuh_tempo': p.segera,
            'paket_berjalan': p.jumlahPaketBerjalan ?? p.paket.length,
            'notifikasi_belum_dibaca': 0,
            ...p.ringkasanTambahan,
          },
          'perlu_perhatian': <Object>[],
          'sertifikat_terbaru': p.sertifikat.take(5).toList(),
          'paket_berjalan': p.paket.take(3).toList(),
        },
        'meta': {'jendela_segera_hari': 30},
      });
    }
    if (jalur == '/alat') {
      var isi = p.terurut;
      final cari = (q['q'] ?? '').toLowerCase();
      if (cari.isNotEmpty) {
        isi = isi
            .where(
              (a) => '${a['nama']} ${a['merk']} ${a['serial']}'
                  .toLowerCase()
                  .contains(cari),
            )
            .toList();
      }
      if (q['saring'] == 'lewat') {
        isi = isi
            .where((a) => ((a['hari_ke_jatuh_tempo'] as int?) ?? 0) < 0)
            .toList();
      } else if (q['saring'] == 'segera') {
        isi = isi.where((a) {
          final h = a['hari_ke_jatuh_tempo'] as int?;
          return h != null && h >= 0 && h <= 30;
        }).toList();
      }
      return _json(_halaman(isi, q));
    }
    final alat = RegExp(r'^/alat/(\d+)$').firstMatch(jalur);
    if (alat != null) {
      final id = int.parse(alat.group(1)!);
      final a = p.alat.where((x) => x['id'] == id);
      return a.isEmpty ? _tidakAda() : _json({'data': a.first});
    }
    if (jalur == '/sertifikat') return _json(_halaman(p.sertifikat, q));
    final unduh = RegExp(r'^/sertifikat/(\d+)/unduh$').firstMatch(jalur);
    if (unduh != null) {
      if (timpaUnduh != null) return timpaUnduh!(r);
      final id = int.parse(unduh.group(1)!);
      final s = p.sertifikat.where((x) => x['id'] == id);
      if (s.isEmpty) return _tidakAda();
      if (s.first['status'] == 'dibatalkan') {
        return _json({
          'message':
              'Sertifikat ini sudah dibatalkan lab, jadi PDF-nya tidak bisa '
              'diunduh lagi.',
        }, 410);
      }
      return http.Response.bytes(
        pdf,
        200,
        headers: {'content-type': 'application/pdf'},
      );
    }
    final sert = RegExp(r'^/sertifikat/(\d+)$').firstMatch(jalur);
    if (sert != null) {
      final id = int.parse(sert.group(1)!);
      final s = p.sertifikat.where((x) => x['id'] == id);
      return s.isEmpty ? _tidakAda() : _json({'data': s.first});
    }
    if (jalur == '/paket') return _json(_halaman(p.paket, q));
    return _tidakAda();
  }
}

/// Sesi uji yang bisa berganti perusahaan dan akun, seperti `SesiController`
/// sungguhan (yang memasang `X-Perusahaan-Id` ke klien API).
class SesiBisaGanti extends SesiController {
  SesiBisaGanti(this._awal);

  final Sesi _awal;

  @override
  Future<Sesi?> build() async => _awal;

  @override
  void pilihPerusahaan(int customerId) {
    final s = state.value;
    if (s == null) return;
    ref.read(apiProvider).perusahaanId = customerId;
    state = AsyncData(Sesi(akun: s.akun, perusahaanId: customerId));
  }

  /// Akun lain masuk di HP yang sama (sesudah keluar).
  void ganti(Sesi baru) {
    ref.read(apiProvider)
      ..token = ServerFitur.token
      ..perusahaanId = baru.perusahaanId;
    state = AsyncData(baru);
  }
}

/// Anggota dua perusahaan (3 dan 4) yang aktif di [aktif].
Sesi sesiDuaPerusahaan({int aktif = 3}) => Sesi(
  akun: Akun.dariJson({
    'id': 7,
    'nama': 'Budi Anggota',
    'email': 'budi@contoh.test',
    'status': 'aktif',
    'butuh_verifikasi': false,
    'keanggotaan': [
      {'customer_id': 3, 'nama_perusahaan': 'PT Alfa', 'peran': 'staf'},
      {'customer_id': 4, 'nama_perusahaan': 'PT Beta', 'peran': 'staf'},
    ],
  }),
  perusahaanId: aktif,
);

/// Override standar untuk layar fitur: server palsu di belakang
/// `ApiPelanggan` asli (header, galat, cache), jam HP tetap ([jamHp], bawaan
/// [hariIniUji]; hanya cadangan, "hari ini" sebenarnya dari server).
List<Override> overrideFitur(
  ServerFitur server, {
  Sesi? sesi,
  int perusahaan = 3,
  PenyimpanPratinjau? pratinjau,
  DateTime? jamHp,
  List<Override> tambahan = const [],
}) {
  final api = ApiPelanggan(
    klien: MockClient(server.tangani),
    token: ServerFitur.token,
    perusahaanId: perusahaan,
    jedaUlang: const [],
  );
  return [
    ...overrideDasar(pratinjau: pratinjau),
    apiProvider.overrideWithValue(api),
    sesiProvider.overrideWith(
      () => SesiBisaGanti(sesi ?? sesiDuaPerusahaan(aktif: perusahaan)),
    ),
    jamHpProvider.overrideWithValue(() => jamHp ?? hariIniUji),
    ...tambahan,
  ];
}
