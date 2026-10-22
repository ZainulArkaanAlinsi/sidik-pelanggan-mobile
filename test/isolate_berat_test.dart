import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/dekode_json.dart';
import 'package:sidik_pelanggan/core/penyimpan_cache.dart';
import 'package:sidik_pelanggan/services/klien_rilis.dart';

/// Kerja berat (hash APK, JSON besar) dipindah dari isolate UI — hasilnya
/// harus PERSIS sama dengan versi sinkron, termasuk galatnya.
void main() {
  /// JSON daftar alat > [batasDekodeLatar] supaya jalur isolate terpakai.
  String jsonBesar() {
    final data = [
      for (var i = 0; i < 4000; i++)
        {'id': i, 'nama': 'Termometer digital $i', 'seri': 'SN-$i-ÄÖ'},
    ];
    final teks = jsonEncode({'data': data});
    expect(teks.length, greaterThan(batasDekodeLatar));
    return teks;
  }

  group('dekodeJson', () {
    test('teks kecil dan besar: hasil sama dengan jsonDecode', () async {
      expect(await dekodeJson('{"a":1}'), {'a': 1});
      final besar = jsonBesar();
      expect(await dekodeJson(besar), jsonDecode(besar));
    });

    test('bukan JSON → FormatException di kedua jalur', () async {
      await expectLater(dekodeJson('<html>'), throwsFormatException);
      final rusak = '{"x":"${'a' * (batasDekodeLatar + 10)}"';
      await expectLater(dekodeJson(rusak), throwsFormatException);
    });
  });

  group('ApiPelanggan dengan respons besar', () {
    test(
      'GET besar: terurai, tersimpan, lalu terbaca lagi saat offline',
      () async {
        final dir = await Directory.systemTemp.createTemp('cache_uji');
        addTearDown(() => dir.delete(recursive: true));
        final cache = PenyimpanCacheBerkas.di(dir);
        final besar = jsonBesar();
        var offline = false;
        final api = ApiPelanggan(
          versiApp: '1.0.0+1',
          token: 't',
          cache: cache,
          lingkupCache: 'u1',
          jedaUlang: const [],
          klien: MockClient((_) async {
            if (offline) throw const SocketException('mati');
            return http.Response(besar, 200);
          }),
        );

        final isi = await api.get('/alat');
        expect((isi['data'] as List).length, 4000);

        // Penulisan cache tidak ditunggu `get`; beri waktu selesai.
        final kunci = 'u1|p-|/api/pelanggan/v1/alat';
        for (var i = 0; i < 50 && await cache.baca(kunci) == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }

        offline = true;
        final dariCache = await api.get('/alat');
        expect(dariCache, jsonDecode(besar));
      },
    );

    test('galat 422 dengan badan besar tetap terbaca kodenya', () async {
      final badan = jsonEncode({
        'kode': 'VALIDASI',
        'message': 'Tidak sah',
        'errors': {
          'x': ['salah'],
        },
        'pad': 'p' * (batasDekodeLatar + 1),
      });
      final api = ApiPelanggan(
        versiApp: '1.0.0+1',
        token: 't',
        klien: MockClient((_) async => http.Response(badan, 422)),
      );
      await expectLater(
        api.post('/x'),
        throwsA(
          isA<GalatApi>()
              .having((e) => e.kode, 'kode', 'VALIDASI')
              .having((e) => e.isian['x'], 'isian', 'salah'),
        ),
      );
    });
  });

  test('sha256Berkas (isolate) = SHA-256 isi berkas', () async {
    final dir = await Directory.systemTemp.createTemp('sha_uji');
    addTearDown(() => dir.delete(recursive: true));
    final f = File('${dir.path}/apk.bin');
    final isi = List<int>.generate(3 * 1024 * 1024 + 7, (i) => i % 251);
    await f.writeAsBytes(isi);

    expect(await sha256Berkas(f), crypto.sha256.convert(isi).toString());
  });
}
