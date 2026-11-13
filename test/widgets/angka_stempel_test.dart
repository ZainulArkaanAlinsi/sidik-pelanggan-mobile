// AngkaHari, AngkaKata, dan Stempel: semua keadaan (normal, kosong, panjang),
// terang dan gelap, 320 dp x huruf 1,3, kontras dari pohon widget, dan status
// selalu ikon + kata (tidak pernah warna saja).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/models/status_berlaku.dart';
import 'package:sidik_pelanggan/widgets/angka_hari.dart';
import 'package:sidik_pelanggan/widgets/panel_sidik.dart';
import 'package:sidik_pelanggan/widgets/pemetaan_status.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';
import 'package:sidik_pelanggan/widgets/stempel.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/layar_uji.dart';
import '../dukungan/ukur_komponen.dart';

ThemeData _tema(bool gelap) => gelap ? TemaSidik.gelap : TemaSidik.terang;

/// Panel putih seperti di layar sungguhan: latar teks = permukaan panel.
Widget _dalamPanel(Widget anak) => PanelSidik(
  anak: [Padding(padding: const EdgeInsets.all(16), child: anak)],
);

Color _warnaTeks(WidgetTester tester, String teks) =>
    tester.widget<Text>(find.text(teks)).style!.color!;

void main() {
  setUpAll(siapkanTesFitur);

  group('AngkaHari: nada menurut sisa hari', () {
    test('batas: lewat = gagal, 0 sampai 30 = awas, sisanya tinta', () {
      expect(AngkaHari.nadaDari(-1), NadaStatus.gagal);
      expect(AngkaHari.nadaDari(-365), NadaStatus.gagal);
      expect(AngkaHari.nadaDari(0), NadaStatus.awas);
      expect(AngkaHari.nadaDari(30), NadaStatus.awas);
      expect(AngkaHari.nadaDari(31), isNull);
      expect(AngkaHari.nadaDari(200), isNull);
      expect(AngkaHari.nadaDari(null), isNull);
      expect(AngkaHari.batasAwas, 30);
    });

    test('angka dan kata: satu aturan untuk semua keadaan', () {
      expect(AngkaHari.angkaDari(-4), '4');
      expect(AngkaHari.angkaDari(12), '12');
      expect(AngkaHari.angkaDari(0), '0');
      expect(AngkaHari.angkaDari(null), '–');
      expect(AngkaHari.kataDari(-4), 'hari lewat');
      expect(AngkaHari.kataDari(0), 'hari ini');
      expect(AngkaHari.kataDari(12), 'hari lagi');
      expect(AngkaHari.kataDari(null), 'belum ada jadwal');
      expect(AngkaHari.kataDari(-4, panjang: true), 'hari lewat dari jadwal');
    });

    for (final gelap in [false, true]) {
      testWidgets('warna tiap pita (${gelap ? 'gelap' : 'terang'})', (
        tester,
      ) async {
        final s = _tema(gelap).colorScheme;
        final w = _tema(gelap).extension<WarnaSidik>()!;
        Future<Color> warna(int? hari, String angka) async {
          await tester.pumpWidget(aplikasiUji(AngkaHari(hari), gelap: gelap));
          return _warnaTeks(tester, angka);
        }

        expect(await warna(-4, '4'), w.gagal);
        expect(await warna(0, '0'), w.awas);
        expect(await warna(12, '12'), w.awas);
        expect(await warna(30, '30'), w.awas);
        expect(await warna(31, '31'), s.onSurface);
        expect(await warna(200, '200'), s.onSurface);
        expect(await warna(null, '–'), s.onSurfaceVariant);
      });

      testWidgets('kontras >= 4,5:1 di panel, semua pita dan bentuk '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        for (final hari in [-30, -4, 0, 12, 30, 31, 200, null]) {
          for (final bentuk in ['kolom', 'kompak', 'bintang']) {
            await tester.pumpWidget(
              aplikasiUji(
                _dalamPanel(
                  AngkaHari(
                    hari,
                    kompak: bentuk == 'kompak',
                    bintang: bentuk == 'bintang',
                  ),
                ),
                gelap: gelap,
              ),
            );
            expect(
              pelanggaranKontrasTeks(tester, find.byType(AngkaHari)),
              isEmpty,
              reason: 'hari=$hari bentuk=$bentuk',
            );
          }
        }
      });
    }

    testWidgets('kata selalu menyertai angka (warna bukan satu-satunya arti)', (
      tester,
    ) async {
      for (final (hari, angka, kata) in [
        (-4, '4', 'hari lewat'),
        (0, '0', 'hari ini'),
        (12, '12', 'hari lagi'),
        (90, '90', 'hari lagi'),
        (null, '–', 'belum ada jadwal'),
      ]) {
        await tester.pumpWidget(aplikasiUji(AngkaHari(hari)));
        expect(find.text(angka), findsOneWidget, reason: '$hari');
        expect(find.text(kata), findsOneWidget, reason: '$hari');
      }
    });

    testWidgets('label pembaca layar memakai kalimat Format.sisaHari', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      for (final (hari, kalimat) in [
        (-4, 'Lewat 4 hari'),
        (0, 'Kalibrasi ulang hari ini'),
        (12, '12 hari lagi'),
        (null, 'Belum ada jadwal kalibrasi ulang'),
      ]) {
        await tester.pumpWidget(aplikasiUji(AngkaHari(hari)));
        expect(find.bySemanticsLabel(kalimat), findsOneWidget, reason: '$hari');
      }
      semantik.dispose();
    });

    testWidgets('angka 28 sp ke atas dijepit 1,15x terhadap huruf sistem', (
      tester,
    ) async {
      await tester.pumpWidget(aplikasiUji(const AngkaHari(12), skala: 1.3));
      final p = tester.renderObject<RenderParagraph>(find.text('12'));
      expect(p.textScaler.scale(28), closeTo(28 * 1.15, 0.01));

      await tester.pumpWidget(
        aplikasiUji(const AngkaHari(12, bintang: true), skala: 1.3),
      );
      final b = tester.renderObject<RenderParagraph>(find.text('12'));
      expect(b.textScaler.scale(44), closeTo(44 * 1.15, 0.01));

      // Huruf lebih kecil dari batas tidak ikut dibesarkan.
      await tester.pumpWidget(aplikasiUji(const AngkaHari(12), skala: 0.9));
      final k = tester.renderObject<RenderParagraph>(find.text('12'));
      expect(k.textScaler.scale(28), closeTo(28 * 0.9, 0.01));
    });

    testWidgets('angka tiga digit tetap satu baris di kolom 56 dp', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        aplikasiUji(
          const SizedBox(width: 56, child: AngkaHari(128)),
          skala: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      final p = tester.renderObject<RenderParagraph>(find.text('128'));
      expect(barisTeks(p), ['128']);
      // Pas di kolom, mungkin diperkecil oleh FittedBox, tidak meluap.
      expect(
        tester.getSize(find.byType(AngkaHari)).width,
        lessThanOrEqualTo(56),
      );
    });

    for (final gelap in [false, true]) {
      testWidgets('320 dp x huruf 1,3 tanpa luapan, semua bentuk '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 320, tinggi: 640);
        await tester.pumpWidget(
          aplikasiUji(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final hari in [-4, 12, 200, null]) ...[
                  AngkaHari(hari),
                  AngkaHari(hari, kompak: true),
                  AngkaHari(hari, bintang: true),
                ],
              ],
            ),
            gelap: gelap,
            skala: 1.3,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('bukan sasaran sentuh: tanpa aksi ketuk', (tester) async {
      await tester.pumpWidget(aplikasiUji(const AngkaHari(12)));
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });
  });

  group('AngkaKata', () {
    testWidgets('angka + kata, nada mewarnai, tanpa nada = tinta', (
      tester,
    ) async {
      final s = TemaSidik.terang.colorScheme;
      final w = TemaSidik.terang.extension<WarnaSidik>()!;
      for (final (nada, warna) in [
        (NadaStatus.gagal, w.gagal),
        (NadaStatus.awas, w.awas),
        (NadaStatus.lulus, w.lulus),
        (null, s.onSurface),
        (NadaStatus.netral, s.onSurface),
      ]) {
        await tester.pumpWidget(
          aplikasiUji(AngkaKata('2', 'alat', nada: nada)),
        );
        expect(find.text('2'), findsOneWidget);
        expect(find.text('alat'), findsOneWidget);
        expect(_warnaTeks(tester, '2'), warna, reason: '$nada');
      }
    });

    testWidgets('label pembaca layar bawaan dan khusus', (tester) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(aplikasiUji(const AngkaKata('2', 'alat')));
      expect(find.bySemanticsLabel('2 alat'), findsOneWidget);
      await tester.pumpWidget(
        aplikasiUji(
          const AngkaKata('2', 'alat', semantik: '2 paket siap diambil'),
        ),
      );
      expect(find.bySemanticsLabel('2 paket siap diambil'), findsOneWidget);
      semantik.dispose();
    });

    for (final gelap in [false, true]) {
      testWidgets('kontras dan 320 dp x 1,3 (${gelap ? 'gelap' : 'terang'})', (
        tester,
      ) async {
        layarHp(tester, lebar: 320, tinggi: 640);
        for (final nada in [
          NadaStatus.gagal,
          NadaStatus.awas,
          NadaStatus.lulus,
          null,
        ]) {
          for (final kompak in [false, true]) {
            await tester.pumpWidget(
              aplikasiUji(
                _dalamPanel(AngkaKata('2', 'alat', nada: nada, kompak: kompak)),
                gelap: gelap,
                skala: 1.3,
              ),
            );
            expect(tester.takeException(), isNull);
            expect(
              pelanggaranKontrasTeks(tester, find.byType(AngkaKata)),
              isEmpty,
              reason: '$nada kompak=$kompak',
            );
          }
        }
      });
    }
  });

  group('Stempel: persegi sudut 4, ikon + kata', () {
    final semua = <StatusTampil>[
      for (final s in StatusBerlaku.values) statusBerlaku(s),
      statusKeputusan('PASS')!,
      statusKeputusan('FAIL')!,
      for (final kode in [
        'diterima',
        'dikalibrasi',
        'perlu_diulang',
        'menunggu_pemeriksaan',
        'sertifikat_terbit',
        'siap_diambil',
        'diserahkan',
        'kode_tak_dikenal',
      ])
        statusPaket(kode, 'Tahap $kode'),
    ];

    for (final gelap in [false, true]) {
      testWidgets(
        'semua status: ikon + kata + label baca, kontras teks 4,5 dan ikon 3 '
        '(${gelap ? 'gelap' : 'terang'})',
        (tester) async {
          final semantik = tester.ensureSemantics();
          for (final status in semua) {
            for (final tenang in [false, true]) {
              await tester.pumpWidget(
                aplikasiUji(Stempel(status, tenang: tenang), gelap: gelap),
              );
              final ket = '${status.label} tenang=$tenang';
              expect(find.text(status.label), findsOneWidget, reason: ket);
              expect(find.byIcon(status.ikon), findsOneWidget, reason: ket);
              expect(
                find.bySemanticsLabel('Status: ${status.label}'),
                findsOneWidget,
                reason: ket,
              );
              expect(
                pelanggaranKontrasTeks(tester, find.byType(Stempel)),
                isEmpty,
                reason: ket,
              );
              final ikon = tester.widget<Icon>(find.byIcon(status.ikon));
              final elemen = tester.element(find.byIcon(status.ikon));
              expect(
                rasioKontras(ikon.color!, latarEfektif(elemen)),
                greaterThanOrEqualTo(3),
                reason: 'ikon $ket',
              );
            }
          }
          semantik.dispose();
        },
      );
    }

    testWidgets(
      'bentuk: sudut 4 (bukan pil), berlatar tipis; tenang tanpa latar',
      (tester) async {
        final status = statusAlat(StatusKalibrasi.lewat);
        await tester.pumpWidget(aplikasiUji(Stempel(status)));
        var kotak = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(Stempel),
            matching: find.byType(DecoratedBox),
          ),
        );
        var dekor = kotak.decoration as BoxDecoration;
        expect(dekor.borderRadius, Bentuk.sudutKecil);
        expect(dekor.borderRadius, isNot(Bentuk.sudutPil));
        expect(
          dekor.color,
          TemaSidik.terang.extension<WarnaSidik>()!.gagalLatar,
        );

        await tester.pumpWidget(aplikasiUji(Stempel(status, tenang: true)));
        kotak = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(Stempel),
            matching: find.byType(DecoratedBox),
          ),
        );
        dekor = kotak.decoration as BoxDecoration;
        expect(dekor.color, isNull);
        // Tanpa latar pun ikon dan kata tetap ada.
        expect(find.text(status.label), findsOneWidget);
        expect(find.byIcon(status.ikon), findsOneWidget);
      },
    );

    testWidgets('istilah: "Lewat jadwal", bukan kedaluwarsa', (tester) async {
      for (final s in semua) {
        final l = s.label.toLowerCase();
        expect(l, isNot(contains('daluwarsa')), reason: s.label);
        expect(l, isNot(contains('adaluarsa')), reason: s.label);
      }
      await tester.pumpWidget(
        aplikasiUji(Stempel(statusAlat(StatusKalibrasi.lewat))),
      );
      expect(find.text('Lewat jadwal'), findsOneWidget);
    });

    for (final gelap in [false, true]) {
      testWidgets('kata panjang membungkus di 320 dp x 1,3, tidak meluap '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 320, tinggi: 640);
        await tester.pumpWidget(
          aplikasiUji(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stempel(statusKeputusan('FAIL')!),
                Stempel(statusBerlaku(StatusBerlaku.berakhir)),
                Stempel(
                  const StatusTampil(
                    'Sertifikat ini telah digantikan oleh revisi yang lebih '
                    'baru dan tidak lagi berlaku untuk alat tersebut',
                    NadaStatus.awas,
                    Icons.swap_horiz,
                  ),
                ),
              ],
            ),
            gelap: gelap,
            skala: 1.3,
          ),
        );
        expect(tester.takeException(), isNull);
        final lebar = tester.getSize(find.byType(Stempel).last).width;
        expect(lebar, lessThanOrEqualTo(320 - 40));
      });
    }

    testWidgets('bukan tombol: tanpa aksi ketuk', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(Stempel(statusAlat(StatusKalibrasi.lewat))),
      );
      expect(find.byType(InkWell), findsNothing);
    });
  });
}
