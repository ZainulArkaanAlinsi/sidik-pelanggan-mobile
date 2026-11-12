import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_filex/open_filex.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/penyimpan_pratinjau.dart';
import 'package:sidik_pelanggan/core/theme/sidik_theme.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/akun/bantuan_screen.dart';
import 'package:sidik_pelanggan/screens/auth/masuk_screen.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_detail_screen.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';

/// Perbaikan hasil pelatihan: pesan 404 unduh, galat unduh/simpan/buka PDF,
/// teks "Draf", dan /app/info yang belum ada di server.
http.Response _json(Object badan, int status) =>
    http.Response(jsonEncode(badan), status);

const _pesanGenerik = 'Data ini tidak ditemukan atau Anda tidak punya akses.';

Sertifikat _sertifikat() => Sertifikat.dariJson({
  'id': 9,
  'nomor': 'CAL/2026/09/0002',
  'diterbitkan_pada': '2026-09-20',
  'alat': {'id': 1, 'nama': 'Jangka Sorong'},
  'bisa_diunduh': true,
});

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  group('1. 404 rute unduh vs rute detail', () {
    ApiPelanggan apiDengan(int status, Object badan) =>
        ApiPelanggan(klien: MockClient((_) async => _json(badan, status)));

    test('unduh: pesan khusus server dipakai ("PDF belum siap")', () async {
      final api = apiDengan(404, {
        'message': 'Sertifikat ini belum punya PDF yang bisa diunduh.',
      });
      await expectLater(
        api.unduh('/sertifikat/9/unduh'),
        throwsA(
          isA<GalatApi>()
              .having((e) => e.status, 'status', 404)
              .having(
                (e) => e.pesan,
                'pesan',
                'Sertifikat ini belum punya PDF yang bisa diunduh.',
              ),
        ),
      );
    });

    test(
      'unduh: "Berkas PDF tidak ditemukan" juga dipakai apa adanya',
      () async {
        final api = apiDengan(404, {
          'message': 'Berkas PDF sertifikat ini tidak ditemukan.',
        });
        await expectLater(
          api.unduh('/sertifikat/9/unduh'),
          throwsA(
            isA<GalatApi>().having(
              (e) => e.pesan,
              'pesan',
              'Berkas PDF sertifikat ini tidak ditemukan.',
            ),
          ),
        );
      },
    );

    test(
      'unduh: 404 lintas-perusahaan/tak ada (pesan bawaan Laravel) tetap generik',
      () async {
        for (final bawaan in [
          r'No query results for model [App\Models\Certificate] 5',
          'Not Found',
          'The route api/pelanggan/v1/x could not be found.',
          '',
        ]) {
          final api = apiDengan(404, {'message': bawaan});
          await expectLater(
            api.unduh('/sertifikat/5/unduh'),
            throwsA(
              isA<GalatApi>().having((e) => e.pesan, 'pesan', _pesanGenerik),
            ),
            reason: 'pesan bawaan "$bawaan"',
          );
        }
      },
    );

    test('unduh: 404 tanpa JSON (halaman proxy) memakai generik', () async {
      final api = ApiPelanggan(
        klien: MockClient((_) async => http.Response('<html>', 404)),
      );
      await expectLater(
        api.unduh('/sertifikat/5/unduh'),
        throwsA(isA<GalatApi>().having((e) => e.pesan, 'pesan', _pesanGenerik)),
      );
    });

    test('rute detail: pesan server pada 404 TIDAK dipakai', () async {
      final api = apiDengan(404, {
        'message': 'Sertifikat ini belum punya PDF yang bisa diunduh.',
      });
      await expectLater(
        api.get('/sertifikat/9'),
        throwsA(isA<GalatApi>().having((e) => e.pesan, 'pesan', _pesanGenerik)),
      );
    });
  });

  group('2. unduhDanBukaPdf memisahkan tahap gagal', () {
    late Directory folder;

    setUp(() async => folder = await Directory.systemTemp.createTemp('pdf'));
    tearDown(() async => folder.delete(recursive: true));

    LayananPelanggan layanan({
      required http.Client klien,
      Future<Directory> Function()? akar,
      Future<OpenResult> Function(String)? buka,
    }) => LayananPelanggan(
      ApiPelanggan(klien: klien),
      penyimpan: PenyimpanPratinjau(
        akar: akar ?? () async => folder,
        akarLama: () async => folder,
      ),
      pembukaBerkas: buka ?? (_) async => OpenResult(),
    );

    final pdfOk = MockClient(
      (_) async => http.Response(
        '%PDF-1.4',
        200,
        headers: {'content-type': 'application/pdf'},
      ),
    );

    test('sukses: berkas tertulis dan dibuka', () async {
      String? dibuka;
      final path = await layanan(
        klien: pdfOk,
        buka: (p) async {
          dibuka = p;
          return OpenResult();
        },
      ).unduhDanBukaPdf(_sertifikat());
      expect(dibuka, path);
      expect(File(path).readAsStringSync(), '%PDF-1.4');
    });

    test('tidak ada aplikasi pembuka -> tidakAdaPembuka', () async {
      await expectLater(
        layanan(
          klien: pdfOk,
          buka: (_) async => OpenResult(type: ResultType.noAppToOpen),
        ).unduhDanBukaPdf(_sertifikat()),
        throwsA(
          isA<GalatBerkasPdf>().having(
            (e) => e.jenis,
            'jenis',
            JenisGagalPdf.tidakAdaPembuka,
          ),
        ),
      );
    });

    test('penampil galat / izin ditolak / melempar -> buka', () async {
      for (final buka in <Future<OpenResult> Function(String)>[
        (_) async => OpenResult(type: ResultType.error),
        (_) async => OpenResult(type: ResultType.permissionDenied),
        (_) async => throw StateError('plugin'),
      ]) {
        await expectLater(
          layanan(klien: pdfOk, buka: buka).unduhDanBukaPdf(_sertifikat()),
          throwsA(
            isA<GalatBerkasPdf>().having(
              (e) => e.jenis,
              'jenis',
              JenisGagalPdf.buka,
            ),
          ),
        );
      }
    });

    test('gagal tulis berkas -> simpan (bukan "tidak ada pembuka")', () async {
      await expectLater(
        layanan(
          klien: pdfOk,
          // Folder cache tidak bisa dibuat: induknya berkas biasa.
          akar: () async {
            final berkas = File('${folder.path}/bukan-folder')
              ..writeAsStringSync('x');
            return Directory('${berkas.path}/dalam');
          },
        ).unduhDanBukaPdf(_sertifikat()),
        throwsA(
          isA<GalatBerkasPdf>().having(
            (e) => e.jenis,
            'jenis',
            JenisGagalPdf.simpan,
          ),
        ),
      );
    });

    test('jaringan putus saat unduh tetap GalatApi jaringan', () async {
      await expectLater(
        layanan(
          klien: MockClient((_) async => throw const SocketException('putus')),
        ).unduhDanBukaPdf(_sertifikat()),
        throwsA(isA<GalatApi>().having((e) => e.jaringan, 'jaringan', isTrue)),
      );
    });

    test('tiga pesan berbeda satu sama lain', () {
      final pesan = {
        for (final j in JenisGagalPdf.values) GalatBerkasPdf(j).pesan,
      };
      expect(pesan, hasLength(3));
    });
  });

  group('2b. layar detail sertifikat menampilkan pesan yang tepat', () {
    Future<void> ketukUnduh(WidgetTester tester, Object galat) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [layananProvider.overrideWithValue(_LayananGagal(galat))],
          child: MaterialApp(
            theme: SidikTheme.terang,
            home: const SertifikatDetailScreen(id: 9),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Unduh PDF'));
      await tester.tap(find.text('Unduh PDF'));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('gagal simpan bukan "tidak ada aplikasi pembuka"', (
      tester,
    ) async {
      await ketukUnduh(tester, const GalatBerkasPdf(JenisGagalPdf.simpan));
      expect(find.textContaining('gagal disimpan'), findsOneWidget);
      expect(find.textContaining('tidak ada aplikasi'), findsNothing);
    });

    testWidgets('tidak ada pembuka PDF', (tester) async {
      await ketukUnduh(
        tester,
        const GalatBerkasPdf(JenisGagalPdf.tidakAdaPembuka),
      );
      expect(find.textContaining('tidak ada aplikasi pembuka'), findsOneWidget);
    });

    testWidgets('gagal unduh / jaringan memakai pesan galat API', (
      tester,
    ) async {
      await ketukUnduh(tester, GalatApi.jaringan());
      expect(find.textContaining('Tidak bisa terhubung'), findsOneWidget);
      expect(find.textContaining('tidak ada aplikasi'), findsNothing);
    });

    testWidgets('galat tak dikenal tidak dituduh "tidak ada pembuka"', (
      tester,
    ) async {
      await ketukUnduh(tester, StateError('apa saja'));
      expect(find.textContaining('PDF belum bisa dibuka'), findsOneWidget);
      expect(find.textContaining('tidak ada aplikasi'), findsNothing);
    });
  });

  group('3. layar Masuk tanpa janji "draf"', () {
    testWidgets('sesi berakhir: tidak menyebut draf', (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sesiBerakhirProvider.notifier).atur(true);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: SidikTheme.terang,
            home: const MasukScreen(),
          ),
        ),
      );
      expect(find.text('Sesi Anda berakhir. Silakan masuk lagi.'), findsOne);
      expect(find.textContaining('Draf'), findsNothing);
      expect(find.textContaining('draf'), findsNothing);
    });
  });

  group('5. GET /app/info toleran', () {
    test('field null / kosong / tipe aneh -> tidak melempar, tanpa kontak', () {
      for (final j in <Map<String, dynamic>>[
        {},
        {'organisasi': null, 'kontak': null, 'dokumen': null},
        {
          'kontak': {'whatsapp': null, 'whatsapp_url': '  ', 'email': ''},
          'dokumen': {'kebijakan_privasi': null, 'syarat_ketentuan': null},
        },
      ]) {
        final info = InfoAplikasi.dariJson(j);
        expect(info.adaKontak, isFalse);
        expect(info.adaDokumen, isFalse);
      }
    });

    LayananPelanggan layananDari(http.Response Function() jawab) =>
        LayananPelanggan(ApiPelanggan(klien: MockClient((_) async => jawab())));

    test('data null -> kosong; 404 -> kosong; 503 tetap galat', () async {
      expect(
        (await layananDari(
          () => _json({'data': null}, 200),
        ).infoAplikasi()).adaKontak,
        isFalse,
      );
      final k404 = await layananDari(
        () => _json({'message': 'The route could not be found.'}, 404),
      ).infoAplikasi();
      expect(k404.adaKontak, isFalse);
      expect(k404.adaDokumen, isFalse);
      await expectLater(
        layananDari(() => _json({}, 503)).infoAplikasi(),
        throwsA(isA<GalatApi>().having((e) => e.status, 'status', 503)),
      );
    });

    Widget bantuan(LayananPelanggan l) => ProviderScope(
      overrides: [
        layananProvider.overrideWithValue(l),
        infoPaketProvider.overrideWith(
          (ref) async => (versi: '1.0.0', build: '1'),
        ),
      ],
      child: MaterialApp(theme: SidikTheme.terang, home: const BantuanScreen()),
    );

    testWidgets('Bantuan saat server 404: pesan ramah, tanpa galat mentah', (
      tester,
    ) async {
      await tester.pumpWidget(
        bantuan(layananDari(() => _json({'message': 'No query results'}, 404))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Informasi kontak belum tersedia.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
      expect(find.textContaining('tidak punya akses'), findsNothing);
      expect(find.text('WhatsApp'), findsNothing);
      expect(find.text('Email'), findsNothing);
    });

    testWidgets('Bantuan dengan field null: tampil tanpa tombol kontak', (
      tester,
    ) async {
      await tester.pumpWidget(
        bantuan(
          layananDari(
            () => _json({
              'data': {'organisasi': null, 'kontak': null, 'dokumen': null},
            }, 200),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Informasi kontak belum tersedia.'), findsOneWidget);
    });
  });
}

/// Layanan yang menyajikan satu sertifikat lalu gagal saat diunduh.
class _LayananGagal extends LayananPelanggan {
  _LayananGagal(this.galat) : super(ApiPelanggan());

  final Object galat;

  @override
  Future<Sertifikat> sertifikat(int id) async => _sertifikat();

  @override
  Future<String> unduhDanBukaPdf(Sertifikat s) async => throw galat;
}
