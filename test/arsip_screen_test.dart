// Layar Arsip sertifikat: tahun → bulan → pekan → hari, pencarian, dan semua
// keadaan (memuat, kosong, galat, hasil, cari tanpa hasil, 404). Layanan
// palsu mencatat parameter yang dikirim layar; satu tes menjalankan alur yang
// sama lewat ApiPelanggan asli dan server palsu.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/models/arsip.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/sertifikat/arsip_screen.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_screen.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_detail_screen.dart';
import 'package:sidik_pelanggan/services/layanan_pelanggan.dart';
import 'package:sidik_pelanggan/widgets/kartu_kelompok_arsip.dart';
import 'package:sidik_pelanggan/widgets/kartu_sertifikat.dart';
import 'package:sidik_pelanggan/widgets/kerangka.dart';
import 'package:sidik_pelanggan/widgets/kolom_cari.dart';

import 'dukungan/dukungan.dart';
import 'dukungan/fixture_arsip.dart';
import 'dukungan/fixture_fitur.dart';
import 'dukungan/layar_uji.dart';

/// Jawaban server palsu menurut tingkat yang diminta.
Future<HasilArsip> _server(ParameterArsip p, int halaman) async =>
    HasilArsip.dariJson(switch (p.tingkat) {
      TingkatArsip.tahun => arsipTahun(),
      TingkatArsip.bulan => arsipBulan(),
      TingkatArsip.pekan => arsipPekanNovember(),
      TingkatArsip.hari => arsipHari(),
    });

List<Override> _override(LayananPelanggan layanan) =>
    overrideDasar(tambahan: [layananProvider.overrideWithValue(layanan)]);

/// Seperti `Gerbang` produksi: layar baru tampil setelah sesi selesai
/// dipulihkan. Tanpa ini provider data dibangun dua kali (sesi masih memuat,
/// lalu selesai) dan jumlah permintaan di tes tidak sama dengan di aplikasi.
class _Gerbang extends ConsumerWidget {
  const _Gerbang(this.anak);

  final Widget anak;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(sesiProvider).hasValue ? anak : const SizedBox();
}

/// Induk dengan satu tombol yang membuka [anak]: supaya "kembali" punya tujuan.
class _Induk extends StatelessWidget {
  const _Induk(this.anak);

  final Widget anak;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => anak)),
        child: const Text('Buka arsip'),
      ),
    ),
  );
}

Widget _app(Widget anak, LayananPelanggan layanan, {double? skalaHuruf}) =>
    ProviderScope(
      overrides: _override(layanan),
      child: MaterialApp(
        theme: TemaSidik.terang,
        builder: skalaHuruf == null
            ? null
            : (context, child) => MediaQuery.withClampedTextScaling(
                minScaleFactor: skalaHuruf,
                maxScaleFactor: skalaHuruf,
                child: child!,
              ),
        home: _Gerbang(anak),
      ),
    );

Future<void> _buka(
  WidgetTester tester,
  Widget arsip,
  LayananPelanggan l,
) async {
  await tester.pumpWidget(_app(_Induk(arsip), l));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Buka arsip'));
  await tester.pumpAndSettle();
}

Iterable<String> _semuaTeks(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '');

/// Parameter hari untuk pekan 46 (dari `telusuri` server, bukan disusun tes).
ParameterArsip get _pekan46 =>
    HasilArsip.dariJson(arsipPekanNovember()).kelompok.first.parameter;

/// Satu sertifikat hasil cari (baris `GET /sertifikat`).
Sertifikat _s(int id, String nomor) =>
    Sertifikat.dariJson(sertifikatJson(id, nomor));

/// Mengetik [kata] di kolom cari, menunggu jeda ketik, lalu hasilnya.
Future<void> _ketik(WidgetTester tester, String kata) async {
  await tester.enterText(find.byType(TextField), kata);
  await tester.pump(KolomCari.jeda);
  await tester.pumpAndSettle();
}

/// Tab Sertifikat dengan layanan [palsu].
Future<void> _bukaTab(
  WidgetTester tester,
  LayananArsipPalsu palsu, {
  double? skalaHuruf,
}) async {
  await tester.pumpWidget(
    _app(const SertifikatScreen(), palsu, skalaHuruf: skalaHuruf),
  );
  await tester.pumpAndSettle();
}

/// Centang penanda segmen terpilih di dalam segmen berlabel [label].
Finder _centang(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
  matching: find.byIcon(Icons.check),
);

