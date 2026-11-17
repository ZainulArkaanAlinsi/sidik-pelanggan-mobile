// Arsip sertifikat (P5d-B, REVISI-2 butir 4): kelompok TAHUN membuka dan menutup
// isinya di tempat (bulan-bulannya tampil di bawah tahunnya), bulan tetap
// membuka layar tingkat berikutnya, pencarian dan keadaan buka bertahan saat
// kembali dari detail, dan setiap keadaan inline (memuat, galat, panjang)
// punya tindakan yang jelas.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/models/arsip.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/sertifikat/arsip_screen.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_detail_screen.dart';
import 'package:sidik_pelanggan/screens/sertifikat/sertifikat_screen.dart';
import 'package:sidik_pelanggan/widgets/kartu_kelompok_arsip.dart';
import 'package:sidik_pelanggan/widgets/kolom_cari.dart';

import 'dukungan/dukungan.dart';
import 'dukungan/fixture_arsip.dart';
import 'dukungan/fixture_fitur.dart';
import 'dukungan/layar_uji.dart';

class _Gerbang extends ConsumerWidget {
  const _Gerbang(this.anak);

  final Widget anak;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(sesiProvider).hasValue ? anak : const SizedBox();
}

Widget _app(Widget anak, LayananArsipPalsu layanan, {double skala = 1.0}) =>
    ProviderScope(
      overrides: overrideDasar(
        tambahan: [layananProvider.overrideWithValue(layanan)],
      ),
      child: MaterialApp(
        theme: TemaSidik.terang,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: skala,
          maxScaleFactor: skala,
          child: child!,
        ),
        home: _Gerbang(anak),
      ),
    );

/// Jawaban menurut tingkat; tahun 2025 punya satu bulan sendiri.
Future<HasilArsip> _server(ParameterArsip p, int halaman) async {
  switch (p.tingkat) {
    case TingkatArsip.tahun:
      return HasilArsip.dariJson(arsipTahun());
    case TingkatArsip.bulan:
      if (p.query()['tahun'] == '2025') {
        return HasilArsip.dariJson(
          jawabanArsip(
            tingkat: 'bulan',
            induk: {'tahun': 2025},
            total: 1,
            kelompok: [
              kelompokJson(
                '2025-12',
                'Desember 2025',
                1,
                mulai: '2025-12-01',
                selesai: '2025-12-31',
                telusuri: {'tingkat': 'pekan', 'tahun': 2025, 'bulan': 12},
              ),
            ],
          ),
        );
      }
      return HasilArsip.dariJson(arsipBulan());
    case TingkatArsip.pekan:
      return HasilArsip.dariJson(arsipPekanNovember());
    case TingkatArsip.hari:
      return HasilArsip.dariJson(arsipHari());
  }
}

Sertifikat _s(int id, String nomor) =>
    Sertifikat.dariJson(sertifikatJson(id, nomor));

Future<void> _buka(
  WidgetTester tester,
  LayananArsipPalsu l, {
  double skala = 1.0,
  double lebar = 392,
}) async {
  layarHp(tester, lebar: lebar, tinggi: 1600);
  await tester.pumpWidget(_app(const ArsipScreen(), l, skala: skala));
  await tester.pumpAndSettle();
}

Finder get _tahun2026 => find.text('2026');

IconData _ikon(WidgetTester tester, String label) {
  final kartu = find.ancestor(
    of: find.text(label),
    matching: find.byType(KartuKelompokArsip),
  );
  return tester
      .widgetList<Icon>(find.descendant(of: kartu, matching: find.byType(Icon)))
      .last
      .icon!;
}

