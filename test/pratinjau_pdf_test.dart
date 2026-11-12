// Fitur 4 (rencana §14.1): pratinjau PDF di dalam aplikasi.
//
// Penampil `pdfx` butuh plugin platform yang tidak ada di `flutter test`, jadi
// layar diuji dengan penampil palsu (`penampilPdfProvider`) yang menirukan
// kontraknya: jumlah halaman, pindah halaman, zoom. Yang dibuktikan di sini:
// jalur unduh (header hanya ke host API), simpan sementara di cache, bersih
// saat keluar akun / ganti perusahaan, kontrol layar, dan keadaan galatnya.
// Tampilan PDF sungguhan di perangkat BELUM dibuktikan oleh test mana pun.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:sidik_pelanggan/app.dart';
import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/konfigurasi.dart';
import 'package:sidik_pelanggan/core/penyimpan_pratinjau.dart';
import 'package:sidik_pelanggan/core/theme/sidik_theme.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/providers/koneksi_provider.dart';
import 'package:sidik_pelanggan/providers/pdf_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/sertifikat/pratinjau_pdf_screen.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_detail_screen.dart';
import 'package:sidik_pelanggan/widgets/penampil_pdf.dart';

import 'dukungan/dukungan.dart';
import 'dukungan/fixture_fitur.dart';

/// Penampil palsu: [jumlah] halaman, mencatat aksi yang diminta layar.
class _Palsu {
  _Palsu({this.jumlah = 3, this.gagalMembuka = false});

  final int jumlah;
  final bool gagalMembuka;
  final catatan = <String>[];
  final putaranDilihat = <int>[];

  PembangunPenampilPdf get pembangun =>
      (context, arg) => _PenampilPalsu(palsu: this, arg: arg);
}

class _PenampilPalsu extends StatefulWidget {
  const _PenampilPalsu({required this.palsu, required this.arg});

  final _Palsu palsu;
  final ArgumenPenampilPdf arg;

  @override
  State<_PenampilPalsu> createState() => _PenampilPalsuState();
}

class _PenampilPalsuState extends State<_PenampilPalsu> {
  @override
  void initState() {
    super.initState();
    final k = widget.arg.kontrol;
    widget.palsu.putaranDilihat.add(widget.arg.putaran);
    k.pasangAksi(
      this,
      keHalaman: (h) async {
        widget.palsu.catatan.add('ke $h');
        k.halamanBerganti(h);
      },
      zoom: (f) => widget.palsu.catatan.add('zoom ${f.toStringAsFixed(2)}'),
    );
    // Seperti plugin: dokumen siap SESUDAH dibuka (async).
    Future<void>.microtask(() {
      if (widget.palsu.gagalMembuka) {
        k.dokumenGagal(Exception('rusak'));
      } else {
        k.dokumenSiap(widget.palsu.jumlah, halaman: k.halaman);
      }
    });
  }

  @override
  void dispose() {
    widget.arg.kontrol.lepasAksi(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'PDF palsu putaran=${widget.arg.putaran}',
      key: const ValueKey('penampil-palsu'),
    ),
  );
}

ServerFitur _server() => ServerFitur({
  3: DataPerusahaan(
    nama: 'PT Alfa',
    sertifikat: [
      sertifikatJson(11, 'CAL/ALFA/0011'),
      sertifikatJson(12, 'CAL/ALFA/0012', status: 'dibatalkan'),
    ],
  ),
  5: DataPerusahaan(nama: 'PT Kosong'),
});

Widget _app(
  Widget anak,
  ServerFitur server, {
  required _Palsu penampil,
  PenyimpanPratinjau? penyimpan,
  int perusahaan = 3,
  bool skalaHp = false,
}) => ProviderScope(
  key: UniqueKey(),
  overrides: overrideFitur(
    server,
    perusahaan: perusahaan,
    pratinjau: penyimpan,
    tambahan: [penampilPdfProvider.overrideWithValue(penampil.pembangun)],
  ),
  child: MaterialApp(
    theme: SidikTheme.terang,
    builder: skalaHp
        ? (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: batasSkalaHuruf.max,
            maxScaleFactor: batasSkalaHuruf.max,
            child: child!,
          )
        : null,
    home: anak,
  ),
);

Sertifikat _sertifikat(int id, {String status = 'berlaku'}) =>
    Sertifikat.dariJson(sertifikatJson(id, 'CAL/ALFA/00$id', status: status));

