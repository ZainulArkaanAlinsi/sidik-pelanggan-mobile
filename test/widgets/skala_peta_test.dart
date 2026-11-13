// SkalaTempo dan PetaJatuhTempo: batas jendela skala, posisi tik, kata yang
// menyertai batang, zona yang bisa diketuk (>= 48 dp), terang/gelap, 320 dp x
// huruf 1,3, dan tablet.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';
import 'package:sidik_pelanggan/widgets/panel_sidik.dart';
import 'package:sidik_pelanggan/widgets/peta_jatuh_tempo.dart';
import 'package:sidik_pelanggan/widgets/skala_tempo.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/layar_uji.dart';
import '../dukungan/ukur_komponen.dart';

ThemeData _tema(bool gelap) => gelap ? TemaSidik.gelap : TemaSidik.terang;

Widget _dalamPanel(Widget anak) => PanelSidik(
  anak: [Padding(padding: const EdgeInsets.all(16), child: anak)],
);

final _jadwal = DateTime(2026, 11, 9);

/// Kotak berwarna [warna] di dalam [dalam] (batang skala atau batang zona).
Finder _batang(Type dalam, Color warna) => find.descendant(
  of: find.byType(dalam),
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == warna,
  ),
);

void main() {
  setUpAll(siapkanTesFitur);

  group('SkalaTempo.posisi: batas jendela', () {
    test('jendela: 90 hari sebelum jadwal; lewat jadwal -60 sampai +30', () {
      expect(SkalaTempo.jendelaHari, 90);
      expect(SkalaTempo.jendelaLewatSebelum, 60);
      expect(SkalaTempo.jendelaLewatSesudah, 30);
    });

    test(
      'belum lewat: hari ini bergerak dari kiri ke kanan, jadwal di kanan',
      () {
        expect(SkalaTempo.posisi(90).sekarang, 0.0);
        expect(SkalaTempo.posisi(45).sekarang, 0.5);
        expect(SkalaTempo.posisi(30).sekarang, closeTo(60 / 90, 1e-9));
        expect(SkalaTempo.posisi(1).sekarang, closeTo(89 / 90, 1e-9));
        expect(SkalaTempo.posisi(0).sekarang, 1.0);
        for (final h in [90, 45, 0]) {
          expect(SkalaTempo.posisi(h).jadwal, 1.0, reason: 'hari=$h');
        }
      },
    );

    test('di luar jendela: hari ini menempel di tepi, tidak keluar batang', () {
      expect(SkalaTempo.posisi(91).sekarang, 0.0);
      expect(SkalaTempo.posisi(400).sekarang, 0.0);
      expect(SkalaTempo.posisi(-31).sekarang, 1.0);
      expect(SkalaTempo.posisi(-400).sekarang, 1.0);
    });

    test('lewat jadwal: jendela bergeser, jadwal di dua pertiga', () {
      final p = SkalaTempo.posisi(-4);
      expect(p.jadwal, closeTo(60 / 90, 1e-9));
      expect(p.sekarang, closeTo(64 / 90, 1e-9));
      expect(p.sekarang, greaterThan(p.jadwal));
      expect(SkalaTempo.posisi(-1).sekarang, closeTo(61 / 90, 1e-9));
      expect(SkalaTempo.posisi(-30).sekarang, 1.0);
    });

    test('hari 0 dan -1 jatuh di dua sisi tik jadwal', () {
      expect(SkalaTempo.posisi(0).sekarang, 1.0);
      expect(SkalaTempo.posisi(0).jadwal, 1.0);
      // Lewat sehari: jendela berganti, jadwal turun ke 2/3.
      expect(SkalaTempo.posisi(-1).jadwal, lessThan(1.0));
    });
  });

  group('SkalaTempo: widget', () {
    testWidgets('kata dan dua label: lewat jadwal', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(SkalaTempo(hari: -4, jadwal: _jadwal)),
      );
      expect(find.text('Lewat 4 hari'), findsOneWidget);
      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('Jadwal 9 Nov 2026'), findsOneWidget);
    });

    testWidgets(
      'kata menurut hari: lagi, hari ini, tanpa kata bila dimatikan',
      (tester) async {
        await tester.pumpWidget(
          aplikasiUji(SkalaTempo(hari: 12, jadwal: _jadwal)),
        );
        expect(find.text('12 hari lagi'), findsOneWidget);
        await tester.pumpWidget(
          aplikasiUji(SkalaTempo(hari: 0, jadwal: _jadwal)),
        );
        expect(find.text('Kalibrasi ulang hari ini'), findsOneWidget);
        await tester.pumpWidget(
          aplikasiUji(SkalaTempo(hari: 12, jadwal: _jadwal, kata: false)),
        );
        expect(find.text('12 hari lagi'), findsNothing);
        expect(find.text('Hari ini'), findsOneWidget);
      },
    );

    testWidgets('kata berwarna menurut kemendesakan, bukan satu-satunya arti', (
      tester,
    ) async {
      final s = TemaSidik.terang.colorScheme;
      final w = TemaSidik.terang.extension<WarnaSidik>()!;
      for (final (hari, kata, warna) in [
        (-4, 'Lewat 4 hari', w.gagal),
        (12, '12 hari lagi', w.awas),
        (30, '30 hari lagi', w.awas),
        (31, '31 hari lagi', s.onSurface),
      ]) {
        await tester.pumpWidget(
          aplikasiUji(SkalaTempo(hari: hari, jadwal: _jadwal)),
        );
        expect(
          tester.widget<Text>(find.text(kata)).style!.color,
          warna,
          reason: kata,
        );
      }
    });

    testWidgets(
      'geometri: isi kobalt sampai hari ini, ekor merah setelah jadwal',
      (tester) async {
        final s = TemaSidik.terang.colorScheme;
        final w = TemaSidik.terang.extension<WarnaSidik>()!;
        await tester.pumpWidget(
          aplikasiUji(SkalaTempo(hari: -4, jadwal: _jadwal)),
        );
        final trek = tester.getRect(_batang(SkalaTempo, s.outlineVariant));
        final isi = tester.getRect(_batang(SkalaTempo, s.primary));
        final ekor = tester.getRect(_batang(SkalaTempo, w.gagal));
        final p = SkalaTempo.posisiTampak(-4);
        expect(isi.left, closeTo(trek.left, 0.01));
        expect(isi.width, closeTo(trek.width * p.jadwal, 0.01));
        expect(ekor.left, closeTo(trek.left + trek.width * p.jadwal, 0.01));
        expect(ekor.width, closeTo(trek.width * (p.sekarang - p.jadwal), 0.01));
        expect(trek.height, UkuranTik.tinggi);
        // Lewat 4 hari hanya 4% lebar; ekor digambar paling sedikit 8%, supaya
        // tidak jadi hiasan (arti tetap dibawa kata "Lewat 4 hari").
        expect(ekor.width / trek.width, closeTo(SkalaTempo.ekorMinimum, 1e-6));

        // Belum lewat: tanpa ekor, isi sampai hari ini.
        await tester.pumpWidget(
          aplikasiUji(SkalaTempo(hari: 30, jadwal: _jadwal)),
        );
        expect(_batang(SkalaTempo, w.gagal), findsNothing);
        final trek2 = tester.getRect(_batang(SkalaTempo, s.outlineVariant));
        final isi2 = tester.getRect(_batang(SkalaTempo, s.primary));
        expect(isi2.width, closeTo(trek2.width * (60 / 90), 0.01));
      },
    );

    testWidgets(
      'tik jadwal setebal 2 dp dan tinggi 24 dp, tetap di dalam batang',
      (tester) async {
        final s = TemaSidik.terang.colorScheme;
        for (final hari in [-4, 12, 0, 200]) {
          await tester.pumpWidget(
            aplikasiUji(SkalaTempo(hari: hari, jadwal: _jadwal)),
          );
          final tik = find.descendant(
            of: find.byType(SkalaTempo),
            matching: find.byWidgetPredicate(
              (w) => w is ColoredBox && w.color == s.onSurface,
            ),
          );
          expect(tik, findsOneWidget, reason: 'hari=$hari');
          final r = tester.getRect(tik);
          final trek = tester.getRect(_batang(SkalaTempo, s.outlineVariant));
          expect(r.width, UkuranTik.batang);
          expect(r.height, UkuranTik.penanda);
          expect(r.left, greaterThanOrEqualTo(trek.left));
          expect(r.right, lessThanOrEqualTo(trek.right + 0.01));
        }
      },
    );

    testWidgets('label di atas dan di bawah batang, BERPUSAT pada tiknya', (
      tester,
    ) async {
      final s = TemaSidik.terang.colorScheme;
      await tester.pumpWidget(
        aplikasiUji(SkalaTempo(hari: 12, jadwal: _jadwal, kata: false)),
      );
      var trek = tester.getRect(_batang(SkalaTempo, s.outlineVariant));
      var atas = tester.getRect(find.text('Hari ini'));
      var bawah = tester.getRect(find.text('Jadwal 9 Nov 2026'));
      expect(atas.bottom, lessThanOrEqualTo(trek.top));
      expect(bawah.top, greaterThanOrEqualTo(trek.bottom));
      final p = SkalaTempo.posisiTampak(12);
      expect(
        atas.center.dx,
        closeTo(trek.left + trek.width * p.sekarang, 0.5),
        reason: 'label hari ini berpusat pada tik hari ini',
      );
      // Jadwal di ujung kanan: label dijepit rata kanan, tidak keluar batang.
      expect(bawah.right, closeTo(trek.right, 0.5));

      // Hari ini di tengah batang (45 hari): berpusat persis.
      await tester.pumpWidget(
        aplikasiUji(SkalaTempo(hari: 45, jadwal: _jadwal, kata: false)),
      );
      trek = tester.getRect(_batang(SkalaTempo, s.outlineVariant));
      atas = tester.getRect(find.text('Hari ini'));
      expect(atas.center.dx, closeTo(trek.center.dx, 0.5));

      // Lewat jadwal: label jadwal berpusat pada tik jadwal (dua pertiga).
      await tester.pumpWidget(
        aplikasiUji(SkalaTempo(hari: -4, jadwal: _jadwal, kata: false)),
      );
      trek = tester.getRect(_batang(SkalaTempo, s.outlineVariant));
      bawah = tester.getRect(find.text('Jadwal 9 Nov 2026'));
      final lewat = SkalaTempo.posisiTampak(-4);
      expect(
        bawah.center.dx,
        closeTo(trek.left + trek.width * lewat.jadwal, 0.5),
      );
    });

    test('biasTengah: berpusat, dijepit di kedua tepi', () {
      double bias(double lebar, double label, double posisi) =>
          SkalaTempo.biasTengah(
            lebar: lebar,
            lebarLabel: label,
            posisi: posisi,
          );
      expect(bias(300, 60, 0.5), closeTo(0, 1e-9));
      expect(bias(300, 60, 0), -1);
      expect(bias(300, 60, 1), 1);
      expect(bias(300, 60, 0.05), -1, reason: 'dijepit di kiri');
      expect(bias(300, 60, 0.95), 1, reason: 'dijepit di kanan');
      // Label lebih lebar dari batang: rata kiri, tanpa pembagian nol.
      expect(bias(50, 80, 0.5), -1);
      expect(bias(60, 60, 0.5), -1);
      // Antara tepi dan tengah: linear.
      expect(bias(300, 60, 0.3), closeTo(((90 - 30) / 240) * 2 - 1, 1e-9));
    });

    test(
      'posisiTampak: ekor lewat jadwal paling sedikit 8%, angka tak berubah',
      () {
        expect(SkalaTempo.ekorMinimum, 0.08);
        // Belum lewat: sama dengan posisi sebenarnya.
        for (final h in [0, 1, 45, 90, 200]) {
          expect(
            SkalaTempo.posisiTampak(h),
            SkalaTempo.posisi(h),
            reason: '$h',
          );
        }
        // Lewat sehari dan 4 hari: ekor dilebarkan sampai 8%.
        for (final h in [-1, -4, -7]) {
          final t = SkalaTempo.posisiTampak(h);
          expect(t.jadwal, SkalaTempo.posisi(h).jadwal);
          expect(t.sekarang - t.jadwal, closeTo(0.08, 1e-9), reason: '$h');
        }
        // Ekor yang sudah lebih lebar dari 8% tidak diubah.
        expect(SkalaTempo.posisiTampak(-20), SkalaTempo.posisi(-20));
        expect(SkalaTempo.posisiTampak(-30).sekarang, 1.0);
        // Posisi sebenarnya tidak disentuh (lewat 4 hari = 4/90).
        final nyata = SkalaTempo.posisi(-4);
        expect(nyata.sekarang - nyata.jadwal, closeTo(4 / 90, 1e-9));
      },
    );

    testWidgets('hari di luar jendela: label hari ini rata kiri', (
      tester,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(SkalaTempo(hari: 200, jadwal: _jadwal, kata: false)),
      );
      final s = TemaSidik.terang.colorScheme;
      final trek = tester.getRect(_batang(SkalaTempo, s.outlineVariant));
      expect(
        tester.getRect(find.text('Hari ini')).left,
        closeTo(trek.left, 0.5),
      );
      // Isi kobalt kosong: belum ada kemajuan menuju jadwal.
      expect(tester.getRect(_batang(SkalaTempo, s.primary)).width, 0);
    });

    testWidgets('label baca: satu kalimat dengan tanggal', (tester) async {
      final semantik = tester.ensureSemantics();
      for (final (hari, kalimat) in [
        (-4, 'Lewat 4 hari dari jadwal 9 Nov 2026'),
        (12, '12 hari lagi sampai jadwal 9 Nov 2026'),
        (0, 'Jadwal kalibrasi ulang hari ini, 9 Nov 2026'),
      ]) {
        await tester.pumpWidget(
          aplikasiUji(SkalaTempo(hari: hari, jadwal: _jadwal)),
        );
        expect(find.bySemanticsLabel(kalimat), findsOneWidget, reason: '$hari');
      }
      semantik.dispose();
    });

    for (final gelap in [false, true]) {
      testWidgets('kontras: teks 4,5; isi, ekor, tik jadwal terhadap batang 3 '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        final s = _tema(gelap).colorScheme;
        final w = _tema(gelap).extension<WarnaSidik>()!;
        for (final hari in [-4, 12, 31, 200]) {
          await tester.pumpWidget(
            aplikasiUji(
              _dalamPanel(SkalaTempo(hari: hari, jadwal: _jadwal)),
              gelap: gelap,
            ),
          );
          expect(
            pelanggaranKontrasTeks(tester, find.byType(SkalaTempo)),
            isEmpty,
            reason: 'hari=$hari',
          );
        }
        expect(
          rasioKontras(s.primary, s.outlineVariant),
          greaterThanOrEqualTo(3),
        );
        expect(rasioKontras(w.gagal, s.surface), greaterThanOrEqualTo(3));
        expect(
          rasioKontras(s.onSurface, s.outlineVariant),
          greaterThanOrEqualTo(3),
        );
      });

      testWidgets('320 dp x huruf 1,3: tanpa luapan, tinggi mengikuti huruf, '
          'label tidak bertumpuk (${gelap ? 'gelap' : 'terang'})', (
        tester,
      ) async {
        layarHp(tester, lebar: 320, tinggi: 640);
        final s = _tema(gelap).colorScheme;
        await tester.pumpWidget(
          aplikasiUji(SkalaTempo(hari: -4, jadwal: _jadwal), gelap: gelap),
        );
        final tinggiBiasa = tester.getSize(find.byType(SkalaTempo)).height;
        await tester.pumpWidget(
          aplikasiUji(
            SkalaTempo(hari: -4, jadwal: _jadwal),
            gelap: gelap,
            skala: 1.3,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(SkalaTempo)).height,
          greaterThan(tinggiBiasa),
          reason: 'label di luar batang: tinggi mengikuti skala huruf',
        );
        final trek = tester.getRect(_batang(SkalaTempo, s.outlineVariant));
        final atas = tester.getRect(find.text('Hari ini'));
        final bawah = tester.getRect(find.text('Jadwal 9 Nov 2026'));
        expect(atas.bottom, lessThanOrEqualTo(trek.top));
        expect(bawah.top, greaterThanOrEqualTo(trek.bottom));
        expect(bawah.right, lessThanOrEqualTo(320 - 20 + 0.5));
      });
    }

    testWidgets('tablet: batang mengisi lebar yang tersedia', (tester) async {
      layarTablet(tester);
      final s = TemaSidik.terang.colorScheme;
      await tester.pumpWidget(
        aplikasiUji(SkalaTempo(hari: 12, jadwal: _jadwal)),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(_batang(SkalaTempo, s.outlineVariant)).width,
        840 - 40,
      );
    });

    testWidgets('bukan sasaran sentuh', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(SkalaTempo(hari: 12, jadwal: _jadwal)),
      );
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('PetaJatuhTempo', () {
    const zona = [
      ZonaTempo(label: 'Lewat jadwal', jumlah: 1, nada: NadaStatus.gagal),
      ZonaTempo(label: 'Dalam 30 hari', jumlah: 1, nada: NadaStatus.awas),
      ZonaTempo(label: '31 sampai 60 hari', jumlah: 2),
      ZonaTempo(label: '61 sampai 90 hari', jumlah: 0),
    ];

    testWidgets('angka, label, dan batang bernada; nol abu tanpa warna status', (
      tester,
    ) async {
      final s = TemaSidik.terang.colorScheme;
      final w = TemaSidik.terang.extension<WarnaSidik>()!;
      await tester.pumpWidget(aplikasiUji(const PetaJatuhTempo(zona: zona)));
      for (final z in zona) {
        expect(find.text(z.label), findsOneWidget, reason: z.label);
      }
      Color angka(String teks, int urutan) => tester
          .widgetList<Text>(find.text(teks))
          .elementAt(urutan)
          .style!
          .color!;
      // Angka "1" muncul dua kali (lewat jadwal dan 30 hari): gagal lalu awas.
      expect(angka('1', 0), w.gagal);
      expect(angka('1', 1), w.awas);
      expect(angka('2', 0), s.onSurface);
      expect(angka('0', 0), s.onSurfaceVariant);
      // Batang: gagal, awas, garis tegas (netral), dan abu halus untuk zona nol.
      expect(_batang(PetaJatuhTempo, w.gagal), findsOneWidget);
      expect(_batang(PetaJatuhTempo, w.awas), findsOneWidget);
      expect(_batang(PetaJatuhTempo, s.outline), findsOneWidget);
      expect(_batang(PetaJatuhTempo, s.outlineVariant), findsOneWidget);
      for (final f in [
        _batang(PetaJatuhTempo, w.gagal),
        _batang(PetaJatuhTempo, s.outlineVariant),
      ]) {
        expect(tester.getSize(f).height, UkuranTik.tinggi);
        final d = tester.widget<DecoratedBox>(f).decoration as BoxDecoration;
        expect(d.borderRadius, Bentuk.sudutKecil);
      }
    });

    testWidgets('zona berjumlah nol tidak pernah berwarna status', (
      tester,
    ) async {
      final w = TemaSidik.terang.extension<WarnaSidik>()!;
      await tester.pumpWidget(
        aplikasiUji(
          const PetaJatuhTempo(
            zona: [
              ZonaTempo(
                label: 'Lewat jadwal',
                jumlah: 0,
                nada: NadaStatus.gagal,
              ),
              ZonaTempo(
                label: 'Dalam 30 hari',
                jumlah: 0,
                nada: NadaStatus.awas,
              ),
            ],
          ),
        ),
      );
      expect(_batang(PetaJatuhTempo, w.gagal), findsNothing);
      expect(_batang(PetaJatuhTempo, w.awas), findsNothing);
      for (final t in tester.widgetList<Text>(find.text('0'))) {
        expect(t.style!.color, TemaSidik.terang.colorScheme.onSurfaceVariant);
      }
    });

    for (final (nama, lebar, skala, kolom) in [
      ('HP 392', 392.0, 1.0, 4),
      ('HP 360', 360.0, 1.0, 4),
      ('tablet 840', 840.0, 1.0, 4),
      ('HP 339 (kompak)', 339.0, 1.0, 2),
      ('320 dp x huruf 1,3 (kompak)', 320.0, 1.3, 2),
      ('HP 392 x huruf 1,3 (kompak)', 392.0, 1.3, 2),
    ]) {
      testWidgets('$nama: $kolom kolom, label tidak patah di tengah kata', (
        tester,
      ) async {
        layarHp(tester, lebar: lebar, tinggi: lebar > 600 ? 1200 : 900);
        await tester.pumpWidget(
          aplikasiUji(const PetaJatuhTempo(zona: zona), skala: skala),
        );
        expect(tester.takeException(), isNull);
        // Jumlah kolom = jumlah zona yang sebaris dengan zona pertama.
        final atas = tester.getRect(find.text(zona.first.label)).top;
        final sebaris = [
          for (final z in zona)
            if ((tester.getRect(find.text(z.label)).top - atas).abs() < 1) z,
        ];
        expect(sebaris.length, kolom, reason: 'kolom di $nama');
        // Label hanya putus di spasi, tidak pernah di tengah kata.
        for (final z in zona) {
          final p = tester.renderObject<RenderParagraph>(find.text(z.label));
          final baris = barisTeks(p);
          expect(baris.join(), z.label, reason: z.label);
          for (final b in baris.take(baris.length - 1)) {
            expect(
              b.endsWith(' '),
              isTrue,
              reason: 'patah di tengah kata: $baris',
            );
          }
        }
      });
    }

    testWidgets('zona bisa diketuk: indeks diteruskan, label baca, tombol', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      final diketuk = <int>[];
      await tester.pumpWidget(
        aplikasiUji(PetaJatuhTempo(zona: zona, onZona: diketuk.add)),
      );
      await tester.tap(find.text('Dalam 30 hari'));
      await tester.tap(find.text('Lewat jadwal'));
      await tester.tap(find.text('61 sampai 90 hari'));
      expect(diketuk, [1, 0, 3]);
      expect(find.bySemanticsLabel('Lewat jadwal: 1 alat'), findsOneWidget);
      expect(
        find.bySemanticsLabel('61 sampai 90 hari: 0 alat'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Lewat jadwal: 1 alat')),
        matchesSemantics(
          label: 'Lewat jadwal: 1 alat',
          isButton: true,
          hasTapAction: true,
        ),
      );
      tester.semantics.tap(find.semantics.byLabel('Dalam 30 hari: 1 alat'));
      expect(diketuk, [1, 0, 3, 1], reason: 'aksi ketuk lewat pembaca layar');
      // Tanpa onZona: bukan tombol.
      await tester.pumpWidget(aplikasiUji(const PetaJatuhTempo(zona: zona)));
      await tester.tap(find.text('Lewat jadwal'));
      expect(diketuk.length, 4);
      semantik.dispose();
    });

    for (final (nama, lebar, skala) in [
      ('HP 392', 392.0, 1.0),
      ('320 dp x huruf 1,3', 320.0, 1.3),
      ('tablet', 840.0, 1.0),
    ]) {
      for (final gelap in [false, true]) {
        testWidgets('$nama: sasaran >= 48 dp, pedoman sentuh+label, tanpa '
            'luapan (${gelap ? 'gelap' : 'terang'})', (tester) async {
          layarHp(tester, lebar: lebar, tinggi: lebar > 600 ? 1200 : 640);
          final semantik = tester.ensureSemantics();
          await tester.pumpWidget(
            aplikasiUji(
              PetaJatuhTempo(
                zona: const [
                  ZonaTempo(
                    label: 'Lewat jadwal',
                    jumlah: 128,
                    nada: NadaStatus.gagal,
                  ),
                  ZonaTempo(
                    label: 'Dalam 30 hari',
                    jumlah: 7,
                    nada: NadaStatus.awas,
                  ),
                  ZonaTempo(label: '31 sampai 60 hari', jumlah: 12),
                  ZonaTempo(label: '61 sampai 90 hari', jumlah: 0),
                ],
                onZona: (_) {},
              ),
              gelap: gelap,
              skala: skala,
            ),
          );
          expect(tester.takeException(), isNull);
          for (final kotak
              in find
                  .descendant(
                    of: find.byType(PetaJatuhTempo),
                    matching: find.byType(InkWell),
                  )
                  .evaluate()) {
            final ukuran = tester.getSize(find.byWidget(kotak.widget));
            expect(ukuran.height, greaterThanOrEqualTo(48));
            expect(ukuran.width, greaterThanOrEqualTo(48));
          }
          await periksaPedomanSentuh(tester);
          semantik.dispose();
        });
      }
    }

    for (final gelap in [false, true]) {
      testWidgets(
        'kontras angka dan label >= 4,5 (${gelap ? 'gelap' : 'terang'})',
        (tester) async {
          await tester.pumpWidget(
            aplikasiUji(const PetaJatuhTempo(zona: zona), gelap: gelap),
          );
          expect(
            pelanggaranKontrasTeks(tester, find.byType(PetaJatuhTempo)),
            isEmpty,
          );
        },
      );
    }

    testWidgets('tanpa zona: tidak menggambar apa pun', (tester) async {
      await tester.pumpWidget(aplikasiUji(const PetaJatuhTempo(zona: [])));
      expect(find.byType(DecoratedBox), findsNothing);
    });
  });
}