void main() {
  setUpAll(siapkanTesFitur);

  group('tahun membuka dan menutup di tempat', () {
    testWidgets(
      'bawaan tertutup: bulan belum diminta, penunjuknya panah turun',
      (tester) async {
        final palsu = LayananArsipPalsu(_server);
        await _buka(tester, palsu);
        expect(find.text('November 2026'), findsNothing);
        expect(palsu.panggilan, hasLength(1), reason: 'hanya tingkat tahun');
        expect(_ikon(tester, '2026'), Icons.expand_more);
      },
    );

    testWidgets('ketuk tahun: bulan tampil di bawahnya, tanpa layar baru; '
        'ketuk lagi: tertutup', (tester) async {
      final palsu = LayananArsipPalsu(_server);
      await _buka(tester, palsu);

      await tester.tap(_tahun2026);
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('Oktober 2026'), findsOneWidget);
      expect(_ikon(tester, '2026'), Icons.expand_less);
      expect(palsu.panggilan, hasLength(2));
      expect(palsu.panggilan.last.parameter.query(), {
        'tingkat': 'bulan',
        'tahun': '2026',
        'page': '1',
      });
      // Tetap di layar yang sama (tidak ada rute baru) dan tahun lain utuh.
      expect(find.byType(ArsipScreen, skipOffstage: false), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Arsip sertifikat'),
        ),
        findsOneWidget,
      );
      expect(find.text('2025'), findsOneWidget);
      // Bulan menjorok: lebih kanan dari tahunnya.
      expect(
        tester.getTopLeft(find.text('November 2026')).dx,
        greaterThan(tester.getTopLeft(_tahun2026).dx - 1),
      );

      await tester.tap(_tahun2026);
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsNothing);
      expect(_ikon(tester, '2026'), Icons.expand_more);
    });

    testWidgets('pembaca layar menerima status dibuka atau ditutup', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await _buka(tester, LayananArsipPalsu(_server));
      bool? dibuka() => tester
          .getSemantics(find.bySemanticsLabel('2026, 5 sertifikat'))
          .getSemanticsData()
          .flagsCollection
          .isExpanded
          .toBoolOrNull();
      expect(dibuka(), isFalse);
      await tester.tap(_tahun2026);
      await tester.pumpAndSettle();
      expect(dibuka(), isTrue);
      semantik.dispose();
    });

    testWidgets('dua tahun bisa terbuka bersamaan, tiap isi dari tahunnya', (
      tester,
    ) async {
      await _buka(tester, LayananArsipPalsu(_server));
      await tester.tap(_tahun2026);
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('Desember 2025'), findsOneWidget);
    });

    testWidgets('ketuk bulan: layar pekan; kembali: tahun TETAP terbuka tanpa '
        'permintaan ulang', (tester) async {
      final palsu = LayananArsipPalsu(_server);
      await _buka(tester, palsu);
      await tester.tap(_tahun2026);
      await tester.pumpAndSettle();
      await tester.tap(find.text('November 2026'));
      await tester.pumpAndSettle();
      expect(palsu.panggilan.last.parameter.tingkat, TingkatArsip.pekan);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('November 2026'),
        ),
        findsOneWidget,
        reason: 'judul layar = label kelompok',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      expect(_ikon(tester, '2026'), Icons.expand_less);
      expect(palsu.panggilan, hasLength(3), reason: 'tahun, bulan, pekan');
    });

    testWidgets('tahun tanpa telusuri dari server: ketukan diabaikan', (
      tester,
    ) async {
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
      await _buka(tester, palsu);
      await tester.tap(_tahun2026);
      await tester.pumpAndSettle();
      expect(palsu.panggilan, hasLength(1));
      expect(_ikon(tester, '2026'), Icons.expand_more);
      expect(tester.takeException(), isNull);
    });
  });

  group('tahun yang terbuka mengikuti perusahaan dan muat ulang', () {
    Widget appDuaPerusahaan(LayananArsipPalsu layanan) => ProviderScope(
      overrides: overrideDasar(
        tambahan: [
          layananProvider.overrideWithValue(layanan),
          sesiProvider.overrideWith(() => SesiBisaGanti(sesiDuaPerusahaan())),
        ],
      ),
      child: MaterialApp(
        theme: TemaSidik.terang,
        home: const _Gerbang(ArsipScreen()),
      ),
    );

    testWidgets('berganti perusahaan: tahun yang terbuka kembali tertutup, '
        'isinya tidak terbawa ke perusahaan baru', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      final palsu = LayananArsipPalsu(_server);
      await tester.pumpWidget(appDuaPerusahaan(palsu));
      await tester.pumpAndSettle();
      await tester.tap(_tahun2026);
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      expect(_ikon(tester, '2026'), Icons.expand_less);

      ProviderScope.containerOf(
        tester.element(find.byType(ArsipIsi)),
      ).read(sesiProvider.notifier).pilihPerusahaan(4);
      await tester.pumpAndSettle();

      expect(_tahun2026, findsOneWidget);
      expect(find.text('November 2026'), findsNothing);
      expect(_ikon(tester, '2026'), Icons.expand_more);

      // Perusahaan baru: tahun yang sama bisa dibuka lagi seperti biasa.
      await tester.tap(_tahun2026);
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      expect(_ikon(tester, '2026'), Icons.expand_less);
    });

    testWidgets('tarik-muat-ulang: bulan di tahun yang terbuka ikut segar, '
        'tahun yang tertutup tidak diminta', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      var diperbarui = false;
      final palsu = LayananArsipPalsu((p, h) async {
        if (diperbarui &&
            p.tingkat == TingkatArsip.bulan &&
            p.query()['tahun'] == '2026') {
          return HasilArsip.dariJson(
            jawabanArsip(
              tingkat: 'bulan',
              induk: {'tahun': 2026},
              total: 6,
              kelompok: [
                kelompokJson(
                  '2026-12',
                  'Desember 2026',
                  1,
                  mulai: '2026-12-01',
                  selesai: '2026-12-31',
                  telusuri: {'tingkat': 'pekan', 'tahun': 2026, 'bulan': 12},
                ),
              ],
            ),
          );
        }
        return _server(p, h);
      });
      await tester.pumpWidget(appDuaPerusahaan(palsu));
      await tester.pumpAndSettle();
      await tester.tap(_tahun2026);
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('Desember 2026'), findsNothing);
      expect(palsu.panggilan, hasLength(2));

      diperbarui = true;
      await tester.fling(_tahun2026, const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Desember 2026'), findsOneWidget);
      expect(find.text('November 2026'), findsNothing);
      expect(_ikon(tester, '2026'), Icons.expand_less);
      final tahunDiminta = [
        for (final c in palsu.panggilan)
          if (c.parameter.tingkat == TingkatArsip.bulan)
            c.parameter.query()['tahun'],
      ];
      expect(tahunDiminta, [
        '2026',
        '2026',
      ], reason: '2025 tidak pernah dibuka');
    });
  });

  group('keadaan di dalam tahun yang dibuka', () {
    testWidgets('memuat: penanda berlabel, lalu isi', (tester) async {
      final semantik = tester.ensureSemantics();
      final selesai = Completer<HasilArsip>();
      final palsu = LayananArsipPalsu((p, h) {
        if (p.tingkat == TingkatArsip.bulan) return selesai.future;
        return _server(p, h);
      });
      await _buka(tester, palsu);
      await tester.tap(_tahun2026);
      await tester.pump();
      expect(find.bySemanticsLabel('Memuat isi 2026'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      selesai.complete(HasilArsip.dariJson(arsipBulan()));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('November 2026'), findsOneWidget);
      semantik.dispose();
    });

    testWidgets('galat: pesan server dan "Coba lagi" memulihkan', (
      tester,
    ) async {
      var gagal = true;
      final palsu = LayananArsipPalsu((p, h) async {
        if (p.tingkat == TingkatArsip.bulan && gagal) {
          throw const GalatApi(status: 400, pesan: 'Bulan belum bisa dibuka.');
        }
        return _server(p, h);
      });
      await _buka(tester, palsu);
      await tester.tap(_tahun2026);
      await tester.pumpAndSettle();
      expect(find.text('Bulan belum bisa dibuka.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      gagal = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Bulan belum bisa dibuka.'), findsNothing);
      expect(find.text('November 2026'), findsOneWidget);
    });

    testWidgets('isi kosong dijelaskan', (tester) async {
      final palsu = LayananArsipPalsu((p, h) async {
        if (p.tingkat == TingkatArsip.bulan) {
          return HasilArsip.dariJson(jawabanArsip(tingkat: 'bulan', total: 0));
        }
        return _server(p, h);
      });
      await _buka(tester, palsu);
      await tester.tap(_tahun2026);
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada sertifikat di 2026.'), findsOneWidget);
    });
  });

  group('pencarian bertahan saat kembali dari detail', () {
    testWidgets('kata cari dan hasilnya utuh sesudah membuka sertifikat dan '
        'kembali', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 1600);
      final palsu = LayananArsipPalsu(
        _server,
        jawabCari: (cari, h) async => halamanUji([
          _s(21, 'CAL/2026/10/0001'),
          _s(22, 'CAL/2026/10/0002'),
        ]),
      );
      await tester.pumpWidget(_app(const SertifikatScreen(), palsu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arsip'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'CAL/2026');
      await tester.pump(KolomCari.jeda);
      await tester.pumpAndSettle();
      expect(find.text('2 sertifikat cocok'), findsOneWidget);
      final permintaan = palsu.cari.length;

      await tester.tap(find.text('CAL/2026/10/0002'));
      await tester.pumpAndSettle();
      expect(find.byType(SertifikatDetailScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'CAL/2026',
      );
      expect(find.text('2 sertifikat cocok'), findsOneWidget);
      expect(find.text('CAL/2026/10/0002'), findsOneWidget);
      expect(palsu.cari.length, permintaan, reason: 'tanpa muat ulang');
    });

    testWidgets('batas pencarian dijelaskan singkat: nomor persis', (
      tester,
    ) async {
      await _buka(tester, LayananArsipPalsu(_server));
      expect(
        find.text('Tulis nomor persis seperti di sertifikat.'),
        findsOneWidget,
      );
    });
  });

  group('layar sempit dan huruf besar', () {
    testWidgets('320 dp x 1,3: tahun terbuka tanpa luapan, kartu >= 48 dp', (
      tester,
    ) async {
      await _buka(tester, LayananArsipPalsu(_server), skala: 1.3, lebar: 320);
      await tester.tap(_tahun2026);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final label in ['2026', 'November 2026', 'Oktober 2026']) {
        final kartu = find.ancestor(
          of: find.text(label),
          matching: find.byType(KartuKelompokArsip),
        );
        expect(
          tester.getSize(kartu).height,
          greaterThanOrEqualTo(48),
          reason: label,
        );
        expect(
          tester.getRect(kartu).right,
          lessThanOrEqualTo(320.5),
          reason: label,
        );
      }
    });
  });
}