/// Rasio kontras WCAG antara dua warna buram.
double _kontras(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

Finder get _segmen =>
    find.byWidgetPredicate((w) => w is SegmentedButton, description: 'segmen');

void main() {
  setUpAll(siapkanTesFitur);

  group('keadaan layar', () {
    testWidgets('memuat: kerangka, lalu hasil', (tester) async {
      layarHp(tester);
      final selesai = Completer<HasilArsip>();
      final palsu = LayananArsipPalsu((_, _) => selesai.future);
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pump();

      expect(find.byType(KerangkaDaftar), findsOneWidget);
      expect(find.text('2026'), findsNothing);

      selesai.complete(HasilArsip.dariJson(arsipTahun()));
      await tester.pumpAndSettle();
      expect(find.byType(KerangkaDaftar), findsNothing);
      expect(find.text('2026'), findsOneWidget);
    });

    testWidgets('kosong: arsip belum berisi apa pun', (tester) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu(
        (_, _) async =>
            HasilArsip.dariJson(jawabanArsip(tingkat: 'tahun', total: 0)),
      );
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada sertifikat di arsip'), findsOneWidget);
      // Tidak ada ringkasan jumlah untuk daftar kosong.
      expect(find.textContaining('sertifikat, disusun'), findsNothing);
    });

    testWidgets('galat: pesan server + Coba lagi memuat ulang', (tester) async {
      layarHp(tester);
      var gagal = true;
      final palsu = LayananArsipPalsu((p, h) async {
        if (gagal) {
          throw const GalatApi(
            status: 500,
            pesan: 'Terjadi kendala di server. Coba lagi sebentar lagi.',
          );
        }
        return _server(p, h);
      });
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      expect(
        find.text('Terjadi kendala di server. Coba lagi sebentar lagi.'),
        findsOneWidget,
      );
      expect(find.text('2026'), findsNothing);

      gagal = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
    });

    testWidgets('tarik layar: tingkat yang sama diminta lagi', (tester) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu(_server);
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();
      expect(palsu.panggilan, hasLength(1));

      await tester.fling(find.text('2026'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(palsu.panggilan, hasLength(2));
      expect(palsu.panggilan.last.parameter, ParameterArsip.akar);
      expect(find.text('2026'), findsOneWidget);
    });

    testWidgets(
      'galat 4xx tidak dicoba ulang otomatis (tanpa kedip, tanpa ketukan server)',
      (tester) async {
        layarHp(tester);
        final palsu = LayananArsipPalsu(
          (_, _) async =>
              throw const GalatApi(status: 404, pesan: ApiPelanggan.pesan404),
          jawabCari: (_, _) async =>
              throw const GalatApi(status: 429, pesan: 'Terlalu banyak.'),
        );
        await tester.pumpWidget(_app(const ArsipScreen(), palsu));
        await tester.pumpAndSettle();
        // Jauh melewati seluruh jadwal ulang bawaan Riverpod (200 ms sampai 6,4 s).
        await tester.pump(const Duration(seconds: 40));
        expect(palsu.panggilan, hasLength(1), reason: 'garis waktu 404');

        await _ketik(tester, 'CAL/2026');
        await tester.pump(const Duration(seconds: 40));
        expect(palsu.cari, hasLength(1), reason: 'pencarian 429');
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('galat 5xx tetap dicoba ulang otomatis', (tester) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu(
        (_, _) async =>
            throw const GalatApi(status: 500, pesan: 'Terjadi kendala.'),
      );
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      expect(palsu.panggilan.length, greaterThan(1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('tanpa jaringan: kalimat jaringan, bukan crash', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu(
        (_, _) async => throw GalatApi.jaringan(),
      );
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tidak bisa terhubung'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('404 di tingkat bawah: Tidak ditemukan, Kembali menutup', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu(
        (_, _) async =>
            throw const GalatApi(status: 404, pesan: ApiPelanggan.pesan404),
      );
      await _buka(
        tester,
        ArsipScreen(parameter: _pekan46, judul: 'Pekan 46'),
        palsu,
      );

      expect(find.text('Tidak ditemukan'), findsOneWidget);
      expect(find.text(ApiPelanggan.pesan404), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
      expect(find.text('Muat ulang'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Kembali'));
      await tester.pumpAndSettle();
      expect(find.byType(ArsipScreen), findsNothing);
      expect(find.text('Buka arsip'), findsOneWidget);
    });

    testWidgets('404 di tingkat awal: Muat ulang, bukan Kembali', (
      tester,
    ) async {
      layarHp(tester);
      var ada = false;
      final palsu = LayananArsipPalsu((p, h) async {
        if (!ada) {
          throw const GalatApi(status: 404, pesan: ApiPelanggan.pesan404);
        }
        return _server(p, h);
      });
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      expect(find.text('Tidak ditemukan'), findsOneWidget);
      expect(find.text('Kembali'), findsNothing);
      expect(find.text('Coba lagi'), findsNothing);
      ada = true;
      await tester.tap(find.text('Muat ulang'));
      await tester.pumpAndSettle();

      expect(palsu.panggilan, hasLength(2));
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Tidak ditemukan'), findsNothing);
    });
  });

  group('menelusuri', () {
    testWidgets('hasil tahun: label, jumlah, dan ringkasan dari server', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu(_server);
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      expect(find.text('Arsip sertifikat'), findsOneWidget, reason: 'judul');
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('5 sertifikat'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('1 sertifikat'), findsOneWidget);
      expect(
        find.text('6 sertifikat, disusun menurut tanggal terbit'),
        findsOneWidget,
      );
      // Tingkat tahun: tanpa induk, dan hanya SATU permintaan (ringan).
      expect(palsu.panggilan, hasLength(1));
      expect(palsu.panggilan.single.parameter, ParameterArsip.akar);
      expect(palsu.panggilan.single.halaman, 1);
    });

    testWidgets('tahun → bulan → pekan → hari memakai telusuri server', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu(_server);
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      Map<String, String?> terakhir() => palsu.panggilan.last.parameter.query();
      // Judul layar = label kelompok yang dibuka (dari server).
      void judul(String label) => expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(label)),
        findsOneWidget,
        reason: 'judul $label',
      );

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      expect(terakhir(), {'tingkat': 'bulan', 'tahun': '2026', 'page': '1'});
      judul('2026');
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('Oktober 2026'), findsOneWidget);
      expect(find.text('4 sertifikat'), findsWidgets);

      await tester.tap(find.text('November 2026'));
      await tester.pumpAndSettle();
      expect(terakhir()['tingkat'], 'pekan');
      expect(terakhir()['bulan'], '11');
      judul('November 2026');
      // Pekan 44 hanya berisi 1 Nov: label dari server, tidak dihitung ulang.
      expect(find.text('Pekan 46 (9–15 Nov 2026)'), findsOneWidget);
      expect(find.text('Pekan 44 (1 Nov 2026)'), findsOneWidget);

      await tester.tap(find.text('Pekan 46 (9–15 Nov 2026)'));
      await tester.pumpAndSettle();
      expect(terakhir()['tingkat'], 'hari');
      expect(terakhir()['pekan'], '46');
      judul('Pekan 46 (9–15 Nov 2026)');
      expect(palsu.panggilan, hasLength(4), reason: 'satu tingkat per ketukan');

      // Hari: judul hari (label + jumlah server) di atas sertifikatnya.
      expect(find.text('Kamis, 12 Nov 2026'), findsOneWidget);
      expect(find.text('Senin, 9 Nov 2026'), findsOneWidget);
      expect(find.text('ISO/CNT/0003'), findsOneWidget);
      expect(find.text('ISO/CNT/0002'), findsOneWidget);
      expect(find.text('ISO/CNT/0001'), findsOneWidget);
      expect(find.text('2 sertifikat'), findsOneWidget, reason: 'judul 12 Nov');
      expect(find.text('3 sertifikat'), findsOneWidget, reason: 'ringkasan');
      // Nomor seri dan nomor order terlihat di kartu (bahan pencarian).
      expect(find.textContaining('SN-0205'), findsOneWidget);
      expect(find.text('Order PO-2026-0042'), findsNWidgets(2));
    });

    testWidgets('kelompok tanpa telusuri: ketukan diabaikan', (tester) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu(
        (_, _) async => HasilArsip.dariJson(
          jawabanArsip(
            tingkat: 'tahun',
            total: 1,
            kelompok: [
              {'kunci': '2026', 'label': '2026', 'jumlah': 1},
            ],
          ),
        ),
      );
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();

      // Tanpa penjaga, parameter kosong = tingkat awal: layar yang sama
      // bertumpuk di atas dirinya sendiri.
      expect(
        find.byType(ArsipScreen, skipOffstage: false),
        findsOneWidget,
        reason: 'tidak ada layar baru',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tombol kembali membawa ke tingkat sebelumnya', (tester) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu(_server);
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsNothing);
      expect(find.text('2025'), findsOneWidget);
    });

    testWidgets('mengetuk sertifikat membuka detailnya', (tester) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu(_server);
      await tester.pumpWidget(
        _app(ArsipScreen(parameter: _pekan46, judul: 'Pekan 46'), palsu),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ISO/CNT/0002'));
      await tester.pumpAndSettle();

      expect(find.byType(SertifikatDetailScreen), findsOneWidget);
      expect(palsu.detail, [6]);
    });

    testWidgets('hari: halaman 2 dimuat, judul hari tidak ganda', (
      tester,
    ) async {
      layarHp(tester);
      Map<String, Object> meta(int hal) => {
        'current_page': hal,
        'last_page': 2,
        'per_page': 2,
        'total': 3,
      };
      final palsu = LayananArsipPalsu((p, h) async {
        // Hari 12 Nov terbelah: sertifikat pertama di halaman 1, sisanya di 2.
        final item = h == 1
            ? [itemArsipJson(7, 'ISO/CNT/0003', tanggal: '2026-11-12')]
            : [
                itemArsipJson(6, 'ISO/CNT/0002', tanggal: '2026-11-12'),
                itemArsipJson(5, 'ISO/CNT/0001', tanggal: '2026-11-09'),
              ];
        return HasilArsip.dariJson(arsipHari(item: item, meta: meta(h)));
      });
      await tester.pumpWidget(
        _app(ArsipScreen(parameter: _pekan46, judul: 'Pekan 46'), palsu),
      );
      await tester.pumpAndSettle();

      expect(palsu.panggilan.map((c) => c.halaman), [1, 2]);
      expect(palsu.panggilan.last.parameter.query(halaman: 2)['page'], '2');
      expect(find.text('Kamis, 12 Nov 2026'), findsOneWidget);
      expect(find.text('Senin, 9 Nov 2026'), findsOneWidget);
      for (final nomor in ['ISO/CNT/0003', 'ISO/CNT/0002', 'ISO/CNT/0001']) {
        expect(find.text(nomor), findsOneWidget, reason: nomor);
      }
      expect(find.text('Semua 3 sertifikat sudah tampil.'), findsOneWidget);
    });

    testWidgets('galat di halaman 2 tidak membuang yang sudah tampil', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu((p, h) async {
        if (h == 2) throw GalatApi.jaringan();
        return HasilArsip.dariJson(
          arsipHari(
            item: [itemArsipJson(7, 'ISO/CNT/0003')],
            meta: {
              'current_page': 1,
              'last_page': 2,
              'per_page': 1,
              'total': 3,
            },
          ),
        );
      });
      await tester.pumpWidget(
        _app(ArsipScreen(parameter: _pekan46, judul: 'Pekan 46'), palsu),
      );
      await tester.pumpAndSettle();

      expect(find.text('ISO/CNT/0003'), findsOneWidget);
      expect(find.textContaining('Tidak bisa terhubung'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });
  });

  group('pencarian: daftar datar', () {
    LayananArsipPalsu palsuCari({
      Future<Halaman<Sertifikat>> Function(String cari, int halaman)? jawab,
    }) => LayananArsipPalsu(
      _server,
      jawabCari:
          jawab ??
          (cari, h) async => halamanUji([
            _s(21, 'CAL/2026/10/0001'),
            _s(22, 'CAL/2026/10/0002'),
          ]),
    );

    testWidgets('kata tiba apa adanya setelah jeda: daftar datar, satu kali', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = palsuCari();
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();
      expect(palsu.panggilan, hasLength(1));

      // Mengetik cepat: tiap huruf menunda yang sebelumnya.
      for (final kata in ['CA', 'CAL', 'CAL/20', 'CAL/2026/10/0001']) {
        await tester.enterText(find.byType(TextField), kata);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(palsu.cari, isEmpty, reason: 'masih dalam jeda');
      await tester.pump(KolomCari.jeda);
      await tester.pumpAndSettle();

      // SATU permintaan daftar sertifikat, kata apa adanya, tanpa
      // `termasuk_digantikan`; tidak ada permintaan garis waktu baru.
      expect(palsu.cari, hasLength(1));
      expect(palsu.cari.single.cari, 'CAL/2026/10/0001');
      expect(palsu.cari.single.halaman, 1);
      expect(palsu.cari.single.termasukDigantikan, isFalse);
      expect(palsu.panggilan, hasLength(1));

      // Daftar datar: kartu sertifikat, bukan kelompok tahun. (Kata yang diketik
      // sama dengan nomor pertama, jadi dihitung di dalam kartunya.)
      expect(find.byType(KartuSertifikat), findsNWidgets(2));
      for (final nomor in ['CAL/2026/10/0001', 'CAL/2026/10/0002']) {
        expect(
          find.descendant(
            of: find.byType(KartuSertifikat),
            matching: find.text(nomor),
          ),
          findsOneWidget,
          reason: nomor,
        );
      }
      expect(find.text('2 sertifikat cocok'), findsOneWidget);
      expect(find.byType(KartuKelompokArsip), findsNothing);
      expect(find.text('2026'), findsNothing);
    });

    testWidgets('mengetuk hasil membuka detail sertifikatnya', (tester) async {
      layarHp(tester);
      final palsu = palsuCari();
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();
      await _ketik(tester, 'CAL/2026');

      await tester.tap(find.text('CAL/2026/10/0002'));
      await tester.pumpAndSettle();

      expect(find.byType(SertifikatDetailScreen), findsOneWidget);
      expect(palsu.detail, [22]);
    });

    testWidgets('satu huruf tidak dikirim; petunjuk muncul', (tester) async {
      layarHp(tester);
      final palsu = palsuCari();
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      await _ketik(tester, ' a ');

      expect(palsu.cari, isEmpty, reason: 'tidak ada permintaan baru');
      expect(palsu.panggilan, hasLength(1));
      expect(
        find.text('Ketik minimal 2 karakter untuk mencari.'),
        findsOneWidget,
      );
      expect(find.text('2026'), findsOneWidget, reason: 'arsip tak berubah');

      await _ketik(tester, 'ab');
      expect(palsu.cari.map((c) => c.cari), ['ab']);
      expect(
        find.text('Ketik minimal 2 karakter untuk mencari.'),
        findsNothing,
      );
    });

    testWidgets('kata lebih dari 100 huruf dipotong di klien', (tester) async {
      layarHp(tester);
      final palsu = palsuCari();
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      await _ketik(tester, '9' * 130);

      expect(palsu.cari.single.cari, '9' * 100);
    });

    testWidgets('cari tanpa hasil: pesan jelas, bukan arsip', (tester) async {
      layarHp(tester);
      final palsu = palsuCari(
        jawab: (_, _) async => halamanUji(<Sertifikat>[]),
      );
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      await _ketik(tester, 'tidak-ada-ini');

      expect(find.text('Tidak ada yang cocok'), findsOneWidget);
      expect(
        find.textContaining('tulis persis seperti di sertifikat'),
        findsOneWidget,
      );
      expect(find.text('Belum ada sertifikat di arsip'), findsNothing);
      expect(find.text('2026'), findsNothing);
      // Revisi lama tidak ikut hasil: ada di Daftar lewat sakelarnya.
      expect(find.textContaining('ada di Daftar'), findsOneWidget);
      expect(
        find.textContaining('Tampilkan juga yang sudah direvisi'),
        findsOneWidget,
      );
    });

    testWidgets('kolom dikosongkan: kembali ke garis waktu', (tester) async {
      layarHp(tester);
      final palsu = palsuCari();
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();
      await _ketik(tester, 'CAL/2026');
      expect(find.byType(KartuKelompokArsip), findsNothing);

      await _ketik(tester, '');

      expect(find.text('2026'), findsOneWidget);
      expect(find.text('CAL/2026/10/0001'), findsNothing);
      expect(palsu.panggilan.last.parameter, ParameterArsip.akar);
      expect(palsu.cari, hasLength(1), reason: 'kosong tidak mencari');
    });

    testWidgets('hasil banyak: halaman 2 dimuat saat daftar digulir', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = palsuCari(
        jawab: (cari, h) async => Halaman(
          isi: h == 1
              ? [_s(21, 'CAL/A/0001'), _s(22, 'CAL/A/0002')]
              : [_s(23, 'CAL/A/0003')],
          halaman: h,
          halamanTerakhir: 2,
          total: 3,
        ),
      );
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      await _ketik(tester, 'CAL/A');

      expect(palsu.cari.map((c) => c.halaman), [1, 2]);
      for (final nomor in ['CAL/A/0001', 'CAL/A/0002', 'CAL/A/0003']) {
        expect(find.text(nomor), findsOneWidget, reason: nomor);
      }
      expect(find.text('3 sertifikat cocok'), findsOneWidget);
      expect(find.text('Semua 3 sertifikat sudah tampil.'), findsOneWidget);
    });

    testWidgets('galat pencarian: pesan server + Coba lagi', (tester) async {
      layarHp(tester);
      var gagal = true;
      final palsu = palsuCari(
        jawab: (cari, h) async {
          if (gagal) throw GalatApi.jaringan();
          return halamanUji([_s(21, 'CAL/2026/10/0001')]);
        },
      );
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      await _ketik(tester, 'CAL/2026');
      expect(find.textContaining('Tidak bisa terhubung'), findsOneWidget);

      gagal = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('CAL/2026/10/0001'), findsOneWidget);
    });

    testWidgets('404 pada pencarian: tidak ditemukan, tanpa Coba lagi', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = palsuCari(
        jawab: (_, _) async =>
            throw const GalatApi(status: 404, pesan: ApiPelanggan.pesan404),
      );
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      await _ketik(tester, 'CAL/2026');

      expect(find.text('Tidak ditemukan'), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
      // Pencarian hidup di tab: tidak ada rute untuk "Kembali".
      expect(find.text('Kembali'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Muat ulang'));
      await tester.pumpAndSettle();
      expect(palsu.cari, hasLength(2), reason: 'diminta ulang');
    });

    test('jeda ketik minimal 300 ms (kewajiban klien di kontrak)', () {
      expect(KolomCari.jeda.inMilliseconds, greaterThanOrEqualTo(300));
    });

    testWidgets(
      'catatan di bawah kolom: tulis persis, lalu minimal 2 karakter',
      (tester) async {
        layarHp(tester);
        final palsu = palsuCari();
        await tester.pumpWidget(_app(const ArsipScreen(), palsu));
        await tester.pumpAndSettle();
        const persis = 'Tulis nomor persis seperti di sertifikat.';
        const pendek = 'Ketik minimal 2 karakter untuk mencari.';

        expect(find.text(persis), findsOneWidget, reason: 'sebelum mengetik');
        expect(find.text(pendek), findsNothing);

        await _ketik(tester, 'a');
        expect(find.text(pendek), findsOneWidget);
        expect(find.text(persis), findsNothing);

        await _ketik(tester, 'CAL/2026');
        expect(
          find.text(persis),
          findsNothing,
          reason: 'sedang menampilkan hasil',
        );
        expect(find.text(pendek), findsNothing);

        await _ketik(tester, '');
        expect(find.text(persis), findsOneWidget, reason: 'kembali ke arsip');
      },
    );

    testWidgets('petunjuk kolom tidak terpotong di 320 dp, huruf 1,3×', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      final palsu = palsuCari();
      await tester.pumpWidget(
        _app(const ArsipScreen(), palsu, skalaHuruf: 1.3),
      );
      await tester.pumpAndSettle();

      final petunjuk = find.text('Seri, sertifikat, order');
      expect(petunjuk, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(petunjuk).didExceedMaxLines,
        isFalse,
        reason: 'petunjuk dipotong elipsis',
      );
    });

    testWidgets('tingkat bawah tidak punya kolom cari', (tester) async {
      layarHp(tester);
      final palsu = palsuCari();
      await tester.pumpWidget(
        _app(ArsipScreen(parameter: _pekan46, judul: 'Pekan 46'), palsu),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(palsu.cari, isEmpty);
    });
  });

  group('tampilan', () {
    testWidgets('HP 320 dp, huruf 1,3×: tanpa luapan di semua tingkat', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      final palsu = LayananArsipPalsu(_server);
      await tester.pumpWidget(
        _app(const ArsipScreen(), palsu, skalaHuruf: 1.3),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('November 2026'));
      await tester.pumpAndSettle();
      expect(find.text('Pekan 46 (9–15 Nov 2026)'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Pekan 46 (9–15 Nov 2026)'));
      await tester.pumpAndSettle();
      expect(find.text('ISO/CNT/0003'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet 840 dp: daftar tidak melebar melewati 720 dp', (
      tester,
    ) async {
      layarTablet(tester);
      final palsu = LayananArsipPalsu(_server);
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      final daftar = find.byType(ListView).hitTestable().first;
      expect(tester.getSize(daftar).width, lessThanOrEqualTo(720));
      expect(find.text('2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('kartu kelompok bisa disentuh (>= 48 dp) dan terbaca layar', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu(_server);
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();

      final kartu = find.bySemanticsLabel('2026, 5 sertifikat');
      expect(kartu, findsOneWidget);
      expect(
        tester
            .getSize(
              find
                  .ancestor(of: find.text('2026'), matching: find.byType(Card))
                  .first,
            )
            .height,
        greaterThanOrEqualTo(48),
      );
      semantik.dispose();
    });

    testWidgets('kartu sertifikat 320 dp, huruf 1,3×: nomor seri membungkus', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      final palsu = LayananArsipPalsu(_server);
      await tester.pumpWidget(
        _app(
          ArsipScreen(parameter: _pekan46, judul: 'Pekan 46'),
          palsu,
          skalaHuruf: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      final alat = find.text('Busur Derajat · SN PL-0001');
      expect(alat, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(alat).didExceedMaxLines,
        isFalse,
        reason: '"SN ..." dipotong elipsis',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'judul pekan di 320 dp, huruf 1,3×: mengecil, tidak terpotong',
      (tester) async {
        layarHp(tester, lebar: 320, tinggi: 640);
        final palsu = LayananArsipPalsu(_server);
        const label = 'Pekan 46 (9–15 Nov 2026)';
        await tester.pumpWidget(
          _app(
            ArsipScreen(parameter: _pekan46, judul: label),
            palsu,
            skalaHuruf: 1.3,
          ),
        );
        await tester.pumpAndSettle();

        final judul = find.descendant(
          of: find.byType(AppBar),
          matching: find.text(label),
        );
        expect(judul, findsOneWidget);
        final paragraf = tester.renderObject<RenderParagraph>(judul);
        expect(paragraf.didExceedMaxLines, isFalse, reason: 'tanpa elipsis');
        expect(tester.getRect(judul).right, lessThanOrEqualTo(320));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('istilah "kedaluwarsa" tidak muncul (keputusan K3)', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = LayananArsipPalsu(_server);
      await tester.pumpWidget(_app(const ArsipScreen(), palsu));
      await tester.pumpAndSettle();
      final pola = RegExp('kedaluwarsa|kadaluarsa', caseSensitive: false);
      expect(_semuaTeks(tester).where(pola.hasMatch), isEmpty);

      await tester.pumpWidget(
        _app(ArsipScreen(parameter: _pekan46, judul: 'Pekan 46'), palsu),
      );
      await tester.pumpAndSettle();
      expect(_semuaTeks(tester), contains('ISO/CNT/0003'));
      expect(_semuaTeks(tester).where(pola.hasMatch), isEmpty);

      // Dan di sumbernya, termasuk teks galat/kosong yang tidak tampil di tes.
      for (final berkas in [
        'lib/models/arsip.dart',
        'lib/screens/sertifikat/arsip_screen.dart',
        'lib/widgets/kartu_kelompok_arsip.dart',
        'lib/screens/sertifikat/sertifikat_screen.dart',
      ]) {
        expect(
          pola.hasMatch(File(berkas).readAsStringSync()),
          isFalse,
          reason: berkas,
        );
      }
    });
  });

  group('tab Sertifikat: Daftar | Arsip', () {
    LayananArsipPalsu palsuTab() => LayananArsipPalsu(
      _server,
      jawabCari: (cari, h) async =>
          halamanUji([_s(21, 'CAL/2026/10/0001'), _s(22, 'CAL/2026/10/0002')]),
    );

    testWidgets('bawaan Daftar; arsip belum diminta ke server', (tester) async {
      layarHp(tester);
      final palsu = palsuTab();
      await _bukaTab(tester, palsu);

      expect(find.text('Daftar'), findsOneWidget);
      expect(find.text('Arsip'), findsOneWidget);
      expect(find.text('Tampilkan juga yang sudah direvisi'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(palsu.panggilan, isEmpty, reason: 'arsip dimuat saat dibuka');
      // Tidak ada ikon folder di app bar lagi.
      expect(find.byTooltip('Arsip sertifikat'), findsNothing);
    });

    testWidgets('ketuk Arsip: arsip tampil, Daftar tersembunyi', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = palsuTab();
      await _bukaTab(tester, palsu);

      await tester.tap(find.text('Arsip'));
      await tester.pumpAndSettle();

      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Tampilkan juga yang sudah direvisi'), findsNothing);
      expect(palsu.panggilan, hasLength(1));

      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();
      expect(find.text('Tampilkan juga yang sudah direvisi'), findsOneWidget);
      expect(find.text('2026'), findsNothing);
    });

    testWidgets('berpindah segmen mempertahankan keadaan tiap segmen', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = palsuTab();
      await _bukaTab(tester, palsu);

      // Daftar: kata cari dan sakelar.
      await _ketik(tester, 'ab');
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Arsip: kata cari sendiri, hasil daftar datar.
      await tester.tap(find.text('Arsip'));
      await tester.pumpAndSettle();
      await _ketik(tester, 'sn-9');
      expect(find.text('CAL/2026/10/0001'), findsOneWidget);
      final permintaanDaftar = palsu.cari.length;
      final permintaanArsip = palsu.panggilan.length;

      // Kembali ke Daftar: isian dan sakelar utuh, tanpa muat ulang.
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'ab',
      );
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );

      // Kembali ke Arsip: isian dan hasil cari utuh, tanpa muat ulang.
      await tester.tap(find.text('Arsip'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'sn-9',
      );
      expect(find.text('CAL/2026/10/0001'), findsOneWidget);
      expect(palsu.cari.length, permintaanDaftar);
      expect(palsu.panggilan.length, permintaanArsip);
    });

    testWidgets('penelusuran arsip bertahan: kembali dari tingkat bawah', (
      tester,
    ) async {
      layarHp(tester);
      final palsu = palsuTab();
      await _bukaTab(tester, palsu);
      await tester.tap(find.text('Arsip'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Masih di Arsip, daftar tahun utuh dan tidak diminta ulang.
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(
        palsu.panggilan,
        hasLength(2),
        reason: 'tahun sekali, bulan sekali',
      );
    });

    testWidgets('aksesibilitas: label jelas, target sentuh >= 48 dp', (
      tester,
    ) async {
      layarHp(tester);
      final semantik = tester.ensureSemantics();
      final palsu = palsuTab();
      await _bukaTab(tester, palsu);

      expect(find.bySemanticsLabel('Tampilan sertifikat'), findsOneWidget);
      expect(find.byTooltip('Daftar sertifikat'), findsOneWidget);
      expect(
        find.byTooltip('Arsip sertifikat menurut tanggal terbit'),
        findsOneWidget,
      );
      // Tinggi dan lebar tiap segmen >= 48 dp.
      expect(tester.getSize(_segmen).height, greaterThanOrEqualTo(48));
      for (final label in ['Daftar', 'Arsip']) {
        final segmen = find.ancestor(
          of: find.text(label),
          matching: find.byType(TextButton),
        );
        expect(segmen, findsOneWidget, reason: label);
        expect(tester.getSize(segmen).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(segmen).width, greaterThanOrEqualTo(48));
      }
      // Segmen terpilih terbaca sebagai terpilih; yang lain tidak.
      bool terpilih(String label) => tester
          .getSemantics(find.text(label))
          .getSemanticsData()
          .flagsCollection
          .isSelected
          .toBoolOrNull()!;
      expect(terpilih('Daftar'), isTrue);
      expect(terpilih('Arsip'), isFalse);
      // Penanda NON-warna: hanya segmen terpilih yang bercentang.
      expect(_centang('Daftar'), findsOneWidget);
      expect(_centang('Arsip'), findsNothing);
      await tester.tap(find.text('Arsip'));
      await tester.pumpAndSettle();
      expect(terpilih('Daftar'), isFalse);
      expect(terpilih('Arsip'), isTrue);
      expect(_centang('Arsip'), findsOneWidget);
      expect(_centang('Daftar'), findsNothing);
      // Segmen yang tidak terpilih memakai ikonnya sendiri.
      expect(
        find.descendant(
          of: _segmen,
          matching: find.byIcon(Icons.list_alt_outlined),
        ),
        findsOneWidget,
      );
      semantik.dispose();
    });

    testWidgets('404 di tingkat awal lewat tab: Muat ulang, bukan Kembali', (
      tester,
    ) async {
      layarHp(tester);
      var ada = false;
      final palsu = LayananArsipPalsu((p, h) async {
        if (!ada) {
          throw const GalatApi(status: 404, pesan: ApiPelanggan.pesan404);
        }
        return _server(p, h);
      });
      await _bukaTab(tester, palsu);
      await tester.tap(find.text('Arsip'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak ditemukan'), findsOneWidget);
      expect(find.text('Muat ulang'), findsOneWidget);
      expect(find.text('Kembali'), findsNothing);
      expect(find.text('Coba lagi'), findsNothing);

      ada = true;
      await tester.tap(find.text('Muat ulang'));
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget);
      expect(palsu.panggilan, hasLength(2));
    });

    testWidgets(
      'keadaan terpilih: beda latar < 3:1, jadi wajib ada penanda non-warna',
      (tester) async {
        layarHp(tester);
        await _bukaTab(tester, palsuTab());
        final penanda = tester
            .widget<SegmentedButton<Object>>(_segmen)
            .showSelectedIcon;

        for (final (nama, tema) in [
          ('terang', TemaSidik.terang),
          ('gelap', TemaSidik.gelap),
        ]) {
          final gaya = tema.segmentedButtonTheme.style!;
          final latarTerpilih = gaya.backgroundColor!.resolve({
            WidgetState.selected,
          })!;
          final latarBiasa = gaya.backgroundColor!.resolve({})!;
          final selisih = _kontras(latarTerpilih, latarBiasa);
          // Warna saja baru cukup bila selisihnya >= 3:1 (WCAG 1.4.11).
          expect(
            selisih >= 3 || penanda,
            isTrue,
            reason:
                '$nama: selisih ${selisih.toStringAsFixed(2)}:1 tanpa centang',
          );
          // Teks segmen terpilih terbaca di latarnya.
          final tulisanTerpilih = gaya.foregroundColor!.resolve({
            WidgetState.selected,
          })!;
          expect(
            _kontras(tulisanTerpilih, latarTerpilih),
            greaterThanOrEqualTo(4.5),
          );
        }
      },
    );

    test('tema: tinggi visual segmen minimal 48 dp (terang dan gelap)', () {
      // Target sentuh Material sudah dipaksa 48 dp; tema juga menjaga TINGGI
      // yang terlihat, supaya segmen tidak tampak lebih pendek dari tombol lain.
      for (final tema in [TemaSidik.terang, TemaSidik.gelap]) {
        final gaya = tema.segmentedButtonTheme.style!;
        expect(gaya.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('HP 320 dp huruf 1,3× dan tablet: tanpa luapan', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await _bukaTab(tester, palsuTab(), skalaHuruf: 1.3);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Arsip'));
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget);
      expect(tester.takeException(), isNull);

      layarTablet(tester);
      await tester.pumpAndSettle();
      expect(tester.getSize(_segmen).width, lessThanOrEqualTo(720));
      expect(tester.takeException(), isNull);
    });
  });

  group('lewat ApiPelanggan dan server palsu', () {
    ServerArsip server() => ServerArsip(
      {3: DataPerusahaan(nama: 'PT Alfa'), 4: DataPerusahaan(nama: 'PT Beta')},
      {
        3: {
          'tahun': arsipTahun(),
          'bulan': arsipBulan(),
          'pekan': arsipPekanNovember(),
          'hari': arsipHari(),
        },
      },
    );

    testWidgets('perusahaan sendiri: tahun sampai sertifikat, hanya GET', (
      tester,
    ) async {
      layarHp(tester);
      final s = server();
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrideFitur(s),
          child: MaterialApp(
            theme: TemaSidik.terang,
            home: const _Gerbang(ArsipScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in [
        '2026',
        'November 2026',
        'Pekan 46 (9–15 Nov 2026)',
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(find.text('ISO/CNT/0003'), findsOneWidget);

      final arsip = s.yang('GET', 'garis-waktu').toList();
      expect(arsip, hasLength(4));
      expect(arsip.every((r) => r.headers['X-Perusahaan-Id'] == '3'), isTrue);
      expect(
        arsip.every((r) => !r.url.queryParameters.containsKey('customer_id')),
        isTrue,
      );
      expect(s.permintaan.every((r) => r.method == 'GET'), isTrue);
    });

    testWidgets(
      'cari: daftar datar lewat GET /sertifikat?q=, tanpa garis waktu',
      (tester) async {
        layarHp(tester);
        final s = ServerArsip(
          {
            3: DataPerusahaan(
              nama: 'PT Alfa',
              sertifikat: [
                sertifikatJson(11, 'CAL/ALFA/0001', namaAlat: 'Jangka Sorong'),
                sertifikatJson(12, 'CAL/ALFA/0002', namaAlat: 'Timbangan'),
              ],
            ),
          },
          {
            3: {'tahun': arsipTahun()},
          },
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrideFitur(s),
            child: MaterialApp(
              theme: TemaSidik.terang,
              home: const _Gerbang(ArsipScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(s.yang('GET', 'garis-waktu'), hasLength(1));

        await _ketik(tester, 'Timbangan');

        final cari = s.permintaan
            .where((r) => r.url.queryParameters['q'] == 'Timbangan')
            .toList();
        expect(cari, hasLength(1));
        expect(cari.single.url.path.endsWith('/sertifikat'), isTrue);
        expect(cari.single.headers['X-Perusahaan-Id'], '3');
        expect(find.text('CAL/ALFA/0002'), findsOneWidget);
        expect(find.text('CAL/ALFA/0001'), findsNothing);
        expect(
          s.yang('GET', 'garis-waktu'),
          hasLength(1),
          reason: 'tak diulang',
        );
        expect(s.permintaan.every((r) => r.method == 'GET'), isTrue);
      },
    );

    testWidgets('data perusahaan lain = 404 dari server: tidak ditemukan', (
      tester,
    ) async {
      layarHp(tester);
      // Perusahaan 4 dikenal sesi, tetapi tidak punya arsip ini di server.
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrideFitur(server(), perusahaan: 4),
          child: MaterialApp(
            theme: TemaSidik.terang,
            home: const _Gerbang(ArsipScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tidak ditemukan'), findsOneWidget);
      expect(find.text(ApiPelanggan.pesan404), findsOneWidget);
      // Kalimat bawaan Laravel (nama model) tidak sampai ke layar.
      expect(find.textContaining('No query results'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
