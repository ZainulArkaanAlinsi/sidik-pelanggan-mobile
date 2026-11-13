// Layanan arsip: `GET /sertifikat/garis-waktu` lewat ApiPelanggan asli dengan
// klien HTTP palsu. Yang dibuktikan: rute dan parameter PERSIS kontrak (tanpa
// `customer_id`), hanya `GET`, galat dipetakan, dan pencarian memakai daftar
// sertifikat (`GET /sertifikat?q=`) dengan kata apa adanya.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/konfigurasi.dart';
import 'package:sidik_pelanggan/models/arsip.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';

import 'dukungan/fixture_arsip.dart';

http.Response _json(Object badan, [int status = 200]) => http.Response(
  jsonEncode(badan),
  status,
  headers: {'content-type': 'application/json'},
);

/// Jawaban `GET /sertifikat` tanpa isi.
Map<String, dynamic> _daftarKosong() => {
  'data': <Object>[],
  'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
};

/// Layanan dengan klien yang menjawab [jawab] dan mencatat permintaannya.
({LayananPelanggan layanan, List<http.Request> diterima}) _siap(
  http.Response Function(http.Request r) jawab,
) {
  final diterima = <http.Request>[];
  final api = ApiPelanggan(
    token: 'tkn-uji',
    perusahaanId: 3,
    jedaUlang: const [],
    klien: MockClient((r) async {
      diterima.add(r);
      return jawab(r);
    }),
  );
  return (layanan: LayananPelanggan(api), diterima: diterima);
}

void main() {
  const rute = '${Konfigurasi.prefix}/sertifikat/garis-waktu';

  test('akar: GET rute garis waktu, hanya page=1, header perusahaan', () async {
    final s = _siap((_) => _json(arsipTahun()));

    final h = await s.layanan.garisWaktuSertifikat(ParameterArsip.akar);

    expect(s.diterima, hasLength(1));
    final r = s.diterima.single;
    expect(r.method, 'GET');
    expect(r.url.path, rute);
    expect(r.url.queryParameters, {'page': '1'});
    expect(r.headers['X-Perusahaan-Id'], '3');
    expect(r.headers['Authorization'], 'Bearer tkn-uji');
    expect(h.tingkat, TingkatArsip.tahun);
    expect(h.kelompok.map((k) => k.label), ['2026', '2025']);
  });

  test('telusuri kelompok diteruskan persis, ditambah page', () async {
    final s = _siap((_) => _json(arsipHari()));
    final pekan = HasilArsip.dariJson(arsipPekanNovember()).kelompok.first;

    final h = await s.layanan.garisWaktuSertifikat(pekan.parameter, halaman: 2);

    expect(s.diterima.single.url.queryParameters, {
      'tingkat': 'hari',
      'tahun': '2026',
      'bulan': '11',
      'pekan': '46',
      'page': '2',
    });
    expect(h.item.first.nomorOrder, 'PO-2026-0042');
  });

  test('perusahaan dari konteks: customer_id tidak pernah dikirim', () async {
    final s = _siap((_) => _json(arsipHari()));
    final hari = HasilArsip.dariJson(arsipHari()).kelompok.first;
    await s.layanan.garisWaktuSertifikat(ParameterArsip.akar);
    await s.layanan.garisWaktuSertifikat(hari.parameter);
    expect(s.diterima, hasLength(2));
    for (final r in s.diterima) {
      expect(r.url.queryParameters.containsKey('customer_id'), isFalse);
    }
  });

  test('garis waktu tidak membawa kata cari (q)', () async {
    final s = _siap((_) => _json(arsipTahun()));
    await s.layanan.garisWaktuSertifikat(ParameterArsip.akar);
    expect(s.diterima.single.url.queryParameters.containsKey('q'), isFalse);
  });

  test('hanya membaca: tidak ada permintaan selain GET', () async {
    final s = _siap(
      (r) => _json(
        r.url.path.endsWith('garis-waktu') ? arsipTahun() : _daftarKosong(),
      ),
    );
    await s.layanan.garisWaktuSertifikat(ParameterArsip.akar);
    await s.layanan.garisWaktuSertifikat(ParameterArsip.akar, halaman: 2);
    await s.layanan.daftarSertifikat(cari: 'sn-0204');
    expect(s.diterima.map((r) => r.method).toSet(), {'GET'});
  });

  group('pencarian lewat daftar sertifikat', () {
    test(
      'GET /sertifikat?q= dengan kata apa adanya (/, -, spasi, huruf)',
      () async {
        final s = _siap((_) => _json(_daftarKosong()));
        for (final kata in [
          'CAL/2026/10/0001',
          'cal-2026-10-0001',
          'cal 2026 10 0001',
        ]) {
          await s.layanan.daftarSertifikat(cari: kata);
        }
        for (final r in s.diterima) {
          expect(r.url.path, '${Konfigurasi.prefix}/sertifikat');
          expect(r.url.queryParameters.keys.toSet(), {'q', 'page'});
        }
        expect(s.diterima.map((r) => r.url.queryParameters['q']), [
          'CAL/2026/10/0001',
          'cal-2026-10-0001',
          'cal 2026 10 0001',
        ]);
      },
    );

    test(
      'revisi yang sudah digantikan tidak diminta (bawaan server)',
      () async {
        final s = _siap((_) => _json(_daftarKosong()));
        await s.layanan.daftarSertifikat(cari: 'sn-0204', halaman: 2);
        final q = s.diterima.single.url.queryParameters;
        expect(q.containsKey('termasuk_digantikan'), isFalse);
        expect(q['page'], '2');
      },
    );
  });

  group('galat server', () {
    test('404 (perusahaan lain / rute belum ada): tidak ditemukan', () async {
      final s = _siap(
        (_) => _json({'message': 'No query results for model [X].'}, 404),
      );
      await expectLater(
        s.layanan.garisWaktuSertifikat(ParameterArsip.akar),
        throwsA(
          isA<GalatApi>()
              .having((e) => e.tidakDitemukan, 'tidakDitemukan', isTrue)
              // Kalimat tetap; tidak membocorkan nama model server.
              .having((e) => e.pesan, 'pesan', ApiPelanggan.pesan404),
        ),
      );
    });

    test('422 (induk salah): pesan dan kolom dari server', () async {
      final s = _siap(
        (_) => _json({
          'message': 'Tingkat `pekan` memerlukan parameter `bulan`.',
          'errors': {
            'bulan': ['Tingkat `pekan` memerlukan parameter `bulan`.'],
          },
        }, 422),
      );
      await expectLater(
        s.layanan.garisWaktuSertifikat(ParameterArsip.akar),
        throwsA(
          isA<GalatApi>()
              .having((e) => e.status, 'status', 422)
              .having((e) => e.pesan, 'pesan', contains('memerlukan'))
              .having((e) => e.isian.keys, 'kolom', ['bulan']),
        ),
      );
    });

    test('429 (throttle): kalimat umum, bukan crash', () async {
      final s = _siap((_) => _json(<String, Object>{}, 429));
      await expectLater(
        s.layanan.garisWaktuSertifikat(ParameterArsip.akar),
        throwsA(isA<GalatApi>().having((e) => e.status, 'status', 429)),
      );
    });
  });
}
