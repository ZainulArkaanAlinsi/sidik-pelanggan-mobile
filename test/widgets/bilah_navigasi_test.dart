// Bilah navigasi bawah solid (R1, REVISI-2 butir 13): permukaan putih selebar
// layar dengan garis tipis di atas (tanpa bayangan), SEMUA menu berlabel,
// indikator aktif biru muda, semantik tiap butir (label, selected, petunjuk
// posisi), lencana, huruf 1,3x di 320/360/390, ruang isi yang memperhitungkan
// bilah + banner pembaruan + tepi sistem, papan ketik, dan rel >= 600 dp yang
// tidak berubah. Pengganti `dock_navigasi_test.dart` (dock navy melayang).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/elevasi.dart';
import 'package:sidik_pelanggan/core/tema/palet_sidik.dart';
import 'package:sidik_pelanggan/core/tema/spasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/tipografi.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
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
  bool bahasaId = false,
  bool papanKetik = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  // Bahasa aplikasi (id); tanpa ini tes memakai bahasa Inggris bawaan Material.
  locale: bahasaId ? const Locale('id', 'ID') : null,
  supportedLocales: bahasaId
      ? const [Locale('id', 'ID'), Locale('en')]
      : const [Locale('en', 'US')],
  localizationsDelegates: bahasaId
      ? GlobalMaterialLocalizations.delegates
      : null,
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
      papanKetikTerbuka: papanKetik,
    ),
  ),
);

Finder get _bilah => find.byType(BilahNavigasi);

/// Kotak butir ke-[i]: seperlima lebar bilah (sel `Expanded`).
Rect _sel(WidgetTester tester, int i) {
  final bilah = tester.getRect(_bilah);
  final lebar = bilah.width / _nama.length;
  return Rect.fromLTWH(bilah.left + i * lebar, bilah.top, lebar, bilah.height);
}

Finder get _indikator => find.byKey(BilahNavigasi.kunciIndikator);

/// Label (teks) butir di dalam bilah.
Finder _teks(String label) =>
    find.descendant(of: _bilah, matching: find.text(label));

/// Nilai IconTheme/Icon di dalam bilah untuk ikon [data].
Icon _ikonWidget(WidgetTester tester, IconData data) => tester.widget<Icon>(
  find.descendant(of: _bilah, matching: find.byIcon(data)),
);

/// Petunjuk posisi yang diharapkan di butir ke-[i] (bahasa Inggris bawaan
/// Material di tes: "Tab 1 of 5").
String _petunjuk(int i) => const DefaultMaterialLocalizations().tabLabel(
  tabIndex: i + 1,
  tabCount: _nama.length,
);

bool _memuat(Rect luar, Rect dalam, [double toleransi = 0.01]) =>
    luar.left - toleransi <= dalam.left &&
    luar.top - toleransi <= dalam.top &&
    luar.right + toleransi >= dalam.right &&
    luar.bottom + toleransi >= dalam.bottom;

