// Dock navigasi navy melayang (P4, KOMPONEN.md §Dock): ukuran, bentuk, warna
// dan bayangan dari token; tiap tab terpilih/tidak (semantik, pil, label,
// ikon); lencana; sentuh >= 48 dp di seluruh butir; huruf 1,3x di 320/360/390;
// "kurangi gerak"; cincin fokus papan ketik; isi tidak tertutup dock (tepi
// sistem dan banner); rel >= 600 dp tidak berubah.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/motion/app_motion.dart';
import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/elevasi.dart';
import 'package:sidik_pelanggan/core/tema/spasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';
import 'package:sidik_pelanggan/widgets/dasar/cincin_fokus.dart';
import 'package:sidik_pelanggan/widgets/navigasi_utama.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/layar_uji.dart';
import '../dukungan/ukur_komponen.dart';

const _nama = ['Beranda', 'Alat', 'Sertifikat', 'Notifikasi', 'Akun'];
const _ikon = [
  (Icons.space_dashboard_outlined, Icons.space_dashboard),
  (Icons.precision_manufacturing_outlined, Icons.precision_manufacturing),
  (Icons.description_outlined, Icons.description),
  (Icons.notifications_none, Icons.notifications),
  (Icons.person_outline, Icons.person),
];

List<TujuanNavigasi> _tujuan({int lencana = 0}) => [
  for (var i = 0; i < _nama.length; i++)
    TujuanNavigasi(
      ikon: _ikon[i].$1,
      ikonAktif: _ikon[i].$2,
      label: _nama[i],
      tooltip: i == 3 && lencana > 0
          ? 'Notifikasi, $lencana belum dibaca'
          : null,
      lencana: i == 3 ? lencana : 0,
    ),
];

/// Aplikasi uji: [NavigasiUtama] di dalam `Scaffold`, seperti `Rangka`.
/// [tepi] = tinggi tepi sistem bawah (gesture bar).
Widget _app({
  int indeks = 0,
  ValueChanged<int>? onPilih,
  int lencana = 0,
  bool gelap = false,
  double skala = 1.0,
  double tepi = 0,
  Widget isi = const SizedBox.expand(),
  Widget? penutup,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: TemaSidik.terang,
  darkTheme: TemaSidik.gelap,
  themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(skala),
      padding: EdgeInsets.only(bottom: tepi),
    ),
    child: child!,
  ),
  home: Scaffold(
    body: NavigasiUtama(
      indeks: indeks,
      onPilih: onPilih ?? (_) {},
      tujuan: _tujuan(lencana: lencana),
      isi: isi,
      penutup: penutup,
    ),
  ),
);

Finder get _dock => find.byType(DockNavigasi);
Finder _butir(String tooltip) =>
    find.descendant(of: _dock, matching: find.byTooltip(tooltip));
Finder get _pil => find.byKey(DockNavigasi.kunciPil);

