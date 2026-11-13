// JejakTahap, TikPaket, dan GarisWaktuTahap: tik per langkah `garis_waktu`
// (jumlah dari server, bukan 6 yang dikeraskan), tik per alat, garis waktu
// tegak; semua keadaan, terang/gelap, 320 dp x huruf 1,3, dan kata selalu
// mendampingi tik.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/models/paket.dart';
import 'package:sidik_pelanggan/widgets/garis_waktu_tahap.dart';
import 'package:sidik_pelanggan/widgets/jejak_tahap.dart';
import 'package:sidik_pelanggan/widgets/panel_sidik.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';
import 'package:sidik_pelanggan/widgets/tik_paket.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/fixture_komponen.dart';
import '../dukungan/layar_uji.dart';
import '../dukungan/ukur_komponen.dart';

ThemeData _tema(bool gelap) => gelap ? TemaSidik.gelap : TemaSidik.terang;

Widget _dalamPanel(Widget anak) => PanelSidik(
  anak: [Padding(padding: const EdgeInsets.all(16), child: anak)],
);

/// Kotak dekorasi (tik atau simpul) di dalam [dalam], berurutan.
List<DecoratedBox> _kotak(WidgetTester tester, Type dalam) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(dalam),
        matching: find.byType(DecoratedBox),
      ),
    )
    .toList();

BoxDecoration _dekor(DecoratedBox k) => k.decoration as BoxDecoration;

