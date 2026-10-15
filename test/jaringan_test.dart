import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/id_unik.dart';
import 'package:sidik_pelanggan/core/penyimpan_cache.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';

/// NFR-06 (jaringan & offline), NFR-11 (header permintaan), 04 §6 (404).
void main() {
  http.Response json(Object badan, [int status = 200]) =>
      http.Response(jsonEncode(badan), status);

  group('IdUnik', () {
    test('UUID v4 sah dan tidak berulang', () {
      final a = IdUnik.uuid4();
      final b = IdUnik.uuid4();
      expect(IdUnik.sahUuid4(a), isTrue);
      expect(IdUnik.sahUuid4(b), isTrue);
      expect(a, isNot(b));
      expect(IdUnik.sahUuid4('bukan-uuid'), isFalse);
      expect(IdUnik.sahUuid4(null), isFalse);
    });
  });

  group('header', () {
    test(
      'X-App-Versi & X-Request-Id dikirim; id baru tiap panggilan',
      () async {
        final diterima = <http.BaseRequest>[];
        final api = ApiPelanggan(
          versiApp: '1.4.0+12',
          token: 't',
          perusahaanId: 3,
          klien: MockClient((r) async {
            diterima.add(r);
            return json({'data': []});
          }),
        );
        await api.get('/alat');
        await api.post('/notifikasi/dibaca-semua');

        expect(diterima[0].headers['X-App-Versi'], '1.4.0+12');
        expect(IdUnik.sahUuid4(diterima[0].headers['X-Request-Id']), isTrue);
        expect(IdUnik.sahUuid4(diterima[1].headers['X-Request-Id']), isTrue);
        expect(
          diterima[0].headers['X-Request-Id'],
          isNot(diterima[1].headers['X-Request-Id']),
        );
        expect(diterima[0].headers['X-Perusahaan-Id'], '3');
      },
    );

    test('percobaan ulang GET memakai X-Request-Id yang SAMA', () async {
      final id = <String?>[];
      var n = 0;
      final api = ApiPelanggan(
        jedaUlang: const [Duration.zero, Duration.zero],
        klien: MockClient((r) async {
          id.add(r.headers['X-Request-Id']);
          if (++n < 3) throw const SocketException('putus');
          return json({'data': []});
        }),
      );
      await api.get('/alat');
      expect(id, hasLength(3));
      expect(id.toSet(), hasLength(1));
    });
  });

  group('percobaan ulang (NFR-06)', () {
    test('GET diulang 2× lalu menyerah dengan galat jaringan', () async {
      var n = 0;
      final api = ApiPelanggan(
        jedaUlang: const [Duration.zero, Duration.zero],
        klien: MockClient((_) async {
          n++;
          throw const SocketException('putus');
        }),
      );
      await expectLater(
        api.get('/alat'),
        throwsA(isA<GalatApi>().having((e) => e.jaringan, 'jaringan', true)),
      );
      expect(n, 3);
    });

    test('POST TIDAK diulang (bisa menggandakan data)', () async {
      var n = 0;
      final api = ApiPelanggan(
        jedaUlang: const [Duration.zero, Duration.zero],
        klien: MockClient((_) async {
          n++;
          throw http.ClientException('putus');
        }),
      );
      await expectLater(api.post('/permintaan', {}), throwsA(isA<GalatApi>()));
      expect(n, 1);
    });

    test('batas waktu tidak diulang', () async {
      var n = 0;
      final api = ApiPelanggan(
        batasWaktu: const Duration(milliseconds: 20),
        jedaUlang: const [Duration.zero, Duration.zero],
        klien: MockClient((_) async {
          n++;
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return json({});
        }),
      );
      await expectLater(api.get('/alat'), throwsA(isA<GalatApi>()));
      expect(n, 1);
    });
  });

  group('cache offline', () {
    late PenyimpanCacheMemori cache;
    late bool putus;
    late int status;
    DateTime? offlineDengan;
    var offlineDipanggil = 0;
    var onlineDipanggil = 0;

    ApiPelanggan buat({String? lingkup = 'u7', int? perusahaan = 3}) =>
        ApiPelanggan(
          cache: cache,
          lingkupCache: lingkup,
          perusahaanId: perusahaan,
          jedaUlang: const [],
          saatOffline: (w) {
            offlineDipanggil++;
            offlineDengan = w;
          },
          saatOnline: () => onlineDipanggil++,
          klien: MockClient((r) async {
            if (putus) throw const SocketException('putus');
            return json({
              'data': [
                {'id': 1, 'q': r.url.query},
              ],
            }, status);
          }),
        );

    setUp(() {
      cache = PenyimpanCacheMemori(jam: () => DateTime(2026, 10, 15, 8, 12));
      putus = false;
      status = 200;
      offlineDengan = null;
      offlineDipanggil = 0;
      onlineDipanggil = 0;
    });

    test('jawaban terakhir tersaji saat offline, dengan waktunya', () async {
      final api = buat();
      await api.get('/alat', query: {'page': '1'});
      await pumpEventQueue();
      expect(onlineDipanggil, 1);

      putus = true;
      final b = await api.get('/alat', query: {'page': '1'});
      expect((b['data'] as List).single['id'], 1);
      expect(offlineDipanggil, 1);
      expect(offlineDengan, DateTime(2026, 10, 15, 8, 12));
    });

    test(
      'tanpa cache untuk jalur itu: galat jaringan, banner tanpa jam',
      () async {
        final api = buat();
        putus = true;
        await expectLater(api.get('/sertifikat'), throwsA(isA<GalatApi>()));
        expect(offlineDipanggil, 1);
        expect(offlineDengan, isNull);
      },
    );

    test('pengguna lain / perusahaan lain tidak membaca cache ini', () async {
      await buat().get('/alat');
      await pumpEventQueue();
      putus = true;
      await expectLater(
        buat(lingkup: 'u8').get('/alat'),
        throwsA(isA<GalatApi>()),
      );
      await expectLater(
        buat(perusahaan: 4).get('/alat'),
        throwsA(isA<GalatApi>()),
      );
      // Belum masuk (tanpa pemilik): tidak menyimpan, tidak membaca.
      await expectLater(
        buat(lingkup: null).get('/alat'),
        throwsA(isA<GalatApi>()),
      );
    });

    test('galat server (403) tidak pernah dijawab dari cache', () async {
      final api = buat();
      await api.get('/alat');
      await pumpEventQueue();
      status = 403;
      await expectLater(
        api.get('/alat'),
        throwsA(isA<GalatApi>().having((e) => e.status, 'status', 403)),
      );
      expect(offlineDipanggil, 0);
    });

    test('query berbeda = kunci berbeda (halaman 2 tidak tertukar)', () async {
      final api = buat();
      await api.get('/alat', query: {'page': '1'});
      await api.get('/alat', query: {'page': '2'});
      await pumpEventQueue();
      putus = true;
      final h2 = await api.get('/alat', query: {'page': '2'});
      expect((h2['data'] as List).single['q'], 'page=2');
    });
  });

  test('404 memakai kalimat 04-UI-UX §6, bukan pesan Laravel', () async {
    final api = ApiPelanggan(
      klien: MockClient(
        (_) async => json({
          'message': r'No query results for model [App\Models\Equipment] 5',
        }, 404),
      ),
    );
    await expectLater(
      api.get('/alat/5'),
      throwsA(
        isA<GalatApi>().having(
          (e) => e.pesan,
          'pesan',
          'Data ini tidak ditemukan atau Anda tidak punya akses.',
        ),
      ),
    );
  });

  group('PenyimpanCacheBerkas', () {
    late Directory folder;

    setUp(() async => folder = await Directory.systemTemp.createTemp('cache'));
    tearDown(() async => folder.delete(recursive: true));

    test('simpan, baca, hapus semua', () async {
      final c = PenyimpanCacheBerkas.di(folder);
      await c.simpan('u7|p3|/alat', '{"data":[1]}');
      final e = await c.baca('u7|p3|/alat');
      expect(e?.isi, '{"data":[1]}');
      expect(e?.waktu, isNotNull);
      expect(await c.baca('u7|p3|/sertifikat'), isNull);

      await c.hapusSemua();
      expect(await c.baca('u7|p3|/alat'), isNull);
    });

    test('isi berkas milik kunci lain tidak pernah tersaji', () async {
      final c = PenyimpanCacheBerkas.di(folder);
      // Tiru tabrakan nama berkas: tulis berkas kunci B di nama milik A.
      final namaA = PenyimpanCacheBerkas.namaBerkas('kunci-A');
      await File('${folder.path}/$namaA').writeAsString(
        jsonEncode({'k': 'kunci-B', 't': '2026-10-15T00:00:00Z', 'b': 'x'}),
      );
      expect(await c.baca('kunci-A'), isNull);
    });

    test('jumlah berkas dibatasi', () async {
      final c = PenyimpanCacheBerkas.di(folder, batasBerkas: 10);
      for (var i = 0; i < 60; i++) {
        await c.simpan('k$i', 'v$i');
      }
      final n = await folder
          .list()
          .where((e) => e.path.endsWith('.json'))
          .length;
      expect(n, lessThanOrEqualTo(20));
      expect((await c.baca('k59'))?.isi, 'v59');
    });
  });

  test('keluar semua memanggil /auth/keluar-semua', () async {
    late http.Request diterima;
    final api = ApiPelanggan(
      klien: MockClient((r) async {
        diterima = r;
        return json({
          'data': {'sesi_dicabut': 3},
        });
      }),
    );
    expect(await LayananPelanggan(api).keluarSemua(), 3);
    expect(diterima.url.path, endsWith('/auth/keluar-semua'));
  });
}
