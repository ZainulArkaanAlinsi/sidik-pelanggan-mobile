import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sidik_pelanggan/core/theme/sidik_theme.dart';
import 'package:sidik_pelanggan/models/rilis_aplikasi.dart';
import 'package:sidik_pelanggan/providers/pembaruan_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/gerbang.dart';
import 'package:sidik_pelanggan/services/klien_rilis.dart';
import 'package:sidik_pelanggan/services/pemasang_apk.dart';
import 'package:sidik_pelanggan/widgets/pembaruan.dart';

const _host = {'github.com'};
const _urlApk =
    'https://github.com/ZainulArkaanAlinsi/sidik-pelanggan-mobile/releases/download/v1.2.3%2B45/sidik-pelanggan.apk';

Map<String, dynamic> _manifes({
  int build = 45,
  String url = _urlApk,
  String sha = '',
  int ukuran = 26214400,
  bool wajib = false,
}) => {
  'versi': '1.2.3',
  'build': build,
  'url': url,
  'sha256': sha.isEmpty ? 'a' * 64 : sha,
  'ukuran': ukuran,
  'wajib': wajib,
  'catatan': 'Perbaikan kecil',
};

RilisAplikasi _rilis({int build = 45, bool wajib = false}) =>
    RilisAplikasi.dariJson(
      _manifes(build: build, wajib: wajib),
      hostDiizinkan: _host,
    )!;

/// Respons dengan URL akhir (sesudah redirect), seperti `IOClient`.
class _ResponsUrl extends http.StreamedResponse
    implements http.BaseResponseWithUrl {
  _ResponsUrl(List<int> isi, this.url)
    : super(Stream.value(isi), 200, contentLength: isi.length);

  @override
  final Uri url;
}

class _KlienUji extends http.BaseClient {
  _KlienUji(this.jawab);

  final (List<int>, Uri) Function(http.BaseRequest) jawab;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final (isi, url) = jawab(request);
    return _ResponsUrl(isi, url);
  }
}

class _KlienPalsu implements KlienRilis {
  _KlienPalsu(this.rilis);

  RilisAplikasi? rilis;
  int ambil = 0;
  int unduhan = 0;

  @override
  Future<RilisAplikasi?> ambilTerbaru() async {
    ambil++;
    return rilis;
  }

  @override
  Future<File?> apkSiap(RilisAplikasi rilis) async => null;

  @override
  Future<File> unduh(
    RilisAplikasi rilis, {
    void Function(double? progres)? onProgres,
  }) async {
    unduhan++;
    onProgres?.call(1);
    return File('${Directory.systemTemp.path}/sidik-pelanggan-palsu.apk');
  }
}

class _PemasangPalsu implements PemasangApk {
  _PemasangPalsu({this.wifi = false});

  final bool wifi;
  final dipasang = <String>[];

  @override
  Future<HasilPasang> pasang(File apk) async {
    dipasang.add(apk.path);
    return HasilPasang.dimulai;
  }

  @override
  Future<bool> jaringanTakBerbayar() async => wifi;
}

List<Override> _override(
  _KlienPalsu klien,
  _PemasangPalsu pemasang, {
  String build = '44',
  DateTime Function()? jam,
}) => [
  pembaruanAktifProvider.overrideWithValue(true),
  klienRilisProvider.overrideWithValue(klien),
  pemasangApkProvider.overrideWithValue(pemasang),
  infoPaketProvider.overrideWith((ref) async => (versi: '1.0.0', build: build)),
  if (jam != null) jamProvider.overrideWithValue(jam),
];