/// "Kurangi gerak" menyala di sistem (dipulihkan otomatis).
void _kurangiGerak(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

WarnaSidik _warna(bool gelap) => gelap ? WarnaSidik.gelap : WarnaSidik.terang;

/// Nilai IconTheme di sekitar ikon [data] (ukuran dan warna yang dipakai).
IconThemeData _tema(WidgetTester tester, IconData data) => IconTheme.of(
  tester.element(find.descendant(of: _dock, matching: find.byIcon(data))),
);

void main() {
  setUpAll(siapkanTesFitur);

  group('bentuk dan token', () {
    for (final gelap in [false, true]) {
      testWidgets('dock navy ${gelap ? 'tema gelap' : 'tema terang'}: '
          'tinggi 64, sudut 36, padding 8, bayangan 0/16/32 navy 28%', (
        tester,
      ) async {
        layarHp(tester, lebar: 390, tinggi: 800);
        await tester.pumpWidget(_app(gelap: gelap));
        await tester.pumpAndSettle();

        final dock = tester.getRect(_dock);
        expect(dock.height, UkuranDock.tinggi);
        final dekor =
            tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: _dock,
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        final navy = _warna(gelap).tintaUbin;
        expect(dekor.color, navy);
        expect(dekor.borderRadius, Bentuk.sudutDock);
        expect(dekor.boxShadow, hasLength(1));
        final bayangan = dekor.boxShadow!.single;
        expect(bayangan.offset, const Offset(0, 16));
        expect(bayangan.blurRadius, 32);
        expect(bayangan.color, navy.withValues(alpha: 0.28));
        expect(bayangan.color, navy.withValues(alpha: Elevasi.dockOpasitas));

        // Padding 8: pil aktif (butir pertama) 8 dari tepi kiri dan atas.
        final pil = tester.getRect(_pil);
        expect(pil.left - dock.left, Spasi.sm);
        expect(pil.top - dock.top, Spasi.sm);
        expect(pil.height, UkuranDock.butir);
        // Pil kuning bertepi pil penuh.
        final dekorPil =
            tester.widget<DecoratedBox>(_pil).decoration as BoxDecoration;
        expect(dekorPil.color, _warna(gelap).ubinAwas);
        expect(dekorPil.borderRadius, Bentuk.sudutPil);

        // Butir tidak aktif 48 x 48, jarak 4 antar-butir.
        final alat = tester.getRect(_butir('Alat'));
        final sertifikat = tester.getRect(_butir('Sertifikat'));
        expect(alat.size, const Size.square(UkuranDock.butir));
        expect(sertifikat.size, const Size.square(UkuranDock.butir));
        expect(sertifikat.left - alat.right, Spasi.xs);
        expect(alat.left - pil.right, Spasi.xs);
        // Lebar dock = padding + isi (tanpa ruang kosong).
        expect(dock.right - tester.getRect(_butir('Akun')).right, Spasi.sm);
      });
    }

    testWidgets('melayang 16 dp di atas tepi sistem dan di tengah', (
      tester,
    ) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      await tester.pumpWidget(_app(tepi: 34));
      await tester.pumpAndSettle();
      final dock = tester.getRect(_dock);
      expect(dock.bottom, 800 - 34 - UkuranDock.dariBawah);
      expect(dock.center.dx, closeTo(195, 0.01));

      await tester.pumpWidget(_app(tepi: 0));
      await tester.pumpAndSettle();
      expect(tester.getRect(_dock).bottom, 800 - UkuranDock.dariBawah);
    });
  });

  group('tiap tab terpilih dan tidak', () {
    for (var aktif = 0; aktif < _nama.length; aktif++) {
      testWidgets('tab ${_nama[aktif]} terpilih: pil, label, ikon, semantik', (
        tester,
      ) async {
        final semantik = tester.ensureSemantics();
        layarHp(tester, lebar: 390, tinggi: 800);
        await tester.pumpWidget(_app(indeks: aktif));
        await tester.pumpAndSettle();
        final w = WarnaSidik.terang;

        final pil = tester.getRect(_pil);
        for (var i = 0; i < _nama.length; i++) {
          final dipilih = i == aktif;
          final butir = tester.getRect(_butir(_nama[i]));
          // Semantik: satu simpul tombol berlabel; selected hanya di tab aktif.
          expect(
            tester.getSemantics(find.bySemanticsLabel(_nama[i])),
            matchesSemantics(
              label: _nama[i],
              isButton: true,
              hasEnabledState: true,
              isEnabled: true,
              hasSelectedState: true,
              isSelected: dipilih,
              hasTapAction: true,
            ),
            reason: '${_nama[i]} dipilih=$dipilih',
          );
          // Label tampil hanya di butir aktif.
          expect(
            find.descendant(of: _dock, matching: find.text(_nama[i])),
            dipilih ? findsOneWidget : findsNothing,
            reason: 'label ${_nama[i]}',
          );
          // Ikon: terisi + 20 + navy di butir aktif; garis + 22 + putih lainnya.
          final ikon = _tema(tester, dipilih ? _ikon[i].$2 : _ikon[i].$1);
          expect(
            ikon.size,
            dipilih ? UkuranDock.ikonAktif : UkuranDock.ikon,
            reason: 'ukuran ikon ${_nama[i]}',
          );
          expect(
            ikon.color,
            dipilih ? w.tintaUbin : w.kertasUbin,
            reason: 'warna ikon ${_nama[i]}',
          );
          expect(
            find.descendant(
              of: _dock,
              matching: find.byIcon(dipilih ? _ikon[i].$1 : _ikon[i].$2),
            ),
            findsNothing,
            reason: 'bentuk ikon ${_nama[i]} salah untuk dipilih=$dipilih',
          );
          if (dipilih) {
            // Pil kuning persis di butir aktif; padding 16, ikon 20, jarak 8.
            expect(pil, butir);
            final label = tester.getRect(
              find.descendant(of: _dock, matching: find.text(_nama[i])),
            );
            expect(
              butir.width,
              2 * Spasi.lg + UkuranDock.ikonAktif + Spasi.sm + label.width,
            );
            expect(
              label.left - butir.left,
              Spasi.lg + UkuranDock.ikonAktif + Spasi.sm,
            );
            expect(label.height, lessThan(24), reason: 'satu baris');
          } else {
            expect(butir.size, const Size.square(UkuranDock.butir));
          }
        }
        semantik.dispose();
      });
    }

    testWidgets('pembaca layar: satu simpul berlabel per butir, tooltip tidak '
        'membacakannya dua kali', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 390, tinggi: 800);
      await tester.pumpWidget(_app(indeks: 1, lencana: 3));
      await tester.pumpAndSettle();

      final berlabel = <String>[];
      final bertooltip = <String>[];
      void kunjungi(SemanticsNode simpul) {
        final data = simpul.getSemanticsData();
        if (data.label.isNotEmpty) berlabel.add(data.label);
        if (data.tooltip.isNotEmpty) bertooltip.add(data.tooltip);
        simpul.visitChildren((anak) {
          kunjungi(anak);
          return true;
        });
      }

      kunjungi(tester.getSemantics(find.byType(DockNavigasi)));
      expect(berlabel, [
        'Beranda',
        'Alat',
        'Sertifikat',
        'Notifikasi, 3 belum dibaca',
        'Akun',
      ]);
      expect(bertooltip, isEmpty);
      semantik.dispose();
    });

    testWidgets('ketuk tiap butir memanggil onPilih(indeks) tepat sekali', (
      tester,
    ) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      final dipilih = <int>[];
      await tester.pumpWidget(_app(onPilih: dipilih.add));
      await tester.pumpAndSettle();
      for (var i = 0; i < _nama.length; i++) {
        await tester.tap(_butir(_nama[i]));
        await tester.pump();
        expect(dipilih, hasLength(i + 1), reason: _nama[i]);
        expect(dipilih.last, i, reason: _nama[i]);
      }
    });

    testWidgets('seluruh kotak butir menerima ketukan, termasuk tepinya', (
      tester,
    ) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      final dipilih = <int>[];
      await tester.pumpWidget(_app(onPilih: dipilih.add));
      await tester.pumpAndSettle();
      final alat = tester.getRect(_butir('Alat'));
      await tester.tapAt(alat.topLeft + const Offset(1, 1));
      await tester.tapAt(alat.bottomRight - const Offset(1, 1));
      expect(dipilih, [1, 1]);
    });

    testWidgets('lencana notifikasi: angka, "99+", warna token, label baca', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 390, tinggi: 800);
      await tester.pumpWidget(_app(lencana: 3));
      await tester.pumpAndSettle();
      final w = WarnaSidik.terang;
      final lencana = tester.widget<Badge>(find.byType(Badge));
      expect(lencana.backgroundColor, w.ubinGagal);
      expect(lencana.textColor, w.tintaUbin);
      expect((lencana.label! as Text).data, '3');
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Notifikasi, 3 belum dibaca'),
        ),
        matchesSemantics(
          label: 'Notifikasi, 3 belum dibaca',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      expect(_butir('Notifikasi, 3 belum dibaca'), findsOneWidget);

      await tester.pumpWidget(_app(lencana: 120));
      await tester.pumpAndSettle();
      expect(find.text('99+'), findsOneWidget);

      await tester.pumpWidget(_app(lencana: 0));
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNothing);
      semantik.dispose();
    });

    for (final gelap in [false, true]) {
      testWidgets('kontras ${gelap ? 'gelap' : 'terang'}: ikon putih/navy, '
          'label navy di kuning, lencana navy di koral', (tester) async {
        final w = _warna(gelap);
        expect(
          rasioKontras(w.kertasUbin, w.tintaUbin),
          greaterThanOrEqualTo(7),
        );
        expect(rasioKontras(w.tintaUbin, w.ubinAwas), greaterThanOrEqualTo(7));
        expect(
          rasioKontras(w.tintaUbin, w.ubinGagal),
          greaterThanOrEqualTo(4.5),
        );
        // Dock terhadap halaman bukan batas kontrol; yang diukur: ikon di atas dock.
        layarHp(tester, lebar: 390, tinggi: 800);
        await tester.pumpWidget(_app(gelap: gelap, indeks: 1));
        await tester.pumpAndSettle();
        expect(_tema(tester, Icons.person_outline).color, w.kertasUbin);
        expect(
          tester
              .widget<Text>(
                find.descendant(of: _dock, matching: find.text('Alat')),
              )
              .style!
              .color,
          w.tintaUbin,
        );
      });
    }
  });

  group('lebar dan huruf', () {
    // Lebar layar -> jarak antar-butir yang diharapkan, dan apakah label tampil.
    // 390: spesifikasi (padding 16, ikon-label 8, jarak 4). 360: rapat (12, 4, 0).
    // 320: pil hanya berikon (label tetap dibaca pembaca layar dan tooltip).
    for (final lebar in [320.0, 340.0, 360.0, 390.0, 411.0, 599.0]) {
      for (var aktif = 0; aktif < _nama.length; aktif++) {
        testWidgets('${lebar.toInt()} dp, huruf 1,3x, tab ${_nama[aktif]}: '
            'muat, tanpa overflow, butir >= 48 dp', (tester) async {
          final semantik = tester.ensureSemantics();
          layarHp(tester, lebar: lebar, tinggi: 640);
          await tester.pumpWidget(_app(indeks: aktif, skala: 1.3, lencana: 12));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final dock = tester.getRect(_dock);
          expect(dock.left, greaterThanOrEqualTo(Spasi.sm));
          expect(dock.right, lessThanOrEqualTo(lebar - Spasi.sm));
          expect(dock.height, UkuranDock.tinggi);
          for (final nama in [
            'Beranda',
            'Alat',
            'Sertifikat',
            'Notifikasi, 12 belum dibaca',
            'Akun',
          ]) {
            final butir = tester.getRect(_butir(nama));
            expect(butir.height, greaterThanOrEqualTo(48), reason: nama);
            expect(butir.width, greaterThanOrEqualTo(48), reason: nama);
            expect(dock.contains(butir.topLeft), isTrue, reason: nama);
            expect(dock.contains(butir.bottomRight), isTrue, reason: nama);
            // Label baca ada untuk tiap butir, berlabel atau tidak.
            expect(
              tester.getSemantics(find.bySemanticsLabel(nama)).label,
              nama,
            );
          }
          // Pil mengikuti butir aktif.
          final namaAktif = aktif == 3
              ? 'Notifikasi, 12 belum dibaca'
              : _nama[aktif];
          expect(tester.getRect(_pil), tester.getRect(_butir(namaAktif)));
          semantik.dispose();
        });
      }
    }

    testWidgets('jarak berganti menurut lebar: 390 spesifikasi, 360 rapat, '
        '320 hanya ikon', (tester) async {
      Future<(double, double, bool)> ukur(double lebar) async {
        layarHp(tester, lebar: lebar, tinggi: 640);
        await tester.pumpWidget(_app(indeks: 2, skala: 1.3));
        await tester.pumpAndSettle();
        final jarak =
            tester.getRect(_butir('Akun')).left -
            tester.getRect(_butir('Notifikasi')).right;
        final pil = tester.getRect(_pil);
        final ada = find
            .descendant(of: _dock, matching: find.text('Sertifikat'))
            .evaluate()
            .isNotEmpty;
        return (jarak, pil.width, ada);
      }

      final (j390, p390, l390) = await ukur(390);
      expect(l390, isTrue);
      expect(j390, Spasi.xs);
      final label = tester.getSize(
        find.descendant(of: _dock, matching: find.text('Sertifikat')),
      );
      expect(
        p390,
        2 * Spasi.lg + UkuranDock.ikonAktif + Spasi.sm + label.width,
      );

      final (j360, p360, l360) = await ukur(360);
      expect(l360, isTrue, reason: 'label masih muat di 360 dp');
      expect(j360, 0);
      expect(
        p360,
        2 * Spasi.md + UkuranDock.ikonAktif + Spasi.xs + label.width,
      );

      final (j320, p320, l320) = await ukur(320);
      expect(l320, isFalse, reason: 'tidak muat: pil hanya ikon');
      expect(j320, Spasi.xs);
      expect(p320, UkuranDock.butir);
    });

    testWidgets('label tidak ikut membesar oleh huruf sistem (maks 1,0x)', (
      tester,
    ) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      Future<Size> labelDi(double skala) async {
        await tester.pumpWidget(_app(indeks: 1, skala: skala));
        await tester.pumpAndSettle();
        return tester.getSize(
          find.descendant(of: _dock, matching: find.text('Alat')),
        );
      }

      final biasa = await labelDi(1.0);
      expect(await labelDi(1.3), biasa);
      expect(await labelDi(2.0), biasa);
    });
  });

  group('gerak', () {
    testWidgets('pil meluncur 240 ms ke butir baru, kurva masuk', (
      tester,
    ) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      await tester.pumpWidget(_app(indeks: 0));
      await tester.pumpAndSettle();
      final awal = tester.getRect(_pil);

      await tester.pumpWidget(_app(indeks: 4));
      await tester.pump(); // bingkai pertama = t 0
      expect(tester.getRect(_pil).left, awal.left);
      await tester.pump(AppMotion.sedang ~/ 2);
      final tengah = tester.getRect(_pil);
      expect(tengah.left, greaterThan(awal.left), reason: 'sudah bergeser');
      await tester.pump(AppMotion.sedang);
      await tester.pumpAndSettle();
      final akhir = tester.getRect(_butir('Akun'));
      expect(tengah.left, lessThan(akhir.left), reason: 'belum sampai');
      expect(tester.getRect(_pil), akhir);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('kurangi gerak: pil langsung di butir baru (tanpa bingkai '
        'antara)', (tester) async {
      _kurangiGerak(tester);
      layarHp(tester, lebar: 390, tinggi: 800);
      await tester.pumpWidget(_app(indeks: 0));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(indeks: 3));
      await tester.pump();
      expect(tester.getRect(_pil), tester.getRect(_butir('Notifikasi')));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('papan ketik', () {
    for (final gelap in [false, true]) {
      testWidgets('cincin fokus putih di luar butir, di dalam dock, '
          '>= 3:1 (${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 390, tinggi: 800);
        final dipilih = <int>[];
        await tester.pumpWidget(_app(gelap: gelap, onPilih: dipilih.add));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final cincin = find.byKey(CincinFokus.kunciCincin);
        expect(cincin, findsOneWidget, reason: 'cincin tidak tampil');
        final w = _warna(gelap);
        final garis =
            ((tester.widget<DecoratedBox>(cincin).decoration as BoxDecoration)
                        .border!
                    as Border)
                .top;
        expect(garis.width, UkuranFokus.tebal);
        expect(garis.color, w.kertasUbin);
        expect(
          rasioKontras(garis.color, w.tintaUbin),
          greaterThanOrEqualTo(3),
          reason: 'cincin terhadap dock navy',
        );
        // Mengelilingi butir pertama (yang aktif) dengan celah, di dalam dock.
        final butir = tester.getRect(_butir('Beranda'));
        expect(tester.getRect(cincin), butir.inflate(UkuranFokus.jarakLuar));
        expect(
          tester.getRect(_dock).contains(tester.getRect(cincin).topLeft),
          isTrue,
        );

        // Enter mengaktifkan butir yang berfokus; Tab berikutnya pindah butir.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(dipilih, [1]);
      });
    }
  });

  group('isi tidak tertutup dock', () {
    Widget isiBergulir(Key kunciAkhir) => Builder(
      builder: (context) => ListView(
        // Bawah daftar: tepi sistem yang diberikan NavigasiUtama (harus 0
        // karena pita dock sudah memakainya).
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        children: [
          for (var i = 0; i < 30; i++)
            SizedBox(height: 80, child: Text('baris $i')),
          SizedBox(key: kunciAkhir, height: 80, child: const Text('akhir')),
        ],
      ),
    );

    testWidgets('butir terakhir daftar berhenti di atas pita dock '
        '(16 + 64 + 16 + tepi sistem)', (tester) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      const akhir = ValueKey('akhir');
      await tester.pumpWidget(_app(tepi: 34, isi: isiBergulir(akhir)));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pumpAndSettle();

      final dock = tester.getRect(_dock);
      final terakhir = tester.getRect(find.byKey(akhir));
      expect(terakhir.bottom, lessThanOrEqualTo(dock.top - Spasi.lg));
      expect(
        tester.getRect(find.byType(ListView)).bottom,
        800 - 34 - UkuranDock.dariBawah - UkuranDock.tinggi - Spasi.lg,
        reason: 'isi berakhir 16 di atas dock',
      );
    });

    testWidgets('tab tidak menerima tepi sistem lagi (hitungan ganda)', (
      tester,
    ) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      double? bawah;
      await tester.pumpWidget(
        _app(
          tepi: 34,
          isi: Builder(
            builder: (context) {
              bawah = MediaQuery.paddingOf(context).bottom;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(bawah, 0);
    });

    testWidgets('banner pembaruan duduk di atas dock, isi di atas banner', (
      tester,
    ) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      const banner = ValueKey('banner');
      await tester.pumpWidget(
        _app(
          isi: const ColoredBox(key: ValueKey('isi'), color: Colors.white),
          penutup: const SizedBox(
            key: banner,
            width: double.infinity,
            height: 56,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final dock = tester.getRect(_dock);
      final b = tester.getRect(find.byKey(banner));
      final isi = tester.getRect(find.byKey(const ValueKey('isi')));
      expect(b.bottom, lessThanOrEqualTo(dock.top - Spasi.lg));
      expect(isi.bottom, b.top);
      expect(b.width, 390, reason: 'banner selebar layar');
    });
  });

  group('rel >= 600 dp tetap', () {
    for (final lebar in [600.0, 840.0]) {
      testWidgets('${lebar.toInt()} dp: rel samping lima tujuan, tanpa dock, '
          'tanpa pita bawah', (tester) async {
        layarHp(tester, lebar: lebar, tinggi: 800);
        final dipilih = <int>[];
        await tester.pumpWidget(
          _app(
            indeks: 2,
            onPilih: dipilih.add,
            tepi: 34,
            isi: const ColoredBox(key: ValueKey('isi'), color: Colors.white),
          ),
        );
        await tester.pumpAndSettle();
        expect(_dock, findsNothing);
        final rel = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rel.destinations, hasLength(5));
        expect(rel.selectedIndex, 2);
        expect(rel.labelType, NavigationRailLabelType.all);
        for (final nama in _nama) {
          expect(
            find.descendant(
              of: find.byType(NavigationRail),
              matching: find.text(nama),
            ),
            findsOneWidget,
            reason: nama,
          );
        }
        // Isi mengisi tinggi penuh di kanan rel (tidak ada pita dock).
        expect(tester.getRect(find.byKey(const ValueKey('isi'))).bottom, 800);
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationRail),
            matching: find.text('Akun'),
          ),
        );
        expect(dipilih, [4]);
      });
    }
  });
}
