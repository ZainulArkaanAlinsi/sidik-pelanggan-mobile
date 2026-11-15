// Komponen Bento Lab (P2), bagian ubin: warna ubin dan tinta yang dipisah dari
// tinta halaman (WarnaSidik), Stempel pil 30, UbinAlat, UbinRingkas, UbinMenu,
// PanelSidik 28, dan gerbang token pada berkas baru. Diuji di terang dan
// gelap, ukuran dari token, seluruh ubin bisa diketuk, label baca, cincin
// fokus, "kurangi gerak", dan 320 dp x huruf 1,3 tanpa luapan.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/motion/gerak_bento.dart';
import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/palet_sidik.dart';
import 'package:sidik_pelanggan/core/tema/spasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/models/status_berlaku.dart';
import 'package:sidik_pelanggan/widgets/dasar/cincin_fokus.dart';
import 'package:sidik_pelanggan/widgets/panel_sidik.dart';
import 'package:sidik_pelanggan/widgets/pemetaan_status.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';
import 'package:sidik_pelanggan/widgets/stempel.dart';
import 'package:sidik_pelanggan/widgets/tombol_bulat.dart';
import 'package:sidik_pelanggan/widgets/ubin_alat.dart';
import 'package:sidik_pelanggan/widgets/ubin_menu.dart';
import 'package:sidik_pelanggan/widgets/ubin_ringkas.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/layar_uji.dart';
import '../dukungan/pemindai_token.dart';
import '../dukungan/ukur_komponen.dart';

ThemeData _tema(bool gelap) => gelap ? TemaSidik.gelap : TemaSidik.terang;
ColorScheme _skema(bool gelap) => _tema(gelap).colorScheme;
WarnaSidik _w(bool gelap) => _tema(gelap).extension<WarnaSidik>()!;

const _visual = Key('visual');
const _nadaSemua = NadaStatus.values;

/// Satu status contoh untuk tiap nada.
StatusTampil _status(NadaStatus n) => switch (n) {
  NadaStatus.gagal => statusAlat(StatusKalibrasi.lewat),
  NadaStatus.awas => statusBerlaku(StatusBerlaku.segera),
  NadaStatus.lulus => statusBerlaku(StatusBerlaku.berlaku),
  NadaStatus.tunggu => statusBerlaku(StatusBerlaku.diproses),
  NadaStatus.netral => statusBerlaku(StatusBerlaku.tidakAktif),
};

Color _latarUbin(NadaStatus n, bool gelap) {
  final w = _w(gelap);
  return switch (n) {
    NadaStatus.gagal => w.ubinGagal,
    NadaStatus.awas => w.ubinAwas,
    NadaStatus.lulus => w.ubinLulus,
    NadaStatus.tunggu => w.ubinTunggu,
    NadaStatus.netral => _skema(gelap).surface,
  };
}

