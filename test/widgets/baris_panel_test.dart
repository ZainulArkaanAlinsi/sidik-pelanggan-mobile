// PanelSidik, BarisSidik, NomorSidik, BarisAlat, dan RingkasanPerhatian: satu
// butir = satu baris di dalam satu panel; angka sisa hari memimpin; identitas
// alat (nama, merk, nomor seri) tiap fakta di barisnya; nomor tidak putus di
// tengah. Terang/gelap, 320 dp x huruf 1,3, tablet, sasaran sentuh >= 48 dp.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';
import 'package:sidik_pelanggan/widgets/angka_hari.dart';
import 'package:sidik_pelanggan/widgets/baris_alat.dart';
import 'package:sidik_pelanggan/widgets/baris_sidik.dart';
import 'package:sidik_pelanggan/widgets/jejak_tahap.dart';
import 'package:sidik_pelanggan/widgets/nomor_sidik.dart';
import 'package:sidik_pelanggan/widgets/panel_sidik.dart';
import 'package:sidik_pelanggan/widgets/ringkasan_perhatian.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/fixture_komponen.dart';
import '../dukungan/layar_uji.dart';
import '../dukungan/ukur_komponen.dart';

/// [anak] selebar [lebar], di sudut kiri atas (tanpa dijepit batas ketat induk).
Widget _longgar(double lebar, Widget anak) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox(width: lebar, child: anak),
);

BarisAlat _alat({
  String nama = 'Jangka Sorong Digital',
  String? merk = 'Mitutoyo',
  String? model = 'CD-15CPX',
  String? serial = '2201-0457',
  int? hari = -4,
  bool diLab = true,
  String kode = 'dikalibrasi',
  String label = 'Sedang dikalibrasi',
  VoidCallback? onTap,
}) => BarisAlat(
  nama: nama,
  merk: merk,
  model: model,
  serial: serial,
  hari: hari,
  garisWaktu: diLab ? garisWaktuUji(sekarang: 1) : null,
  kodeTahap: diLab ? kode : null,
  labelTahap: diLab ? label : null,
  onTap: onTap ?? () {},
);

