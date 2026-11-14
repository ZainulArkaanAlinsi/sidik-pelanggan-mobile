// Layanan saklar notifikasi: URL, metode, header, dan badan PERSIS kontrak
// (docs/kontrak-api-pelanggan.md §14.4 di repo API): `GET` dan `PUT`
// `/preferensi-notifikasi`, PUT sebagian, lima kunci, per perusahaan lewat
// header `X-Perusahaan-Id`. Rute tulisnya `PUT`, bukan `PATCH`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/konfigurasi.dart';
import 'package:sidik_pelanggan/core/penyimpan_cache.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';

import 'dukungan/layanan_preferensi_palsu.dart';

/// Contoh respons di kontrak §14.4.
const _kontrak = {
  'data': {
    'pengingat_jadwal': true,
    'status_permintaan': true,
    'pesan_lab': true,
    'ringkasan_email_mingguan': false,
    'tahap_alat': true,
  },
};

void main() {
  late List<http.Request> diterima;

  LayananPelanggan layanan(
    Future<http.Response> Function(http.Request r) jawab, {
    int perusahaan = 3,
  }) {
    diterima = [];
    final klien = MockClient((r) {
      diterima.add(r);
      return jawab(r);
    });
    return LayananPelanggan(
      ApiPelanggan(
        klien: klien,
        token: 'tkn-uji',
        perusahaanId: perusahaan,
        jedaUlang: const [],
      ),
    );
  }

  Future<http.Response> json(Object isi, [int status = 200]) async =>
      http.Response(
        jsonEncode(isi),
        status,
        headers: {'content-type': 'application/json'},
      );

  String jalur(http.Request r) =>
      r.url.path.replaceFirst(Konfigurasi.prefix, '');

  group('GET /preferensi-notifikasi', () {
    test('metode, jalur, dan header perusahaan aktif', () async {
      final hasil = await layanan(
        (_) => json(_kontrak),
        perusahaan: 4,
      ).preferensiNotifikasi();

      expect(diterima, hasLength(1));
      expect(diterima.single.method, 'GET');
      expect(jalur(diterima.single), '/preferensi-notifikasi');
      expect(diterima.single.url.hasQuery, isFalse);
      expect(diterima.single.headers['X-Perusahaan-Id'], '4');
      expect(diterima.single.headers['Authorization'], 'Bearer tkn-uji');
      expect(hasil, {
        'pengingat_jadwal': true,
        'status_permintaan': true,
        'pesan_lab': true,
        'ringkasan_email_mingguan': false,
        'tahap_alat': true,
      });
    });

    test('perusahaan lain = header lain (saklar per perusahaan)', () async {
      await layanan(
        (_) => json(_kontrak),
        perusahaan: 3,
      ).preferensiNotifikasi();
      final a = diterima.single.headers['X-Perusahaan-Id'];
      await layanan(
        (_) => json(_kontrak),
        perusahaan: 8,
      ).preferensiNotifikasi();
      expect([a, diterima.single.headers['X-Perusahaan-Id']], ['3', '8']);
    });

    test(
      'nilai bukan boolean dan kunci tak dikenal tidak menjatuhkan',
      () async {
        final hasil = await layanan(
          (_) => json({
            'data': {
              'tahap_alat': true,
              'kategori_baru_dari_server': false,
              'aneh': 'ya',
              'angka': 1,
              'kosong': null,
            },
          }),
        ).preferensiNotifikasi();

        // Layanan hanya menyaring tipe; kunci asing disaring di provider.
        expect(hasil, {'tahap_alat': true, 'kategori_baru_dari_server': false});
      },
    );

    test('data larik kosong (PHP `[]`) atau hilang: peta kosong', () async {
      expect(
        await layanan((_) => json({'data': <Object>[]})).preferensiNotifikasi(),
        isEmpty,
      );
      expect(
        await layanan((_) => json(<String, Object>{})).preferensiNotifikasi(),
        isEmpty,
      );
    });

    test('403 dan 500 menjadi GalatApi dengan statusnya', () async {
      for (final status in [403, 500]) {
        await expectLater(
          layanan(
            (_) => json({'message': 'tolak'}, status),
          ).preferensiNotifikasi(),
          throwsA(isA<GalatApi>().having((g) => g.status, 'status', status)),
        );
      }
    });
  });

  group('PUT /preferensi-notifikasi', () {
    test('PUT sebagian: hanya kunci yang diubah, badan JSON persis', () async {
      final hasil = await layanan(
        (_) => json({
          'data': {..._kontrak['data']!, 'tahap_alat': false},
        }),
      ).simpanPreferensiNotifikasi({'tahap_alat': false});

      expect(diterima, hasLength(1));
      final r = diterima.single;
      expect(r.method, 'PUT', reason: 'bukan PATCH: rute server hanya PUT');
      expect(jalur(r), '/preferensi-notifikasi');
      expect(r.headers['Content-Type'], contains('application/json'));
      expect(r.headers['X-Perusahaan-Id'], '3');
      expect(r.headers['Authorization'], 'Bearer tkn-uji');
      expect(jsonDecode(r.body), {'tahap_alat': false});
      expect(hasil['tahap_alat'], isFalse);
      expect(hasil.length, 5, reason: 'jawaban = seluruh set');
    });

    test(
      'nilai dikirim sebagai boolean JSON (bukan teks atau angka)',
      () async {
        await layanan(
          (_) => json(_kontrak),
        ).simpanPreferensiNotifikasi({'ringkasan_email_mingguan': true});
        expect(diterima.single.body, '{"ringkasan_email_mingguan":true}');
      },
    );

    test('422 membawa pesan per kolom; 403 dan 429 dibedakan', () async {
      await expectLater(
        layanan(
          (_) => json({
            'message': 'invalid',
            'errors': {
              'tahap_alat': ['harus true atau false'],
            },
          }, 422),
        ).simpanPreferensiNotifikasi({'tahap_alat': false}),
        throwsA(
          isA<GalatApi>()
              .having((g) => g.status, 'status', 422)
              .having((g) => g.isian['tahap_alat'], 'isian', isNotNull),
        ),
      );
      for (final status in [403, 429]) {
        await expectLater(
          layanan(
            (_) => json({'message': 'tolak'}, status),
          ).simpanPreferensiNotifikasi({'tahap_alat': false}),
          throwsA(isA<GalatApi>().having((g) => g.status, 'status', status)),
        );
      }
    });

    test('jaringan putus: GalatApi.jaringan dan TIDAK diulang', () async {
      final l = layanan((_) async => throw http.ClientException('putus'));
      await expectLater(
        l.simpanPreferensiNotifikasi({'tahap_alat': false}),
        throwsA(isA<GalatApi>().having((g) => g.jaringan, 'jaringan', true)),
      );
      expect(
        diterima,
        hasLength(1),
        reason: 'PUT tidak pernah diulang diam-diam',
      );
    });
  });

  group('catatPreferensiNotifikasi (write-through cache GET)', () {
    LayananPelanggan denganCache(
      PenyimpanCache cache, {
      required bool Function() putus,
      int perusahaan = 3,
      String? pemilik = 'u7',
    }) => LayananPelanggan(
      ApiPelanggan(
        klien: MockClient((r) async {
          if (putus()) throw http.ClientException('putus');
          return json(_kontrak);
        }),
        token: 'tkn-uji',
        perusahaanId: perusahaan,
        cache: cache,
        lingkupCache: pemilik,
        jedaUlang: const [],
      ),
    );

    test(
      'GET offline sesudahnya menjawab yang dicatat, bukan GET lama',
      () async {
        var putus = false;
        final cache = PenyimpanCacheMemori();
        final l = denganCache(cache, putus: () => putus);
        expect((await l.preferensiNotifikasi())['tahap_alat'], isTrue);

        await l.catatPreferensiNotifikasi({
          ...LayananPreferensiPalsu.kunciKontrak,
          'tahap_alat': false,
        });
        putus = true;

        final offline = await l.preferensiNotifikasi();
        expect(offline['tahap_alat'], isFalse);
        expect(offline['pesan_lab'], isTrue, reason: 'kunci lain utuh');
      },
    );

    test('isi cache berbentuk jawaban server: {data: {kunci: bool}}', () async {
      final cache = PenyimpanCacheMemori();
      final l = denganCache(cache, putus: () => false);
      await l.catatPreferensiNotifikasi({'tahap_alat': false});
      final entri = cache.isi.values.single;
      expect(jsonDecode(entri.isi), {
        'data': {'tahap_alat': false},
      });
    });

    test('kunci cache sama dengan GET (pemilik, perusahaan, jalur)', () async {
      final cache = PenyimpanCacheMemori();
      final l = denganCache(cache, putus: () => false);
      await l.preferensiNotifikasi();
      final kunciGet = cache.isi.keys.single;
      await l.catatPreferensiNotifikasi({'tahap_alat': false});
      expect(
        cache.isi.keys.single,
        kunciGet,
        reason: 'menimpa, bukan menambah',
      );
      expect(kunciGet, contains('p3'));
      expect(kunciGet, endsWith('/preferensi-notifikasi'));
    });

    test('perusahaan lain tidak ikut (satu cache, dua perusahaan)', () async {
      final cache = PenyimpanCacheMemori();
      final a = denganCache(cache, putus: () => false, perusahaan: 3);
      await a.catatPreferensiNotifikasi({'tahap_alat': false});
      final b = denganCache(cache, putus: () => true, perusahaan: 4);
      await expectLater(
        b.preferensiNotifikasi(),
        throwsA(isA<GalatApi>().having((g) => g.jaringan, 'jaringan', true)),
      );
    });

    test(
      'tanpa pemilik cache atau tanpa cache: tidak menulis, tidak melempar',
      () async {
        final cache = PenyimpanCacheMemori();
        await denganCache(
          cache,
          putus: () => false,
          pemilik: null,
        ).catatPreferensiNotifikasi({'tahap_alat': false});
        expect(cache.isi, isEmpty);

        final tanpaCache = LayananPelanggan(
          ApiPelanggan(
            klien: MockClient((_) => json(_kontrak)),
            perusahaanId: 3,
            jedaUlang: const [],
          ),
        );
        await tanpaCache.catatPreferensiNotifikasi({'tahap_alat': false});
      },
    );

    test('cache yang gagal menulis tidak menggagalkan pemanggil', () async {
      final l = denganCache(_CacheRusak(), putus: () => false);
      await l.catatPreferensiNotifikasi({'tahap_alat': false});
    });
  });

  group('layanan palsu uji mengikuti bentuk kontrak', () {
    test('kunciKontrak = contoh di kontrak', () {
      expect(LayananPreferensiPalsu.kunciKontrak, _kontrak['data']);
    });
  });
}

/// Cache yang selalu gagal menulis (disk penuh).
class _CacheRusak extends PenyimpanCacheMemori {
  @override
  Future<void> simpan(String kunci, String teks) async =>
      throw const FileSystemException('penuh');
}
