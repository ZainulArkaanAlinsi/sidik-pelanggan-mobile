// KalimatUtama, PlatNama, dan Fakta: kalimat besar dengan frasa status
// berwarna (kata, bukan warna saja), plat nama nomor seri, dan label-nilai yang
// MEMBUNGKUS di 320 dp (pengganti BarisInfo yang menumpuk di bawah 300 dp).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';
import 'package:sidik_pelanggan/widgets/fakta.dart';
import 'package:sidik_pelanggan/widgets/kalimat_utama.dart';
import 'package:sidik_pelanggan/widgets/panel_sidik.dart';
import 'package:sidik_pelanggan/widgets/plat_nama.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/fixture_komponen.dart';
import '../dukungan/layar_uji.dart';
import '../dukungan/ukur_komponen.dart';

ThemeData _tema(bool gelap) => gelap ? TemaSidik.gelap : TemaSidik.terang;

const _kalimatPerhatian = KalimatUtama(
  dateline: 'Jumat, 13 November 2026',
  kalimat: [
    [
      PotonganKalimat('1 alat '),
      PotonganKalimat('lewat jadwal', nada: NadaStatus.gagal),
      PotonganKalimat('.'),
    ],
    [
      PotonganKalimat('1 paket '),
      PotonganKalimat('siap diambil', nada: NadaStatus.lulus),
      PotonganKalimat('.'),
    ],
  ],
);