void main() {
  setUpAll(siapkanTesFitur);

  group('posisiTahap: satu aturan pemetaan tahap ke posisi', () {
    final garis = garisWaktuUji(sekarang: 1);

    test('tanpa kode: ikuti penanda sekarang dari server', () {
      expect(posisiTahap(garis), 1);
      expect(posisiTahap(garisWaktuUji(sekarang: 4)), 4);
    });

    test(
      'tanpa sekarang: langkah terakhir yang lewat; tanpa apa pun: null',
      () {
        final tanpaSekarang = [
          for (final l in garisWaktuUji(sekarang: 3))
            LangkahPaketSalin(l).tanpaSekarang(),
        ];
        expect(posisiTahap(tanpaSekarang), 2);
        expect(posisiTahap(const []), isNull);
        expect(
          posisiTahap(
            garisWaktuUji(
              sekarang: 0,
            ).map((l) => LangkahPaketSalin(l).tanpaSekarang()).toList(),
          ),
          isNull,
        );
      },
    );

    test('dengan kode alat: dicari di garis_waktu, menang atas penanda', () {
      expect(posisiTahap(garis, kode: 'diterima'), 0);
      expect(posisiTahap(garis, kode: 'dikalibrasi'), 1);
      expect(posisiTahap(garis, kode: 'sertifikat_terbit'), 3);
      expect(posisiTahap(garis, kode: 'diserahkan'), 5);
    });

    test('menunggu_pengesahan dipetakan ke menunggu_pemeriksaan', () {
      expect(posisiTahap(garis, kode: 'menunggu_pengesahan'), 2);
    });

    test('kode tidak dikenal: null, tidak ada tik sekarang yang dikarang', () {
      expect(posisiTahap(garis, kode: 'tahap_baru_dari_server'), isNull);
    });

    test(
      'tujuh langkah: "Sedang dikerjakan ulang" punya posisinya sendiri',
      () {
        final tujuh = garisWaktuUji(sekarang: 2, tambahUlang: true);
        expect(tujuh.length, 7);
        expect(posisiTahap(tujuh, kode: 'perlu_diulang'), 2);
        expect(posisiTahap(tujuh, kode: 'menunggu_pemeriksaan'), 3);
      },
    );
  });

  group('JejakTahap', () {
    testWidgets('jumlah tik = panjang garis_waktu dari server (bukan 6)', (
      tester,
    ) async {
      for (final n in [2, 4, 6, 7, 9]) {
        await tester.pumpWidget(
          aplikasiUji(
            JejakTahap(garisWaktu: garisWaktuSepanjang(n), kata: 'Di lab'),
          ),
        );
        expect(_kotak(tester, JejakTahap).length, n, reason: 'n=$n');
      }
    });

    testWidgets('tik sampai sekarang kobalt, sekarang lebih tinggi, sisanya '
        'garis halus', (tester) async {
      final s = TemaSidik.terang.colorScheme;
      for (var posisi = 0; posisi < 6; posisi++) {
        await tester.pumpWidget(
          aplikasiUji(
            JejakTahap(
              garisWaktu: garisWaktuUji(sekarang: posisi),
              kata: 'Di lab: tes',
            ),
          ),
        );
        final tik = _kotak(tester, JejakTahap);
        expect(tik.length, 6);
        for (var i = 0; i < 6; i++) {
          expect(
            _dekor(tik[i]).color,
            i <= posisi ? s.primary : s.outlineVariant,
            reason: 'tik $i dari posisi $posisi',
          );
          expect(_dekor(tik[i]).borderRadius, Bentuk.sudutKecil);
        }
        // Tinggi: hanya tik sekarang yang 12, sisanya 6.
        final tinggi = [
          for (final k
              in find
                  .descendant(
                    of: find.byType(JejakTahap),
                    matching: find.byType(DecoratedBox),
                  )
                  .evaluate())
            tester.getSize(find.byWidget(k.widget)).height,
        ];
        for (var i = 0; i < 6; i++) {
          expect(
            tinggi[i],
            i == posisi ? UkuranTik.tinggiSekarang : UkuranTik.tinggi,
            reason: 'tinggi tik $i dari posisi $posisi',
          );
        }
      }
    });

    testWidgets('kode tahap alat menggeser tik sekarang', (tester) async {
      final s = TemaSidik.terang.colorScheme;
      await tester.pumpWidget(
        aplikasiUji(
          JejakTahap(
            garisWaktu: garisWaktuUji(sekarang: 1),
            kodeTahap: 'menunggu_pengesahan',
            kata: 'Di lab: Hasil sedang diperiksa',
          ),
        ),
      );
      final tik = _kotak(tester, JejakTahap);
      expect(_dekor(tik[2]).color, s.primary);
      expect(_dekor(tik[3]).color, s.outlineVariant);
    });

    testWidgets('kode tidak dikenal: tidak ada tik kobalt yang dikarang', (
      tester,
    ) async {
      final s = TemaSidik.terang.colorScheme;
      await tester.pumpWidget(
        aplikasiUji(
          JejakTahap(
            garisWaktu: garisWaktuUji(),
            kodeTahap: 'tahap_baru',
            kata: 'Di lab: Tahap baru',
          ),
        ),
      );
      for (final k in _kotak(tester, JejakTahap)) {
        expect(_dekor(k).color, s.outlineVariant);
      }
      expect(find.text('Di lab: Tahap baru'), findsOneWidget);
    });

    testWidgets('kata WAJIB tampil dan menjadi label baca "Tahap n dari m"', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(
        aplikasiUji(
          JejakTahap(
            garisWaktu: garisWaktuUji(sekarang: 1),
            kata: 'Di lab: Sedang dikalibrasi',
          ),
        ),
      );
      expect(find.text('Di lab: Sedang dikalibrasi'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Tahap 2 dari 6: Di lab: Sedang dikalibrasi'),
        findsOneWidget,
      );
      await tester.pumpWidget(
        aplikasiUji(
          JejakTahap(
            garisWaktu: garisWaktuUji(sekarang: 2, tambahUlang: true),
            kata: 'Di lab: Sedang dikerjakan ulang',
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(
          'Tahap 3 dari 7: Di lab: Sedang dikerjakan ulang',
        ),
        findsOneWidget,
      );
      semantik.dispose();
    });

    testWidgets(
      'garis_waktu kosong: tanpa tik, tetapi kata yang wajib tetap tampil dan '
      'terbaca',
      (tester) async {
        final semantik = tester.ensureSemantics();
        await tester.pumpWidget(
          aplikasiUji(
            const JejakTahap(
              garisWaktu: [],
              kata: 'Di lab: Sedang dikalibrasi',
            ),
          ),
        );
        expect(find.byType(DecoratedBox), findsNothing);
        expect(find.text('Di lab: Sedang dikalibrasi'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Di lab: Sedang dikalibrasi'),
          findsOneWidget,
        );
        semantik.dispose();
      },
    );

    for (final gelap in [false, true]) {
      testWidgets(
        'kontras kata 4,5 dan tik terisi 3 (${gelap ? 'gelap' : 'terang'})',
        (tester) async {
          final s = _tema(gelap).colorScheme;
          for (final nada in [null, NadaStatus.lulus]) {
            await tester.pumpWidget(
              aplikasiUji(
                _dalamPanel(
                  JejakTahap(
                    garisWaktu: garisWaktuUji(sekarang: 4),
                    kata: 'Di lab: Siap diambil',
                    nadaKata: nada,
                  ),
                ),
                gelap: gelap,
              ),
            );
            expect(
              pelanggaranKontrasTeks(tester, find.byType(JejakTahap)),
              isEmpty,
              reason: '$nada',
            );
          }
          // Tik kobalt terhadap permukaan panel: komponen UI >= 3:1.
          final tik = _kotak(tester, JejakTahap).first;
          expect(
            rasioKontras(_dekor(tik).color!, s.surface),
            greaterThanOrEqualTo(3),
          );
        },
      );

      testWidgets('320 dp x huruf 1,3: tujuh tik, kata panjang membungkus '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 320, tinggi: 640);
        await tester.pumpWidget(
          aplikasiUji(
            JejakTahap(
              garisWaktu: garisWaktuUji(sekarang: 2, tambahUlang: true),
              kata:
                  'Di lab: Sedang dikerjakan ulang karena hasil pengukuran '
                  'perlu diperiksa kembali oleh petugas',
            ),
            gelap: gelap,
            skala: 1.3,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(_kotak(tester, JejakTahap).length, 7);
      });
    }
  });

  group('TikPaket: satu tik per alat', () {
    test('pemetaan kode tahap alat', () {
      expect(TikPaket.tahapDari('diterima'), TahapTik.baru);
      for (final k in [
        'dikalibrasi',
        'perlu_diulang',
        'menunggu_pemeriksaan',
      ]) {
        expect(TikPaket.tahapDari(k), TahapTik.jalan, reason: k);
      }
      expect(TikPaket.tahapDari('menunggu_pengesahan'), TahapTik.jalan);
      for (final k in ['sertifikat_terbit', 'siap_diambil', 'diserahkan']) {
        expect(TikPaket.tahapDari(k), TahapTik.selesai, reason: k);
      }
      expect(TikPaket.tahapDari('kode_baru'), TahapTik.jalan);
    });

    testWidgets('urut dari yang paling maju; selesai terisi, jalan tipis, baru '
        'kosong berbingkai', (tester) async {
      final s = TemaSidik.terang.colorScheme;
      await tester.pumpWidget(
        aplikasiUji(
          TikPaket.dariTahap(const [
            'diterima',
            'dikalibrasi',
            'sertifikat_terbit',
            'diterima',
          ]),
        ),
      );
      final tik = _kotak(tester, TikPaket);
      expect(tik.length, 4);
      final selesai = _dekor(tik[0]);
      expect(selesai.color, s.primary);
      expect(selesai.border, isNull);
      final jalan = _dekor(tik[1]);
      expect(jalan.color, s.primaryContainer);
      expect((jalan.border! as Border).top.color, s.primary);
      for (final i in [2, 3]) {
        final baru = _dekor(tik[i]);
        expect(baru.color, isNull);
        expect((baru.border! as Border).top.color, s.outline);
        expect(
          tester.getSize(find.byWidget(tik[i])).height,
          UkuranTik.tinggiSekarang,
        );
      }
      expect(find.text('1 dari 4 alat selesai'), findsOneWidget);
    });

    testWidgets('dariJumlah: N dari M, selesai terisi lebih dulu', (
      tester,
    ) async {
      final s = TemaSidik.terang.colorScheme;
      await tester.pumpWidget(
        aplikasiUji(TikPaket.dariJumlah(jumlahAlat: 4, jumlahSelesai: 3)),
      );
      final tik = _kotak(tester, TikPaket);
      expect(
        [for (final k in tik) _dekor(k).color == s.primary],
        [true, true, true, false],
      );
      expect(find.text('3 dari 4 alat selesai'), findsOneWidget);

      // Selesai lebih dari jumlah alat: dijepit, bukan tik tambahan.
      await tester.pumpWidget(
        aplikasiUji(TikPaket.dariJumlah(jumlahAlat: 2, jumlahSelesai: 9)),
      );
      expect(_kotak(tester, TikPaket).length, 2);
      expect(find.text('2 dari 2 alat selesai'), findsOneWidget);
    });

    testWidgets('kata khusus menggantikan kalimat bawaan; label baca = kata', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(
        aplikasiUji(
          TikPaket.dariTahap(const ['diterima'], kata: 'Baru diterima lab'),
        ),
      );
      expect(find.text('Baru diterima lab'), findsOneWidget);
      expect(find.bySemanticsLabel('Baru diterima lab'), findsOneWidget);
      await tester.pumpWidget(
        aplikasiUji(TikPaket.dariTahap(const ['diterima', 'siap_diambil'])),
      );
      expect(find.bySemanticsLabel('1 dari 2 alat selesai'), findsOneWidget);
      semantik.dispose();
    });

    testWidgets('tanpa alat: tidak menggambar apa pun', (tester) async {
      await tester.pumpWidget(aplikasiUji(const TikPaket(tik: [])));
      expect(find.byType(DecoratedBox), findsNothing);
      await tester.pumpWidget(
        aplikasiUji(TikPaket.dariJumlah(jumlahAlat: -3, jumlahSelesai: 1)),
      );
      expect(find.byType(DecoratedBox), findsNothing);
    });

    testWidgets('paket besar (100 alat) jadi batang bersegmen, tanpa luapan', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        aplikasiUji(
          TikPaket.dariTahap([
            for (var i = 0; i < 100; i++)
              i < 40
                  ? 'siap_diambil'
                  : i < 70
                  ? 'dikalibrasi'
                  : 'diterima',
          ]),
          skala: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      // Tiga segmen (selesai, jalan, baru), bukan 100 tik.
      expect(_kotak(tester, TikPaket).length, 3);
      expect(find.text('40 dari 100 alat selesai'), findsOneWidget);
      // Tepat di batas: 24 alat masih tik satuan.
      await tester.pumpWidget(
        aplikasiUji(TikPaket.dariJumlah(jumlahAlat: 24, jumlahSelesai: 5)),
      );
      expect(_kotak(tester, TikPaket).length, UkuranTik.tikPaketMaksimum);
      await tester.pumpWidget(
        aplikasiUji(TikPaket.dariJumlah(jumlahAlat: 25, jumlahSelesai: 5)),
      );
      expect(_kotak(tester, TikPaket).length, 2);
    });

    for (final gelap in [false, true]) {
      testWidgets('kontras: kata 4,5; bingkai tik kosong dan berisi 3 '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        final s = _tema(gelap).colorScheme;
        await tester.pumpWidget(
          aplikasiUji(
            _dalamPanel(
              TikPaket.dariTahap(const [
                'siap_diambil',
                'dikalibrasi',
                'diterima',
              ]),
            ),
            gelap: gelap,
          ),
        );
        expect(pelanggaranKontrasTeks(tester, find.byType(TikPaket)), isEmpty);
        final tik = _kotak(tester, TikPaket);
        expect(
          rasioKontras(_dekor(tik[0]).color!, s.surface),
          greaterThanOrEqualTo(3),
        );
        expect(
          rasioKontras((_dekor(tik[1]).border! as Border).top.color, s.surface),
          greaterThanOrEqualTo(3),
        );
        expect(
          rasioKontras((_dekor(tik[2]).border! as Border).top.color, s.surface),
          greaterThanOrEqualTo(3),
          reason: 'bingkai tik kosong = garis tegas',
        );
      });

      testWidgets(
        '320 dp x huruf 1,3 tanpa luapan (${gelap ? 'gelap' : 'terang'})',
        (tester) async {
          layarHp(tester, lebar: 320, tinggi: 640);
          await tester.pumpWidget(
            aplikasiUji(
              TikPaket.dariTahap(
                const ['siap_diambil', 'dikalibrasi', 'diterima', 'diterima'],
                kata:
                    '1 dari 4 alat selesai, menunggu pemeriksaan dua alat '
                    'lainnya di laboratorium',
              ),
              gelap: gelap,
              skala: 1.3,
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('GarisWaktuTahap', () {
    testWidgets('satu simpul per langkah server: enam dan tujuh', (
      tester,
    ) async {
      for (final tambah in [false, true]) {
        final garis = garisWaktuUji(sekarang: 1, tambahUlang: tambah);
        await tester.pumpWidget(aplikasiUji(GarisWaktuTahap(langkah: garis)));
        expect(_kotak(tester, GarisWaktuTahap).length, garis.length);
        for (final l in garis) {
          expect(find.text(l.label), findsOneWidget, reason: l.label);
        }
      }
    });

    testWidgets('bentuk simpul: lewat = terisi + centang, sekarang = lingkar '
        'tipis, belum = bingkai tegas kosong', (tester) async {
      final s = TemaSidik.terang.colorScheme;
      await tester.pumpWidget(
        aplikasiUji(GarisWaktuTahap(langkah: garisWaktuUji(sekarang: 2))),
      );
      final simpul = _kotak(tester, GarisWaktuTahap);
      for (var i = 0; i < 6; i++) {
        final d = _dekor(simpul[i]);
        expect(d.borderRadius, Bentuk.sudutKecil, reason: 'simpul $i persegi');
        final ukuran = tester.getSize(find.byWidget(simpul[i]));
        if (i < 2) {
          expect(d.color, s.primary);
          expect(d.border, isNull);
          expect(ukuran.width, UkuranTik.simpul);
        } else if (i == 2) {
          expect(d.color, s.primary);
          final b = (d.border! as Border).top;
          expect(b.color, s.primaryContainer);
          expect(b.width, UkuranTik.lingkar);
          expect(ukuran.width, UkuranTik.simpulSekarang);
        } else {
          expect(d.color, isNull);
          final b = (d.border! as Border).top;
          expect(b.color, s.outline);
          expect(b.width, UkuranTik.batang);
          expect(ukuran.width, UkuranTik.simpul);
        }
      }
      // Centang hanya pada langkah yang sudah lewat.
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('catatan hanya di bawah langkah sekarang', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(
          GarisWaktuTahap(
            langkah: garisWaktuUji(sekarang: 1),
            catatan: 'Menunggu: Jangka Sorong Digital dan Mikrometer Sekrup',
          ),
        ),
      );
      expect(
        find.text('Menunggu: Jangka Sorong Digital dan Mikrometer Sekrup'),
        findsOneWidget,
      );
      // Posisinya tepat di bawah judul "Sedang dikalibrasi".
      final judul = tester.getRect(find.text('Sedang dikalibrasi'));
      final catatan = tester.getRect(find.textContaining('Menunggu:'));
      expect(catatan.top, greaterThanOrEqualTo(judul.bottom));
      expect(catatan.top - judul.bottom, lessThan(12));
      // Tanpa langkah sekarang, catatan tidak digambar.
      await tester.pumpWidget(
        aplikasiUji(
          GarisWaktuTahap(
            langkah: [
              for (final l in garisWaktuUji(sekarang: 6))
                LangkahPaketSalin(l).tanpaSekarang(),
            ],
            catatan: 'Menunggu: X',
          ),
        ),
      );
      expect(find.text('Menunggu: X'), findsNothing);
    });

    test('menunggu(): batas 0, 1, 2 nama, maksimum kecil, dan nama kembar', () {
      String? m(List<String> n, [int maks = 3]) =>
          GarisWaktuTahap.menunggu(n, maksimum: maks);
      // 0, 1, 2 nama.
      expect(m(const []), isNull);
      expect(m(const ['A']), 'Menunggu: A');
      expect(m(const ['A', 'B']), 'Menunggu: A dan B');
      // maksimum kecil tidak pernah menghasilkan kalimat tanpa nama.
      expect(m(const ['A'], 1), 'Menunggu: A');
      expect(m(const ['A', 'B'], 1), 'Menunggu: A dan 1 alat lain');
      expect(m(const ['A', 'B', 'C'], 1), 'Menunggu: A dan 2 alat lain');
      expect(m(const ['A', 'B', 'C'], 0), 'Menunggu: A dan 2 alat lain');
      expect(m(const ['A', 'B', 'C'], 2), 'Menunggu: A dan 2 alat lain');
      // Nama kembar digabung; hitungan alat tetap benar.
      expect(m(const ['T', 'T']), 'Menunggu: T (2 unit)');
      expect(m(const ['T', 'T', 'A']), 'Menunggu: T (2 unit) dan A');
      expect(
        m(const ['T', 'A', 'T', 'B', 'C']),
        'Menunggu: T (2 unit), A, dan 2 alat lain',
      );
      expect(m(const ['T', 'T', 'T'], 1), 'Menunggu: T (3 unit)');
      // Sapuan: tidak pernah koma gantung atau awal tanpa nama.
      for (var n = 0; n <= 6; n++) {
        for (var maks = 0; maks <= 5; maks++) {
          final hasil = m([for (var i = 0; i < n; i++) 'A${i % 3}'], maks);
          if (n == 0) {
            expect(hasil, isNull);
            continue;
          }
          expect(hasil, startsWith('Menunggu: A'), reason: '$n/$maks: $hasil');
          expect(hasil, isNot(contains(': ,')), reason: '$n/$maks: $hasil');
          expect(hasil, isNot(contains(', dan 1 alat')), reason: '$n/$maks');
          expect(hasil, isNot(contains('  ')), reason: '$n/$maks: $hasil');
        }
      }
    });

    test('menunggu(): daftar nama alat penahan', () {
      expect(GarisWaktuTahap.menunggu(const []), isNull);
      expect(GarisWaktuTahap.menunggu(const ['  ', '']), isNull);
      expect(GarisWaktuTahap.menunggu(const ['A']), 'Menunggu: A');
      expect(GarisWaktuTahap.menunggu(const ['A', 'B']), 'Menunggu: A dan B');
      expect(
        GarisWaktuTahap.menunggu(const ['A', 'B', 'C']),
        'Menunggu: A, B, dan C',
      );
      expect(
        GarisWaktuTahap.menunggu(const ['A', 'B', 'C', 'D', 'E']),
        'Menunggu: A, B, dan 3 alat lain',
      );
      expect(
        GarisWaktuTahap.menunggu(const ['A', 'B', 'C', 'D'], maksimum: 4),
        'Menunggu: A, B, C, dan D',
      );
    });

    testWidgets('label baca satu kalimat per langkah', (tester) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(
        aplikasiUji(
          GarisWaktuTahap(
            langkah: garisWaktuUji(sekarang: 1),
            catatan: 'Menunggu: Jangka Sorong Digital',
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Alat diterima lab, selesai'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Sedang dikalibrasi, tahap sekarang. Menunggu: Jangka Sorong Digital',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Hasil sedang diperiksa, belum'),
        findsOneWidget,
      );
      semantik.dispose();
    });

    testWidgets('langkah kosong: tidak menggambar apa pun', (tester) async {
      await tester.pumpWidget(aplikasiUji(const GarisWaktuTahap(langkah: [])));
      expect(find.byType(DecoratedBox), findsNothing);
    });

    for (final gelap in [false, true]) {
      testWidgets('kontras: judul 4,5; simpul belum (garis tegas) dan terisi 3 '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        final s = _tema(gelap).colorScheme;
        await tester.pumpWidget(
          aplikasiUji(
            _dalamPanel(
              GarisWaktuTahap(
                langkah: garisWaktuUji(sekarang: 2),
                catatan: 'Menunggu: Jangka Sorong Digital',
              ),
            ),
            gelap: gelap,
          ),
        );
        expect(
          pelanggaranKontrasTeks(tester, find.byType(GarisWaktuTahap)),
          isEmpty,
        );
        final simpul = _kotak(tester, GarisWaktuTahap);
        expect(
          rasioKontras(_dekor(simpul[0]).color!, s.surface),
          greaterThanOrEqualTo(3),
        );
        expect(
          rasioKontras(
            (_dekor(simpul[4]).border! as Border).top.color,
            s.surface,
          ),
          greaterThanOrEqualTo(3),
          reason: 'bingkai simpul belum',
        );
        // Centang putih di atas kobalt.
        final centang = tester.widget<Icon>(find.byIcon(Icons.check).first);
        expect(
          rasioKontras(centang.color!, _dekor(simpul[0]).color!),
          greaterThanOrEqualTo(3),
        );
      });

      testWidgets('320 dp x huruf 1,3: label dan catatan panjang membungkus '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 320, tinggi: 800);
        await tester.pumpWidget(
          aplikasiUji(
            GarisWaktuTahap(
              langkah: garisWaktuUji(sekarang: 1, tambahUlang: true),
              catatan: GarisWaktuTahap.menunggu(const [
                'Alat Ukur Tekanan Digital Presisi Tinggi Multi Rentang',
                'Jangka Sorong Digital',
                'Mikrometer Sekrup Luar',
                'Termometer Inframerah',
                'Neraca Analitik',
              ]),
            ),
            gelap: gelap,
            skala: 1.3,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}

/// Salinan [LangkahPaket] dengan penanda `sekarang` dimatikan (uji saja).
class LangkahPaketSalin {
  const LangkahPaketSalin(this.asal);
  final LangkahPaket asal;

  LangkahPaket tanpaSekarang() => LangkahPaket(
    kode: asal.kode,
    label: asal.label,
    lewat: asal.lewat,
    sekarang: false,
  );
}
