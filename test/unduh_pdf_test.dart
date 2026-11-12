// Unduhan PDF sertifikat: hanya PDF sungguhan yang diterima, ukurannya
// dibatasi, dan tempat penyimpanannya adalah cache yang dibersihkan.
//
// - `ApiPelanggan.unduh`: Content-Type DAN awalan `%PDF-`, batas 25 MB,
//   pesan galat yang tepat, header auth hanya ke host API.
// - `LayananPelanggan.unduhDanBukaPdf`: menyimpan di cache aplikasi (bukan
//   folder Dokumen), tidak menyimpan berkas yang ditolak, dan sisa unduhan
//   versi lama (`Sertifikat-*.pdf`) ikut dibersihkan.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:open_filex/open_filex.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/konfigurasi.dart';
import 'package:sidik_pelanggan/core/penyimpan_pratinjau.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';

import 'dukungan/fixture_fitur.dart';

final _pdf = utf8.encode('%PDF-1.4\n% isi uji\n%%EOF\n');

http.Response _jawab(
  List<int> isi, {
  String? jenis = 'application/pdf',
  int status = 200,
}) => http.Response.bytes(isi, status, headers: {'content-type': ?jenis});

ApiPelanggan _api(
  Future<http.Response> Function(http.Request) server, {
  void Function()? saatTokenDitolak,
}) => ApiPelanggan(
  klien: MockClient(server),
  token: 'tkn-uji',
  perusahaanId: 3,
  jedaUlang: const [],
  saatTokenDitolak: saatTokenDitolak,
);

Matcher _galat(String kode, String pesanMengandung) => isA<GalatApi>()
    .having((e) => e.kode, 'kode', kode)
    .having((e) => e.pesan, 'pesan', contains(pesanMengandung))
    .having((e) => e.jaringan, 'jaringan', isFalse);

Sertifikat _sertifikat() =>
    Sertifikat.dariJson(sertifikatJson(11, 'CAL/RAHASIA/0011'));