void main() {
  group('RilisAplikasi', () {
    test('membaca manifes yang sah', () {
      final r = _rilis();
      expect(r.versi, '1.2.3');
      expect(r.build, 45);
      expect(r.ukuranMb, '25 MB');
      expect(r.wajib, isFalse);
    });

    test('membandingkan build, bukan teks versi', () {
      final r = _rilis(build: 45);
      expect(r.lebihBaruDari(44), isTrue);
      expect(r.lebihBaruDari(9), isTrue); // "45" < "9" sebagai teks
      expect(r.lebihBaruDari(45), isFalse);
      expect(r.lebihBaruDari(46), isFalse);
      // Build terpasang tak terbaca → tidak menawarkan apa-apa.
      expect(r.lebihBaruDari(0), isFalse);
    });

    test('menolak manifes cacat atau dari host lain', () {
      RilisAplikasi? baca(Map<String, dynamic> j) =>
          RilisAplikasi.dariJson(j, hostDiizinkan: _host);
      expect(
        baca(_manifes(url: _urlApk.replaceFirst('https', 'http'))),
        isNull,
      );
      expect(baca(_manifes(url: 'https://contoh.com/a.apk')), isNull);
      expect(baca(_manifes(sha: 'abc')), isNull);
      expect(baca(_manifes(build: 0)), isNull);
      expect(baca({..._manifes(), 'versi': ''}), isNull);
    });
  });

  group('KlienRilisGithub', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('pembaruan_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    final isiApk = utf8.encode('APK PALSU ' * 100);
    final shaBenar = crypto.sha256.convert(isiApk).toString();

    KlienRilisGithub klien(
      List<http.BaseRequest> catat, {
      String? manifes,
      String akhir = 'https://release-assets.githubusercontent.com/a/b',
    }) => KlienRilisGithub(
      client: _KlienUji((req) {
        catat.add(req);
        if (req.url.path.endsWith('.json')) {
          return (utf8.encode(manifes ?? ''), req.url);
        }
        return (isiApk, Uri.parse(akhir));
      }),
      urlManifes: Uri.parse(
        'https://github.com/ZainulArkaanAlinsi/sidik-pelanggan-mobile/releases/latest/download/versi-pelanggan.json',
      ),
      direktori: () async => dir,
    );

    test('membaca manifes (dengan BOM) tanpa header kredensial', () async {
      final catat = <http.BaseRequest>[];
      final r = await klien(
        catat,
        manifes: '${String.fromCharCode(0xFEFF)}${jsonEncode(_manifes())}',
      ).ambilTerbaru();
      expect(r?.build, 45);
      expect(catat.single.method, 'GET');
      expect(
        catat.single.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('authorization')),
      );
    });

    test('SHA-256 tidak cocok → ditolak dan berkas dibuang', () async {
      final r = RilisAplikasi.dariJson(
        _manifes(sha: 'b' * 64, ukuran: isiApk.length),
        hostDiizinkan: _host,
      )!;
      final catat = <http.BaseRequest>[];
      await expectLater(klien(catat).unduh(r), throwsA(isA<ShaTidakCocok>()));
      expect(dir.listSync(), isEmpty);
      expect(
        catat.single.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('authorization')),
      );
    });

    test('SHA-256 cocok → APK tersimpan dan dikenali siap', () async {
      final r = RilisAplikasi.dariJson(
        _manifes(sha: shaBenar, ukuran: isiApk.length),
        hostDiizinkan: _host,
      )!;
      final k = klien([]);
      final apk = await k.unduh(r);
      expect(apk.readAsBytesSync(), isiApk);
      expect((await k.apkSiap(r))?.path, apk.path);
    });

    test('redirect ke host selain GitHub → ditolak sebelum menulis', () async {
      final r = RilisAplikasi.dariJson(
        _manifes(sha: shaBenar, ukuran: isiApk.length),
        hostDiizinkan: _host,
      )!;
      for (final akhir in [
        'https://contoh.com/sidik-pelanggan.apk',
        'https://githubusercontent.com.jahat.net/a.apk',
        'http://objects.githubusercontent.com/a.apk',
      ]) {
        await expectLater(
          klien([], akhir: akhir).unduh(r),
          throwsA(isA<UnduhGagal>()),
          reason: akhir,
        );
      }
      expect(dir.listSync(), isEmpty);
    });

    test('ukuran tidak sesuai manifes → ditolak', () async {
      final r = RilisAplikasi.dariJson(
        _manifes(sha: shaBenar, ukuran: isiApk.length + 1),
        hostDiizinkan: _host,
      )!;
      await expectLater(klien([]).unduh(r), throwsA(isA<UnduhGagal>()));
      expect(dir.listSync(), isEmpty);
    });
  });

  group('PembaruanController', () {
    test('jeda 1 jam antar-pemeriksaan; paksa menembusnya', () async {
      var sekarang = DateTime(2026, 10, 22, 8);
      final klien = _KlienPalsu(_rilis());
      final c = ProviderContainer(
        overrides: _override(klien, _PemasangPalsu(), jam: () => sekarang),
      );
      addTearDown(c.dispose);
      final p = c.read(pembaruanProvider.notifier);

      await p.periksa();
      expect(klien.ambil, 1);
      expect(c.read(pembaruanProvider).rilis?.build, 45);

      await p.periksa();
      sekarang = sekarang.add(const Duration(minutes: 59));
      await p.periksa();
      expect(klien.ambil, 1);

      sekarang = sekarang.add(const Duration(minutes: 1));
      await p.periksa();
      expect(klien.ambil, 2);

      await p.periksa(paksa: true);
      expect(klien.ambil, 3);
    });

    test(
      'build terpasang sama atau lebih baru → tidak ada pembaruan',
      () async {
        final c = ProviderContainer(
          overrides: _override(
            _KlienPalsu(_rilis()),
            _PemasangPalsu(),
            build: '45',
          ),
        );
        addTearDown(c.dispose);
        await c.read(pembaruanProvider.notifier).periksa();
        expect(c.read(pembaruanProvider).tersedia, isFalse);
      },
    );

    test('unduh otomatis hanya di Wi-Fi, dan tidak membuka pemasang', () async {
      final seluler = _KlienPalsu(_rilis());
      final c1 = ProviderContainer(
        overrides: _override(seluler, _PemasangPalsu()),
      );
      addTearDown(c1.dispose);
      await c1.read(pembaruanProvider.notifier).periksa();
      expect(seluler.unduhan, 0);
      expect(c1.read(pembaruanProvider).tahap, TahapPembaruan.diam);

      final wifi = _KlienPalsu(_rilis());
      final pemasang = _PemasangPalsu(wifi: true);
      final c2 = ProviderContainer(overrides: _override(wifi, pemasang));
      addTearDown(c2.dispose);
      await c2.read(pembaruanProvider.notifier).periksa();
      expect(wifi.unduhan, 1);
      expect(c2.read(pembaruanProvider).tahap, TahapPembaruan.siap);
      expect(pemasang.dipasang, isEmpty);
    });

    test('build sama, wajib berubah → rilis diperbarui, APK tetap', () async {
      final klien = _KlienPalsu(_rilis(wajib: true));
      final c = ProviderContainer(
        overrides: _override(klien, _PemasangPalsu(wifi: true)),
      );
      addTearDown(c.dispose);
      final p = c.read(pembaruanProvider.notifier);
      await p.periksa();
      expect(c.read(pembaruanProvider).wajib, isTrue);
      expect(c.read(pembaruanProvider).tahap, TahapPembaruan.siap);

      klien.rilis = _rilis(wajib: false);
      await p.periksa(paksa: true);
      expect(c.read(pembaruanProvider).wajib, isFalse);
      expect(c.read(pembaruanProvider).tahap, TahapPembaruan.siap);
      expect(klien.unduhan, 1);
    });

    test('Perbarui di seluler: unduh lalu buka pemasang', () async {
      final klien = _KlienPalsu(_rilis());
      final pemasang = _PemasangPalsu();
      final c = ProviderContainer(overrides: _override(klien, pemasang));
      addTearDown(c.dispose);
      final p = c.read(pembaruanProvider.notifier);
      await p.periksa();
      await p.perbarui();
      expect(klien.unduhan, 1);
      expect(pemasang.dipasang, hasLength(1));
      expect(c.read(pembaruanProvider).tahap, TahapPembaruan.siap);
    });
  });

  group('UI', () {
    Future<ProviderContainer> pasangBanner(
      WidgetTester tester,
      _KlienPalsu klien,
      _PemasangPalsu pemasang, {
      String build = '44',
    }) async {
      final c = ProviderContainer(
        overrides: _override(klien, pemasang, build: build),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: SidikTheme.terang,
            home: const Scaffold(bottomNavigationBar: BannerPembaruan()),
          ),
        ),
      );
      await tester.runAsync(() => c.read(pembaruanProvider.notifier).periksa());
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('banner tampil saat ada versi baru; Nanti menutupnya', (
      tester,
    ) async {
      final pemasang = _PemasangPalsu();
      await pasangBanner(tester, _KlienPalsu(_rilis()), pemasang);
      expect(find.text('Versi 1.2.3 tersedia'), findsOneWidget);
      expect(find.text('Perbarui (25 MB)'), findsOneWidget);

      await tester.tap(find.text('Nanti'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('banner-pembaruan')), findsNothing);
    });

    testWidgets('banner tidak tampil kalau sudah versi terbaru', (
      tester,
    ) async {
      await pasangBanner(
        tester,
        _KlienPalsu(_rilis()),
        _PemasangPalsu(),
        build: '45',
      );
      expect(find.byKey(const ValueKey('banner-pembaruan')), findsNothing);
    });

    testWidgets('rilis wajib tidak memakai banner yang bisa ditutup', (
      tester,
    ) async {
      await pasangBanner(
        tester,
        _KlienPalsu(_rilis(wajib: true)),
        _PemasangPalsu(),
      );
      expect(find.byKey(const ValueKey('banner-pembaruan')), findsNothing);
    });

    testWidgets('dialog wajib tidak bisa ditutup dengan tombol kembali', (
      tester,
    ) async {
      final c = ProviderContainer(
        overrides: _override(
          _KlienPalsu(_rilis(wajib: true)),
          _PemasangPalsu(),
        ),
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: SidikTheme.terang,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const DialogPembaruanWajib(),
                  ),
                  child: const Text('buka'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => c.read(pembaruanProvider.notifier).periksa());
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();

      expect(find.text('Pembaruan wajib'), findsOneWidget);
      expect(find.text('Nanti'), findsNothing);
      expect(find.text('Perbarui (25 MB)'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Pembaruan wajib'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5)); // di luar dialog
      await tester.pumpAndSettle();
      expect(find.text('Pembaruan wajib'), findsOneWidget);
    });

    testWidgets(
      'gerbang versi minimum memasang di aplikasi, bukan Play Store',
      (tester) async {
        final pemasang = _PemasangPalsu();
        final c = ProviderContainer(
          overrides: _override(_KlienPalsu(_rilis()), pemasang),
        );
        addTearDown(c.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
              theme: SidikTheme.terang,
              home: const LayarWajibPerbarui(
                terpasang: '1.0.0',
                terbaru: '1.2.3',
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => c.read(pembaruanProvider.notifier).periksa(),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Play Store'), findsNothing);
        await tester.tap(find.text('Perbarui (25 MB)'));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
        expect(pemasang.dipasang, hasLength(1));
      },
    );
  });
}