void _kurangiGerak(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

/// Bahan (latar) ubin: Material terluar di bawah [ubin].
Finder _bahan(Finder ubin) =>
    find.descendant(of: ubin, matching: find.byType(Material)).first;

/// Aplikasi uji dengan margin halaman 16 dan huruf [skala].
Widget _app(Widget anak, {bool gelap = false, double skala = 1}) =>
    aplikasiUji(anak, gelap: gelap, skala: skala);

Widget _visualUji() =>
    const SizedBox.expand(key: _visual, child: ColoredBox(color: Colors.transparent));

void _periksaCincin(WidgetTester tester, Rect isi, {required bool gelap}) {
  final cincin = find.byKey(CincinFokus.kunciCincin);
  expect(cincin, findsOneWidget, reason: 'cincin fokus tidak tampil');
  expect(tester.getRect(cincin), isi.inflate(UkuranFokus.jarakLuar));
  final dekor = tester.widget<DecoratedBox>(cincin).decoration as BoxDecoration;
  final garis = (dekor.border! as Border).top;
  expect(garis.color, _skema(gelap).primary);
  expect(garis.width, UkuranFokus.tebal);
  expect(
    rasioKontras(garis.color, _tema(gelap).scaffoldBackgroundColor),
    greaterThanOrEqualTo(3),
  );
}

UbinAlat _ubinAlat({
  String nama = 'Oven Memmert',
  NadaStatus nada = NadaStatus.gagal,
  int? hari = -4,
  bool beranda = false,
  bool adaVisual = true,
  VoidCallback? onTap,
  String? semantik,
  int? urutan,
  String? merkTipe = 'Memmert UF55',
  String? serial = 'SN-0457-2201',
  String? tanggal = '9 Nov 2026',
}) => UbinAlat(
  nama: nama,
  status: _status(nada),
  merkTipe: merkTipe,
  serial: serial,
  hari: hari,
  tanggal: tanggal,
  beranda: beranda,
  visual: adaVisual ? _visualUji() : null,
  onTap: onTap ?? () {},
  semantik: semantik,
  urutan: urutan,
);

void main() {
  setUpAll(siapkanTesFitur);

  group('WarnaSidik: tinta UBIN dipisah dari tinta HALAMAN', () {
    test('ubin pastel dan tinta navy sama di terang dan gelap', () {
      final t = _w(false);
      final g = _w(true);
      expect(t.ubinGagal, PaletSidik.koral);
      expect(t.ubinAwas, PaletSidik.kuning);
      expect(t.ubinLulus, PaletSidik.hijau);
      expect(t.ubinTunggu, PaletSidik.langit);
      expect(t.tintaUbin, PaletSidik.navy);
      expect(t.kertasUbin, PaletSidik.kartu);
      for (final (a, b) in [
        (t.ubinGagal, g.ubinGagal),
        (t.ubinAwas, g.ubinAwas),
        (t.ubinLulus, g.ubinLulus),
        (t.ubinTunggu, g.ubinTunggu),
        (t.tintaUbin, g.tintaUbin),
        (t.kertasUbin, g.kertasUbin),
      ]) {
        expect(a, b, reason: 'ubin tetap terang di mode gelap');
      }
    });

    test('tinta HALAMAN gelap tetap pastel dan berbeda dari tinta ubin', () {
      final g = _w(true);
      expect(g.lulus, PaletSidik.hijau);
      expect(g.gagal, PaletSidik.koral);
      for (final tinta in [g.lulus, g.awas, g.gagal, g.tunggu]) {
        expect(tinta, isNot(g.tintaUbin));
        expect(
          rasioKontras(tinta, _skema(true).surface),
          greaterThanOrEqualTo(4.5),
          reason: 'teks status di halaman gelap',
        );
      }
    });

    for (final gelap in [false, true]) {
      test('tinta ubin di atas tiap ubin >= 7:1, putih/navy >= 7:1 '
          '(${gelap ? 'gelap' : 'terang'})', () {
        final w = _w(gelap);
        for (final latar in [
          w.ubinGagal,
          w.ubinAwas,
          w.ubinLulus,
          w.ubinTunggu,
          w.kertasUbin,
        ]) {
          expect(rasioKontras(w.tintaUbin, latar), greaterThanOrEqualTo(7));
        }
        expect(
          rasioKontras(w.kertasUbin, w.tintaUbin),
          greaterThanOrEqualTo(7),
          reason: 'stempel gagal: putih di atas navy',
        );
      });
    }

    test('copyWith dan lerp membawa kolom ubin', () {
      final t = _w(false);
      final w = t.copyWith(ubinGagal: PaletSidik.garis, tintaUbin: PaletSidik.teksKedua);
      expect(w.ubinGagal, PaletSidik.garis);
      expect(w.tintaUbin, PaletSidik.teksKedua);
      expect(w.ubinLulus, t.ubinLulus);
      final tengah = t.lerp(w, 1);
      expect(tengah.ubinGagal, PaletSidik.garis);
      expect(tengah.tintaUbin, PaletSidik.teksKedua);
    });

    testWidgets('StatusTampil: ubin, ubinDari, diAtasUbin untuk tiap nada', (
      tester,
    ) async {
      for (final gelap in [false, true]) {
        late BuildContext konteks;
        await tester.pumpWidget(
          aplikasiUji(
            Builder(
              builder: (c) {
                konteks = c;
                return const SizedBox();
              },
            ),
            gelap: gelap,
          ),
        );
        // Ganti tema dianimasikan MaterialApp: tunggu sampai selesai.
        await tester.pumpAndSettle();
        final w = _w(gelap);
        for (final n in _nadaSemua) {
          final (tinta, latar) = StatusTampil.ubinDari(konteks, n);
          expect(latar, _latarUbin(n, gelap), reason: '$n gelap=$gelap');
          expect(
            tinta,
            n == NadaStatus.netral ? _skema(gelap).onSurface : w.tintaUbin,
          );
          final (tintaStempel, latarStempel) = _status(n).diAtasUbin(konteks);
          switch (n) {
            case NadaStatus.gagal:
              expect((tintaStempel, latarStempel), (w.kertasUbin, w.tintaUbin));
            case NadaStatus.netral:
              expect(
                (tintaStempel, latarStempel),
                (_skema(gelap).onSurfaceVariant, _skema(gelap).surfaceContainerHigh),
              );
            default:
              expect((tintaStempel, latarStempel), (w.tintaUbin, w.kertasUbin));
          }
          expect(
            rasioKontras(tintaStempel, latarStempel),
            greaterThanOrEqualTo(4.5),
            reason: 'stempel $n di atas ubin (gelap=$gelap)',
          );
        }
      }
    });
  });

  group('Stempel pil', () {
    testWidgets('tinggi 30, sudut 15, padding 12, ikon 14, jarak 6, 12/700', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(Stempel(statusAlat(StatusKalibrasi.lewat))),
      );
      final kotak = tester.getRect(find.byType(Stempel));
      expect(kotak.height, UkuranKontrol.stempel);
      expect(UkuranKontrol.stempel, 30);
      expect(Bentuk.stempel, 15);
      final dekor = tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byType(Stempel),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration as BoxDecoration;
      expect(dekor.borderRadius, BorderRadius.circular(15));
      final ikon = tester.getRect(find.byType(Icon));
      final kata = tester.getRect(find.text('Lewat jadwal'));
      expect(ikon.left - kotak.left, 12);
      expect(ikon.size, const Size.square(14));
      expect(kata.left - ikon.right, 6);
      expect(kotak.right - kata.right, 12);
      final gaya = tester.widget<Text>(find.text('Lewat jadwal')).style!;
      expect(gaya.fontSize, 12);
      expect(gaya.fontWeight, FontWeight.w700);
    });

    for (final gelap in [false, true]) {
      testWidgets('latar = warna ubin status, tinta navy di dua tema; tenang = '
          'tinta halaman tanpa latar (${gelap ? 'gelap' : 'terang'})', (
        tester,
      ) async {
        final w = _w(gelap);
        for (final n in _nadaSemua) {
          await tester.pumpWidget(_app(Stempel(_status(n)), gelap: gelap));
          final dekor = tester
              .widget<DecoratedBox>(
                find.descendant(
                  of: find.byType(Stempel),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .decoration as BoxDecoration;
          final harapanLatar = n == NadaStatus.netral
              ? _skema(gelap).surfaceContainerHigh
              : _latarUbin(n, gelap);
          // Netral memakai pasangan netral halaman; empat nada = pastel ubin.
          if (n != NadaStatus.netral) {
            expect(dekor.color, harapanLatar, reason: '$n');
            expect(
              tester.widget<Icon>(find.byType(Icon)).color,
              w.tintaUbin,
              reason: '$n: ikon navy',
            );
          }
          expect(
            pelanggaranKontrasTeks(tester, find.byType(Stempel)),
            isEmpty,
            reason: '$n gelap=$gelap',
          );
          // Tenang: tanpa latar, tinta halaman (pastel di gelap).
          await tester.pumpWidget(
            _app(Stempel(_status(n), tenang: true), gelap: gelap),
          );
          final tenang = tester
              .widget<DecoratedBox>(
                find.descendant(
                  of: find.byType(Stempel),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .decoration as BoxDecoration;
          expect(tenang.color, isNull);
          if (n == NadaStatus.lulus) {
            expect(tester.widget<Icon>(find.byType(Icon)).color, w.lulus);
          }
        }
      });
    }

    for (final gelap in [false, true]) {
      testWidgets('diAtasUbin: gagal navy + putih, lainnya putih + navy; '
          'tenang mengabaikannya (${gelap ? 'gelap' : 'terang'})', (
        tester,
      ) async {
        final w = _w(gelap);
        for (final n in [
          NadaStatus.gagal,
          NadaStatus.awas,
          NadaStatus.lulus,
          NadaStatus.tunggu,
        ]) {
          await tester.pumpWidget(
            _app(Stempel(_status(n), diAtasUbin: true), gelap: gelap),
          );
          final dekor = tester
              .widget<DecoratedBox>(
                find.descendant(
                  of: find.byType(Stempel),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .decoration as BoxDecoration;
          final gagal = n == NadaStatus.gagal;
          expect(dekor.color, gagal ? w.tintaUbin : w.kertasUbin, reason: '$n');
          final ikon = tester.widget<Icon>(find.byType(Icon)).color;
          expect(ikon, gagal ? w.kertasUbin : w.tintaUbin, reason: '$n: ikon');
          expect(
            tester.widget<Text>(find.text(_status(n).label)).style!.color,
            ikon,
          );
          expect(
            pelanggaranKontrasTeks(tester, find.byType(Stempel)),
            isEmpty,
            reason: '$n',
          );
        }
        await tester.pumpWidget(
          _app(
            Stempel(_status(NadaStatus.gagal), tenang: true, diAtasUbin: true),
            gelap: gelap,
          ),
        );
        expect(
          tester.widget<Icon>(find.byType(Icon)).color,
          w.gagal,
          reason: 'tenang memakai tinta halaman',
        );
      });
    }

    testWidgets('kata panjang di 320 dp x 1,3: pil tumbuh ke bawah, tetap '
        'sudut 15, tanpa luapan', (tester) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        _app(
          const Stempel(
            StatusTampil(
              'Sertifikat ini telah digantikan oleh revisi yang lebih baru',
              NadaStatus.awas,
              Icons.swap_horiz,
            ),
          ),
          skala: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      final r = tester.getRect(find.byType(Stempel));
      expect(r.height, greaterThan(UkuranKontrol.stempel));
      expect(r.width, lessThanOrEqualTo(320 - 2 * Spasi.sisi));
    });
  });

  group('UbinAlat', () {
    for (final gelap in [false, true]) {
      testWidgets('warna ubin dari status di dua tema; teks navy >= 4,5:1 '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        for (final n in _nadaSemua) {
          await tester.pumpWidget(_app(_ubinAlat(nada: n), gelap: gelap));
          final bahan = tester.widget<Material>(_bahan(find.byType(UbinAlat)));
          expect(bahan.color, _latarUbin(n, gelap), reason: '$n gelap=$gelap');
          expect(
            (bahan.shape! as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(32),
          );
          expect(bahan.clipBehavior, Clip.antiAlias, reason: 'visual dipotong');
          expect(
            pelanggaranKontrasTeks(tester, find.byType(UbinAlat)),
            isEmpty,
            reason: '$n gelap=$gelap',
          );
          final nama = tester.widget<Text>(find.text('Oven Memmert')).style!;
          expect(
            nama.color,
            n == NadaStatus.netral
                ? _skema(gelap).onSurface
                : _w(gelap).tintaUbin,
            reason: 'teks ubin memakai tinta ubin, bukan tinta halaman',
          );
        }
      });
    }

    testWidgets('tinggi minimum 196 / 232, padding 18, stempel di kiri atas, '
        'isi tidak dikunci', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 900);
      await tester.pumpWidget(_app(_ubinAlat()));
      var tile = tester.getRect(find.byType(UbinAlat));
      expect(tile.height, UkuranUbin.alat);
      expect(tile.width, 392 - 32);
      final stempel = tester.getRect(find.byType(Stempel));
      expect(stempel.left - tile.left, 18);
      expect(stempel.top - tile.top, 18);
      expect(stempel.height, 30);
      // Nama pendek: visual 176 memakan lebar, nama panjang membungkus dan
      // menambah tinggi (minimum tetap 232).
      await tester.pumpWidget(_app(_ubinAlat(beranda: true, nama: 'Oven')));
      tile = tester.getRect(find.byType(UbinAlat));
      expect(tile.height, UkuranUbin.alatBeranda);
      // Huruf 1,3 dan nama panjang: tumbuh melewati minimum.
      layarHp(tester, lebar: 320, tinggi: 900);
      await tester.pumpWidget(
        _app(
          _ubinAlat(
            nama: 'Timbangan Analitik Presisi Tinggi Laboratorium Pusat',
            merkTipe: 'Mettler Toledo XPR205 Seri Lengkap',
            serial: 'B419223017-ABCD',
          ),
          skala: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(UbinAlat)).height,
        greaterThan(UkuranUbin.alat),
      );
    });

    testWidgets('isi: nama 22 maks 2 baris, merk 14, seri 14 nomor sendiri, '
        'angka 44 (Beranda 64), kata 12/700, tanggal 12/500', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 900);
      await tester.pumpWidget(_app(_ubinAlat()));
      final nama = tester.widget<Text>(find.text('Oven Memmert'));
      expect(nama.style!.fontSize, 22);
      expect(nama.maxLines, 2);
      expect(nama.overflow, TextOverflow.ellipsis);
      expect(tester.widget<Text>(find.text('Memmert UF55')).style!.fontSize, 14);
      final seri = tester.widget<Text>(find.text('SN-0457-2201')).style!;
      expect(seri.fontSize, 14);
      expect(seri.fontFeatures, contains(const FontFeature.slashedZero()));
      final merk = tester.getRect(find.text('Memmert UF55'));
      final nomor = tester.getRect(find.text('SN-0457-2201'));
      expect(nomor.top, greaterThanOrEqualTo(merk.bottom), reason: 'baris sendiri');
      expect(tester.widget<Text>(find.text('4')).style!.fontSize, 44);
      expect(find.text('hari lewat'), findsOneWidget);
      final kata = tester.widget<Text>(find.text('hari lewat')).style!;
      expect(kata.fontSize, 12);
      expect(kata.fontWeight, FontWeight.w700);
      final tgl = tester.widget<Text>(find.text('9 Nov 2026')).style!;
      expect(tgl.fontSize, 12);
      expect(tgl.fontWeight, FontWeight.w500);
      await tester.pumpWidget(_app(_ubinAlat(beranda: true)));
      expect(tester.widget<Text>(find.text('4')).style!.fontSize, 64);
      // Tanpa jadwal dan tanpa data: tanda "–" dan kata tanpa angka palsu.
      await tester.pumpWidget(
        _app(
          _ubinAlat(
            nada: NadaStatus.netral,
            hari: null,
            merkTipe: null,
            serial: null,
            tanggal: null,
          ),
        ),
      );
      expect(find.text('–'), findsOneWidget);
      expect(find.text('belum ada jadwal'), findsOneWidget);
      expect(find.text('Memmert UF55'), findsNothing);
      await tester.pumpWidget(_app(_ubinAlat(hari: 12)));
      expect(find.text('12'), findsOneWidget);
      expect(find.text('hari lagi'), findsOneWidget);
    });

    testWidgets('nama panjang dipotong di dua baris, label baca membawa nama '
        'utuh', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 320, tinggi: 900);
      const panjang =
          'Alat Ukur Tekanan Digital Presisi Tinggi Untuk Laboratorium Pusat '
          'Dan Cabang Seluruh Indonesia';
      await tester.pumpWidget(_app(_ubinAlat(nama: panjang)));
      final p = tester.renderObject<RenderParagraph>(find.text(panjang));
      expect(p.maxLines, 2);
      expect(p.didExceedMaxLines, isTrue);
      expect(find.bySemanticsLabel(RegExp(panjang)), findsOneWidget);
      semantik.dispose();
    });

    for (final (lebar, skala, ukuran) in [
      (392.0, 1.0, UkuranVisual.alat),
      (320.0, 1.0, UkuranVisual.alatKompak),
      (392.0, 1.0, UkuranVisual.alatBeranda),
    ]) {
      testWidgets('visual $ukuran di kanan bawah: keluar 10 dari kanan dan 20 '
          'dari bawah, dipotong ubin, tidak menimpa teks (lebar $lebar)', (
        tester,
      ) async {
        layarHp(tester, lebar: lebar, tinggi: 900);
        final beranda = ukuran == UkuranVisual.alatBeranda;
        // Nama dan merk PANJANG: tanpa ruang yang dicadangkan, barisnya akan
        // membentang sampai ke kanan dan menabrak visual.
        const nama = 'Timbangan Analitik Presisi Tinggi';
        const merk = 'Mettler Toledo XPR205 Seri Lengkap';
        await tester.pumpWidget(
          _app(
            _ubinAlat(nama: nama, merkTipe: merk, beranda: beranda),
            skala: skala,
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        final tile = tester.getRect(find.byType(UbinAlat));
        final v = tester.getRect(find.byKey(_visual));
        expect(v.size, Size.square(ukuran));
        expect(v.right - tile.right, UkuranVisual.keluarSamping);
        expect(v.bottom - tile.bottom, UkuranVisual.keluarBawah);
        for (final teks in [
          find.text(nama),
          find.text(merk),
          find.text('SN-0457-2201'),
          find.text('4'),
          find.text('hari lewat'),
          find.text('9 Nov 2026'),
          find.byType(Stempel),
        ]) {
          expect(
            tester.getRect(teks).overlaps(v),
            isFalse,
            reason: 'visual tidak boleh menimpa teks',
          );
        }
      });
    }

    testWidgets('seluruh ubin satu tombol: ketukan di sudut, tengah, visual, '
        'dan stempel, tepat sekali', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 900);
      var n = 0;
      await tester.pumpWidget(_app(_ubinAlat(onTap: () => n++)));
      final r = tester.getRect(find.byType(UbinAlat));
      final titik = [
        r.topLeft + const Offset(14, 14),
        r.topRight + const Offset(-14, 14),
        r.bottomLeft + const Offset(14, -14),
        r.bottomRight + const Offset(-14, -14),
        r.center,
        tester.getCenter(find.byKey(_visual)).translate(-20, -20),
        tester.getCenter(find.byType(Stempel)),
        tester.getCenter(find.text('Oven Memmert')),
      ];
      for (final p in titik) {
        final sebelum = n;
        await tester.tapAt(p);
        expect(n, sebelum + 1, reason: 'ketukan di $p');
      }
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('semantik: kalimat bawaan dari isi, bisa diganti; label tetap '
        'ada pada ubin statis dan tombol berlabel bisa diaktifkan', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 900);
      var n = 0;
      await tester.pumpWidget(_app(_ubinAlat(onTap: () => n++)));
      const kalimat =
          'Oven Memmert. Status: Lewat jadwal. Memmert UF55. Nomor seri '
          'SN-0457-2201. Lewat 4 hari. 9 Nov 2026';
      expect(
        tester.getSemantics(find.bySemanticsLabel(kalimat)),
        matchesSemantics(label: kalimat, isButton: true, hasTapAction: true),
      );
      tester.semantics.tap(find.semantics.byLabel(kalimat));
      expect(n, 1);
      // Diganti pemanggil.
      await tester.pumpWidget(
        _app(_ubinAlat(onTap: () => n++, semantik: 'Buka Oven Memmert')),
      );
      expect(find.bySemanticsLabel('Buka Oven Memmert'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Status: ')), findsNothing);
      // Statis (tanpa onTap) dengan semantik: berlabel, bukan tombol.
      await tester.pumpWidget(
        _app(
          UbinAlat(
            nama: 'Oven Memmert',
            status: _status(NadaStatus.gagal),
            hari: -4,
            semantik: 'Ringkasan oven',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Ringkasan oven')),
        matchesSemantics(label: 'Ringkasan oven'),
      );
      expect(find.byType(InkWell), findsNothing);
      semantik.dispose();
    });

    testWidgets('ditekan: skala 0,97', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 900);
      await tester.pumpWidget(_app(_ubinAlat()));
      final skala = find.descendant(
        of: find.byType(UbinAlat),
        matching: find.byType(AnimatedScale),
      );
      expect(tester.widget<AnimatedScale>(skala).scale, 1);
      final g = await tester.startGesture(tester.getCenter(find.byType(UbinAlat)));
      await tester.pump();
      expect(tester.widget<AnimatedScale>(skala).scale, skalaTekan);
      await g.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.widget<AnimatedScale>(skala).scale, 1);
    });

    testWidgets('masuk berurutan hanya bila diminta; kurangi gerak = akhir', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 900);
      double opasitas() => tester
          .widget<FadeTransition>(
            find
                .descendant(
                  of: find.byType(UbinAlat),
                  matching: find.byType(FadeTransition),
                )
                .first,
          )
          .opacity
          .value;
      await tester.pumpWidget(_app(_ubinAlat(adaVisual: false, urutan: 2)));
      expect(opasitas(), 0);
      await tester.pump(const Duration(milliseconds: 70 + 260));
      expect(opasitas(), 1);
      await tester.pumpWidget(_app(_ubinAlat(adaVisual: false)));
      expect(
        find.descendant(
          of: find.byType(UbinAlat),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
        reason: 'tanpa urutan = tanpa animasi masuk',
      );
      _kurangiGerak(tester);
      await tester.pumpWidget(_app(_ubinAlat(adaVisual: false, urutan: 4)));
      expect(opasitas(), 1);
    });

    for (final gelap in [false, true]) {
      testWidgets('cincin fokus di luar ubin, 3:1, Enter mengaktifkan '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 392, tinggi: 900);
        var n = 0;
        await tester.pumpWidget(
          _app(_ubinAlat(onTap: () => n++), gelap: gelap),
        );
        expect(find.byKey(CincinFokus.kunciCincin), findsNothing);
        await _tab(tester);
        _periksaCincin(
          tester,
          tester.getRect(_bahan(find.byType(UbinAlat))),
          gelap: gelap,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(n, 1);
      });
    }

    for (final gelap in [false, true]) {
      testWidgets('320 dp x huruf 1,3, semua nada: tanpa luapan, kontras '
          'tetap (${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 320, tinggi: 1400);
        for (final n in _nadaSemua) {
          await tester.pumpWidget(
            _app(
              _ubinAlat(
                nada: n,
                nama: 'Timbangan Analitik Presisi Tinggi',
                hari: 128,
                beranda: true,
              ),
              gelap: gelap,
              skala: 1.3,
            ),
          );
          expect(tester.takeException(), isNull, reason: '$n');
          expect(
            pelanggaranKontrasTeks(tester, find.byType(UbinAlat)),
            isEmpty,
            reason: '$n',
          );
        }
      });
    }
  });

  group('UbinRingkas', () {
    UbinRingkas ringkas({
      NadaStatus nada = NadaStatus.awas,
      VoidCallback? onTap,
      bool adaVisual = true,
      String kalimat = 'Belum ada sertifikat yang terbit.',
    }) => UbinRingkas(
      judul: 'Sertifikat terbaru',
      kalimat: kalimat,
      aksi: 'Lihat semua',
      nada: nada,
      visual: adaVisual ? _visualUji() : null,
      onTap: onTap ?? () {},
    );

    for (final gelap in [false, true]) {
      testWidgets('188, sudut 28, padding 16, warna per nada, kontras '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 392, tinggi: 900);
        for (final n in _nadaSemua) {
          await tester.pumpWidget(
            _app(
              Row(
                children: [
                  Expanded(child: ringkas(nada: n)),
                  const SizedBox(width: Spasi.antarUbin),
                  Expanded(child: ringkas(nada: n)),
                ],
              ),
              gelap: gelap,
            ),
          );
          final tile = tester.getRect(find.byType(UbinRingkas).first);
          expect(tile.height, UkuranUbin.pasangan, reason: '$n');
          expect(tile.width, (392 - 32 - 12) / 2);
          final bahan = tester.widget<Material>(
            _bahan(find.byType(UbinRingkas).first),
          );
          expect(bahan.color, _latarUbin(n, gelap));
          expect(
            (bahan.shape! as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(28),
          );
          expect(
            pelanggaranKontrasTeks(tester, find.byType(UbinRingkas).first),
            isEmpty,
            reason: '$n gelap=$gelap',
          );
        }
      });
    }

    testWidgets('isi: judul 17, kalimat 14, "Lihat semua" 12 bergaris bawah di '
        'kiri bawah, visual 112 keluar 10', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 900);
      await tester.pumpWidget(
        _app(
          Row(
            children: [
              Expanded(child: ringkas()),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      final tile = tester.getRect(find.byType(UbinRingkas));
      final judul = tester.getRect(find.text('Sertifikat terbaru'));
      expect(judul.left - tile.left, 16);
      expect(judul.top - tile.top, closeTo(16, 4));
      expect(
        tester.widget<Text>(find.text('Sertifikat terbaru')).style!.fontSize,
        17,
      );
      expect(
        tester.widget<Text>(find.text('Belum ada sertifikat yang terbit.')).style!.fontSize,
        14,
      );
      final aksi = tester.widget<Text>(find.text('Lihat semua')).style!;
      expect(aksi.fontSize, 12);
      expect(aksi.decoration, TextDecoration.underline);
      final ra = tester.getRect(find.text('Lihat semua'));
      expect(ra.left - tile.left, 16);
      expect(tile.bottom - ra.bottom, closeTo(16, 4));
      final v = tester.getRect(find.byKey(_visual));
      expect(v.size, const Size.square(UkuranVisual.ubinKecil));
      expect(v.right - tile.right, UkuranVisual.keluarKecil);
      expect(v.bottom - tile.bottom, UkuranVisual.keluarKecil);
    });

    testWidgets('satu tombol, tidak bersarang; ketuk di sudut dan tengah; '
        'semantik bawaan; cincin fokus', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 900);
      var n = 0;
      await tester.pumpWidget(
        _app(Row(children: [Expanded(child: ringkas(onTap: () => n++)), const Expanded(child: SizedBox())])),
      );
      expect(find.byType(InkWell), findsOneWidget);
      final r = tester.getRect(find.byType(UbinRingkas));
      for (final p in [
        r.topLeft + const Offset(14, 14),
        r.bottomRight + const Offset(-14, -14),
        r.center,
        tester.getCenter(find.text('Lihat semua')),
      ]) {
        final sebelum = n;
        await tester.tapAt(p);
        expect(n, sebelum + 1, reason: '$p');
      }
      expect(
        find.bySemanticsLabel(
          'Sertifikat terbaru. Belum ada sertifikat yang terbit.. Lihat semua',
        ),
        findsOneWidget,
      );
      expect(find.semantics.byFlag(SemanticsFlag.isButton), findsOneWidget);
      await _tab(tester);
      _periksaCincin(tester, tester.getRect(_bahan(find.byType(UbinRingkas))), gelap: false);
      semantik.dispose();
    });

    testWidgets('satu kolom 320 dp x huruf 1,3 dengan kalimat panjang: tumbuh, '
        'tanpa luapan', (tester) async {
      layarHp(tester, lebar: 320, tinggi: 900);
      await tester.pumpWidget(
        _app(
          ringkas(
            kalimat:
                'Tiga sertifikat baru telah terbit minggu ini dan siap diunduh '
                'dari halaman sertifikat.',
          ),
          skala: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(UbinRingkas)).height,
        greaterThan(UkuranUbin.pasangan),
      );
    });
  });

  group('UbinMenu', () {
    UbinMenu menu({
      NadaStatus nada = NadaStatus.lulus,
      VoidCallback? onTap,
      bool adaVisual = true,
      List<String> inisial = const [],
      String judul = 'Pelacakan paket',
    }) => UbinMenu(
      judul: judul,
      nada: nada,
      visual: adaVisual ? _visualUji() : null,
      inisial: inisial,
      onTap: onTap ?? () {},
    );

    for (final gelap in [false, true]) {
      testWidgets('140, sudut 28, padding 16, warna per nada, kontras '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        layarHp(tester, lebar: 392, tinggi: 900);
        for (final n in _nadaSemua) {
          await tester.pumpWidget(
            _app(
              Row(
                children: [
                  Expanded(child: menu(nada: n)),
                  const SizedBox(width: Spasi.antarUbin),
                  const Expanded(child: SizedBox()),
                ],
              ),
              gelap: gelap,
            ),
          );
          final tile = tester.getRect(find.byType(UbinMenu));
          expect(tile.height, UkuranUbin.menu, reason: '$n');
          final bahan = tester.widget<Material>(_bahan(find.byType(UbinMenu)));
          expect(bahan.color, _latarUbin(n, gelap));
          expect(
            (bahan.shape! as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(28),
          );
          expect(
            pelanggaranKontrasTeks(tester, find.byType(UbinMenu)),
            isEmpty,
            reason: '$n gelap=$gelap',
          );
          // Penanda bulat 40 tetap navy + ikon putih di dua tema.
          final bulat = tester.widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(TombolBulat),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          expect((bulat.decoration as BoxDecoration).color, _w(gelap).tintaUbin);
          expect(tester.widget<Icon>(find.byType(Icon)).color, _w(gelap).kertasUbin);
        }
      });
    }

    testWidgets('judul 17 maks 2 baris lebar <= 100; penanda 40 di kiri bawah; '
        'visual 100 keluar 10', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 900);
      await tester.pumpWidget(
        _app(
          Row(
            children: [
              Expanded(child: menu(judul: 'Pelacakan paket kalibrasi alat')),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      final tile = tester.getRect(find.byType(UbinMenu));
      final judul = find.text('Pelacakan paket kalibrasi alat');
      expect(tester.getSize(judul).width, lessThanOrEqualTo(UkuranUbin.judulMenuMaks));
      expect(tester.widget<Text>(judul).style!.fontSize, 17);
      expect(tester.widget<Text>(judul).maxLines, 2);
      expect(tester.getRect(judul).left - tile.left, 16);
      final bulat = tester.getRect(find.byType(TombolBulat));
      expect(bulat.size, const Size.square(UkuranKontrol.tombolBulatUbin));
      expect(bulat.left - tile.left, 16);
      expect(tile.bottom - bulat.bottom, 16);
      final v = tester.getRect(find.byKey(_visual));
      expect(v.size, const Size.square(UkuranVisual.ubinMenu));
      expect(v.right - tile.right, UkuranVisual.keluarKecil);
      expect(v.bottom - tile.bottom, UkuranVisual.keluarKecil);
      // Visual digambar DI BAWAH teks (anak pertama Stack ubin): bila sudut
      // atas visual menyentuh judul, teks tetap di atas dan tidak tertutup.
      expect(
        find.descendant(
          of: find.byType(UbinMenu),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Stack &&
                w.children.length == 2 &&
                w.children.first is Positioned &&
                w.children.last is Padding,
          ),
        ),
        findsOneWidget,
        reason: 'visual paling bawah, teks (Padding) paling atas',
      );
    });

    testWidgets('tumpukan avatar 40 di kanan bawah, paling banyak 3, tanpa '
        'visual', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 900);
      await tester.pumpWidget(
        _app(
          Row(
            children: [
              Expanded(
                child: menu(
                  adaVisual: false,
                  inisial: const ['AR', 'BS', 'CD', 'EF'],
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
      final tile = tester.getRect(find.byType(UbinMenu));
      expect(find.text('AR'), findsOneWidget);
      expect(find.text('CD'), findsOneWidget);
      expect(find.text('EF'), findsNothing, reason: 'paling banyak tiga');
      final a = tester.getRect(find.text('AR'));
      final c = tester.getRect(find.text('CD'));
      expect(
        c.left - a.left,
        closeTo(2 * (UkuranUbin.avatarUbin - Spasi.md), 1),
        reason: 'avatar ke-1 dan ke-3 berjarak dua kali selisih tumpukan',
      );
      final tumpukan = tester.getRect(
        find.ancestor(of: find.text('CD'), matching: find.byType(SizedBox)).first,
      );
      expect(tumpukan.height, UkuranUbin.avatarUbin);
      expect(tile.right - tumpukan.right, 16);
      expect(tile.bottom - tumpukan.bottom, 16);
      expect(find.byKey(_visual), findsNothing);
    });

    testWidgets('satu tombol, penanda bulat bukan tombol kedua; ketuk '
        'seluruh ubin; cincin fokus; label judul', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 900);
      var n = 0;
      await tester.pumpWidget(
        _app(Row(children: [Expanded(child: menu(onTap: () => n++)), const Expanded(child: SizedBox())])),
      );
      expect(find.byType(InkWell), findsOneWidget);
      expect(find.semantics.byFlag(SemanticsFlag.isButton), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Pelacakan paket')),
        matchesSemantics(
          label: 'Pelacakan paket',
          isButton: true,
          hasTapAction: true,
        ),
      );
      final r = tester.getRect(find.byType(UbinMenu));
      for (final p in [
        r.topLeft + const Offset(14, 14),
        r.bottomRight + const Offset(-14, -14),
        tester.getCenter(find.byType(TombolBulat)),
        r.center,
      ]) {
        final sebelum = n;
        await tester.tapAt(p);
        expect(n, sebelum + 1, reason: '$p');
      }
      await _tab(tester);
      _periksaCincin(tester, tester.getRect(_bahan(find.byType(UbinMenu))), gelap: false);
      semantik.dispose();
    });

    testWidgets('320 dp x huruf 1,3: judul panjang, tanpa luapan, tinggi '
        'tumbuh', (tester) async {
      layarHp(tester, lebar: 320, tinggi: 900);
      await tester.pumpWidget(
        _app(menu(judul: 'Pelacakan paket kalibrasi'), skala: 1.3),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(UbinMenu)).height,
        greaterThanOrEqualTo(UkuranUbin.menu),
      );
    });
  });

  group('PanelSidik 28', () {
    testWidgets('sudut 28, padding bawaan nol, paddingBaris 6, paddingIsi 18', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 900);
      Future<Rect> isi(EdgeInsets? padding) async {
        await tester.pumpWidget(
          _app(
            padding == null
                ? const PanelSidik(anak: [SizedBox(key: Key('anak'), height: 60)])
                : PanelSidik(
                    padding: padding,
                    anak: const [SizedBox(key: Key('anak'), height: 60)],
                  ),
          ),
        );
        final panel = tester.getRect(find.byType(PanelSidik));
        final anak = tester.getRect(find.byKey(const Key('anak')));
        expect(anak.left - panel.left, anak.top - panel.top);
        return Rect.fromLTRB(
          anak.left - panel.left,
          anak.top - panel.top,
          panel.right - anak.right,
          panel.bottom - anak.bottom,
        );
      }

      Material bahan() => tester.widget<Material>(_bahan(find.byType(PanelSidik)));
      expect((await isi(null)).left, 0, reason: 'bawaan = tanpa padding');
      expect(
        (bahan().shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(28),
      );
      expect(Bentuk.panel, 28);
      expect((await isi(PanelSidik.paddingBaris)).left, UkuranKontrol.panelBaris);
      expect(UkuranKontrol.panelBaris, 6);
      expect((await isi(PanelSidik.paddingIsi)).left, UkuranUbin.paddingAlat);
      expect(UkuranUbin.paddingAlat, 18);
    });
  });

  group('gerbang token pada berkas Bento baru', () {
    const berkas = [
      'lib/core/motion/gerak_bento.dart',
      'lib/widgets/dasar/cincin_fokus.dart',
      'lib/widgets/dasar/dasar_ubin.dart',
      'lib/widgets/dasar/kontrol_ketuk.dart',
      'lib/widgets/saringan_pil.dart',
      'lib/widgets/segmen_pil.dart',
      'lib/widgets/tombol_bulat.dart',
      'lib/widgets/ubin_alat.dart',
      'lib/widgets/ubin_menu.dart',
      'lib/widgets/ubin_ringkas.dart',
      'lib/widgets/stempel.dart',
      'lib/widgets/panel_sidik.dart',
      'lib/widgets/tombol_sidik.dart',
      'lib/widgets/kolom_cari_utuh.dart',
    ];

    // Parameter ukuran yang tidak boleh berisi angka mentah (selain nol).
    final ukuranMentah = RegExp(
      r'\b(width|height|minHeight|maxHeight|minWidth|maxWidth|dimension|radius|'
      r'thickness|spacing|runSpacing|indent|endIndent|fontSize)\s*:\s*'
      r'[^,;)]*?(?<=[:?]\s*)[1-9]\d*(\.\d+)?(?![\w.])',
    );
    final jarakMentah = RegExp(
      r'EdgeInsets(Directional)?\.\w+\([^)]*(?<=[(:,?]\s*)[1-9]\d*(\.\d+)?(?![\w.])',
    );

    for (final b in berkas) {
      test(b, () {
        final sumber = File(b).readAsStringSync();
        final hitung = PemindaiToken.hitung(sumber, jalur: b);
        expect(
          hitung.entries.where((e) => e.value != 0).toList(),
          isEmpty,
          reason: 'berkas baru tidak boleh punya pelanggaran token-only',
        );
        final c = PemindaiToken.buangKomentar(sumber);
        expect(ukuranMentah.allMatches(c).map((m) => m.group(0)).toList(), isEmpty);
        expect(jarakMentah.allMatches(c).map((m) => m.group(0)).toList(), isEmpty);
        expect(RegExp(r'\bColors\.(?!transparent)\w+').hasMatch(c), isFalse);
        expect(c.contains(' · '), isFalse);
        expect(c.contains('KartuSidik('), isFalse);
        expect(c.contains('ChipStatus('), isFalse);
      });
    }

    test('tidak ada paket baru dan tidak ada tulis di jaringan', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('google_fonts'), isFalse);
      for (final b in berkas) {
        final c = File(b).readAsStringSync();
        expect(c.contains('package:http'), isFalse, reason: b);
        expect(c.contains('package:dio'), isFalse, reason: b);
      }
    });
  });
}