void main() {
  setUpAll(siapkanTesFitur);

  group('PanelSidik', () {
    testWidgets(
      'satu panel: sudut 16, garis halus, tanpa bayangan, tanpa Card',
      (tester) async {
        final s = TemaSidik.terang.colorScheme;
        await tester.pumpWidget(
          aplikasiUji(
            const PanelSidik(anak: [Text('satu'), Text('dua'), Text('tiga')]),
          ),
        );
        final bahan = tester.widget<Material>(
          find
              .descendant(
                of: find.byType(PanelSidik),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(bahan.color, s.surface);
        expect(bahan.elevation, 0);
        expect(bahan.clipBehavior, Clip.antiAlias);
        final bentuk = bahan.shape! as RoundedRectangleBorder;
        expect(bentuk.borderRadius, Bentuk.sudutKartu);
        expect(bentuk.side.color, s.outlineVariant);
        expect(find.byType(Card), findsNothing);
      },
    );

    testWidgets('pemisah halus hanya di antara butir (n-1)', (tester) async {
      for (final n in [1, 2, 5]) {
        await tester.pumpWidget(
          aplikasiUji(
            PanelSidik(anak: [for (var i = 0; i < n; i++) Text('butir $i')]),
          ),
        );
        expect(find.byType(Divider), findsNWidgets(n - 1), reason: 'n=$n');
      }
    });

    testWidgets('tanpa butir: tidak menggambar kotak kosong', (tester) async {
      await tester.pumpWidget(aplikasiUji(const PanelSidik(anak: [])));
      expect(find.byType(Material), findsWidgets); // hanya Scaffold
      expect(
        find.descendant(
          of: find.byType(PanelSidik),
          matching: find.byType(Material),
        ),
        findsNothing,
      );
    });

    testWidgets('ripple baris terpotong di sudut panel', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(
          PanelSidik(
            anak: [BarisSidik(judul: 'Satu', onTap: () {})],
          ),
        ),
      );
      await tester.tap(find.text('Satu'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('BarisSidik', () {
    testWidgets('tinggi minimum 72 dp, sentuh seluruh baris, label baca', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      var diketuk = 0;
      await tester.pumpWidget(
        aplikasiUji(
          PanelSidik(
            anak: [
              BarisSidik(
                judul: 'Satu baris',
                semantik: 'Satu baris, dibaca utuh',
                onTap: () => diketuk++,
              ),
            ],
          ),
        ),
      );
      final ukuran = tester.getSize(find.byType(BarisSidik));
      expect(ukuran.height, greaterThanOrEqualTo(72));
      await tester.tap(find.byType(BarisSidik));
      expect(diketuk, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Satu baris, dibaca utuh')),
        matchesSemantics(
          label: 'Satu baris, dibaca utuh',
          isButton: true,
          hasTapAction: true,
        ),
      );
      // Pembaca layar benar-benar bisa mengaktifkannya (aksi ketuk ada pada
      // node berlabel, bukan hanya pada InkWell yang semantiknya dibuang).
      tester.semantics.tap(find.semantics.byLabel('Satu baris, dibaca utuh'));
      expect(diketuk, 2);
      semantik.dispose();
    });

    testWidgets(
      'baris statis dengan semantik: dibaca SATU kalimat, bukan tombol',
      (tester) async {
        final semantik = tester.ensureSemantics();
        await tester.pumpWidget(
          aplikasiUji(
            const PanelSidik(
              anak: [
                BarisSidik(
                  judul: 'Timbangan Analitik',
                  semantik: 'Timbangan Analitik, dibaca satu kalimat',
                  baris: [Text('Mettler Toledo XPR205')],
                ),
              ],
            ),
          ),
        );
        expect(
          tester.getSemantics(
            find.bySemanticsLabel('Timbangan Analitik, dibaca satu kalimat'),
          ),
          matchesSemantics(label: 'Timbangan Analitik, dibaca satu kalimat'),
        );
        // Kepingan teks anak tidak terbaca terpisah.
        expect(find.bySemanticsLabel('Mettler Toledo XPR205'), findsNothing);
        semantik.dispose();
      },
    );

    testWidgets('tanpa onTap: bukan tombol, tanpa panah', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(const PanelSidik(anak: [BarisSidik(judul: 'Statis')])),
      );
      expect(find.byType(InkWell), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('panah hanya bila bisa diketuk dan panah:true', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(
          PanelSidik(
            anak: [BarisSidik(judul: 'A', onTap: () {})],
          ),
        ),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.pumpWidget(
        aplikasiUji(
          PanelSidik(
            anak: [BarisSidik(judul: 'A', onTap: () {}, panah: false)],
          ),
        ),
      );
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets(
      'tiap keterangan di baris sendiri; tanpa pemisah titik tengah',
      (tester) async {
        await tester.pumpWidget(
          aplikasiUji(
            const PanelSidik(
              anak: [
                BarisSidik(
                  judul: 'Timbangan Analitik',
                  baris: [
                    Text('Mettler Toledo XPR205'),
                    Text('No. seri B419223017'),
                  ],
                ),
              ],
            ),
          ),
        );
        final judul = tester.getRect(find.text('Timbangan Analitik'));
        final merk = tester.getRect(find.text('Mettler Toledo XPR205'));
        final seri = tester.getRect(find.text('No. seri B419223017'));
        expect(merk.top, greaterThanOrEqualTo(judul.bottom));
        expect(seri.top, greaterThanOrEqualTo(merk.bottom));
        expect(
          semuaTeks(tester, find.byType(BarisSidik)),
          isNot(contains(' · ')),
        );
      },
    );

    group('tata letak kompak', () {
      Widget baris({bool? kompak}) => PanelSidik(
        anak: [
          BarisSidik(
            awal: (k) => AngkaHari(12, kompak: k),
            judul: 'Timbangan Analitik',
            baris: const [Text('Mettler Toledo XPR205')],
            akhir: const Text('13 Nov'),
            onTap: () {},
            kompak: kompak,
          ),
        ],
      );

      testWidgets('HP 392 dp, huruf 1,0: angka di kiri judul, akhir di kanan', (
        tester,
      ) async {
        layarHp(tester, lebar: 392, tinggi: 800);
        await tester.pumpWidget(aplikasiUji(baris()));
        final judul = tester.getRect(find.text('Timbangan Analitik'));
        final angka = tester.getRect(find.text('12'));
        final akhir = tester.getRect(find.text('13 Nov'));
        expect(angka.right, lessThanOrEqualTo(judul.left));
        expect(akhir.left, greaterThan(judul.right));
        expect(find.text('hari lagi'), findsOneWidget);
      });

      testWidgets('lebar 360 dp tidak kompak: ambang 340 dp (bukan 300)', (
        tester,
      ) async {
        layarHp(tester, lebar: 360, tinggi: 800);
        await tester.pumpWidget(aplikasiUji(baris()));
        expect(
          tester.getRect(find.text('12')).right,
          lessThanOrEqualTo(
            tester.getRect(find.text('Timbangan Analitik')).left,
          ),
        );
      });

      testWidgets('lebar 339 dp: kompak, angka pindah ke atas judul', (
        tester,
      ) async {
        layarHp(tester, lebar: 339, tinggi: 800);
        await tester.pumpWidget(aplikasiUji(baris()));
        final judul = tester.getRect(find.text('Timbangan Analitik'));
        final angka = tester.getRect(find.text('12'));
        expect(angka.bottom, lessThanOrEqualTo(judul.top));
        // Akhir pindah ke bawah teks.
        expect(
          tester.getRect(find.text('13 Nov')).top,
          greaterThanOrEqualTo(
            tester.getRect(find.text('Mettler Toledo XPR205')).bottom,
          ),
        );
      });

      testWidgets('huruf 1,3 di HP lebar: kompak', (tester) async {
        layarHp(tester, lebar: 392, tinggi: 800);
        await tester.pumpWidget(aplikasiUji(baris(), skala: 1.3));
        expect(
          tester.getRect(find.text('12')).bottom,
          lessThanOrEqualTo(
            tester.getRect(find.text('Timbangan Analitik')).top,
          ),
        );
      });

      testWidgets('huruf 1,15 belum kompak (batas dijepit 1,15x)', (
        tester,
      ) async {
        layarHp(tester, lebar: 392, tinggi: 800);
        await tester.pumpWidget(aplikasiUji(baris(), skala: 1.15));
        expect(
          tester.getRect(find.text('12')).right,
          lessThanOrEqualTo(
            tester.getRect(find.text('Timbangan Analitik')).left,
          ),
        );
      });

      testWidgets('kompak:true / false mengganti keputusan otomatis', (
        tester,
      ) async {
        layarHp(tester, lebar: 392, tinggi: 800);
        await tester.pumpWidget(aplikasiUji(baris(kompak: true)));
        expect(
          tester.getRect(find.text('12')).bottom,
          lessThanOrEqualTo(
            tester.getRect(find.text('Timbangan Analitik')).top,
          ),
        );
        layarHp(tester, lebar: 320, tinggi: 800);
        await tester.pumpWidget(aplikasiUji(baris(kompak: false), skala: 1.3));
        expect(
          tester.getRect(find.text('12')).right,
          lessThanOrEqualTo(
            tester.getRect(find.text('Timbangan Analitik')).left,
          ),
        );
      });

      testWidgets('tataLetakKompak: ambang lebar tepat 340', (tester) async {
        Future<bool> ukur(double lebar, double skala) async {
          layarHp(tester, lebar: lebar, tinggi: 600);
          late bool hasil;
          await tester.pumpWidget(
            MediaQuery.withClampedTextScaling(
              minScaleFactor: skala,
              maxScaleFactor: skala,
              child: Builder(
                builder: (context) {
                  hasil = tataLetakKompak(context);
                  return const SizedBox();
                },
              ),
            ),
          );
          return hasil;
        }

        expect(await ukur(339.9, 1.0), isTrue);
        expect(await ukur(340, 1.0), isFalse);
        expect(await ukur(392, 1.15), isFalse);
        expect(await ukur(392, 1.16), isTrue);
        expect(await ukur(320, 1.0), isTrue);
      });
    });

    group('judul nomor (gayaNomor)', () {
      for (final gelap in [false, true]) {
        testWidgets('320 dp x huruf 1,3: nomor order satu baris, tidak putus '
            '(${gelap ? 'gelap' : 'terang'})', (tester) async {
          layarHp(tester, lebar: 320, tinggi: 640);
          await tester.pumpWidget(
            aplikasiUji(
              PanelSidik(
                anak: [
                  BarisSidik(
                    judul: nomorOrderUji,
                    gayaNomor: true,
                    baris: const [Text('Target selesai 16 Nov 2026')],
                    onTap: () {},
                  ),
                ],
              ),
              gelap: gelap,
              skala: 1.3,
            ),
          );
          expect(tester.takeException(), isNull);
          final p = tester.renderObject<RenderParagraph>(
            find.text(nomorOrderUji),
          );
          expect(barisTeks(p), [nomorOrderUji]);
          // Mengecil, tidak turun di bawah 12 sp efektif.
          final dalam = tester.getSize(find.byType(FittedBox)).width;
          final aslinya = tester.getSize(find.text(nomorOrderUji)).width;
          final gaya = (p.text as TextSpan).style!;
          expect(
            gaya.fontSize! * 1.3 * (dalam / aslinya),
            greaterThanOrEqualTo(12),
          );
        });
      }
    });

    testWidgets(
      'judul panjang membungkus, baris tumbuh, tanpa luapan di 320 x 1,3',
      (tester) async {
        layarHp(tester, lebar: 320, tinggi: 800);
        await tester.pumpWidget(
          aplikasiUji(
            PanelSidik(
              anak: [
                BarisSidik(
                  awal: (k) => AngkaHari(-4, kompak: k),
                  judul: namaAlatPanjang,
                  baris: const [
                    Text('Merk dan model yang juga cukup panjang sekali'),
                  ],
                  akhir: const Text('13 Nov'),
                  onTap: () {},
                ),
              ],
            ),
            skala: 1.3,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(BarisSidik)).height,
          greaterThan(72 * 2),
        );
      },
    );

    for (final (nama, lebar, skala) in [
      ('HP 392', 392.0, 1.0),
      ('320 dp x huruf 1,3', 320.0, 1.3),
      ('tablet', 840.0, 1.0),
    ]) {
      for (final gelap in [false, true]) {
        testWidgets('$nama: pedoman sentuh + label dan kontras teks '
            '(${gelap ? 'gelap' : 'terang'})', (tester) async {
          layarHp(tester, lebar: lebar, tinggi: lebar > 600 ? 1200 : 800);
          final semantik = tester.ensureSemantics();
          await tester.pumpWidget(
            aplikasiUji(
              PanelSidik(
                anak: [
                  BarisSidik(
                    awal: (k) => AngkaHari(12, kompak: k),
                    judul: 'Timbangan Analitik',
                    baris: const [Text('Mettler Toledo XPR205')],
                    semantik: 'Timbangan Analitik. 12 hari lagi',
                    onTap: () {},
                  ),
                  BarisSidik(judul: 'Tanpa semantik khusus', onTap: () {}),
                ],
              ),
              gelap: gelap,
              skala: skala,
            ),
          );
          expect(tester.takeException(), isNull);
          await periksaPedomanSentuh(tester);
          for (final b in find.byType(BarisSidik).evaluate()) {
            expect(
              tester.getSize(find.byWidget(b.widget)).height,
              greaterThanOrEqualTo(48),
            );
          }
          expect(
            pelanggaranKontrasTeks(tester, find.byType(PanelSidik)),
            isEmpty,
          );
          semantik.dispose();
        });
      }
    }
  });

  group('NomorSidik: nomor tidak pernah putus di tengah angka', () {
    Future<double> lebarAsli(
      WidgetTester tester,
      String nomor,
      TextStyle gaya,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(
          _longgar(1000, NomorSidik(nomor, gaya: gaya)),
          bergulir: false,
        ),
      );
      // Lebar teks sebenarnya (bukan lebar kotak paragraf, yang mengisi induk).
      return tester
          .renderObject<RenderParagraph>(find.text(nomor))
          .getMaxIntrinsicWidth(double.infinity);
    }

    testWidgets('muat: apa adanya, tanpa FittedBox', (tester) async {
      await tester.pumpWidget(aplikasiUji(const NomorSidik(nomorOrderUji)));
      expect(find.byType(FittedBox), findsNothing);
      final p = tester.renderObject<RenderParagraph>(find.text(nomorOrderUji));
      expect(barisTeks(p), [nomorOrderUji]);
    });

    testWidgets('digit selebar tetap + nol bergaris', (tester) async {
      await tester.pumpWidget(aplikasiUji(const NomorSidik('2201-0457')));
      final gaya = tester.widget<Text>(find.text('2201-0457')).style!;
      expect(gaya.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(gaya.fontFeatures, contains(const FontFeature.slashedZero()));
    });

    testWidgets('tidak muat tetapi >= 12 sp efektif: satu baris mengecil', (
      tester,
    ) async {
      const gaya = TextStyle(fontSize: 16);
      final w0 = await lebarAsli(tester, nomorOrderUji, gaya);
      // 0,80 x lebar asli = 12,8 sp efektif: masih di atas batas 12.
      await tester.pumpWidget(
        aplikasiUji(
          _longgar(w0 * 0.80, const NomorSidik(nomorOrderUji, gaya: gaya)),
          bergulir: false,
        ),
      );
      expect(find.byType(FittedBox), findsOneWidget);
      final p = tester.renderObject<RenderParagraph>(find.text(nomorOrderUji));
      expect(barisTeks(p), [nomorOrderUji]);
      expect(
        tester.getSize(find.byType(FittedBox)).width,
        lessThanOrEqualTo(w0 * 0.80 + 0.01),
      );
    });

    testWidgets('akan turun di bawah 12 sp: membungkus pada garis miring', (
      tester,
    ) async {
      const gaya = TextStyle(fontSize: 16);
      final w0 = await lebarAsli(tester, nomorOrderPanjang, gaya);
      await tester.pumpWidget(
        aplikasiUji(
          _longgar(w0 * 0.5, const NomorSidik(nomorOrderPanjang, gaya: gaya)),
          bergulir: false,
        ),
      );
      expect(find.byType(FittedBox), findsNothing);
      final p = tester.renderObject<RenderParagraph>(
        find.text(nomorOrderPanjang),
      );
      final baris = barisTeks(p);
      expect(baris.length, greaterThan(1));
      expect(
        baris.join(),
        nomorOrderPanjang,
        reason: 'tidak ada karakter hilang',
      );
      for (final b in baris.take(baris.length - 1)) {
        expect(
          b.endsWith('/'),
          isTrue,
          reason: 'putus hanya setelah "/": "$b"',
        );
      }
      // Ukuran huruf tidak diubah.
      expect(p.textScaler.scale(16), 16);
    });

    testWidgets('tanpa batas lebar (gulir mendatar): tampil apa adanya', (
      tester,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: NomorSidik(nomorOrderPanjang),
          ),
          bergulir: false,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text(nomorOrderPanjang), findsOneWidget);
    });

    testWidgets('rata tengah dan label baca = nomor itu sendiri', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(
        aplikasiUji(const NomorSidik(nomorOrderUji, rataTengah: true)),
      );
      expect(find.bySemanticsLabel(nomorOrderUji), findsOneWidget);
      semantik.dispose();
    });
  });

  group('BarisAlat', () {
    testWidgets('identitas: nama, merk + model, nomor seri berdiri sendiri', (
      tester,
    ) async {
      await tester.pumpWidget(aplikasiUji(PanelSidik(anak: [_alat()])));
      expect(find.text('Jangka Sorong Digital'), findsOneWidget);
      expect(find.text('Mitutoyo CD-15CPX'), findsOneWidget);
      expect(
        find.textContaining('2201-0457', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('No. seri', findRichText: true),
        findsOneWidget,
      );
      final teks = semuaTeks(tester, find.byType(BarisAlat));
      expect(teks, isNot(contains(' · ')));
      expect(teks, isNot(contains('—')));
      // Tiga baris identitas tersusun ke bawah.
      final nama = tester.getRect(find.text('Jangka Sorong Digital'));
      final merk = tester.getRect(find.text('Mitutoyo CD-15CPX'));
      final seri = tester.getRect(
        find.textContaining('2201-0457', findRichText: true),
      );
      expect(merk.top, greaterThanOrEqualTo(nama.bottom));
      expect(seri.top, greaterThanOrEqualTo(merk.bottom));
    });

    testWidgets('angka sisa hari memimpin (kiri) dan jadi bintang baris', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 800);
      await tester.pumpWidget(aplikasiUji(PanelSidik(anak: [_alat(hari: -4)])));
      expect(find.byType(AngkaHari), findsOneWidget);
      final angka = tester.getRect(find.text('4'));
      final nama = tester.getRect(find.text('Jangka Sorong Digital'));
      expect(angka.right, lessThanOrEqualTo(nama.left));
      // Angka lebih besar dari judul (hierarki: angka 28 sp, judul 17 sp).
      final gayaAngka = tester.widget<Text>(find.text('4')).style!;
      final gayaJudul = tester
          .widget<Text>(find.text('Jangka Sorong Digital'))
          .style!;
      expect(gayaAngka.fontSize, greaterThan(gayaJudul.fontSize!));
      expect(find.text('hari lewat'), findsOneWidget);
    });

    testWidgets('nomor seri: digit selebar tetap + nol bergaris', (
      tester,
    ) async {
      await tester.pumpWidget(aplikasiUji(PanelSidik(anak: [_alat()])));
      final anak = tester.widget<Text>(find.text('2201-0457')).style!;
      expect(anak.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(anak.fontFeatures, contains(const FontFeature.slashedZero()));
    });

    testWidgets('jejak tahap hanya bila di lab, dengan kata "Di lab: ..."', (
      tester,
    ) async {
      await tester.pumpWidget(aplikasiUji(PanelSidik(anak: [_alat()])));
      expect(find.byType(JejakTahap), findsOneWidget);
      expect(find.text('Di lab: Sedang dikalibrasi'), findsOneWidget);

      await tester.pumpWidget(
        aplikasiUji(PanelSidik(anak: [_alat(diLab: false)])),
      );
      expect(find.byType(JejakTahap), findsNothing);
      expect(find.textContaining('Di lab'), findsNothing);
    });

    testWidgets('siap diambil: kata berwarna lulus', (tester) async {
      final w = TemaSidik.terang.extension<WarnaSidik>()!;
      await tester.pumpWidget(
        aplikasiUji(
          PanelSidik(
            anak: [_alat(kode: 'siap_diambil', label: 'Siap diambil')],
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('Di lab: Siap diambil')).style!.color,
        w.lulus,
      );
    });

    testWidgets('tanpa onTap: tetap dibaca satu kalimat gabungan', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(
        aplikasiUji(
          const PanelSidik(
            anak: [
              BarisAlat(
                nama: 'Jangka Sorong Digital',
                merk: 'Mitutoyo',
                model: 'CD-15CPX',
                serial: '2201-0457',
                hari: -4,
              ),
            ],
          ),
        ),
      );
      const kalimat =
          'Jangka Sorong Digital, Mitutoyo CD-15CPX, nomor seri 2201-0457. '
          'Lewat 4 hari';
      expect(
        tester.getSemantics(find.bySemanticsLabel(kalimat)),
        matchesSemantics(label: kalimat),
      );
      expect(find.byType(InkWell), findsNothing);
      semantik.dispose();
    });

    testWidgets(
      '320 dp x huruf 1,3: nama dan merk paling banyak dua baris, nomor seri '
      'tetap utuh',
      (tester) async {
        layarHp(tester, lebar: 320, tinggi: 900);
        const merkModel =
            'Merk Dengan Nama Sangat Panjang Sekali Model-Seri-Panjang-12345';
        await tester.pumpWidget(
          aplikasiUji(
            PanelSidik(
              anak: [
                _alat(
                  nama: namaAlatPanjang,
                  merk: 'Merk Dengan Nama Sangat Panjang Sekali',
                  model: 'Model-Seri-Panjang-12345',
                  serial: '2201-0457',
                  hari: 3,
                  diLab: false,
                ),
              ],
            ),
            skala: 1.3,
          ),
        );
        expect(tester.takeException(), isNull);
        final nama = tester.renderObject<RenderParagraph>(
          find.text(namaAlatPanjang),
        );
        expect(nama.didExceedMaxLines, isTrue);
        expect(barisTeks(nama).length, 2);
        final merk = tester.renderObject<RenderParagraph>(find.text(merkModel));
        expect(barisTeks(merk).length, lessThanOrEqualTo(2));
        // Nomor seri utuh, satu baris, tanpa elipsis.
        final seri = tester.renderObject<RenderParagraph>(
          find.text('2201-0457'),
        );
        expect(seri.didExceedMaxLines, isFalse);
        expect(barisTeks(seri), ['2201-0457']);
      },
    );

    testWidgets(
      'belum ada jadwal: satu baris di atas nama (bukan tiga baris di kolom '
      'sempit)',
      (tester) async {
        layarHp(tester, lebar: 392, tinggi: 800);
        await tester.pumpWidget(
          aplikasiUji(
            PanelSidik(
              anak: [
                _alat(hari: null, diLab: false),
                _alat(hari: 12, diLab: false),
              ],
            ),
          ),
        );
        final kata = tester.renderObject<RenderParagraph>(
          find.text('belum ada jadwal'),
        );
        expect(barisTeks(kata), ['belum ada jadwal']);
        final nama = tester.getRect(find.text('Jangka Sorong Digital').first);
        expect(
          tester.getRect(find.text('belum ada jadwal')).bottom,
          lessThanOrEqualTo(nama.top),
        );
        // Alat berjadwal tetap memakai kolom angka di kiri judul.
        expect(
          tester.getRect(find.text('12')).right,
          lessThanOrEqualTo(
            tester.getRect(find.text('Jangka Sorong Digital').last).left,
          ),
        );
      },
    );

    testWidgets('data tidak lengkap: tanpa baris kosong atau "—"', (
      tester,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(
          PanelSidik(
            anak: [
              _alat(
                merk: null,
                model: '  ',
                serial: null,
                hari: null,
                diLab: false,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Jangka Sorong Digital'), findsOneWidget);
      expect(find.text('–'), findsOneWidget); // angka-hari tanpa jadwal
      expect(find.text('belum ada jadwal'), findsOneWidget);
      expect(find.textContaining('No. seri', findRichText: true), findsNothing);
      expect(semuaTeks(tester, find.byType(BarisAlat)), isNot(contains('—')));
    });

    testWidgets('merk saja atau model saja tanpa spasi berlebih', (
      tester,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(PanelSidik(anak: [_alat(model: null, diLab: false)])),
      );
      expect(find.text('Mitutoyo'), findsOneWidget);
      await tester.pumpWidget(
        aplikasiUji(PanelSidik(anak: [_alat(merk: null, diLab: false)])),
      );
      expect(find.text('CD-15CPX'), findsOneWidget);
    });

    testWidgets(
      'label baca: identitas, sisa hari, dan tahap dalam satu kalimat',
      (tester) async {
        final semantik = tester.ensureSemantics();
        await tester.pumpWidget(aplikasiUji(PanelSidik(anak: [_alat()])));
        expect(
          find.bySemanticsLabel(
            'Jangka Sorong Digital, Mitutoyo CD-15CPX, nomor seri 2201-0457. '
            'Lewat 4 hari. Di lab: Sedang dikalibrasi',
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(
          aplikasiUji(
            PanelSidik(anak: [_alat(hari: null, diLab: false, serial: null)]),
          ),
        );
        expect(
          find.bySemanticsLabel(
            'Jangka Sorong Digital, Mitutoyo CD-15CPX. '
            'Belum ada jadwal kalibrasi ulang',
          ),
          findsOneWidget,
        );
        semantik.dispose();
      },
    );

    for (final (nama, lebar, skala) in [
      ('HP 392', 392.0, 1.0),
      ('320 dp x huruf 1,3', 320.0, 1.3),
      ('tablet', 840.0, 1.0),
    ]) {
      for (final gelap in [false, true]) {
        testWidgets('$nama: nama panjang, pedoman sentuh+label, kontras '
            '(${gelap ? 'gelap' : 'terang'})', (tester) async {
          layarHp(tester, lebar: lebar, tinggi: lebar > 600 ? 1200 : 900);
          final semantik = tester.ensureSemantics();
          await tester.pumpWidget(
            aplikasiUji(
              PanelSidik(
                anak: [
                  _alat(),
                  _alat(nama: namaAlatPanjang, hari: 12, diLab: false),
                  _alat(hari: 200, kode: 'siap_diambil', label: 'Siap diambil'),
                  _alat(
                    hari: null,
                    merk: null,
                    model: null,
                    serial: null,
                    diLab: false,
                  ),
                ],
              ),
              gelap: gelap,
              skala: skala,
            ),
          );
          expect(tester.takeException(), isNull);
          await periksaPedomanSentuh(tester);
          expect(
            pelanggaranKontrasTeks(tester, find.byType(PanelSidik)),
            isEmpty,
          );
          semantik.dispose();
        });
      }
    }
  });

  group('RingkasanPerhatian', () {
    List<Widget> butir(int n) => [
      for (var i = 0; i < n; i++)
        _alat(nama: 'Alat nomor $i', hari: -i - 1, diLab: false),
    ];

    testWidgets('tanpa butir: bagian TIDAK digambar sama sekali', (
      tester,
    ) async {
      await tester.pumpWidget(aplikasiUji(RingkasanPerhatian(butir: const [])));
      expect(find.text('Perlu perhatian'), findsNothing);
      expect(find.byType(PanelSidik), findsNothing);
    });

    testWidgets('judul + jumlah + paling banyak 3 butir', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(RingkasanPerhatian(butir: butir(5), total: 9)),
      );
      expect(
        find.textContaining('Perlu perhatian', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('9', findRichText: true), findsWidgets);
      expect(find.byType(BarisAlat), findsNWidgets(3));
      expect(find.text('Alat nomor 2'), findsOneWidget);
      expect(find.text('Alat nomor 3'), findsNothing);
      expect(RingkasanPerhatian.maksimum, 3);
    });

    testWidgets('jumlah bawaan = jumlah butir; judul bisa diganti', (
      tester,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(RingkasanPerhatian(butir: butir(2), judul: 'Segera')),
      );
      expect(
        find.textContaining('Segera  2', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('tautan "lihat semua" hanya bila teks dan aksi ada', (
      tester,
    ) async {
      var dibuka = 0;
      await tester.pumpWidget(aplikasiUji(RingkasanPerhatian(butir: butir(1))));
      expect(find.text('Lihat semua alat (9)'), findsNothing);
      await tester.pumpWidget(
        aplikasiUji(
          RingkasanPerhatian(
            butir: butir(1),
            teksLihatSemua: 'Lihat semua alat (9)',
          ),
        ),
      );
      expect(find.text('Lihat semua alat (9)'), findsNothing);
      await tester.pumpWidget(
        aplikasiUji(
          RingkasanPerhatian(
            butir: butir(1),
            teksLihatSemua: 'Lihat semua alat (9)',
            onLihatSemua: () => dibuka++,
          ),
        ),
      );
      await tester.tap(find.text('Lihat semua alat (9)'));
      expect(dibuka, 1);
    });

    for (final (nama, lebar, skala) in [
      ('HP 392', 392.0, 1.0),
      ('320 dp x huruf 1,3', 320.0, 1.3),
      ('tablet', 840.0, 1.0),
    ]) {
      for (final gelap in [false, true]) {
        testWidgets('$nama: pedoman sentuh+label, kontras, tanpa luapan '
            '(${gelap ? 'gelap' : 'terang'})', (tester) async {
          layarHp(tester, lebar: lebar, tinggi: lebar > 600 ? 1200 : 900);
          final semantik = tester.ensureSemantics();
          await tester.pumpWidget(
            aplikasiUji(
              RingkasanPerhatian(
                butir: [
                  _alat(),
                  _alat(nama: namaAlatPanjang, hari: 12, diLab: false),
                  _alat(hari: 20, diLab: false),
                ],
                total: 9,
                teksLihatSemua: 'Lihat semua alat (9)',
                semantikLihatSemua: 'Lihat semua alat, sembilan',
                onLihatSemua: () {},
              ),
              gelap: gelap,
              skala: skala,
            ),
          );
          expect(tester.takeException(), isNull);
          await periksaPedomanSentuh(tester);
          expect(
            pelanggaranKontrasTeks(tester, find.byType(RingkasanPerhatian)),
            isEmpty,
          );
          expect(
            tester
                .getSize(
                  find.byType(TextButton).evaluate().isEmpty
                      ? find.text('Lihat semua alat (9)')
                      : find.byType(TextButton),
                )
                .height,
            greaterThan(0),
          );
          semantik.dispose();
        });
      }
    }
  });
}
