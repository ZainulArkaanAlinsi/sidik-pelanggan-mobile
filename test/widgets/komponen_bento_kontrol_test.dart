// Komponen Bento Lab (P2), bagian kontrol: gerak, TombolBulat, SaringanPil,
// SegmenPil, TombolSidik (lencana, pil, tekan), dan KolomCariUtuh (tombol
// bulat). Tiap kontrol diuji: ukuran dari token, seluruh area sentuh >= 48 dp,
// label baca, keadaan mati (semantik + warna token), cincin fokus papan ketik
// (di luar isi, 3:1 di dua tema), "kurangi gerak", dan 320 dp x huruf 1,3.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/motion/app_motion.dart';
import 'package:sidik_pelanggan/core/motion/gerak_bento.dart';
import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';
import 'package:sidik_pelanggan/widgets/dasar/cincin_fokus.dart';
import 'package:sidik_pelanggan/widgets/kolom_cari_utuh.dart';
import 'package:sidik_pelanggan/widgets/saringan_pil.dart';
import 'package:sidik_pelanggan/widgets/segmen_pil.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';
import 'package:sidik_pelanggan/widgets/tombol_bulat.dart';
import 'package:sidik_pelanggan/widgets/tombol_sidik.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/layar_uji.dart';
import '../dukungan/ukur_komponen.dart';

ThemeData _tema(bool gelap) => gelap ? TemaSidik.gelap : TemaSidik.terang;
ColorScheme _skema(bool gelap) => _tema(gelap).colorScheme;

/// Papan ketik: Tab memindahkan fokus dan mengubah mode sorot ke tradisional.
Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