void _layar(WidgetTester t, {double lebar = 800, double tinggi = 1200}) {
  t.view.physicalSize = Size(lebar, tinggi);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(siapkanTesFitur);

  group('PenyimpanPratinjau (berkas sungguhan)', () {
    late Directory akar;

    setUp(() => akar = Directory.systemTemp.createTempSync('pratinjau_'));
    tearDown(() {
      if (akar.existsSync()) akar.deleteSync(recursive: true);
    });

    PenyimpanPratinjau buat({int maks = 12}) =>
        PenyimpanPratinjau(akar: () async => akar, maks: maks);

    test('menyimpan di folder khusus, bernama ID sertifikat', () async {
      final f = await buat().simpan(11, Uint8List.fromList([1, 2, 3]));
      expect(f.path.replaceAll(r'\', '/'), contains('/sidik_pratinjau/'));
      expect(f.path, endsWith('sertifikat-11.pdf'));
      expect(f.readAsBytesSync(), [1, 2, 3]);
      // Tidak ada nomor sertifikat / nama alat di nama berkas.
      expect(f.path, isNot(contains('CAL')));
    });

    test('menimpa berkas yang sama, tanpa sisa berkas sementara', () async {
      final p = buat();
      await p.simpan(11, Uint8List.fromList([1]));
      final f = await p.simpan(11, Uint8List.fromList([9, 9]));
      expect(f.readAsBytesSync(), [9, 9]);
      final isi = f.parent.listSync().map((e) => e.path).toList();
      expect(isi.length, 1, reason: '$isi');
      expect(isi.single, isNot(endsWith('.tmp')));
    });

    test('paling banyak maks berkas; yang tertua dibuang', () async {
      final p = buat(maks: 3);
      for (var i = 1; i <= 5; i++) {
        final f = await p.simpan(i, Uint8List.fromList([i]));
        f.setLastModifiedSync(DateTime(2026, 1, i));
      }
      // Berkas ke-5 baru saja ditulis; rapikan terjadi pada simpan berikut.
      await p.simpan(6, Uint8List.fromList([6]));
      final nama = Directory(
        '${akar.path}/sidik_pratinjau',
      ).listSync().map((e) => e.path.split(RegExp(r'[\\/]')).last).toSet();
      expect(nama.length, 3);
      expect(nama, contains('sertifikat-6.pdf'));
      expect(nama, isNot(contains('sertifikat-1.pdf')));
    });

    test(
      'dua simpan bersamaan untuk sertifikat yang sama: utuh, tanpa sisa',
      () async {
        final p = buat();
        final a = Uint8List.fromList(List.filled(4096, 1));
        final b = Uint8List.fromList(List.filled(8192, 2));
        final f = await Future.wait([p.simpan(11, a), p.simpan(11, b)]);
        expect(f[0].path, f[1].path);
        final isi = f[0].readAsBytesSync();
        // Salah satunya menang UTUH; tidak ada campuran separuh-separuh.
        expect(isi.length, anyOf(4096, 8192));
        expect(isi.toSet().length, 1);
        final nama = f[0].parent.listSync().map((e) => e.path).toList();
        expect(nama.length, 1, reason: 'tanpa berkas .tmp tertinggal: $nama');
      },
    );

    test('gagal menulis: berkas sementara tidak tertinggal', () async {
      // `sertifikat-11.pdf` sudah ada sebagai FOLDER: rename ke sana gagal.
      Directory(
        '${akar.path}/sidik_pratinjau/sertifikat-11.pdf/isi',
      ).createSync(recursive: true);
      await expectLater(
        buat().simpan(11, Uint8List.fromList([1])),
        throwsA(isA<FileSystemException>()),
      );
      final sisa = Directory(
        '${akar.path}/sidik_pratinjau',
      ).listSync().map((e) => e.path).where((p) => p.endsWith('.tmp'));
      expect(sisa, isEmpty);
    });

    test('bersihkan membuang semuanya; aman dipanggil dua kali', () async {
      final p = buat();
      await p.simpan(11, Uint8List.fromList([1]));
      await p.simpan(12, Uint8List.fromList([2]));
      await p.bersihkan();
      expect(Directory('${akar.path}/sidik_pratinjau').existsSync(), isFalse);
      await p.bersihkan();
    });

    test('bersihkan tidak melempar bila folder cache tak terjangkau', () async {
      final rusak = PenyimpanPratinjau(
        akar: () async => throw const FileSystemException('tidak ada'),
      );
      await rusak.bersihkan();
    });

    test('folder = cache aplikasi, bukan folder publik', () {
      final isi = File('lib/core/penyimpan_pratinjau.dart').readAsStringSync();
      expect(isi, contains('getApplicationCacheDirectory'));
      // Folder Dokumen aplikasi dibaca HANYA untuk membuang sisa unduhan
      // versi lama (`Sertifikat-*.pdf`); PDF baru tidak pernah ditulis ke sana.
      expect(
        RegExp('getApplicationDocumentsDirectory').allMatches(isi).length,
        1,
      );
      expect(
        isi,
        contains('_akarLama = akarLama ?? getApplicationDocumentsDirectory'),
      );
      for (final publik in [
        'getExternalStorageDirectory',
        'getDownloadsDirectory',
        'getExternalCacheDirectories',
        '/sdcard',
        '/storage/emulated',
      ]) {
        expect(isi, isNot(contains(publik)), reason: publik);
      }
    });
  });

  group('batas kode', () {
    test('pdfx hanya diimpor satu berkas', () {
      final pelanggar = [
        for (final f in Directory('lib').listSync(recursive: true))
          if (f is File &&
              f.path.endsWith('.dart') &&
              f.readAsStringSync().contains('package:pdfx/') &&
              !f.path
                  .replaceAll(r'\', '/')
                  .endsWith('lib/widgets/penampil_pdf.dart'))
            f.path,
      ];
      expect(pelanggar, isEmpty);
    });

    test(
      'layar pratinjau tidak bicara HTTP sendiri dan tidak menyebut GitHub',
      () {
        final isi = File(
          'lib/screens/sertifikat/pratinjau_pdf_screen.dart',
        ).readAsStringSync();
        // Komentar boleh menyebut header; kodenya tidak.
        final kode = isi
            .split('\n')
            .where((l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        expect(kode, isNot(contains('package:http')));
        expect(kode.toLowerCase(), isNot(contains('github')));
        expect(kode, isNot(contains('Authorization')));
      },
    );
  });

  group('sesi membersihkan salinan PDF', () {
    Akun akun2() => Akun.dariJson({
      'id': 7,
      'nama': 'Budi Anggota',
      'email': 'budi@contoh.test',
      'status': 'aktif',
      'butuh_verifikasi': false,
      'keanggotaan': [
        {'customer_id': 3, 'nama_perusahaan': 'PT Alfa', 'peran': 'staf'},
        {'customer_id': 4, 'nama_perusahaan': 'PT Beta', 'peran': 'staf'},
      ],
    });

    test('ganti perusahaan dan keluar akun membuang semua salinan', () async {
      final memori = PenyimpanPratinjauMemori();
      final layanan = _LayananSesi(akun2());
      final c = ProviderContainer(
        overrides: overrideDasar(
          sesi: PenyimpanSesiMemori(
            tokenAwal: 'tkn',
            penggunaAwal: 7,
            perusahaanAwal: 3,
          ),
          pratinjau: memori,
          tambahan: [layananProvider.overrideWithValue(layanan)],
        ),
      );
      addTearDown(c.dispose);
      final sesi = await c.read(sesiProvider.future);
      expect(sesi?.perusahaanId, 3);

      await memori.simpan(11, Uint8List.fromList([1]));
      final sebelumGanti = memori.dibersihkan;
      c.read(sesiProvider.notifier).pilihPerusahaan(4);
      await Future<void>.delayed(Duration.zero);
      expect(memori.dibersihkan, greaterThan(sebelumGanti));
      expect(memori.isi, isEmpty, reason: 'PDF PT lama tidak tertinggal');

      await memori.simpan(12, Uint8List.fromList([2]));
      await c.read(sesiProvider.notifier).keluar();
      expect(memori.isi, isEmpty, reason: 'keluar akun membuangnya');
      expect(c.read(sesiProvider).value, isNull);
    });
  });

  group('sesi membersihkan salinan PDF: 401 dan masuk', () {
    http.Response json(Object isi, [int status = 200]) => http.Response(
      jsonEncode(isi),
      status,
      headers: {'content-type': 'application/json'},
    );

    Map<String, dynamic> akunJson() => {
      'id': 7,
      'nama': 'Budi Anggota',
      'email': 'budi@contoh.test',
      'status': 'aktif',
      'butuh_verifikasi': false,
      'keanggotaan': [
        {'customer_id': 3, 'nama_perusahaan': 'PT Alfa', 'peran': 'staf'},
      ],
    };

    ProviderContainer buat(
      Future<http.Response> Function(http.Request) server,
      PenyimpanPratinjauMemori memori,
      PenyimpanSesiMemori sesi,
    ) {
      final c = ProviderContainer(
        overrides: [
          ...overrideDasar(sesi: sesi, pratinjau: memori),
          apiProvider.overrideWithValue(
            ApiPelanggan(klien: MockClient(server), jedaUlang: const []),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('401 saat memulihkan sesi (token tersimpan sudah dicabut)', () async {
      final memori = PenyimpanPratinjauMemori()..isi[11] = [1, 2, 3];
      final sesi = PenyimpanSesiMemori(
        tokenAwal: 'tkn-lama',
        penggunaAwal: 7,
        perusahaanAwal: 3,
      );
      final c = buat(
        (r) async =>
            json({'kode': 'sesi_berakhir', 'message': 'Sesi berakhir.'}, 401),
        memori,
        sesi,
      );

      final hasil = await c.read(sesiProvider.future);

      expect(hasil, isNull, reason: 'kembali ke layar masuk');
      expect(sesi.tokenAwal, isNull, reason: 'token lokal dibuang');
      expect(memori.isi, isEmpty, reason: 'PDF sesi lama tidak tertinggal');
      expect(memori.dibersihkan, greaterThanOrEqualTo(1));
    });

    test('401 di tengah sesi (token dicabut dari HP lain)', () async {
      final memori = PenyimpanPratinjauMemori();
      final sesi = PenyimpanSesiMemori(
        tokenAwal: 'tkn',
        penggunaAwal: 7,
        perusahaanAwal: 3,
      );
      final c = buat(
        (r) async {
          final jalur = r.url.path.replaceFirst(Konfigurasi.prefix, '');
          if (jalur == '/saya') return json({'data': akunJson()});
          return json({
            'kode': 'sesi_berakhir',
            'message': 'Sesi berakhir.',
          }, 401);
        },
        memori,
        sesi,
      );
      expect((await c.read(sesiProvider.future))?.perusahaanId, 3);

      // Pengguna sudah membuka pratinjau; lalu server menolak tokennya.
      await memori.simpan(11, Uint8List.fromList([1, 2, 3]));
      await expectLater(
        c.read(layananProvider).alat(1),
        throwsA(isA<GalatApi>().having((e) => e.status, 'status', 401)),
      );
      await pumpEventQueue();

      expect(c.read(sesiBerakhirProvider), isTrue);
      expect(c.read(sesiProvider).value, isNull);
      expect(memori.isi, isEmpty, reason: 'PDF dibuang walau data cache tetap');
    });

    test('masuk membuang sisa PDF dari proses yang dimatikan paksa', () async {
      final memori = PenyimpanPratinjauMemori()..isi[12] = [9, 9];
      final sesi = PenyimpanSesiMemori(); // belum ada token
      final c = buat(
        (r) async {
          final jalur = r.url.path.replaceFirst(Konfigurasi.prefix, '');
          if (r.method == 'POST' && jalur == '/auth/masuk') {
            return json({
              'data': {'token': 'tkn-baru', 'user': akunJson()},
            });
          }
          return json({'data': akunJson()});
        },
        memori,
        sesi,
      );
      expect(await c.read(sesiProvider.future), isNull);
      expect(memori.isi, isNotEmpty, reason: 'sisa dari sesi sebelumnya');

      await c
          .read(sesiProvider.notifier)
          .masuk('budi@contoh.test', 'rahasia-uji');
      await pumpEventQueue();

      expect(c.read(sesiProvider).value?.perusahaanId, 3);
      expect(memori.isi, isEmpty, reason: 'akun baru mulai dari bersih');
    });
  });

  group('layar pratinjau', () {
    testWidgets('dari detail: Lihat PDF, unduh lewat API, simpan sementara', (
      tester,
    ) async {
      _layar(tester);
      final server = _server();
      final memori = PenyimpanPratinjauMemori();
      await tester.pumpWidget(
        _app(
          const SertifikatDetailScreen(id: 11),
          server,
          penampil: _Palsu(),
          penyimpan: memori,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lihat PDF'), findsOneWidget);
      expect(find.text('Unduh PDF'), findsOneWidget);

      await tester.tap(find.text('Lihat PDF'));
      await tester.pumpAndSettle();

      expect(find.byType(PratinjauPdfScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('penampil-palsu')), findsOneWidget);
      expect(find.text('Halaman 1 dari 3'), findsOneWidget);

      // Satu unduhan, lewat rute unduh, dengan token — hanya ke host API.
      final unduh = server
          .yang('GET', RegExp(r'^/sertifikat/11/unduh$'))
          .toList();
      expect(unduh.length, 1);
      final api = Uri.parse(Konfigurasi.apiBaseUrl);
      for (final r in server.permintaan) {
        expect(r.method, 'GET', reason: 'pratinjau tidak menulis apa pun');
        expect(r.url.host, api.host, reason: 'host selain API: ${r.url}');
        expect(r.url.host, isNot(contains('github')));
        expect(r.headers['Authorization'], 'Bearer ${ServerFitur.token}');
      }
      // Disimpan di penyimpan cache, sama persis dengan yang diunduh.
      expect(memori.isi[11], ServerFitur.pdf);
    });

    testWidgets('pindah halaman: tombol, label, dan batas awal/akhir', (
      tester,
    ) async {
      _layar(tester);
      final palsu = _Palsu(jumlah: 3);
      await tester.pumpWidget(
        _app(
          PratinjauPdfScreen(sertifikat: _sertifikat(11)),
          _server(),
          penampil: palsu,
        ),
      );
      await tester.pumpAndSettle();

      IconButton tombol(IconData ikon) =>
          tester.widget<IconButton>(find.widgetWithIcon(IconButton, ikon));
      expect(tombol(Icons.chevron_left).onPressed, isNull, reason: 'halaman 1');
      expect(tombol(Icons.chevron_right).onPressed, isNotNull);

      await tester.tap(find.byTooltip('Halaman berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('Halaman 2 dari 3'), findsOneWidget);
      await tester.tap(find.byTooltip('Halaman berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('Halaman 3 dari 3'), findsOneWidget);
      expect(tombol(Icons.chevron_right).onPressed, isNull, reason: 'terakhir');

      await tester.tap(find.byTooltip('Halaman sebelumnya'));
      await tester.pumpAndSettle();
      expect(find.text('Halaman 2 dari 3'), findsOneWidget);
      expect(palsu.catatan, ['ke 2', 'ke 3', 'ke 2']);
    });

    testWidgets('perbesar dan perkecil meminta penampil menskala', (
      tester,
    ) async {
      _layar(tester);
      final palsu = _Palsu();
      await tester.pumpWidget(
        _app(
          PratinjauPdfScreen(sertifikat: _sertifikat(11)),
          _server(),
          penampil: palsu,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Perbesar'));
      await tester.tap(find.text('Perkecil'));
      await tester.pump();
      expect(palsu.catatan, ['zoom 1.50', 'zoom 0.67']);
    });

    testWidgets('putar: 90° tiap ketukan, kembali ke 0 setelah empat kali', (
      tester,
    ) async {
      _layar(tester);
      final palsu = _Palsu();
      await tester.pumpWidget(
        _app(
          PratinjauPdfScreen(sertifikat: _sertifikat(11)),
          _server(),
          penampil: palsu,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PDF palsu putaran=0'), findsOneWidget);

      for (final n in [1, 2, 3, 0]) {
        await tester.tap(find.text('Putar'));
        await tester.pumpAndSettle();
        expect(find.text('PDF palsu putaran=$n'), findsOneWidget);
      }
      // Halaman yang dibaca tidak hilang saat memutar.
      await tester.tap(find.byTooltip('Halaman berikutnya'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Putar'));
      await tester.pumpAndSettle();
      expect(find.text('Halaman 2 dari 3'), findsOneWidget);
    });

    testWidgets('alat bantu mati sampai dokumen terbuka', (tester) async {
      _layar(tester);
      await tester.pumpWidget(
        _app(
          PratinjauPdfScreen(sertifikat: _sertifikat(11)),
          _server(),
          // Penampil yang belum/tidak melaporkan halaman apa pun.
          penampil: _Palsu(jumlah: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Membuka halaman…'), findsOneWidget);
      for (final label in ['Perkecil', 'Perbesar', 'Putar']) {
        final tap = tester
            .widget<InkWell>(
              find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(InkWell),
                  )
                  .first,
            )
            .onTap;
        expect(tap, isNull, reason: label);
      }
    });

    testWidgets('sertifikat dibatalkan (410): pesan server, tanpa Coba lagi', (
      tester,
    ) async {
      _layar(tester);
      await tester.pumpWidget(
        _app(
          PratinjauPdfScreen(sertifikat: _sertifikat(12, status: 'dibatalkan')),
          _server(),
          penampil: _Palsu(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('sudah dibatalkan lab'), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
      expect(find.byKey(const ValueKey('penampil-palsu')), findsNothing);
    });

    testWidgets('ditutup selagi mengunduh: PDF tidak ditulis ke cache', (
      tester,
    ) async {
      _layar(tester);
      final server = _server()..jeda = const Duration(seconds: 2);
      final memori = PenyimpanPratinjauMemori();
      await tester.pumpWidget(
        _app(
          PratinjauPdfScreen(sertifikat: _sertifikat(11)),
          server,
          penampil: _Palsu(),
          penyimpan: memori,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(server.yang('GET', RegExp(r'/unduh$')).length, 1);

      // Pengguna menutup layar; unduhan baru selesai sesudahnya.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));

      expect(memori.isi, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('server mengirim HTML, bukan PDF: ditolak, tidak disimpan', (
      tester,
    ) async {
      _layar(tester);
      final server = _server()
        ..timpaUnduh = (r) async => http.Response(
          '<html><body>Login wifi</body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      final memori = PenyimpanPratinjauMemori();
      await tester.pumpWidget(
        _app(
          PratinjauPdfScreen(sertifikat: _sertifikat(11)),
          server,
          penampil: _Palsu(),
          penyimpan: memori,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('bukan PDF'), findsOneWidget);
      expect(find.byKey(const ValueKey('penampil-palsu')), findsNothing);
      expect(memori.isi, isEmpty, reason: 'tidak ada yang disimpan');
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('milik perusahaan lain: kalimat 404 umum', (tester) async {
      _layar(tester);
      await tester.pumpWidget(
        _app(
          PratinjauPdfScreen(sertifikat: _sertifikat(11)),
          _server(),
          penampil: _Palsu(),
          perusahaan: 5,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Data ini tidak ditemukan atau Anda tidak punya akses.'),
        findsOneWidget,
      );
    });

    testWidgets('galat server: Coba lagi memulihkan', (tester) async {
      _layar(tester);
      final server = _server()..gagal.add('/sertifikat');
      await tester.pumpWidget(
        _app(
          PratinjauPdfScreen(sertifikat: _sertifikat(11)),
          server,
          penampil: _Palsu(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Terjadi kendala di server'), findsOneWidget);

      server.gagal.clear();
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('penampil-palsu')), findsOneWidget);
    });

    testWidgets('gagal simpan di HP: kalimat yang menjelaskan', (tester) async {
      _layar(tester);
      await tester.pumpWidget(
        _app(
          PratinjauPdfScreen(sertifikat: _sertifikat(11)),
          _server(),
          penampil: _Palsu(),
          penyimpan: _PenyimpanPenuh(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('gagal disimpan di HP'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('PDF tidak bisa dirender: jalan keluar ke aplikasi PDF lain', (
      tester,
    ) async {
      _layar(tester);
      final layanan = _LayananBuka();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrideFitur(
              _server(),
              tambahan: [
                penampilPdfProvider.overrideWithValue(
                  _Palsu(gagalMembuka: true).pembangun,
                ),
              ],
            ),
            layananProvider.overrideWithValue(layanan),
          ],
          child: MaterialApp(
            theme: SidikTheme.terang,
            home: PratinjauPdfScreen(sertifikat: _sertifikat(11)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('tidak bisa ditampilkan di aplikasi'),
        findsOneWidget,
      );
      await tester.tap(find.text('Buka di aplikasi PDF lain'));
      await tester.pumpAndSettle();
      expect(layanan.dibuka, [11]);
    });

    testWidgets(
      'detail: Lihat PDF mati untuk dibatalkan, belum siap, dan offline',
      (tester) async {
        _layar(tester);
        final server = ServerFitur({
          3: DataPerusahaan(
            nama: 'PT Alfa',
            sertifikat: [
              sertifikatJson(11, 'CAL/A/11'),
              sertifikatJson(12, 'CAL/A/12', status: 'dibatalkan'),
              sertifikatJson(13, 'CAL/A/13', bisaDiunduh: false),
            ],
          ),
        });

        Future<bool> aktif(int id) async {
          await tester.pumpWidget(
            _app(SertifikatDetailScreen(id: id), server, penampil: _Palsu()),
          );
          await tester.pumpAndSettle();
          return tester
                  .widget<GestureDetector>(
                    find
                        .ancestor(
                          of: find.text('Lihat PDF'),
                          matching: find.byType(GestureDetector),
                        )
                        .first,
                  )
                  .onTap !=
              null;
        }

        expect(await aktif(11), isTrue);
        expect(await aktif(12), isFalse, reason: 'dibatalkan');
        expect(await aktif(13), isFalse, reason: 'PDF belum siap');

        // Offline: tombol mati dan alasannya tertulis.
        await tester.pumpWidget(
          _app(
            const SertifikatDetailScreen(id: 11),
            server,
            penampil: _Palsu(),
          ),
        );
        await tester.pumpAndSettle();
        ProviderScope.containerOf(
          tester.element(find.byType(SertifikatDetailScreen)),
        ).read(koneksiProvider.notifier).offline(null);
        await tester.pumpAndSettle();
        expect(
          find.text('Sambungkan internet untuk mengunduh PDF.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('320 dp / 1,3×: bilah alat tanpa luapan, sentuh ≥ 48 dp', (
      tester,
    ) async {
      _layar(tester, lebar: 320, tinggi: 640);
      // Padding navigasi sistem 48 dp di bawah (edge-to-edge).
      tester.view.padding = const FakeViewPadding(bottom: 48);
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.pumpWidget(
        _app(
          PratinjauPdfScreen(
            sertifikat: Sertifikat.dariJson(
              sertifikatJson(11, 'CAL/2026/09/000123-REV.2-PANJANG-SEKALI'),
            ),
          ),
          _server(),
          penampil: _Palsu(jumlah: 12),
          skalaHp: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Halaman 1 dari 12'), findsOneWidget);

      for (final ikon in [Icons.chevron_left, Icons.chevron_right]) {
        final ukuran = tester.getSize(find.widgetWithIcon(IconButton, ikon));
        expect(ukuran.width, greaterThanOrEqualTo(48));
        expect(ukuran.height, greaterThanOrEqualTo(48));
      }
      for (final label in ['Perkecil', 'Perbesar', 'Putar']) {
        final ukuran = tester.getSize(
          find
              .ancestor(of: find.text(label), matching: find.byType(InkWell))
              .first,
        );
        expect(ukuran.width, greaterThanOrEqualTo(48), reason: label);
        expect(ukuran.height, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets(
      'keluar dari layar tidak memanggil penampil lagi (tanpa bocor)',
      (tester) async {
        _layar(tester);
        final palsu = _Palsu();
        await tester.pumpWidget(
          _app(
            PratinjauPdfScreen(sertifikat: _sertifikat(11)),
            _server(),
            penampil: palsu,
          ),
        );
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}

/// Layanan untuk `SesiController` sungguhan: akun tetap, keluar diam.
class _LayananSesi extends LayananUji {
  _LayananSesi(this.akun);

  final Akun akun;

  @override
  Future<Akun> saya() async => akun;

  @override
  Future<void> keluar() async {}
}

/// Mencatat sertifikat yang dibuka di aplikasi PDF lain.
class _LayananBuka extends LayananUji {
  final dibuka = <int>[];

  @override
  Future<Uint8List> unduhPdf(Sertifikat s) async =>
      Uint8List.fromList(ServerFitur.pdf);

  @override
  Future<String> unduhDanBukaPdf(Sertifikat s) async {
    dibuka.add(s.id);
    return 'tidak-dipakai';
  }
}

/// Penyimpanan yang selalu gagal (ruang habis).
class _PenyimpanPenuh extends PenyimpanPratinjauMemori {
  @override
  Future<File> simpan(int idSertifikat, Uint8List byte) async =>
      throw const FileSystemException('ruang penyimpanan habis');
}