void main() {
  setUpAll(siapkanTesFitur);

  group('bentuk: solid, selebar layar, garis tipis, tanpa bayangan', () {
    for (final gelap in [false, true]) {
      testWidgets(
        'tema ${gelap ? 'gelap' : 'terang'}: permukaan surface, garis '
        'atas outlineVariant 1 dp, tanpa bayangan dan tanpa sudut',
        (tester) async {
          layarHp(tester, lebar: 390, tinggi: 800);
          await tester.pumpWidget(_app(gelap: gelap));
          await tester.pumpAndSettle();
          final tema = gelap ? TemaSidik.gelap : TemaSidik.terang;

          final bilah = tester.getRect(_bilah);
          // Selebar layar, menempel ke tepi bawah (bukan melayang).
          expect(bilah.left, 0);
          expect(bilah.right, 390);
          expect(bilah.bottom, 800);
          expect(bilah.height, greaterThanOrEqualTo(UkuranBilah.tinggi));

          final bahan = tester.widget<Material>(
            find.descendant(of: _bilah, matching: find.byType(Material)).first,
          );
          expect(bahan.color, tema.colorScheme.surface);
          expect(bahan.elevation, 0);
          expect(bahan.shadowColor, isNull);
          expect(bahan.borderRadius, isNull);

          final dekor =
              tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: _bilah,
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration;
          expect(dekor.boxShadow, isNull, reason: 'tanpa bayangan');
          expect(dekor.borderRadius, isNull, reason: 'tanpa sudut membulat');
          final garis = dekor.border! as Border;
          expect(garis.top.color, tema.colorScheme.outlineVariant);
          expect(garis.top.width, Elevasi.garis);
          expect(garis.bottom, BorderSide.none);
          expect(garis.left, BorderSide.none);
          expect(garis.right, BorderSide.none);
        },
      );
    }

    testWidgets('tepi sistem ditambahkan DI DALAM permukaan, bukan sebagai '
        'celah di bawahnya', (tester) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      await tester.pumpWidget(_app(tepi: 34));
      await tester.pumpAndSettle();
      final bilah = tester.getRect(_bilah);
      expect(bilah.bottom, 800, reason: 'permukaan sampai ke tepi layar');
      // Isi butir (ikon + kata) berhenti 34 dp di atas tepi layar.
      expect(bilah.height, greaterThanOrEqualTo(UkuranBilah.tinggi + 34));
      final akun = tester.getRect(_teks('Akun'));
      expect(akun.bottom, lessThanOrEqualTo(800 - 34));

      await tester.pumpWidget(_app(tepi: 0));
      await tester.pumpAndSettle();
      expect(tester.getRect(_bilah).bottom, 800);
      expect(tester.getRect(_bilah).height, greaterThanOrEqualTo(64));
    });
  });

  group('semua menu berlabel, butir aktif berindikator', () {
    for (var aktif = 0; aktif < _nama.length; aktif++) {
      testWidgets('tab ${_nama[aktif]} aktif: kelima label tampil, satu '
          'indikator biru muda di butir aktif, ikon terisi hanya di aktif', (
        tester,
      ) async {
        layarHp(tester, lebar: 390, tinggi: 800);
        await tester.pumpWidget(_app(indeks: aktif));
        await tester.pumpAndSettle();
        final s = TemaSidik.terang.colorScheme;

        for (var i = 0; i < _nama.length; i++) {
          final dipilih = i == aktif;
          // SEMUA label tampil, aktif atau tidak.
          expect(_teks(_nama[i]), findsOneWidget, reason: 'label ${_nama[i]}');
          final label = tester.widget<Text>(_teks(_nama[i]));
          expect(label.maxLines, 1);
          expect(
            label.style!.fontWeight,
            dipilih ? TipografiSidik.beratLencana : TipografiSidik.beratLabel,
            reason: 'berat huruf ${_nama[i]}',
          );
          expect(
            label.style!.color,
            dipilih ? s.onSurface : s.onSurfaceVariant,
            reason: 'warna label ${_nama[i]}',
          );
          // Ikon: terisi hanya di butir aktif (bentuk, bukan hanya warna).
          final ikon = _ikonWidget(tester, dipilih ? _ikon[i].$2 : _ikon[i].$1);
          expect(ikon.size, UkuranBilah.ikon);
          expect(
            ikon.color,
            dipilih ? s.onPrimaryContainer : s.onSurfaceVariant,
          );
          expect(
            find.descendant(
              of: _bilah,
              matching: find.byIcon(dipilih ? _ikon[i].$1 : _ikon[i].$2),
            ),
            findsNothing,
            reason: 'bentuk ikon ${_nama[i]} salah untuk dipilih=$dipilih',
          );
          // Label di tengah selnya, di bawah ikon.
          final sel = _sel(tester, i);
          final kotakLabel = tester.getRect(_teks(_nama[i]));
          final kotakIkon = tester.getRect(
            find.descendant(
              of: _bilah,
              matching: find.byIcon(dipilih ? _ikon[i].$2 : _ikon[i].$1),
            ),
          );
          expect(kotakLabel.center.dx, closeTo(sel.center.dx, 0.5));
          expect(kotakLabel.top, greaterThanOrEqualTo(kotakIkon.bottom));
        }

        // Tepat satu indikator, di belakang ikon butir aktif.
        expect(_indikator, findsOneWidget);
        final kotak = tester.getRect(_indikator);
        expect(
          kotak.size,
          const Size(UkuranBilah.indikatorLebar, UkuranBilah.indikatorTinggi),
        );
        expect(kotak.center.dx, closeTo(_sel(tester, aktif).center.dx, 0.5));
        final dekor =
            tester.widget<DecoratedBox>(_indikator).decoration as BoxDecoration;
        expect(dekor.color, s.primaryContainer);
        expect(dekor.color, PaletSidik.biruMuda, reason: 'biru muda REVISI');
        expect(dekor.borderRadius, Bentuk.sudutPil);
        // Ikon aktif berada di dalam indikator.
        final ikonAktif = tester.getRect(
          find.descendant(of: _bilah, matching: find.byIcon(_ikon[aktif].$2)),
        );
        expect(_memuat(kotak, ikonAktif), isTrue);
      });
    }

    testWidgets('berganti tab memindahkan indikator, label tetap lengkap', (
      tester,
    ) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      await tester.pumpWidget(_app(indeks: 0));
      await tester.pumpAndSettle();
      final awal = tester.getRect(_indikator).center.dx;
      await tester.pumpWidget(_app(indeks: 4));
      await tester.pumpAndSettle();
      expect(tester.getRect(_indikator).center.dx, greaterThan(awal));
      for (final n in _nama) {
        expect(_teks(n), findsOneWidget);
      }
    });

    for (final gelap in [false, true]) {
      testWidgets('kontras ${gelap ? 'gelap' : 'terang'}: label dan ikon '
          'terhadap permukaan dan indikator', (tester) async {
        layarHp(tester, lebar: 390, tinggi: 800);
        await tester.pumpWidget(_app(gelap: gelap, indeks: 1));
        await tester.pumpAndSettle();
        final s = (gelap ? TemaSidik.gelap : TemaSidik.terang).colorScheme;
        // Label biasa/terpilih di atas permukaan; ikon aktif di atas indikator.
        expect(
          rasioKontras(s.onSurfaceVariant, s.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(rasioKontras(s.onSurface, s.surface), greaterThanOrEqualTo(4.5));
        expect(
          rasioKontras(s.onPrimaryContainer, s.primaryContainer),
          greaterThanOrEqualTo(4.5),
        );
        // Indikator terlihat terhadap permukaan lewat bentuk + ikon terisi
        // (bukan warna saja); garis atas bilah terhadap halaman tidak diuji
        // (pemisah dekoratif).
        expect(
          _ikonWidget(tester, Icons.precision_manufacturing).color,
          s.onPrimaryContainer,
        );
      });
    }
  });

  group('semantik: satu simpul berlabel per butir', () {
    for (var aktif = 0; aktif < _nama.length; aktif++) {
      testWidgets('tab ${_nama[aktif]} terpilih: selected hanya di butir '
          'aktif, tombol, petunjuk posisi', (tester) async {
        final semantik = tester.ensureSemantics();
        layarHp(tester, lebar: 390, tinggi: 800);
        await tester.pumpWidget(_app(indeks: aktif));
        await tester.pumpAndSettle();
        for (var i = 0; i < _nama.length; i++) {
          final dipilih = i == aktif;
          expect(
            tester.getSemantics(find.bySemanticsLabel(_nama[i])),
            matchesSemantics(
              label: _nama[i],
              hint: _petunjuk(i),
              isButton: true,
              hasEnabledState: true,
              isEnabled: true,
              hasSelectedState: true,
              isSelected: dipilih,
              hasTapAction: true,
            ),
            reason: '${_nama[i]} dipilih=$dipilih',
          );
        }
        semantik.dispose();
      });
    }

    testWidgets('pembaca layar: lima simpul berlabel berurutan, tanpa label '
        'ganda dari ikon, kata, atau lencana', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 390, tinggi: 800);
      await tester.pumpWidget(_app(indeks: 1, lencana: 3));
      await tester.pumpAndSettle();

      final berlabel = <String>[];
      final berpetunjuk = <String>[];
      void kunjungi(SemanticsNode simpul) {
        final data = simpul.getSemanticsData();
        if (data.label.isNotEmpty) berlabel.add(data.label);
        if (data.hint.isNotEmpty) berpetunjuk.add(data.hint);
        simpul.visitChildren((anak) {
          kunjungi(anak);
          return true;
        });
      }

      kunjungi(tester.getSemantics(_bilah));
      // Urutan fokus = urutan kiri ke kanan.
      expect(berlabel, [
        'Beranda',
        'Alat',
        'Sertifikat',
        'Notifikasi, 3 belum dibaca',
        'Akun',
      ]);
      expect(berpetunjuk, [
        for (var i = 0; i < _nama.length; i++) _petunjuk(i),
      ]);
      semantik.dispose();
    });

    testWidgets('petunjuk posisi memakai bahasa aplikasi: "Tab 2 dari 5"', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 390, tinggi: 800);
      await tester.pumpWidget(_app(bahasaId: true));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Alat')).hint,
        'Tab 2 dari 5',
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Akun')).hint,
        'Tab 5 dari 5',
      );
      semantik.dispose();
    });
  });

  group('ketuk', () {
    testWidgets('ketuk tiap butir memanggil onPilih(indeks) tepat sekali', (
      tester,
    ) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      final dipilih = <int>[];
      await tester.pumpWidget(_app(onPilih: dipilih.add));
      await tester.pumpAndSettle();
      for (var i = 0; i < _nama.length; i++) {
        await tester.tap(_teks(_nama[i]));
        await tester.pump();
        expect(dipilih, hasLength(i + 1), reason: _nama[i]);
        expect(dipilih.last, i, reason: _nama[i]);
      }
    });

    testWidgets('seluruh sel butir menerima ketukan, tepi ke tepi, dan area '
        'sentuhnya >= 48 dp', (tester) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      final dipilih = <int>[];
      await tester.pumpWidget(_app(onPilih: dipilih.add));
      await tester.pumpAndSettle();
      final sel = _sel(tester, 1);
      expect(sel.width, greaterThanOrEqualTo(48));
      expect(sel.height, greaterThanOrEqualTo(48));
      await tester.tapAt(sel.topLeft + const Offset(1, 1));
      await tester.tapAt(sel.bottomRight - const Offset(1, 1));
      expect(dipilih, [1, 1]);
    });
  });

  group('lencana notifikasi', () {
    testWidgets('angka, "99+", merah galat, tanpa lencana bila 0; label '
        'baca memuat jumlahnya', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 390, tinggi: 800);
      await tester.pumpWidget(_app(lencana: 3));
      await tester.pumpAndSettle();
      final s = TemaSidik.terang.colorScheme;
      final lencana = tester.widget<Badge>(find.byType(Badge));
      expect(lencana.backgroundColor, s.error);
      expect(lencana.textColor, s.onError);
      expect((lencana.label! as Text).data, '3');
      expect(
        rasioKontras(s.onError, s.error),
        greaterThanOrEqualTo(4.5),
        reason: 'angka lencana terbaca',
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Notifikasi, 3 belum dibaca'),
        ),
        matchesSemantics(
          label: 'Notifikasi, 3 belum dibaca',
          hint: _petunjuk(3),
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );

      await tester.pumpWidget(_app(lencana: 120));
      await tester.pumpAndSettle();
      expect(find.text('99+'), findsOneWidget);

      // Batas: 99 tampil apa adanya, 100 menjadi "99+" (bukan 101 atau 100).
      for (final (jumlah, teks) in [
        (1, '1'),
        (98, '98'),
        (99, '99'),
        (100, '99+'),
        (101, '99+'),
      ]) {
        await tester.pumpWidget(_app(lencana: jumlah));
        await tester.pumpAndSettle();
        expect(
          (tester.widget<Badge>(find.byType(Badge)).label! as Text).data,
          teks,
          reason: 'lencana untuk $jumlah',
        );
      }

      await tester.pumpWidget(_app(lencana: 0));
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNothing);
      semantik.dispose();
    });

    for (final lebar in [390.0, 360.0, 320.0]) {
      for (final aktif in [false, true]) {
        testWidgets('${lebar.toInt()} dp, huruf 1,3x, tab Notifikasi '
            '${aktif ? 'aktif' : 'tidak aktif'}: "99+" utuh di dalam layar', (
          tester,
        ) async {
          layarHp(tester, lebar: lebar, tinggi: 640);
          await tester.pumpWidget(
            _app(indeks: aktif ? 3 : 0, skala: 1.3, lencana: 120),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final angka = tester.getRect(find.text('99+'));
          expect(
            _memuat(Offset.zero & Size(lebar, 640), angka),
            isTrue,
            reason: 'lencana di dalam layar: $angka',
          );
          expect(_memuat(tester.getRect(_bilah), angka), isTrue);
          // Lencana menempel di sudut kanan atas ikon Notifikasi.
          final ikon = tester.getRect(
            find.descendant(
              of: _bilah,
              matching: find.byIcon(
                aktif ? Icons.notifications : Icons.notifications_none,
              ),
            ),
          );
          expect(angka.center.dy, lessThan(ikon.center.dy));
          expect(angka.center.dx, greaterThan(ikon.center.dx));
        });
      }
    }
  });

  group('lebar dan huruf', () {
    for (final lebar in [320.0, 340.0, 360.0, 390.0, 411.0, 599.0]) {
      for (final skala in [1.0, 1.3, 2.0]) {
        testWidgets('${lebar.toInt()} dp, huruf ${skala}x: lima butir sama '
            'lebar, label utuh dan satu baris, tanpa overflow', (tester) async {
          layarHp(tester, lebar: lebar, tinggi: 640);
          for (var aktif = 0; aktif < _nama.length; aktif++) {
            await tester.pumpWidget(
              _app(indeks: aktif, skala: skala, lencana: 12),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'tab $aktif');
            expect(
              find.byType(NavigationBar),
              findsNothing,
              reason: 'HP memakai bilah sendiri, bukan NavigationBar',
            );
            final bilah = tester.getRect(_bilah);
            expect(bilah.width, lebar);
            for (var i = 0; i < _nama.length; i++) {
              final sel = _sel(tester, i);
              expect(sel.width, closeTo(lebar / 5, 0.01));
              expect(sel.height, greaterThanOrEqualTo(48));
              final label = tester.getRect(_teks(_nama[i]));
              // Label utuh: seluruhnya di dalam selnya (tidak terpotong,
              // tidak menimpa butir sebelah), satu baris.
              expect(
                _memuat(sel, label),
                isTrue,
                reason: '${_nama[i]} di ${lebar}dp/${skala}x: $label di $sel',
              );
              expect(label.height, lessThan(30), reason: 'satu baris');
              expect(
                tester.widget<Text>(_teks(_nama[i])).overflow,
                isNull,
                reason: 'label tidak boleh dielipsis',
              );
              // Ukuran efektif tidak mengecil di bawah 11 sp (huruf 12 sp x
              // skala x pengecilan FittedBox).
              final efektif =
                  tester.getSize(_teks(_nama[i])).height /
                  (tester.widget<Text>(_teks(_nama[i])).style!.height ?? 1);
              expect(efektif, greaterThanOrEqualTo(11), reason: _nama[i]);
            }
          }
        });
      }
    }

    testWidgets('huruf sistem 2,0x dijepit 1,3x: bilah tidak lebih tinggi '
        'daripada pada 1,3x', (tester) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      await tester.pumpWidget(_app(skala: 1.3));
      await tester.pumpAndSettle();
      final tinggi13 = tester.getRect(_bilah).height;
      await tester.pumpWidget(_app(skala: 2.0));
      await tester.pumpAndSettle();
      expect(tester.getRect(_bilah).height, tinggi13);
    });

    testWidgets('tinggi isi bilah 64 dp pada huruf 1,0x', (tester) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(tester.getRect(_bilah).height, UkuranBilah.tinggi);
    });
  });

  group('label tidak terpotong (lebar alami <= sel)', () {
    // `softWrap: false` menjepit ukuran kotak Text ke sel, jadi pemeriksaan
    // "label di dalam sel" tidak pernah gagal. Yang diukur di sini LEBAR ALAMI
    // paragraf (`getMaxIntrinsicWidth`): kalau melebihi sel, kata terpotong.
    for (final lebar in [320.0, 360.0, 392.0]) {
      for (final skala in [1.0, 1.3, 2.0]) {
        testWidgets('${lebar.toInt()} dp, huruf ${skala}x: lebar alami '
            'tiap label (dalam berat terpilih) <= sel, di setiap tab aktif', (
          tester,
        ) async {
          layarHp(tester, lebar: lebar, tinggi: 640);
          for (var aktif = 0; aktif < _nama.length; aktif++) {
            await tester.pumpWidget(_app(indeks: aktif, skala: skala));
            await tester.pumpAndSettle();
            final sel = _sel(tester, 0).width;
            for (final n in _nama) {
              final p = tester.renderObject<RenderParagraph>(_teks(n));
              final alami = p.getMaxIntrinsicWidth(double.infinity);
              expect(
                alami,
                lessThanOrEqualTo(sel),
                reason:
                    '$n terpotong di ${lebar}dp/${skala}x tab $aktif: '
                    'lebar alami $alami > sel $sel',
              );
            }
          }
        });
      }
    }
  });

  group('ukuran label seragam', () {
    for (final lebar in [320.0, 340.0, 360.0, 390.0]) {
      testWidgets('${lebar.toInt()} dp, huruf 1,3x: kelima label sama besar '
          '(satu faktor pengecil untuk semua), tidak di bawah 12 sp efektif, '
          'dan tetap sama saat tab berganti', (tester) async {
        layarHp(tester, lebar: lebar, tinggi: 640);
        double tinggiLabel(String n) => tester.getSize(_teks(n)).height;
        for (var aktif = 0; aktif < _nama.length; aktif++) {
          await tester.pumpWidget(_app(indeks: aktif, skala: 1.3));
          await tester.pumpAndSettle();
          final tinggi = [for (final n in _nama) tinggiLabel(n)];
          for (final t in tinggi) {
            expect(
              t,
              closeTo(tinggi.first, 0.01),
              reason: 'tab $aktif: $tinggi',
            );
          }
          // 12 sp x 16/12 baris: tinggi >= 16 berarti ukuran efektif >= 12 sp.
          expect(tinggi.first, greaterThanOrEqualTo(16 - 0.01));
        }
      });
    }

    testWidgets('lebar longgar: label memakai skala sistem penuh (1,3x), '
        'tidak dikecilkan', (tester) async {
      layarHp(tester, lebar: 599, tinggi: 640);
      await tester.pumpWidget(_app(skala: 1.3));
      await tester.pumpAndSettle();
      // 12 sp x 1,3 x baris 16/12 = 20,8.
      expect(tester.getSize(_teks('Akun')).height, closeTo(20.8, 0.3));
    });
  });

  group('papan ketik', () {
    for (final gelap in [false, true]) {
      testWidgets('cincin fokus di luar butir, warna primary >= 3:1 terhadap '
          'permukaan (${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 390, tinggi: 800);
        final dipilih = <int>[];
        await tester.pumpWidget(_app(gelap: gelap, onPilih: dipilih.add));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        final cincin = find.byKey(CincinFokus.kunciCincin);
        expect(cincin, findsOneWidget, reason: 'cincin tidak tampil');
        final s = (gelap ? TemaSidik.gelap : TemaSidik.terang).colorScheme;
        final garis =
            ((tester.widget<DecoratedBox>(cincin).decoration as BoxDecoration)
                        .border!
                    as Border)
                .top;
        expect(garis.width, UkuranFokus.tebal);
        expect(garis.color, s.primary);
        expect(rasioKontras(garis.color, s.surface), greaterThanOrEqualTo(3));
        // Mengelilingi butir pertama dengan celah.
        expect(
          tester.getRect(cincin),
          _sel(tester, 0).inflate(UkuranFokus.jarakLuar),
        );

        // Tab berikutnya pindah butir; Enter memilihnya.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(dipilih, [1]);
      });
    }
  });

  group('ruang isi: bilah, banner pembaruan, dan tepi sistem', () {
    Widget isiBergulir(Key kunciAkhir) => Builder(
      builder: (context) => ListView(
        // Bawah daftar: tepi sistem yang diberikan NavigasiUtama (harus 0
        // karena bilah sudah memakainya).
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        children: [
          for (var i = 0; i < 30; i++)
            SizedBox(height: 80, child: Text('baris $i')),
          SizedBox(key: kunciAkhir, height: 80, child: const Text('akhir')),
        ],
      ),
    );

    testWidgets('butir terakhir daftar berhenti tepat di atas bilah '
        '(tidak tertutup)', (tester) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      const akhir = ValueKey('akhir');
      await tester.pumpWidget(_app(tepi: 34, isi: isiBergulir(akhir)));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pumpAndSettle();

      final bilah = tester.getRect(_bilah);
      final terakhir = tester.getRect(find.byKey(akhir));
      expect(terakhir.bottom, lessThanOrEqualTo(bilah.top));
      expect(
        tester.getRect(find.byType(ListView)).bottom,
        bilah.top,
        reason: 'area isi berakhir tepat di garis atas bilah',
      );
      expect(bilah.top, 800 - bilah.height);
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

    testWidgets('banner pembaruan duduk TEPAT di atas bilah, isi di atas '
        'banner, banner selebar layar', (tester) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      const banner = ValueKey('banner');
      await tester.pumpWidget(
        _app(
          tepi: 34,
          isi: const ColoredBox(key: ValueKey('isi'), color: Colors.white),
          penutup: const SizedBox(
            key: banner,
            width: double.infinity,
            height: 56,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bilah = tester.getRect(_bilah);
      final b = tester.getRect(find.byKey(banner));
      final isi = tester.getRect(find.byKey(const ValueKey('isi')));
      expect(b.bottom, bilah.top, reason: 'banner menempel di atas bilah');
      expect(isi.bottom, b.top, reason: 'isi berakhir di atas banner');
      expect(b.width, 390);
      expect(b.height, 56);
      expect(isi.top, 0);
    });

    testWidgets('tanpa banner isi langsung di atas bilah; dengan banner isi '
        'menyusut sebesar tinggi banner', (tester) async {
      layarHp(tester, lebar: 390, tinggi: 800);
      const isiKunci = ValueKey('isi');
      const isi = ColoredBox(key: isiKunci, color: Colors.white);
      await tester.pumpWidget(_app(isi: isi));
      await tester.pumpAndSettle();
      final tanpa = tester.getRect(find.byKey(isiKunci));
      await tester.pumpWidget(
        _app(
          isi: isi,
          penutup: const SizedBox(width: double.infinity, height: 56),
        ),
      );
      await tester.pumpAndSettle();
      final dengan = tester.getRect(find.byKey(isiKunci));
      expect(tanpa.bottom, tester.getRect(_bilah).top);
      expect(dengan.height, tanpa.height - 56);
    });
  });

  group('papan ketik terbuka', () {
    testWidgets('bilah DAN banner disembunyikan, isi mengisi sampai bawah; '
        'tertutup lagi = kembali', (tester) async {
      layarHp(tester, lebar: 360, tinggi: 800);
      const isi = ColoredBox(key: ValueKey('isi'), color: Colors.white);
      const banner = SizedBox(
        key: ValueKey('banner'),
        width: double.infinity,
        height: 56,
      );
      await tester.pumpWidget(_app(isi: isi, penutup: banner, tepi: 24));
      await tester.pumpAndSettle();
      expect(_bilah, findsOneWidget);
      expect(find.byKey(const ValueKey('banner')), findsOneWidget);
      final tinggiNormal = tester
          .getSize(find.byKey(const ValueKey('isi')))
          .height;

      await tester.pumpWidget(
        _app(isi: isi, penutup: banner, tepi: 24, papanKetik: true),
      );
      await tester.pumpAndSettle();
      expect(_bilah, findsNothing, reason: 'bilah disembunyikan');
      expect(find.byKey(const ValueKey('banner')), findsNothing);
      // Isi memakai ruang bilah + banner + tepi (64 + 24 + 56 = 144 dp).
      expect(
        tester.getSize(find.byKey(const ValueKey('isi'))).height,
        tinggiNormal + 56 + 24 + UkuranBilah.tinggi,
      );

      await tester.pumpWidget(_app(isi: isi, penutup: banner, tepi: 24));
      await tester.pumpAndSettle();
      expect(_bilah, findsOneWidget);
      expect(find.byKey(const ValueKey('banner')), findsOneWidget);
    });

    testWidgets('keadaan isi (teks yang sedang diketik) tidak hilang waktu '
        'bilah hilang dan muncul', (tester) async {
      layarHp(tester, lebar: 360, tinggi: 800);
      const isi = TextField(key: ValueKey('isian'));
      await tester.pumpWidget(_app(isi: isi));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('isian')), 'ORD/0021');
      await tester.pumpWidget(_app(isi: isi, papanKetik: true));
      await tester.pumpAndSettle();
      expect(find.text('ORD/0021'), findsOneWidget);
      await tester.pumpWidget(_app(isi: isi));
      await tester.pumpAndSettle();
      expect(find.text('ORD/0021'), findsOneWidget);
      expect(_bilah, findsOneWidget);
    });

    testWidgets('rel >= 600 dp tidak terpengaruh papan ketik', (tester) async {
      layarHp(tester, lebar: 840, tinggi: 800);
      await tester.pumpWidget(_app(papanKetik: true));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });

  group('rel >= 600 dp tetap', () {
    for (final lebar in [600.0, 840.0]) {
      testWidgets('${lebar.toInt()} dp: rel samping lima tujuan, tanpa '
          'bilah, tanpa pita bawah', (tester) async {
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
        expect(_bilah, findsNothing);
        final rel = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rel.destinations, hasLength(5));
        expect(rel.selectedIndex, 2);
        expect(rel.labelType, NavigationRailLabelType.all);
        // Indikator rel memakai biru muda tema.
        expect(
          TemaSidik.terang.navigationRailTheme.indicatorColor,
          TemaSidik.terang.colorScheme.primaryContainer,
        );
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
        // Isi mengisi tinggi penuh di kanan rel (tidak ada pita bawah).
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

  test('token bilah: tinggi 64, ikon 24, indikator 56 x 32', () {
    expect(UkuranBilah.tinggi, 64);
    expect(UkuranBilah.ikon, 24);
    expect(UkuranBilah.indikatorLebar, 56);
    expect(UkuranBilah.indikatorTinggi, 32);
    expect(UkuranBilah.skalaLabel, 1.3);
    // Jarak di dalam butir memakai token jarak.
    expect(
      Spasi.sm + UkuranBilah.indikatorTinggi + Spasi.xs + 16 + Spasi.xs,
      UkuranBilah.tinggi,
    );
  });
}