/// "Kurangi gerak" menyala di sistem (dipulihkan otomatis).
void _kurangiGerak(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Finder _bahanDi(Finder dalam) =>
    find.descendant(of: dalam, matching: find.byType(Material));

/// Cincin fokus harus di LUAR [isi] dengan celah dan tebal dari token, berwarna
/// `primary`, dan >= 3:1 terhadap halaman di tema [gelap].
void _periksaCincin(WidgetTester tester, Rect isi, {required bool gelap}) {
  final cincin = find.byKey(CincinFokus.kunciCincin);
  expect(cincin, findsOneWidget, reason: 'cincin fokus tidak tampil');
  expect(
    tester.getRect(cincin),
    isi.inflate(UkuranFokus.jarakLuar),
    reason: 'cincin harus mengelilingi isi dengan celah, di luar',
  );
  final dekor = tester.widget<DecoratedBox>(cincin).decoration as BoxDecoration;
  final garis = (dekor.border! as Border).top;
  expect(garis.width, UkuranFokus.tebal);
  expect(garis.color, _skema(gelap).primary);
  expect(
    rasioKontras(garis.color, _tema(gelap).scaffoldBackgroundColor),
    greaterThanOrEqualTo(3),
    reason: 'cincin terhadap halaman (${gelap ? 'gelap' : 'terang'})',
  );
}

/// Padding wadah segmen dan lebar satu sel pada layar 392 dp.
const _pad = UkuranKontrol.segmenPadding;
const _selSegmen = (392 - 2 * _pad) / 2;

void main() {
  setUpAll(siapkanTesFitur);

  group('gerak_bento', () {
    double opasitas(WidgetTester t, Type tipe) => t
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(tipe),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;

    double geser(WidgetTester t) => t
        .widget<Transform>(
          find.descendant(
            of: find.byType(MasukBerurutan),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .getTranslation()
        .y;

    testWidgets('MasukBerurutan: tunda 35 ms x indeks, pudar + naik 12 dp, '
        '240 ms', (tester) async {
      await tester.pumpWidget(
        aplikasiUji(
          const MasukBerurutan(indeks: 3, child: SizedBox(height: 40)),
          bergulir: false,
        ),
      );
      expect(opasitas(tester, MasukBerurutan), 0);
      expect(geser(tester), 12);
      await tester.pump(const Duration(milliseconds: 105)); // tunda 3 x 35
      expect(opasitas(tester, MasukBerurutan), closeTo(0, 0.001));
      await tester.pump(const Duration(milliseconds: 120)); // separuh jalan
      expect(
        opasitas(tester, MasukBerurutan),
        closeTo(AppMotion.masuk.transform(0.5), 0.02),
      );
      expect(geser(tester), closeTo(12 * (1 - AppMotion.masuk.transform(0.5)), 0.3));
      await tester.pump(const Duration(milliseconds: 200));
      expect(opasitas(tester, MasukBerurutan), 1);
      expect(geser(tester), 0);
    });

    testWidgets('MasukBerurutan: tunda dibatasi 210 ms (indeks 50)', (
      tester,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(
          const MasukBerurutan(indeks: 50, child: SizedBox(height: 40)),
          bergulir: false,
        ),
      );
      await tester.pump(const Duration(milliseconds: 209));
      expect(opasitas(tester, MasukBerurutan), closeTo(0, 0.001));
      await tester.pump(const Duration(milliseconds: 250));
      expect(opasitas(tester, MasukBerurutan), 1, reason: 'bukan 50 x 35 ms');
    });

    testWidgets('MasukBerurutan: kurangi gerak = langsung di keadaan akhir', (
      tester,
    ) async {
      _kurangiGerak(tester);
      await tester.pumpWidget(
        aplikasiUji(
          const MasukBerurutan(indeks: 5, child: SizedBox(height: 40)),
          bergulir: false,
        ),
      );
      expect(opasitas(tester, MasukBerurutan), 1);
      expect(geser(tester), 0);
    });

    testWidgets('MasukBerurutan: tidak mengulang saat dibangun ulang', (
      tester,
    ) async {
      Widget pohon(int n) => aplikasiUji(
        MasukBerurutan(indeks: 0, child: Text('data $n')),
        bergulir: false,
      );
      await tester.pumpWidget(pohon(1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(opasitas(tester, MasukBerurutan), 1);
      await tester.pumpWidget(pohon(2)); // data disegarkan
      expect(opasitas(tester, MasukBerurutan), 1);
      expect(find.text('data 2'), findsOneWidget);
    });

    testWidgets('TekanSkala: 0,97 selama ditekan, 120 ms, kembali 1', (
      tester,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(
          const Center(child: TekanSkala(child: SizedBox.square(dimension: 60))),
          bergulir: false,
        ),
      );
      double skala() => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
      expect(skala(), 1);
      final g = await tester.startGesture(
        tester.getCenter(find.byType(TekanSkala)),
      );
      await tester.pump();
      expect(skala(), skalaTekan);
      expect(skalaTekan, 0.97);
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
        AppMotion.kilat,
      );
      await g.up();
      await tester.pump();
      expect(skala(), 1);
      // Dibatalkan juga mengembalikan.
      final h = await tester.startGesture(
        tester.getCenter(find.byType(TekanSkala)),
      );
      await tester.pump();
      expect(skala(), skalaTekan);
      await h.cancel();
      await tester.pump();
      expect(skala(), 1);
    });

    testWidgets('TekanSkala: mati = tanpa umpan balik; kurangi gerak = durasi 0',
        (tester) async {
      await tester.pumpWidget(
        aplikasiUji(
          const Center(
            child: TekanSkala(
              aktif: false,
              child: SizedBox.square(dimension: 60),
            ),
          ),
          bergulir: false,
        ),
      );
      final g = await tester.startGesture(
        tester.getCenter(find.byType(TekanSkala)),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        1,
        reason: 'kontrol mati tidak boleh mengecil saat ditekan',
      );
      await g.up();

      _kurangiGerak(tester);
      await tester.pumpWidget(
        aplikasiUji(
          const Center(child: TekanSkala(child: SizedBox.square(dimension: 60))),
          bergulir: false,
        ),
      );
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
        Duration.zero,
      );
    });

    testWidgets('VisualMasuk: tunggu ubin 240 ms lalu 0,92 -> 1 + pudar 240 ms', (
      tester,
    ) async {
      await tester.pumpWidget(
        aplikasiUji(
          const VisualMasuk(child: SizedBox.square(dimension: 60)),
          bergulir: false,
        ),
      );
      double skala() => tester
          .widget<ScaleTransition>(
            find.descendant(
              of: find.byType(VisualMasuk),
              matching: find.byType(ScaleTransition),
            ),
          )
          .scale
          .value;
      expect(opasitas(tester, VisualMasuk), 0);
      expect(skala(), skalaVisualAwal);
      expect(skalaVisualAwal, 0.92);
      await tester.pump(const Duration(milliseconds: 240));
      expect(opasitas(tester, VisualMasuk), closeTo(0, 0.001));
      await tester.pump(const Duration(milliseconds: 250));
      expect(opasitas(tester, VisualMasuk), 1);
      expect(skala(), 1);
    });

    testWidgets('AngkaNaik: 0 -> nilai sekali, nilai baru langsung, label akhir',
        (tester) async {
      final semantik = tester.ensureSemantics();
      Widget pohon(int n) =>
          aplikasiUji(AngkaNaik(nilai: n), bergulir: false);
      await tester.pumpWidget(pohon(124));
      expect(find.text('0'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 120));
      final tengah = int.parse(
        (tester.widget<Text>(find.byType(Text)).data)!,
      );
      expect(tengah, inInclusiveRange(1, 123), reason: 'sedang menghitung');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('124'), findsOneWidget);
      // Pembaca layar membaca nilai akhir, bukan hitungan antara.
      expect(find.bySemanticsLabel('124'), findsOneWidget);
      // Penyegaran data: langsung nilai baru, tanpa hitung ulang dari 0.
      await tester.pumpWidget(pohon(130));
      expect(find.text('130'), findsOneWidget);
      semantik.dispose();
    });

    testWidgets('AngkaNaik: kurangi gerak = nilai akhir di bingkai pertama', (
      tester,
    ) async {
      _kurangiGerak(tester);
      await tester.pumpWidget(aplikasiUji(const AngkaNaik(nilai: 88), bergulir: false));
      expect(find.text('88'), findsOneWidget);
    });
  });

  group('TombolBulat', () {
    Widget app(Widget t, {bool gelap = false, double skala = 1}) =>
        aplikasiUji(Center(child: t), gelap: gelap, skala: skala, bergulir: false);

    testWidgets('ukuran: lingkaran 36 / 48 / 52, kotak sentuh >= 48', (
      tester,
    ) async {
      for (final (u, sisi, kotak) in [
        (UkuranTombolBulat.kecil, UkuranKontrol.tombolBulatKecil, 48.0),
        (UkuranTombolBulat.sedang, UkuranKontrol.tombolBulat, 48.0),
        (UkuranTombolBulat.besar, UkuranKontrol.tombolBulatBesar, 52.0),
      ]) {
        await tester.pumpWidget(
          app(
            TombolBulat(
              ikon: Icons.search,
              semantik: 'Cari',
              onTap: () {},
              ukuran: u,
            ),
          ),
        );
        expect(
          tester.getSize(_bahanDi(find.byType(TombolBulat))),
          Size.square(sisi),
          reason: '$u',
        );
        expect(
          tester.getSize(find.byType(TombolBulat)),
          Size.square(kotak),
          reason: '$u: kotak sentuh',
        );
        expect(tester.widget<Icon>(find.byType(Icon)).size, u.ikon);
      }
      expect(UkuranTombolBulat.kecil.sisi, 36);
      expect(UkuranTombolBulat.sedang.sisi, 48);
      expect(UkuranTombolBulat.besar.sisi, 52);
      expect(UkuranTombolBulat.kecil.ikon, 20);
      expect(UkuranTombolBulat.besar.ikon, 22);
    });

    testWidgets('ketuk di SELURUH kotak (juga di luar lingkaran), sekali', (
      tester,
    ) async {
      var n = 0;
      await tester.pumpWidget(app(TombolBulat.cari(onTap: () => n++)));
      final r = tester.getRect(find.byType(TombolBulat));
      expect(r.size, const Size.square(48));
      final titik = [
        r.center,
        r.topLeft + const Offset(1, 1),
        r.topRight + const Offset(-1, 1),
        r.bottomLeft + const Offset(1, -1),
        r.bottomRight + const Offset(-1, -1),
        r.centerLeft + const Offset(1, 0),
      ];
      for (final p in titik) {
        final sebelum = n;
        await tester.tapAt(p);
        expect(n, sebelum + 1, reason: 'ketukan di $p harus tepat satu kali');
      }
      final sebelum = n;
      await tester.tapAt(r.topLeft - const Offset(3, 3));
      expect(n, sebelum, reason: 'di luar kotak tidak boleh menembus');
    });

    for (final gelap in [false, true]) {
      testWidgets('warna dari token per nada (${gelap ? 'gelap' : 'terang'}); '
          'ikon >= 3:1', (tester) async {
        final s = _skema(gelap);
        final w = _tema(gelap).extension<WarnaSidik>()!;
        final harapan = {
          NadaTombolBulat.biru: (s.primary, s.onPrimary, BorderSide.none),
          NadaTombolBulat.navyUbin: (
            w.tintaUbin,
            w.kertasUbin,
            BorderSide.none,
          ),
          NadaTombolBulat.putih: (
            s.surface,
            s.onSurface,
            BorderSide(color: s.outlineVariant),
          ),
          NadaTombolBulat.aksen: (
            s.primaryContainer,
            s.onPrimaryContainer,
            BorderSide(color: s.primary),
          ),
        };
        for (final e in harapan.entries) {
          await tester.pumpWidget(
            app(
              TombolBulat(
                ikon: Icons.north_east,
                semantik: 'Buka',
                onTap: () {},
                nada: e.key,
              ),
              gelap: gelap,
            ),
          );
          final bahan = tester.widget<Material>(
            _bahanDi(find.byType(TombolBulat)),
          );
          final (isi, ikon, garis) = e.value;
          expect(bahan.color, isi, reason: '${e.key}');
          expect(tester.widget<Icon>(find.byType(Icon)).color, ikon);
          final tepi = (bahan.shape! as RoundedRectangleBorder).side;
          expect(tepi.color, garis.color, reason: '${e.key}: garis');
          expect(
            rasioKontras(ikon, isi),
            greaterThanOrEqualTo(3),
            reason: '${e.key}: ikon terhadap isi',
          );
        }
      });
    }

    testWidgets('semantik: tombol berlabel, aktif; mati = enabled:false tanpa '
        'aksi ketuk, label tetap ada', (tester) async {
      final semantik = tester.ensureSemantics();
      var n = 0;
      await tester.pumpWidget(
        app(
          TombolBulat(
            ikon: Icons.arrow_back,
            semantik: 'Kembali ke daftar alat',
            onTap: () => n++,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Kembali ke daftar alat')),
        matchesSemantics(
          label: 'Kembali ke daftar alat',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      tester.semantics.tap(find.semantics.byLabel('Kembali ke daftar alat'));
      expect(n, 1, reason: 'pembaca layar bisa mengaktifkan');

      await tester.pumpWidget(
        app(
          const TombolBulat(
            ikon: Icons.arrow_back,
            semantik: 'Kembali ke daftar alat',
            onTap: null,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Kembali ke daftar alat')),
        matchesSemantics(
          label: 'Kembali ke daftar alat',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      await tester.tap(find.byType(TombolBulat));
      expect(n, 1, reason: 'mati tidak boleh memanggil');
      semantik.dispose();
    });

    for (final gelap in [false, true]) {
      testWidgets('mati: warna dari token onSurface 12 % / 38 % '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        final s = _skema(gelap);
        await tester.pumpWidget(
          app(
            const TombolBulat.cari(onTap: null),
            gelap: gelap,
          ),
        );
        final bahan = tester.widget<Material>(_bahanDi(find.byType(TombolBulat)));
        expect(bahan.color, s.onSurface.withValues(alpha: 0.12));
        expect(
          tester.widget<Icon>(find.byType(Icon)).color,
          s.onSurface.withValues(alpha: 0.38),
        );
        // Berbeda dari keadaan aktif (bukan sekadar nilai bawaan).
        await tester.pumpWidget(
          app(TombolBulat.cari(onTap: () {}), gelap: gelap),
        );
        expect(
          tester.widget<Material>(_bahanDi(find.byType(TombolBulat))).color,
          s.primary,
        );
      });
    }

    testWidgets('hiasan: tanpa semantik dan tanpa ketukan sendiri', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(app(const TombolBulat.hiasan()));
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
      expect(
        find.semantics.byFlag(SemanticsFlag.isButton),
        findsNothing,
      );
      expect(
        tester.getSize(find.byType(TombolBulat)),
        const Size.square(UkuranKontrol.tombolBulatUbin),
      );
      semantik.dispose();
    });

    for (final gelap in [false, true]) {
      testWidgets('cincin fokus: di luar lingkaran, 3:1, Enter mengaktifkan, '
          'sentuhan tidak memunculkannya (${gelap ? 'gelap' : 'terang'})', (
        tester,
      ) async {
        var n = 0;
        await tester.pumpWidget(
          app(TombolBulat.cari(onTap: () => n++), gelap: gelap),
        );
        expect(find.byKey(CincinFokus.kunciCincin), findsNothing);
        await _tab(tester);
        _periksaCincin(
          tester,
          tester.getRect(_bahanDi(find.byType(TombolBulat))),
          gelap: gelap,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(n, 1);
        // Ketukan jari: mode sorot kembali ke sentuh, cincin hilang.
        await tester.tap(find.byType(TombolBulat));
        await tester.pump();
        expect(find.byKey(CincinFokus.kunciCincin), findsNothing);
        expect(n, 2);
      });
    }

    testWidgets('320 dp x huruf 1,3: ukuran tidak berubah, tanpa luapan', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TombolBulat.cari(onTap: () {}),
              TombolBulat.kembali(onTap: () {}),
              TombolBulat.aksi(semantik: 'Buka', onTap: () {}),
            ],
          ),
          skala: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(_bahanDi(find.byType(TombolBulat).first)),
        const Size.square(UkuranKontrol.tombolBulatKecil),
      );
    });
  });

  group('SaringanPil', () {
    const pilihan = [
      PilihanPil('Semua', jumlah: 9),
      PilihanPil('Lewat jadwal', jumlah: 1, nada: NadaStatus.gagal),
      PilihanPil('Dalam 30 hari', jumlah: 3),
      PilihanPil('Berlaku'),
    ];

    Widget app(
      Widget t, {
      bool gelap = false,
      double skala = 1,
    }) => aplikasiUji(t, gelap: gelap, skala: skala, bergulir: false);

    Finder pil(String label) => _bahanDi(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_Pil',
        ),
      ),
    );

    testWidgets('tinggi 40 radius 12, bulatan 24, tinggi baris 56 dengan '
        'ruang cincin', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 640);
      await tester.pumpWidget(
        app(SaringanPil(pilihan: pilihan, terpilih: 0, onPilih: (_) {})),
      );
      expect(tester.getSize(pil('Semua')).height, UkuranKontrol.saringan);
      expect(tester.getSize(pil('Lewat jadwal')).height, 40);
      final bahan = tester.widget<Material>(pil('Semua'));
      expect(
        (bahan.shape! as RoundedRectangleBorder).borderRadius,
        Bentuk.sudutKapsul,
      );
      final bulatan = find.ancestor(
        of: find.text('9'),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(bulatan), const Size.square(24));
      // Kata dan bulatan: padding 16 kiri, 4 kanan, jarak 8.
      final r = tester.getRect(pil('Semua'));
      expect(tester.getRect(find.text('Semua')).left - r.left, 16);
      expect(r.right - tester.getRect(bulatan).right, 4);
      expect(
        tester.getRect(bulatan).left - tester.getRect(find.text('Semua')).right,
        8,
      );
      // Tanpa jumlah: padding 16 di kedua sisi.
      final b = tester.getRect(pil('Berlaku'));
      expect(tester.getRect(find.text('Berlaku')).left - b.left, 16);
      expect(b.right - tester.getRect(find.text('Berlaku')).right, 16);
      // Jarak antar-saringan 8.
      expect(
        tester.getRect(pil('Lewat jadwal')).left - r.right,
        8,
      );
      expect(tester.getSize(find.byType(SaringanPil)).height, 56);
    });

    testWidgets('ketuk di seluruh kotak 48 (juga di atas/bawah pil), sekali', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 640);
      final dipilih = <int>[];
      await tester.pumpWidget(
        app(SaringanPil(pilihan: pilihan, terpilih: 0, onPilih: dipilih.add)),
      );
      final r = tester.getRect(pil('Lewat jadwal'));
      await tester.tapAt(r.center);
      await tester.tapAt(Offset(r.center.dx, r.top - 1.5)); // di atas pil
      await tester.tapAt(Offset(r.center.dx, r.bottom + 1.5)); // di bawah pil
      await tester.tapAt(r.topLeft + const Offset(14, 2));
      expect(dipilih, [1, 1, 1, 1]);
      await tester.tapAt(Offset(r.center.dx, r.top - 6));
      expect(dipilih.length, 4, reason: 'di luar kotak 48 tidak boleh menembus');
    });

    testWidgets('semantik: tombol "kata, jumlah", selected hanya satu, aksi ada',
        (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 640);
      final dipilih = <int>[];
      await tester.pumpWidget(
        app(SaringanPil(pilihan: pilihan, terpilih: 1, onPilih: dipilih.add)),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Lewat jadwal, 1')),
        matchesSemantics(
          label: 'Lewat jadwal, 1',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Semua, 9')),
        matchesSemantics(
          label: 'Semua, 9',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      tester.semantics.tap(find.semantics.byLabel('Dalam 30 hari, 3'));
      expect(dipilih, [2]);
      semantik.dispose();
    });

    for (final gelap in [false, true]) {
      testWidgets('warna dari token: terpilih biru muda + tepi biru + navy + '
          'bulatan biru; tidak terpilih putih + tepi tegas + bulatan status '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 392, tinggi: 640);
        final s = _skema(gelap);
        final w = _tema(gelap).extension<WarnaSidik>()!;
        await tester.pumpWidget(
          app(
            SaringanPil(pilihan: pilihan, terpilih: 0, onPilih: (_) {}),
            gelap: gelap,
          ),
        );
        final terpilih = tester.widget<Material>(pil('Semua'));
        expect(terpilih.color, s.primaryContainer);
        expect(
          (terpilih.shape! as RoundedRectangleBorder).side.color,
          s.primary,
          reason: 'terpilih: tepi biru (bukan warna saja)',
        );
        final tidak = tester.widget<Material>(pil('Dalam 30 hari'));
        expect(tidak.color, s.surface);
        expect(
          (tidak.shape! as RoundedRectangleBorder).side.color,
          s.outline,
        );
        Color? isiBulatan(String angka) =>
            ((tester
                            .widget<AnimatedContainer>(
                              find.ancestor(
                                of: find.text(angka),
                                matching: find.byType(AnimatedContainer),
                              ),
                            )
                            .decoration!)
                        as BoxDecoration)
                    .color;
        expect(isiBulatan('9'), s.primary, reason: 'terpilih: bulatan biru');
        expect(isiBulatan('3'), s.surfaceContainer, reason: 'tanpa nada');
        // Nada gagal = merah muda di dua tema (ubin tetap terang), tinta navy.
        expect(isiBulatan('1'), w.ubinGagal, reason: 'nada gagal');
        // Semua teks (kata terpilih onPrimaryContainer di atas biru muda,
        // angka putih di atas biru, angka navy di atas warna muda) >= 4,5:1.
        expect(
          pelanggaranKontrasTeks(tester, find.byType(SaringanPil)),
          isEmpty,
        );
      });
    }

    testWidgets('mati (onPilih null): semua enabled:false, ketukan tidak '
        'berefek, terpilih tetap ditandai', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 640);
      await tester.pumpWidget(
        app(const SaringanPil(pilihan: pilihan, terpilih: 1)),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Lewat jadwal, 1')),
        matchesSemantics(
          label: 'Lewat jadwal, 1',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      final s = _skema(false);
      expect(
        tester.widget<Material>(pil('Semua')).color,
        s.onSurface.withValues(alpha: 0.12),
      );
      semantik.dispose();
    });

    testWidgets('pilihan terpilih yang jauh di kanan digulirkan masuk layar', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        app(
          const SaringanPil(
            pilihan: [
              PilihanPil('Semua', jumlah: 9),
              PilihanPil('Lewat jadwal', jumlah: 1),
              PilihanPil('Dalam 30 hari', jumlah: 1),
              PilihanPil('31 sampai 60 hari', jumlah: 2),
              PilihanPil('61 sampai 90 hari', jumlah: 2),
            ],
            terpilih: 4,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final r = tester.getRect(pil('61 sampai 90 hari'));
      expect(r.right, lessThanOrEqualTo(320 + 0.5));
      expect(r.left, greaterThanOrEqualTo(0));
    });

    for (final gelap in [false, true]) {
      testWidgets('cincin fokus: di luar pil, tidak terpotong gulir, 3:1 '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 392, tinggi: 640);
        final dipilih = <int>[];
        await tester.pumpWidget(
          app(
            SaringanPil(pilihan: pilihan, terpilih: 0, onPilih: dipilih.add),
            gelap: gelap,
          ),
        );
        await _tab(tester);
        _periksaCincin(tester, tester.getRect(pil('Semua')), gelap: gelap);
        final baris = tester.getRect(find.byType(SaringanPil));
        final cincin = tester.getRect(find.byKey(CincinFokus.kunciCincin));
        expect(baris.top, lessThanOrEqualTo(cincin.top));
        expect(baris.bottom, greaterThanOrEqualTo(cincin.bottom));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(dipilih, [0]);
      });
    }

    testWidgets('angka tiga digit pada 320 dp x huruf 1,3: bulatan tumbuh, '
        'tanpa luapan', (tester) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        app(
          SaringanPil(
            pilihan: const [
              PilihanPil('Semua', jumlah: 128),
              PilihanPil('Lewat jadwal', jumlah: 1),
            ],
            terpilih: 0,
            onPilih: (_) {},
          ),
          skala: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      final bulatan = tester.getSize(
        find.ancestor(
          of: find.text('128'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(bulatan.width, greaterThanOrEqualTo(UkuranKontrol.jumlahSaringan));
      expect(
        bulatan.height,
        greaterThanOrEqualTo(UkuranKontrol.jumlahSaringan),
      );
      expect(
        tester.getSize(pil('Semua')).height,
        greaterThanOrEqualTo(UkuranKontrol.saringan),
      );
    });
  });

  group('SegmenPil', () {
    Widget app(Widget t, {bool gelap = false, double skala = 1}) =>
        aplikasiUji(t, gelap: gelap, skala: skala, bergulir: false);

    Finder pilNavy(bool gelap) => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color ==
              _skema(gelap).primaryContainer &&
          (w.decoration as BoxDecoration).border != null,
    );

    // Salinan kata ada DI DALAM penanda yang bergeser (warnanya sama dengan
    // kata dasar di tema terang, jadi dibedakan lewat letaknya).
    Finder salinan(String kata, bool gelap) => find.descendant(
      of: pilNavy(gelap),
      matching: find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText() == kata &&
            (w.text as TextSpan).style?.color ==
                _skema(gelap).onPrimaryContainer,
      ),
    );

    Widget segmen({
      required int terpilih,
      ValueChanged<int>? onPilih,
      List<String> pilihan = const ['Daftar', 'Arsip'],
    }) => SegmenPil(pilihan: pilihan, terpilih: terpilih, onPilih: onPilih);

    testWidgets('wadah 48 padding 4, penanda 40 radius 8, lebar separuh', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 640);
      await tester.pumpWidget(app(segmen(terpilih: 0, onPilih: (_) {})));
      final luar = tester.getRect(find.byType(SegmenPil));
      expect(luar.height, UkuranKontrol.segmenLuar);
      expect(luar.width, 392);
      final pilRect = tester.getRect(pilNavy(false));
      expect(pilRect.height, UkuranKontrol.segmenDalam);
      expect(pilRect.width, (392 - 2 * _pad) / 2);
      expect(pilRect.left - luar.left, _pad);
      expect(pilRect.top - luar.top, _pad);
      final klip = tester.widget<ClipRRect>(
        find.ancestor(of: pilNavy(false), matching: find.byType(ClipRRect)).first,
      );
      expect(klip.borderRadius, Bentuk.sudutPenanda);
      final dekorPil =
          tester.widget<DecoratedBox>(pilNavy(false)).decoration as BoxDecoration;
      expect(dekorPil.color, _skema(false).primaryContainer);
      expect(
        dekorPil.border,
        Border.all(color: _skema(false).primary, width: 1),
        reason: 'penanda bertepi biru: bukan warna saja',
      );
      final bahan = tester.widget<Material>(
        find.descendant(
          of: find.byType(SegmenPil),
          matching: find.byType(Material),
        ).first,
      );
      expect(
        (bahan.shape! as RoundedRectangleBorder).borderRadius,
        Bentuk.sudutKapsul,
      );
      expect(bahan.color, _skema(false).surface);
    });

    testWidgets('satu kata per pilihan di pohon teks dan semantik (salinan '
        'putih tidak terhitung)', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 640);
      await tester.pumpWidget(app(segmen(terpilih: 1, onPilih: (_) {})));
      expect(find.text('Daftar'), findsOneWidget);
      expect(find.text('Arsip'), findsOneWidget);
      expect(find.semantics.byLabel('Arsip'), findsOneWidget);
      expect(
        find.semantics.byLabel('Arsip').evaluate().single,
        matchesSemantics(
          label: 'Arsip',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        find.semantics.byLabel('Daftar').evaluate().single,
        matchesSemantics(
          label: 'Daftar',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      semantik.dispose();
    });

    testWidgets('ketuk di seluruh wadah: tiap separuh dari tepi ke tepi', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 640);
      final dipilih = <int>[];
      await tester.pumpWidget(
        app(segmen(terpilih: 0, onPilih: dipilih.add)),
      );
      final r = tester.getRect(find.byType(SegmenPil));
      await tester.tapAt(r.centerRight - const Offset(3, 0)); // padding kanan
      await tester.tapAt(r.topRight + const Offset(-60, 2)); // tepi atas
      await tester.tapAt(r.bottomLeft + const Offset(60, -2)); // tepi bawah
      await tester.tapAt(r.centerLeft + const Offset(3, 0)); // padding kiri
      await tester.tapAt(r.center + const Offset(-4, 0)); // tepat kiri tengah
      await tester.tapAt(r.center + const Offset(4, 0)); // tepat kanan tengah
      expect(dipilih, [1, 1, 0, 0, 0, 1]);
      expect(r.height, greaterThanOrEqualTo(48));
    });

    for (final gelap in [false, true]) {
      testWidgets('pil BERGESER 240 ms dan salinan kata putih tetap tepat di '
          'atas kata dasar di tiap bingkai (${gelap ? 'gelap' : 'terang'})', (
        tester,
      ) async {
        layarHp(tester, lebar: 392, tinggi: 640);
        var t = 0;
        late StateSetter ubah;
        await tester.pumpWidget(
          app(
            StatefulBuilder(
              builder: (c, setState) {
                ubah = setState;
                return segmen(terpilih: t, onPilih: (_) {});
              },
            ),
            gelap: gelap,
          ),
        );
        expect(tester.getRect(pilNavy(gelap)).left, _pad);
        ubah(() => t = 1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        final tengah = tester.getRect(pilNavy(gelap)).left;
        expect(tengah, greaterThan(_pad));
        expect(tengah, lessThan(_pad + _selSegmen), reason: 'masih bergeser');
        expect(
          tester.getCenter(salinan('Arsip', gelap)).dx,
          closeTo(tester.getCenter(find.text('Arsip')).dx, 0.5),
          reason: 'salinan harus tepat di atas kata dasar saat bergeser',
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          tester.getRect(pilNavy(gelap)).left,
          closeTo(_pad + _selSegmen, 0.01),
        );
        expect(
          tester.getCenter(salinan('Arsip', gelap)),
          offsetMoreOrLessEquals(tester.getCenter(find.text('Arsip')), epsilon: 0.5),
        );
        // Kata dalam penanda: onPrimaryContainer di atas primaryContainer.
        expect(
          rasioKontras(
            _skema(gelap).onPrimaryContainer,
            _skema(gelap).primaryContainer,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          pelanggaranKontrasTeks(tester, find.byType(SegmenPil)),
          isEmpty,
        );
      });
    }

    testWidgets('kurangi gerak: pil langsung di tempat baru', (tester) async {
      _kurangiGerak(tester);
      layarHp(tester, lebar: 392, tinggi: 640);
      var t = 0;
      late StateSetter ubah;
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (c, setState) {
              ubah = setState;
              return segmen(terpilih: t, onPilih: (_) {});
            },
          ),
        ),
      );
      ubah(() => t = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        tester.getRect(pilNavy(false)).left,
        closeTo(_pad + _selSegmen, 0.01),
      );
    });

    testWidgets('mati (onPilih null): semua enabled:false, pil redup dari '
        'token, ketukan tidak berefek', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 640);
      await tester.pumpWidget(app(segmen(terpilih: 0)));
      expect(
        find.semantics.byLabel('Arsip').evaluate().single,
        matchesSemantics(
          label: 'Arsip',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasSelectedState: true,
        ),
      );
      final s = _skema(false);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color ==
                  s.onSurface.withValues(alpha: 0.12),
        ),
        findsOneWidget,
      );
      expect(pilNavy(false), findsNothing);
      semantik.dispose();
    });

    testWidgets('tiga pilihan: pil sepertiga lebar dan bergeser ke sel ketiga',
        (tester) async {
      layarHp(tester, lebar: 392, tinggi: 640);
      await tester.pumpWidget(
        app(
          segmen(
            terpilih: 2,
            onPilih: (_) {},
            pilihan: const ['Satu', 'Dua', 'Tiga'],
          ),
        ),
      );
      final r = tester.getRect(pilNavy(false));
      expect(r.width, closeTo((392 - 2 * _pad) / 3, 0.01));
      expect(r.right, closeTo(392 - _pad, 0.01));
      expect(
        tester.getCenter(salinan('Tiga', false)).dx,
        closeTo(tester.getCenter(find.text('Tiga')).dx, 0.5),
      );
    });

    for (final gelap in [false, true]) {
      testWidgets('cincin fokus: mengelilingi penanda sel (40), di dalam wadah, '
          '3:1 (${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 392, tinggi: 640);
        final dipilih = <int>[];
        await tester.pumpWidget(
          app(segmen(terpilih: 0, onPilih: dipilih.add), gelap: gelap),
        );
        await _tab(tester);
        final luar = tester.getRect(find.byType(SegmenPil));
        _periksaCincin(
          tester,
          Rect.fromLTWH(
            luar.left + _pad,
            luar.top + _pad,
            _selSegmen,
            UkuranKontrol.segmenDalam,
          ),
          gelap: gelap,
        );
        expect(
          luar.contains(tester.getRect(find.byKey(CincinFokus.kunciCincin)).topLeft),
          isTrue,
          reason: 'cincin tidak keluar dari wadah',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(dipilih, [0]);
      });
    }

    testWidgets('320 dp x huruf 1,3 dengan kata panjang: tumbuh, tidak '
        'dipotong, tanpa luapan', (tester) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        app(
          segmen(
            terpilih: 1,
            onPilih: (_) {},
            pilihan: const ['Sertifikat berlaku', 'Arsip lama'],
          ),
          skala: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(SegmenPil)).height,
        greaterThanOrEqualTo(UkuranKontrol.segmenLuar),
      );
      final p = tester.renderObject<RenderParagraph>(find.text('Sertifikat berlaku'));
      expect(p.didExceedMaxLines, isFalse);
      expect(barisTeks(p).join(' ').replaceAll('  ', ' '), contains('Sertifikat'));
    });
  });

  group('TombolSidik Bento', () {
    Widget app(Widget t, {bool gelap = false, double skala = 1}) =>
        aplikasiUji(t, gelap: gelap, skala: skala, bergulir: false);

    Finder lencana(String angka) => find.ancestor(
      of: find.text(angka),
      matching: find.byType(DecoratedBox),
    );

    testWidgets('utama + jumlah: 48, padding 20/8, lencana 28 putih, label '
        'kiri dan lencana kanan', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 640);
      await tester.pumpWidget(
        app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: TombolSidik(
              label: 'Periksa alat',
              ragam: RagamTombol.utama,
              jumlah: 2,
              penuh: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      final tombol = tester.getRect(find.byType(FilledButton));
      expect(tombol.height, UkuranBaris.tombolUtama);
      expect(tombol.width, 392 - 32);
      expect(
        tester.getRect(find.text('Periksa alat')).left - tombol.left,
        UkuranKontrol.tombolUtamaAwal,
      );
      final l = tester.getRect(lencana('2').first);
      expect(l.size, const Size.square(UkuranKontrol.lencanaTombol));
      expect(tombol.right - l.right, 8);
      final dekor = tester.widget<DecoratedBox>(lencana('2').first).decoration
          as BoxDecoration;
      expect(dekor.color, _skema(false).secondary);
      expect(dekor.borderRadius, Bentuk.sudutPil);
      // Lencana putih bertinta biru di atas tombol biru.
      expect(
        rasioKontras(_skema(false).onSecondary, dekor.color!),
        greaterThanOrEqualTo(4.5),
      );
      // Bentuk tombol dari tema: persegi bersudut 10.
      final bahan = tester.widget<Material>(_bahanDi(find.byType(FilledButton)));
      expect(
        (bahan.shape! as RoundedRectangleBorder).borderRadius,
        Bentuk.sudutTombol,
      );
    });

    testWidgets('semantik "label, jumlah"; mati: lencana redup dari token', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 640);
      await tester.pumpWidget(
        app(
          const TombolSidik(
            label: 'Periksa alat',
            ragam: RagamTombol.utama,
            jumlah: 2,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Periksa alat, 2'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
      final dekor = tester.widget<DecoratedBox>(lencana('2').first).decoration
          as BoxDecoration;
      expect(dekor.color, _skema(false).onSurface.withValues(alpha: 0.12));
      semantik.dispose();
    });

    testWidgets('jumlah hanya untuk ragam utama; sekunder 48 padding 20, sudut 10', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 640);
      await tester.pumpWidget(
        app(
          Column(
            children: [
              TombolSidik(label: 'Unduh', jumlah: 5, onPressed: () {}),
              TombolSidik(
                label: 'Hapus',
                ragam: RagamTombol.bahaya,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      expect(find.text('5'), findsNothing, reason: 'sekunder tak punya lencana');
      final o = find.byType(OutlinedButton).first;
      expect(tester.getSize(o).height, 48);
      expect(
        tester.getSize(o).width,
        tester.getSize(find.text('Unduh')).width +
            2 * UkuranKontrol.tombolSekunder,
      );
      final bahan = tester.widget<Material>(_bahanDi(o));
      expect(
        (bahan.shape! as RoundedRectangleBorder).borderRadius,
        Bentuk.sudutTombol,
      );
      final bahaya = find.byType(OutlinedButton).last;
      expect(
        tester.getSize(bahaya).width,
        tester.getSize(find.text('Hapus')).width +
            2 * UkuranKontrol.tombolSekunder,
      );
    });

    testWidgets('ditekan: skala 0,97; mati dan sibuk tidak mengecil', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 640);
      Future<double> tekan(Widget t) async {
        await tester.pumpWidget(app(Center(child: t)));
        final g = await tester.startGesture(
          tester.getCenter(find.byType(TombolSidik)),
        );
        await tester.pump();
        final skala = tester
            .widget<AnimatedScale>(
              find.descendant(
                of: find.byType(TombolSidik),
                matching: find.byType(AnimatedScale),
              ),
            )
            .scale;
        await g.up();
        await tester.pump(const Duration(milliseconds: 200));
        return skala;
      }

      expect(
        await tekan(TombolSidik(label: 'Aksi', onPressed: () {})),
        skalaTekan,
      );
      expect(await tekan(const TombolSidik(label: 'Aksi')), 1);
      expect(
        await tekan(TombolSidik(label: 'Aksi', sibuk: true, onPressed: () {})),
        1,
      );
    });

    for (final gelap in [false, true]) {
      testWidgets('cincin fokus di luar pil, 3:1 '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 392, tinggi: 640);
        var n = 0;
        await tester.pumpWidget(
          app(
            Center(
              child: TombolSidik(
                label: 'Aksi',
                ragam: RagamTombol.utama,
                onPressed: () => n++,
              ),
            ),
            gelap: gelap,
          ),
        );
        await _tab(tester);
        _periksaCincin(
          tester,
          tester.getRect(find.byType(FilledButton)),
          gelap: gelap,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(n, 1);
      });
    }

    testWidgets('320 dp x huruf 1,3: label panjang + lencana 3 digit tanpa '
        'luapan', (tester) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: TombolSidik(
              label: 'Periksa seluruh alat yang menunggu',
              ragam: RagamTombol.utama,
              jumlah: 128,
              penuh: true,
              onPressed: () {},
            ),
          ),
          skala: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(UkuranBaris.tombolUtama),
      );
    });
  });

  group('KolomCariUtuh Bento', () {
    const petunjuk = 'Cari nama, merk, atau nomor seri';

    Widget app(Widget t, {bool gelap = false, double skala = 1}) =>
        aplikasiUji(t, gelap: gelap, skala: skala, bergulir: false);

    testWidgets('kotak 48, sudut 10, padding 16 kiri, tombol bulat 36 biru 6 dp '
        'dari tepi kanan, kotak sentuh 48', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 640);
      await tester.pumpWidget(
        app(KolomCariUtuh(petunjuk: petunjuk, onCari: (_) {})),
      );
      final kolom = tester.getRect(find.byType(TextField));
      expect(kolom.height, greaterThanOrEqualTo(UkuranKontrol.kolomCari));
      expect(kolom.left, 16);
      expect(kolom.right, 392 - 16);
      final dekor = tester.widget<TextField>(find.byType(TextField)).decoration!;
      final tepi = dekor.enabledBorder! as OutlineInputBorder;
      expect(tepi.borderRadius, Bentuk.sudutTombol);
      expect(tepi.borderSide.color, _skema(false).outline);
      expect((dekor.focusedBorder! as OutlineInputBorder).borderSide.width, 2);
      // Petunjuk mulai 16 dp dari tepi kiri kolom.
      expect(
        tester.getRect(find.text(petunjuk)).left - kolom.left,
        closeTo(UkuranKontrol.kolomCariAwal, 1),
      );
      final lingkaran = tester.getRect(_bahanDi(find.byType(TombolBulat)));
      expect(lingkaran.size, const Size.square(UkuranKontrol.tombolBulatKecil));
      expect(kolom.right - lingkaran.right, UkuranKontrol.kolomCariAkhir);
      expect(lingkaran.center.dy, closeTo(kolom.center.dy, 0.5));
      expect(tester.getSize(find.byType(TombolBulat)), const Size.square(48));
      expect(
        tester.widget<Material>(_bahanDi(find.byType(TombolBulat))).color,
        _skema(false).primary,
      );
      // Petunjuk 13/400 teksKedua.
      final gaya = dekor.hintStyle!;
      expect(gaya.fontSize, 13);
      expect(gaya.fontWeight, FontWeight.w400);
      expect(gaya.color, _skema(false).onSurfaceVariant);
    });

    testWidgets('tombol Cari: label baca, mencari SEKARANG sekali, tanpa kirim '
        'ganda setelah jeda', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 640);
      final kata = <String>[];
      await tester.pumpWidget(
        app(KolomCariUtuh(petunjuk: petunjuk, onCari: kata.add)),
      );
      expect(find.bySemanticsLabel('Cari'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  jangka ');
      await tester.tap(find.byType(TombolBulat));
      expect(kata, ['jangka'], reason: 'tanpa menunggu 350 ms');
      await tester.pump(KolomCariUtuh.jeda * 2);
      expect(kata, ['jangka'], reason: 'jeda tidak boleh mengirim ulang');
      await tester.tap(find.byType(TombolBulat));
      expect(kata, ['jangka'], reason: 'kata yang sama tidak dikirim lagi');
      await tester.enterText(find.byType(TextField), 'timbangan');
      await tester.tap(find.byType(TombolBulat));
      expect(kata, ['jangka', 'timbangan']);
      // Tombol cari di papan ketik soft juga mencari sekarang.
      await tester.enterText(find.byType(TextField), 'mikrometer');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(kata.last, 'mikrometer');
      semantik.dispose();
    });

    testWidgets('mati (aktif:false): TextField.enabled false, tombol '
        'enabled:false, tidak mencari', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 640);
      final kata = <String>[];
      await tester.pumpWidget(
        app(KolomCariUtuh(petunjuk: petunjuk, onCari: kata.add, aktif: false)),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Cari')),
        matchesSemantics(
          label: 'Cari',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      await tester.tap(find.byType(TombolBulat));
      await tester.tap(find.byType(TextField));
      await tester.pump(KolomCariUtuh.jeda * 2);
      expect(kata, isEmpty);
      expect(
        tester.widget<Material>(_bahanDi(find.byType(TombolBulat))).color,
        _skema(false).onSurface.withValues(alpha: 0.12),
      );
      // Aktif: sebaliknya.
      await tester.pumpWidget(
        app(KolomCariUtuh(petunjuk: petunjuk, onCari: kata.add)),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
      semantik.dispose();
    });

    testWidgets('tetap SATU node text-field; tombol terpisah, bukan bagian '
        'dari node isian', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 640);
      await tester.pumpWidget(
        app(KolomCariUtuh(petunjuk: petunjuk, onCari: (_) {})),
      );
      final isian = nodeTextField(tester);
      expect(isian.length, 1);
      expect(isian.single.label, contains(petunjuk));
      expect(isian.single.label, isNot(contains('Cari\n')));
      semantik.dispose();
    });

    testWidgets('320 dp x huruf 1,3: petunjuk utuh dan kolom tumbuh', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        app(KolomCariUtuh(petunjuk: petunjuk, onCari: (_) {}), skala: 1.3),
      );
      expect(tester.takeException(), isNull);
      final hint = tester.renderObject<RenderParagraph>(find.text(petunjuk));
      expect(hint.didExceedMaxLines, isFalse);
      expect(barisTeks(hint).join(), petunjuk);
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(56),
      );
    });

    for (final gelap in [false, true]) {
      testWidgets('petunjuk >= 4,5:1 di atas isian; tepi isian >= 3:1 '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 392, tinggi: 640);
        await tester.pumpWidget(
          app(
            KolomCariUtuh(petunjuk: petunjuk, onCari: (_) {}),
            gelap: gelap,
          ),
        );
        final dekor = tester.widget<TextField>(find.byType(TextField)).decoration!;
        final s = _skema(gelap);
        expect(
          rasioKontras(dekor.hintStyle!.color!, s.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          rasioKontras(
            (dekor.enabledBorder! as OutlineInputBorder).borderSide.color,
            _tema(gelap).scaffoldBackgroundColor,
          ),
          greaterThanOrEqualTo(3),
          reason: 'tepi kolom terhadap halaman',
        );
      });
    }
  });
}