void main() {
  setUpAll(siapkanTesFitur);

  group('KalimatUtama', () {
    testWidgets('dateline kecil, kalimat besar, frasa status berwarna nada', (
      tester,
    ) async {
      final s = TemaSidik.terang.colorScheme;
      final w = TemaSidik.terang.extension<WarnaSidik>()!;
      await tester.pumpWidget(aplikasiUji(_kalimatPerhatian));
      expect(find.text('Jumat, 13 November 2026'), findsOneWidget);
      final potongan = {
        for (final x in ukurTeks(tester, find.byType(KalimatUtama))) x.teks: x,
      };
      expect(potongan['lewat jadwal']!.warna, w.gagal);
      expect(potongan['siap diambil']!.warna, w.lulus);
      expect(potongan['1 alat ']!.warna, s.onSurface);
      expect(potongan['.']!.warna, s.onSurface);
      // Kalimat 32 sp (kalimat utama), dateline 14 sp (keterangan).
      expect(potongan['lewat jadwal']!.ukuran, 32);
      expect(potongan['Jumat, 13 November 2026']!.ukuran, 14);
    });

    testWidgets('nada awas berwarna awas; netral dan tunggu tetap tinta', (
      tester,
    ) async {
      final s = TemaSidik.terang.colorScheme;
      final w = TemaSidik.terang.extension<WarnaSidik>()!;
      await tester.pumpWidget(
        aplikasiUji(
          const KalimatUtama(
            dateline: 'x',
            kalimat: [
              [
                PotonganKalimat('segera', nada: NadaStatus.awas),
                PotonganKalimat(' diproses', nada: NadaStatus.tunggu),
                PotonganKalimat(' netral', nada: NadaStatus.netral),
              ],
            ],
          ),
        ),
      );
      final p = {
        for (final x in ukurTeks(tester, find.byType(KalimatUtama))) x.teks: x,
      };
      expect(p['segera']!.warna, w.awas);
      expect(p[' diproses']!.warna, s.onSurface);
      expect(p[' netral']!.warna, s.onSurface);
    });

    testWidgets('paling banyak dua kalimat yang digambar', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(
          const KalimatUtama(
            dateline: 'x',
            kalimat: [
              [PotonganKalimat('Satu.')],
              [PotonganKalimat('Dua.')],
              [PotonganKalimat('Tiga.')],
            ],
          ),
        ),
      );
      expect(find.text('Satu.', findRichText: true), findsOneWidget);
      expect(find.text('Dua.', findRichText: true), findsOneWidget);
      expect(find.text('Tiga.', findRichText: true), findsNothing);
      expect(KalimatUtama.maksimumKalimat, 2);
    });

    testWidgets('keadaan tenang: "Semua alat Anda berlaku."', (tester) async {
      final w = TemaSidik.terang.extension<WarnaSidik>()!;
      await tester.pumpWidget(
        aplikasiUji(
          const KalimatUtama.tenang(dateline: 'Jumat, 13 November 2026'),
        ),
      );
      expect(
        find.text('Semua alat Anda berlaku.', findRichText: true),
        findsOneWidget,
      );
      final berlaku = ukurTeks(
        tester,
        find.byType(KalimatUtama),
      ).firstWhere((x) => x.teks == 'berlaku');
      expect(berlaku.warna, w.lulus);
    });

    test('frasa berwarna harus kata: angka atau tanda saja ditolak', () {
      expect(
        const PotonganKalimat(
          'lewat jadwal',
          nada: NadaStatus.gagal,
        ).warnaBerkata,
        isTrue,
      );
      expect(
        const PotonganKalimat('3 alat', nada: NadaStatus.gagal).warnaBerkata,
        isTrue,
      );
      expect(
        const PotonganKalimat('3', nada: NadaStatus.gagal).warnaBerkata,
        isFalse,
      );
      expect(
        const PotonganKalimat('!', nada: NadaStatus.awas).warnaBerkata,
        isFalse,
      );
      expect(const PotonganKalimat('3').warnaBerkata, isTrue);
    });

    testWidgets('warna tanpa kata ditolak saat dibangun (assert)', (
      tester,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(
          const KalimatUtama(
            dateline: 'x',
            kalimat: [
              [PotonganKalimat('3', nada: NadaStatus.gagal)],
            ],
          ),
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('setiap frasa berwarna yang tampil memuat huruf (kata)', (
      tester,
    ) async {
      final s = TemaSidik.terang.colorScheme;
      await tester.pumpWidget(aplikasiUji(_kalimatPerhatian));
      for (final x in ukurTeks(tester, find.byType(KalimatUtama))) {
        if (x.warna != s.onSurface && x.warna != s.onSurfaceVariant) {
          expect(
            RegExp(r'\p{L}', unicode: true).hasMatch(x.teks),
            isTrue,
            reason: '"${x.teks}" berwarna tanpa kata',
          );
        }
      }
    });

    testWidgets('huruf sistem dijepit 1,15x pada kalimat dan dateline', (
      tester,
    ) async {
      await tester.pumpWidget(aplikasiUji(_kalimatPerhatian, skala: 1.3));
      final kalimat = tester.renderObject<RenderParagraph>(
        find.text('1 alat lewat jadwal.', findRichText: true),
      );
      expect(kalimat.textScaler.scale(32), closeTo(32 * 1.15, 0.01));
      final dateline = tester.renderObject<RenderParagraph>(
        find.text('Jumat, 13 November 2026'),
      );
      expect(dateline.textScaler.scale(14), closeTo(14 * 1.15, 0.01));
    });

    for (final gelap in [false, true]) {
      testWidgets('kontras frasa status dan teks >= 4,5 di latar layar '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        await tester.pumpWidget(
          aplikasiUji(
            const Column(
              children: [
                _kalimatPerhatian,
                KalimatUtama(
                  dateline: 'x',
                  kalimat: [
                    [
                      PotonganKalimat('2 alat '),
                      PotonganKalimat(
                        'segera jatuh tempo',
                        nada: NadaStatus.awas,
                      ),
                      PotonganKalimat('.'),
                    ],
                  ],
                ),
                KalimatUtama.tenang(dateline: 'x'),
              ],
            ),
            gelap: gelap,
          ),
        );
        expect(
          pelanggaranKontrasTeks(tester, find.byType(Column).first),
          isEmpty,
        );
      });

      testWidgets('320 dp x huruf 1,3: tanpa luapan, paling banyak 8 baris '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 320, tinggi: 640);
        await tester.pumpWidget(
          aplikasiUji(_kalimatPerhatian, gelap: gelap, skala: 1.3),
        );
        expect(tester.takeException(), isNull);
        var baris = 0;
        for (final rt
            in find
                .descendant(
                  of: find.byType(KalimatUtama),
                  matching: find.byType(RichText),
                )
                .evaluate()) {
          baris += barisTeks(
            tester.renderObject<RenderParagraph>(find.byWidget(rt.widget)),
          ).length;
        }
        // Dateline + dua kalimat 32 sp yang dijepit: tidak membengkak jadi
        // belasan baris seperti 32 sp x 1,3 = 42 sp.
        expect(baris, lessThanOrEqualTo(8));
      });
    }

    testWidgets('tablet tanpa luapan', (tester) async {
      layarTablet(tester);
      await tester.pumpWidget(aplikasiUji(_kalimatPerhatian));
      expect(tester.takeException(), isNull);
    });
  });

  group('PlatNama', () {
    const fakta = <(String, String?)>[
      ('No. identifikasi', 'AST-0457'),
      ('Rentang ukur', '0–150 mm'),
      ('Catatan', null),
      ('Kalibrasi terakhir', '   '),
      ('Lokasi', 'Lab Mutu'),
    ];

    testWidgets(
      'nomor seri sebagai identitas: 22 sp, selebar tetap, nol bergaris',
      (tester) async {
        await tester.pumpWidget(
          aplikasiUji(const PlatNama(seri: '2201-0457', fakta: fakta)),
        );
        expect(find.text('No. seri'), findsOneWidget);
        final seri = tester.widget<Text>(find.text('2201-0457')).style!;
        expect(seri.fontSize, 22);
        expect(seri.fontFeatures, contains(const FontFeature.slashedZero()));
        expect(seri.fontFeatures, contains(const FontFeature.tabularFigures()));
      },
    );

    testWidgets('hanya fakta yang terisi; tanpa baris "—"', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(const PlatNama(seri: '2201-0457', fakta: fakta)),
      );
      for (final t in [
        'No. identifikasi',
        'AST-0457',
        'Rentang ukur',
        '0–150 mm',
        'Lokasi',
        'Lab Mutu',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.text('Catatan'), findsNothing);
      expect(find.text('Kalibrasi terakhir'), findsNothing);
      expect(semuaTeks(tester, find.byType(PlatNama)), isNot(contains('—')));
    });

    testWidgets('tanpa fakta: tanpa pemisah; tanpa seri: "Belum tercatat"', (
      tester,
    ) async {
      await tester.pumpWidget(aplikasiUji(const PlatNama(seri: '2201-0457')));
      expect(find.byType(Divider), findsNothing);
      await tester.pumpWidget(
        aplikasiUji(const PlatNama(seri: '2201-0457', fakta: fakta)),
      );
      expect(find.byType(Divider), findsOneWidget);

      for (final kosong in [null, '', '   ']) {
        await tester.pumpWidget(aplikasiUji(PlatNama(seri: kosong)));
        expect(find.text('Belum tercatat'), findsOneWidget, reason: '$kosong');
        expect(find.text('No. seri'), findsOneWidget);
      }
    });

    testWidgets('bingkai: persegi sudut 4, garis tegas, selebar halaman', (
      tester,
    ) async {
      layarHp(tester, lebar: 360, tinggi: 640);
      final s = TemaSidik.terang.colorScheme;
      await tester.pumpWidget(aplikasiUji(const PlatNama(seri: '2201-0457')));
      final kotak = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(PlatNama),
          matching: find.byType(DecoratedBox),
        ),
      );
      final d = kotak.decoration as BoxDecoration;
      expect(d.borderRadius, Bentuk.sudutKecil);
      expect(d.color, s.surface);
      expect((d.border! as Border).top.color, s.outline);
      expect(tester.getSize(find.byType(PlatNama)).width, 360 - 40);
    });

    testWidgets('label baca: satu kalimat berisi semua fakta yang terisi', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(
        aplikasiUji(const PlatNama(seri: '2201-0457', fakta: fakta)),
      );
      expect(
        find.bySemanticsLabel(
          'Plat nama alat. No. seri 2201-0457. No. identifikasi AST-0457. '
          'Rentang ukur 0–150 mm. Lokasi Lab Mutu',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(aplikasiUji(const PlatNama(seri: null)));
      expect(
        find.bySemanticsLabel('Plat nama alat. No. seri belum tercatat'),
        findsOneWidget,
      );
      semantik.dispose();
    });

    for (final gelap in [false, true]) {
      testWidgets(
        'kontras: teks 4,5; garis tegas 3 (${gelap ? 'gelap' : 'terang'})',
        (tester) async {
          final s = _tema(gelap).colorScheme;
          await tester.pumpWidget(
            aplikasiUji(
              const Column(
                children: [
                  PlatNama(seri: '2201-0457', fakta: fakta),
                  PlatNama(seri: null),
                ],
              ),
              gelap: gelap,
            ),
          );
          expect(
            pelanggaranKontrasTeks(tester, find.byType(Column).first),
            isEmpty,
          );
          expect(rasioKontras(s.outline, s.surface), greaterThanOrEqualTo(3));
          expect(
            rasioKontras(s.outline, _tema(gelap).scaffoldBackgroundColor),
            greaterThanOrEqualTo(3),
          );
        },
      );

      testWidgets('320 dp x huruf 1,3: seri panjang dan fakta panjang tanpa '
          'luapan (${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 320, tinggi: 800);
        await tester.pumpWidget(
          aplikasiUji(
            const PlatNama(
              seri: nomorOrderPanjang,
              fakta: [
                ('No. identifikasi', 'AST-0457-REVISI-DUA'),
                ('Rentang ukur', '0–150 mm dengan resolusi 0,01 mm'),
                ('Lokasi', 'Laboratorium Mutu Lantai Dua Gedung Timur'),
              ],
            ),
            gelap: gelap,
            skala: 1.3,
          ),
        );
        expect(tester.takeException(), isNull);
        final seri = tester.renderObject<RenderParagraph>(
          find.text(nomorOrderPanjang),
        );
        // Tidak pernah putus di tengah angka: hanya setelah "/".
        final baris = barisTeks(seri);
        expect(baris.join(), nomorOrderPanjang);
        for (final b in baris.take(baris.length - 1)) {
          expect(b.endsWith('/'), isTrue, reason: b);
        }
      });
    }

    testWidgets('tablet tanpa luapan', (tester) async {
      layarTablet(tester);
      await tester.pumpWidget(
        aplikasiUji(const PlatNama(seri: '2201-0457', fakta: fakta)),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Fakta', () {
    testWidgets('label dan nilai satu paragraf (mengalir, bukan ditumpuk)', (
      tester,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(const Fakta('Target selesai', '16 Nov 2026')),
      );
      final kotak = find.descendant(
        of: find.byType(Fakta),
        matching: find.byType(RichText),
      );
      expect(kotak, findsOneWidget);
      expect(
        tester
            .widget<RichText>(kotak)
            .text
            .toPlainText()
            .replaceAll('\u00A0', ' '),
        'Target selesai  16 Nov 2026',
      );
    });

    testWidgets('HP 360 dp (isi kartu 296 dp): label dan nilai SATU baris, '
        'tidak menumpuk seperti BarisInfo', (tester) async {
      layarHp(tester, lebar: 360, tinggi: 640);
      await tester.pumpWidget(
        aplikasiUji(
          const PanelSidik(
            anak: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Fakta('Rentang ukur', '0–150 mm'),
              ),
            ],
          ),
        ),
      );
      final p = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(Fakta),
          matching: find.byType(RichText),
        ),
      );
      expect(
        [for (final b in barisTeks(p)) b.replaceAll('\u00A0', ' ')],
        ['Rentang ukur  0–150 mm'],
      );
    });

    testWidgets('320 dp x huruf 1,3: nilai panjang membungkus, tidak meluap', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        aplikasiUji(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Fakta(
                'Alamat',
                'Jl. Kalibrasi Presisi No. 285, Kawasan Industri Timur, Jakarta 13920',
              ),
              Fakta('Target selesai', '16 Nov 2026'),
            ],
          ),
          skala: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      final p = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(Fakta).first,
          matching: find.byType(RichText),
        ),
      );
      expect(barisTeks(p).length, greaterThan(1));
    });

    testWidgets('nilai kosong: tidak digambar; dengan "kosong": teks redup', (
      tester,
    ) async {
      final s = TemaSidik.terang.colorScheme;
      for (final nilai in [null, '', '   ']) {
        await tester.pumpWidget(aplikasiUji(Fakta('Catatan', nilai)));
        expect(tester.getSize(find.byType(Fakta)), Size.zero, reason: '$nilai');
        expect(find.text('Catatan', findRichText: true), findsNothing);
      }
      await tester.pumpWidget(
        aplikasiUji(const Fakta('Catatan', null, kosong: 'Belum dicatat')),
      );
      expect(
        find.textContaining('Belum dicatat', findRichText: true),
        findsOneWidget,
      );
      final nilai = ukurTeks(
        tester,
        find.byType(Fakta),
      ).firstWhere((x) => x.teks == 'Belum dicatat');
      expect(nilai.warna, s.onSurfaceVariant);
    });

    testWidgets('nomor: selebar tetap + nol bergaris; tumpuk: label di atas', (
      tester,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(
          const Fakta('Nomor order', nomorOrderUji, nomor: true, tumpuk: true),
        ),
      );
      final judul = tester.getRect(find.text('Nomor order'));
      final nilai = tester.getRect(find.text(nomorOrderUji));
      expect(nilai.top, greaterThanOrEqualTo(judul.bottom));
      final gaya = tester.widget<Text>(find.text(nomorOrderUji)).style!;
      expect(gaya.fontFeatures, contains(const FontFeature.slashedZero()));
    });

    testWidgets('tumpuk + nomor panjang di 320 x 1,3: tidak putus di tengah', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        aplikasiUji(
          const Fakta(
            'Nomor order',
            nomorOrderPanjang,
            nomor: true,
            tumpuk: true,
          ),
          skala: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      final baris = barisTeks(
        tester.renderObject<RenderParagraph>(find.text(nomorOrderPanjang)),
      );
      expect(baris.join(), nomorOrderPanjang);
      for (final b in baris.take(baris.length - 1)) {
        expect(b.endsWith('/'), isTrue, reason: b);
      }
    });

    testWidgets('nomor pendek sebaris dengan label; nomor panjang dapat baris '
        'sendiri, satu baris, tidak putus (320 dp x huruf 1,3)', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      Future<void> pompa(String seri) => tester.pumpWidget(
        aplikasiUji(Fakta('No. seri', seri, nomor: true), skala: 1.3),
      );

      await pompa('2201-0457');
      expect(tester.takeException(), isNull);
      var label = tester.getRect(find.text('No. seri'));
      var nomor = tester.getRect(find.text('2201-0457'));
      expect(nomor.left, greaterThanOrEqualTo(label.right));
      expect((nomor.center.dy - label.center.dy).abs(), lessThan(12));

      const panjang = 'SN-0000-1111-2222-3333-4444-5555';
      await pompa(panjang);
      expect(tester.takeException(), isNull);
      label = tester.getRect(find.text('No. seri'));
      nomor = tester.getRect(find.text(panjang));
      expect(
        nomor.top,
        greaterThanOrEqualTo(label.bottom),
        reason: 'baris sendiri',
      );
      final p = tester.renderObject<RenderParagraph>(find.text(panjang));
      expect(barisTeks(p), [panjang]);
      expect(
        tester.getRect(find.byType(FittedBox)).right,
        lessThanOrEqualTo(320 - 20 + 0.5),
      );
    });

    testWidgets('nomor sedang: tetap sebaris dengan label tetapi mengecil, '
        'tidak keluar dari lebar (320 dp x huruf 1,3)', (tester) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      const sedang = 'SN-0000-1111-2222-3333';
      await tester.pumpWidget(
        aplikasiUji(const Fakta('No. seri', sedang, nomor: true), skala: 1.3),
      );
      expect(tester.takeException(), isNull);
      final label = tester.getRect(find.text('No. seri'));
      final nomor = tester.getRect(find.byType(FittedBox));
      expect(nomor.left, greaterThanOrEqualTo(label.right));
      expect(nomor.right, lessThanOrEqualTo(320 - 20 + 0.5));
      final p = tester.renderObject<RenderParagraph>(find.text(sedang));
      expect(barisTeks(p), [sedang]);
    });

    testWidgets('nilai pendek tidak dipatahkan di tengah: pindah utuh', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      // Lebar sempit memaksa membungkus: "Target selesai" lalu tanggal.
      await tester.pumpWidget(
        aplikasiUji(
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 190,
              child: Fakta('Target selesai', '16 Nov 2026'),
            ),
          ),
          skala: 1.3,
          bergulir: false,
        ),
      );
      final p = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(Fakta),
          matching: find.byType(RichText),
        ),
      );
      final baris = [
        for (final b in barisTeks(p)) b.replaceAll('\u00A0', ' ').trim(),
      ];
      expect(
        baris.any((b) => b == '2026' || b == 'Nov 2026'),
        isFalse,
        reason: '$baris',
      );
      expect(baris.length, greaterThan(1), reason: 'harus membungkus: $baris');
      expect(baris.join(' '), contains('16 Nov 2026'));
    });

    testWidgets('label baca: "label: nilai"', (tester) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(
        aplikasiUji(const Fakta('Target selesai', '16 Nov 2026')),
      );
      expect(
        find.bySemanticsLabel('Target selesai: 16 Nov 2026'),
        findsOneWidget,
      );
      semantik.dispose();
    });

    for (final gelap in [false, true]) {
      testWidgets('kontras label dan nilai >= 4,5 di latar layar dan panel '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        await tester.pumpWidget(
          aplikasiUji(
            const Column(
              children: [
                Fakta('Target selesai', '16 Nov 2026'),
                Fakta('Catatan', null, kosong: 'Belum dicatat'),
                PanelSidik(
                  anak: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Fakta('No. seri', '2201-0457', nomor: true),
                    ),
                  ],
                ),
              ],
            ),
            gelap: gelap,
          ),
        );
        expect(
          pelanggaranKontrasTeks(tester, find.byType(Column).first),
          isEmpty,
        );
      });
    }
  });
}