void main() {
  group('ApiPelanggan.unduh', () {
    test('PDF sungguhan lolos; header hanya ke host API', () async {
      http.Request? minta;
      final byte = await _api((r) async {
        minta = r;
        return _jawab(_pdf);
      }).unduh('/sertifikat/11/unduh');

      expect(byte, _pdf);
      expect(minta!.method, 'GET');
      expect(minta!.url.host, Uri.parse(Konfigurasi.apiBaseUrl).host);
      expect(minta!.url.host, isNot(contains('github')));
      expect(minta!.headers['Authorization'], 'Bearer tkn-uji');
      expect(minta!.headers['X-Perusahaan-Id'], '3');
      expect(minta!.headers['Accept'], 'application/pdf');
    });

    test('Content-Type dengan parameter tetap diterima', () async {
      final byte = await _api(
        (r) async => _jawab(_pdf, jenis: 'application/pdf; charset=binary'),
      ).unduh('/x');
      expect(byte, _pdf);
    });

    test('jenis biner umum diterima HANYA bila isinya PDF', () async {
      // Penyimpanan berkas yang tidak mendeteksi jenis (mis. S3 tanpa
      // metadata) mengirim octet-stream; PDF sungguhan tidak boleh ikut ditolak.
      for (final jenis in ['application/octet-stream', 'binary/octet-stream']) {
        expect(
          await _api((r) async => _jawab(_pdf, jenis: jenis)).unduh('/x'),
          _pdf,
          reason: jenis,
        );
        await expectLater(
          _api(
            (r) async => _jawab(utf8.encode('<html></html>'), jenis: jenis),
          ).unduh('/x'),
          throwsA(_galat('berkas_bukan_pdf', 'bukan PDF')),
          reason: '$jenis dengan isi HTML',
        );
      }
    });

    test(
      'bukan PDF ditolak: Content-Type salah, isi salah, atau tanpa jenis',
      () async {
        final html = utf8.encode('<html><body>Login wifi</body></html>');
        final kasus = <String, http.Response>{
          'HTML bertanda text/html': _jawab(html, jenis: 'text/html'),
          'PDF bertanda text/html': _jawab(_pdf, jenis: 'text/html'),
          'JSON': _jawab(utf8.encode('{"a":1}'), jenis: 'application/json'),
          'gambar': _jawab(_pdf, jenis: 'image/png'),
          'bertanda PDF tapi isinya HTML': _jawab(html),
          'bertanda PDF tapi terlalu pendek': _jawab(utf8.encode('%PD')),
          'bertanda PDF tapi kosong': _jawab(<int>[]),
          'tanpa Content-Type': _jawab(_pdf, jenis: null),
        };
        for (final e in kasus.entries) {
          await expectLater(
            _api((r) async => e.value).unduh('/x'),
            throwsA(_galat('berkas_bukan_pdf', 'bukan PDF')),
            reason: e.key,
          );
        }
      },
    );

    test(
      'terlalu besar menurut Content-Length: ditolak tanpa dibaca',
      () async {
        await expectLater(
          _api(
            (r) async => _jawab(List.filled(100, 0x41)),
          ).unduh('/x', maksByte: 50),
          throwsA(_galat('berkas_terlalu_besar', 'terlalu besar')),
        );
      },
    );

    test(
      'terlalu besar tanpa Content-Length: berhenti di tengah jalan',
      () async {
        var dikirim = 0;
        final klien = MockClient.streaming((req, badan) async {
          Stream<List<int>> aliran() async* {
            yield utf8.encode('%PDF-');
            for (var i = 0; i < 1000; i++) {
              dikirim++;
              yield List.filled(40, 0x41);
            }
          }

          return http.StreamedResponse(
            aliran(),
            200,
            headers: {'content-type': 'application/pdf'},
          );
        });
        final api = ApiPelanggan(klien: klien, jedaUlang: const []);

        await expectLater(
          api.unduh('/x', maksByte: 200),
          throwsA(_galat('berkas_terlalu_besar', 'terlalu besar')),
        );
        expect(dikirim, lessThan(1000), reason: 'sisa jawaban tidak diunduh');
      },
    );

    test('batas bawaan 25 MB dan pesannya menyebut angkanya', () async {
      expect(ApiPelanggan.batasUnduhByte, 25 * 1024 * 1024);
      final besar = Uint8List(ApiPelanggan.batasUnduhByte + 1)
        ..setRange(0, 5, utf8.encode('%PDF-'));
      await expectLater(
        _api((r) async => _jawab(besar)).unduh('/x'),
        throwsA(_galat('berkas_terlalu_besar', 'maksimal 25 MB')),
      );
      // Tepat di batas masih lolos.
      final pas = Uint8List(ApiPelanggan.batasUnduhByte)
        ..setRange(0, 5, utf8.encode('%PDF-'));
      expect(
        (await _api((r) async => _jawab(pas)).unduh('/x')).length,
        pas.length,
      );
    });

    test('galat HTTP tetap dipetakan seperti sebelumnya', () async {
      Future<Object> galat(int status, [Object? isi]) async {
        try {
          await _api(
            (r) async => http.Response(
              jsonEncode(isi ?? {'message': 'No query results for model [X].'}),
              status,
              headers: {'content-type': 'application/json'},
            ),
          ).unduh('/x');
        } catch (e) {
          return e;
        }
        fail('seharusnya gagal');
      }

      expect(
        (await galat(404) as GalatApi).pesan,
        ApiPelanggan.pesan404,
        reason: 'kalimat 404 umum, bukan pesan framework',
      );
      expect(
        (await galat(410, {'message': 'Sertifikat ini sudah dibatalkan lab.'})
                as GalatApi)
            .pesan,
        'Sertifikat ini sudah dibatalkan lab.',
      );
      expect((await galat(500) as GalatApi).status, 500);
    });

    test('401 memanggil saatTokenDitolak', () async {
      var dipanggil = 0;
      await expectLater(
        _api(
          (r) async => http.Response(
            jsonEncode({'kode': 'sesi_berakhir', 'message': 'Sesi berakhir.'}),
            401,
            headers: {'content-type': 'application/json'},
          ),
          saatTokenDitolak: () => dipanggil++,
        ).unduh('/x'),
        throwsA(
          isA<GalatApi>().having(
            (e) => e.tokenTidakBerlaku,
            'tidak berlaku',
            isTrue,
          ),
        ),
      );
      expect(dipanggil, 1);
    });

    test('jaringan putus = galat jaringan', () async {
      await expectLater(
        _api((r) async => throw const SocketException('putus')).unduh('/x'),
        throwsA(isA<GalatApi>().having((e) => e.jaringan, 'jaringan', isTrue)),
      );
    });
  });

  group('unduhDanBukaPdf dan penyimpanan cache', () {
    late Directory cache;
    late Directory dokumen;

    setUp(() {
      cache = Directory.systemTemp.createTempSync('cache_');
      dokumen = Directory.systemTemp.createTempSync('dokumen_');
    });
    tearDown(() {
      for (final d in [cache, dokumen]) {
        if (d.existsSync()) d.deleteSync(recursive: true);
      }
    });

    PenyimpanPratinjau penyimpan() => PenyimpanPratinjau(
      akar: () async => cache,
      akarLama: () async => dokumen,
    );

    LayananPelanggan layanan(
      Future<http.Response> Function(http.Request) server,
      List<String> dibuka,
    ) => LayananPelanggan(
      _api(server),
      penyimpan: penyimpan(),
      pembukaBerkas: (p) async {
        dibuka.add(p);
        return OpenResult();
      },
    );

    test('disimpan di cache, bernama ID, tidak di folder Dokumen', () async {
      final dibuka = <String>[];
      final path = await layanan(
        (r) async => _jawab(_pdf),
        dibuka,
      ).unduhDanBukaPdf(_sertifikat());

      final norm = path.replaceAll(r'\', '/');
      expect(norm, startsWith(cache.path.replaceAll(r'\', '/')));
      expect(norm, contains('/sidik_pratinjau/sertifikat-11.pdf'));
      expect(norm, isNot(contains('RAHASIA')), reason: 'nomor tak ada di nama');
      expect(File(path).readAsBytesSync(), _pdf);
      expect(dibuka, [path]);
      expect(
        dokumen.listSync(),
        isEmpty,
        reason: 'folder Dokumen tak disentuh',
      );
    });

    test('bukan PDF: tidak disimpan dan penampil tidak dipanggil', () async {
      final dibuka = <String>[];
      await expectLater(
        layanan(
          (r) async =>
              _jawab(utf8.encode('<html>wifi</html>'), jenis: 'text/html'),
          dibuka,
        ).unduhDanBukaPdf(_sertifikat()),
        throwsA(_galat('berkas_bukan_pdf', 'bukan PDF')),
      );
      expect(dibuka, isEmpty);
      expect(
        Directory('${cache.path}/sidik_pratinjau').existsSync()
            ? Directory('${cache.path}/sidik_pratinjau').listSync()
            : <FileSystemEntity>[],
        isEmpty,
      );
    });

    test('bersihkan membuang PDF cache DAN sisa unduhan versi lama', () async {
      final p = penyimpan();
      await p.simpan(11, Uint8List.fromList(_pdf));
      // Peninggalan versi ≤ 0.2.2: nomor sertifikat di nama berkas, folder
      // Dokumen, tidak pernah dibersihkan.
      File(
        '${dokumen.path}/Sertifikat-CAL-2026-09-0001.pdf',
      ).writeAsBytesSync(_pdf);
      File(
        '${dokumen.path}/Sertifikat-CAL-2026-09-0002.pdf',
      ).writeAsBytesSync(_pdf);
      // Bukan milik kita: harus tetap ada.
      File('${dokumen.path}/catatan.txt').writeAsStringSync('jangan hapus');
      File(
        '${dokumen.path}/Sertifikat-x.pdf.bak',
      ).writeAsStringSync('jangan hapus');
      Directory('${dokumen.path}/Sertifikat-folder.pdf').createSync();

      await p.bersihkan();

      expect(Directory('${cache.path}/sidik_pratinjau').existsSync(), isFalse);
      final sisa = dokumen
          .listSync()
          .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
          .toSet();
      expect(sisa, {
        'catatan.txt',
        'Sertifikat-x.pdf.bak',
        'Sertifikat-folder.pdf',
      });
    });

    test(
      'bersihkan tetap membuang cache walau folder Dokumen tak terbaca',
      () async {
        final p = PenyimpanPratinjau(
          akar: () async => cache,
          akarLama: () async => throw const FileSystemException('tak terbaca'),
        );
        await p.simpan(11, Uint8List.fromList(_pdf));
        await p.bersihkan();
        expect(
          Directory('${cache.path}/sidik_pratinjau').existsSync(),
          isFalse,
        );
      },
    );
  });
}
