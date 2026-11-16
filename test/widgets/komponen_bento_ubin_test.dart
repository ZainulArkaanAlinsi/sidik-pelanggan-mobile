// Komponen bersama, bagian ubin (diselaraskan ke REVISI 16 Nov): warna ubin
// dan tinta yang dipisah dari tinta halaman (WarnaSidik), lencana status 24,
// UbinAlat (kartu netral), UbinRingkas, UbinMenu, PanelSidik 16, dan gerbang
// token pada berkas komponen. Diuji di terang dan
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

/// (tinta, latar) status untuk teks di HALAMAN: tinta gelap di atas warna muda
/// (terang) atau tinta pastel di atas latar gelap (gelap).
(Color, Color) _pasanganHalaman(NadaStatus n, bool gelap) {
  final w = _w(gelap);
  return switch (n) {
    NadaStatus.gagal => (w.gagal, w.gagalLatar),
    NadaStatus.awas => (w.awas, w.awasLatar),
    NadaStatus.lulus => (w.lulus, w.lulusLatar),
    NadaStatus.tunggu => (w.tunggu, w.tungguLatar),
    NadaStatus.netral => (
      _skema(gelap).onSurfaceVariant,
      _skema(gelap).surfaceContainerHigh,
    ),
  };
}

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

Widget _visualUji() => const SizedBox.expand(
  key: _visual,
  child: ColoredBox(color: Colors.transparent),
);

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
  VoidCallback? onTap,
  String? semantik,
  int? urutan,
  String? merkTipe = 'Memmert UF55',
  String? serial = '0457-2201',
  String? tanggal = '9 Nov 2026',
  String? lokasi = 'Gudang 1',
  StatusTampil? tahap,
  bool nonaktif = false,
  int? maksBarisNama,
}) => UbinAlat(
  nama: nama,
  status: _status(nada),
  merkTipe: merkTipe,
  serial: serial,
  awalanSerial: 'SN',
  lokasi: lokasi,
  hari: hari,
  tanggal: tanggal,
  tahap: tahap,
  nonaktif: nonaktif,
  maksBarisNama: maksBarisNama,
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
      expect(g.lulus, PaletSidik.hijauTintaGelap);
      expect(g.gagal, PaletSidik.koralTintaGelap);
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
          reason: 'putih dan navy saling terbaca',
        );
      });
    }

    test('copyWith dan lerp membawa kolom ubin', () {
      final t = _w(false);
      final w = t.copyWith(
        ubinGagal: PaletSidik.garis,
        tintaUbin: PaletSidik.teksKedua,
      );
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
            case NadaStatus.netral:
              expect(
                (tintaStempel, latarStempel),
                (
                  _skema(gelap).onSurfaceVariant,
                  _skema(gelap).surfaceContainerHigh,
                ),
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

  group('Lencana status (Stempel)', () {
    testWidgets('tinggi 24, sudut 6, padding 8, ikon 14, jarak 4, 12/600', (
      tester,
    ) async {
      await tester.pumpWidget(_app(Stempel(statusAlat(StatusKalibrasi.lewat))));
      final kotak = tester.getRect(find.byType(Stempel));
      expect(kotak.height, UkuranKontrol.stempel);
      expect(UkuranKontrol.stempel, 24);
      expect(Bentuk.stempel, 6);
      final dekor =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(Stempel),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(dekor.borderRadius, BorderRadius.circular(6));
      final ikon = tester.getRect(find.byType(Icon));
      final kata = tester.getRect(find.text('Lewat jadwal'));
      expect(ikon.left - kotak.left, 8);
      expect(ikon.size, const Size.square(14));
      expect(kata.left - ikon.right, 4);
      expect(kotak.right - kata.right, 8);
      final gaya = tester.widget<Text>(find.text('Lewat jadwal')).style!;
      expect(gaya.fontSize, 12);
      expect(gaya.fontWeight, FontWeight.w600);
    });

    for (final gelap in [false, true]) {
      testWidgets('latar = warna muda status, tinta gelap (terang) atau pastel '
          '(gelap); tenang = tinta halaman tanpa latar '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        final w = _w(gelap);
        for (final n in _nadaSemua) {
          await tester.pumpWidget(_app(Stempel(_status(n)), gelap: gelap));
          final dekor =
              tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byType(Stempel),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration;
          final (tintaHalaman, latarHalaman) = _pasanganHalaman(n, gelap);
          // Semua nada memakai pasangan halaman tema aktif.
          expect(dekor.color, latarHalaman, reason: '$n');
          expect(
            tester.widget<Icon>(find.byType(Icon)).color,
            tintaHalaman,
            reason: '$n: ikon bertinta status',
          );
          expect(
            pelanggaranKontrasTeks(tester, find.byType(Stempel)),
            isEmpty,
            reason: '$n gelap=$gelap',
          );
          // Tenang: tanpa latar, tinta halaman (pastel di gelap).
          await tester.pumpWidget(
            _app(Stempel(_status(n), tenang: true), gelap: gelap),
          );
          final tenang =
              tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byType(Stempel),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration;
          expect(tenang.color, isNull);
          if (n == NadaStatus.lulus) {
            expect(tester.widget<Icon>(find.byType(Icon)).color, w.lulus);
          }
        }
      });
    }

    for (final gelap in [false, true]) {
      testWidgets('diAtasUbin: navy di atas putih untuk semua nada berwarna; '
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
          final dekor =
              tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byType(Stempel),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration;
          expect(dekor.color, w.kertasUbin, reason: '$n');
          final ikon = tester.widget<Icon>(find.byType(Icon)).color;
          expect(ikon, w.tintaUbin, reason: '$n: ikon');
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

    testWidgets('kata panjang di 320 dp x 1,3: lencana tumbuh ke bawah, tetap '
        'sudut 6, tanpa luapan', (tester) async {
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
      testWidgets('kartu NETRAL di dua tema (permukaan tema, garis halus); '
          'status hanya di lencana; teks >= 4,5:1 '
          '(${gelap ? 'gelap' : 'terang'})', (tester) async {
        for (final n in _nadaSemua) {
          await tester.pumpWidget(_app(_ubinAlat(nada: n), gelap: gelap));
          final bahan = tester.widget<Material>(_bahan(find.byType(UbinAlat)));
          expect(
            bahan.color,
            _skema(gelap).surface,
            reason: '$n gelap=$gelap: kartu netral, bukan warna status',
          );
          final shape = bahan.shape! as RoundedRectangleBorder;
          expect(shape.borderRadius, BorderRadius.circular(16));
          expect(shape.side.color, _skema(gelap).outlineVariant);
          expect(shape.side.width, 1);
          expect(
            find.descendant(
              of: find.byType(UbinAlat),
              matching: find.byType(Stempel),
            ),
            findsOneWidget,
            reason: '$n: status tetap tampil sebagai lencana',
          );
          expect(
            pelanggaranKontrasTeks(tester, find.byType(UbinAlat)),
            isEmpty,
            reason: '$n gelap=$gelap',
          );
          final nama = tester.widget<Text>(find.text('Oven Memmert')).style!;
          expect(
            nama.color,
            _skema(gelap).onSurface,
            reason: 'teks kartu netral memakai tinta tema',
          );
        }
      });
    }

    testWidgets('tinggi minimum 120, padding 16, nama di kiri atas, isi tidak '
        'dikunci; RINGKAS dibanding kartu Bento (144 + angka besar)', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 900);
      await tester.pumpWidget(_app(_ubinAlat()));
      final tile = tester.getRect(find.byType(UbinAlat));
      expect(UkuranUbin.alatRingkas, 120);
      expect(tile.height, greaterThanOrEqualTo(UkuranUbin.alatRingkas));
      expect(tile.height, lessThan(180));
      expect(tile.width, 392 - 32);
      final nama = tester.getRect(find.text('Oven Memmert'));
      expect(nama.left - tile.left, UkuranUbin.paddingAlat);
      expect(nama.top - tile.top, UkuranUbin.paddingAlat);
      final stempel = tester.getRect(find.byType(Stempel));
      expect(stempel.left - tile.left, UkuranUbin.paddingAlat);
      expect(stempel.height, UkuranKontrol.stempel);
      // Sedikit isi (nama + lencana): minimum 120 yang menahan.
      await tester.pumpWidget(
        _app(
          _ubinAlat(
            nama: 'Oven',
            merkTipe: null,
            serial: null,
            lokasi: null,
            hari: null,
            tanggal: null,
            nada: NadaStatus.netral,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(UbinAlat)).height,
        inInclusiveRange(UkuranUbin.alatRingkas, UkuranUbin.alatRingkas + 8),
      );
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
        greaterThan(UkuranUbin.alatRingkas + 60),
      );
    });

    testWidgets('isi: nama 20 semibold, "merk · SN seri" 13 dengan seri mono, '
        'lokasi 13, lencana 24, aksi warna primer', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 900);
      await tester.pumpWidget(_app(_ubinAlat()));
      final nama = tester.widget<Text>(find.text('Oven Memmert'));
      expect(nama.style!.fontSize, 20);
      expect(nama.style!.fontWeight, FontWeight.w600);
      // Tanpa batas baris bawaan; ellipsis hanya bila ada batas (ellipsis tanpa
      // batas memaksa satu baris).
      expect(nama.maxLines, isNull);
      expect(nama.overflow, TextOverflow.clip);
      final identitas = tester.widget<Text>(
        find.text('Memmert UF55 · SN 0457-2201'),
      );
      expect(identitas.style!.fontSize, 13);
      final anak = (identitas.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(anak.map((x) => x.text), ['Memmert UF55', ' · ', 'SN 0457-2201']);
      final seri = anak.last.style!;
      expect(
        seri.fontFamily,
        'IBMPlexMono',
        reason: 'nomor seri = IBM Plex Mono',
      );
      expect(seri.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(anak.first.style, isNull, reason: 'merk memakai gaya Inter induk');
      expect(tester.widget<Text>(find.text('Gudang 1')).style!.fontSize, 13);
      final aksi = tester.widget<Text>(find.text('Lihat detail')).style!;
      expect(aksi.color, _skema(false).primary);
      expect(aksi.fontSize, 14);
      // Tanpa merk: hanya seri (tanpa pemisah menggantung); tanpa seri: hanya
      // merk; tanpa keduanya: tanpa baris identitas.
      await tester.pumpWidget(_app(_ubinAlat(merkTipe: null)));
      expect(find.text('SN 0457-2201'), findsOneWidget);
      expect(find.textContaining(' · '), findsNothing);
      await tester.pumpWidget(_app(_ubinAlat(serial: null)));
      expect(find.text('Memmert UF55'), findsOneWidget);
      expect(find.textContaining(' · '), findsNothing);
      await tester.pumpWidget(_app(_ubinAlat(serial: null, merkTipe: null)));
      expect(find.textContaining('SN'), findsNothing);
      expect(find.textContaining('UF55'), findsNothing);
    });

    test('labelStatus: tiga status jadwal membawa waktunya, lainnya katanya '
        'saja', () {
      String label(NadaStatus nada, int? hari, {bool nonaktif = false}) =>
          UbinAlat(
            nama: 'x',
            status: _status(nada),
            hari: hari,
            nonaktif: nonaktif,
          ).labelStatus;
      expect(label(NadaStatus.gagal, -4), 'Lewat jadwal 4 hari');
      expect(label(NadaStatus.gagal, -1), 'Lewat jadwal 1 hari');
      expect(label(NadaStatus.awas, 12), 'Segera jatuh tempo 12 hari lagi');
      expect(label(NadaStatus.awas, 0), 'Segera jatuh tempo hari ini');
      expect(label(NadaStatus.lulus, 120), 'Berlaku 120 hari lagi');
      // Tanpa jadwal, atau waktu yang tidak cocok dengan statusnya: kata saja.
      expect(label(NadaStatus.gagal, null), 'Lewat jadwal');
      expect(label(NadaStatus.gagal, 3), 'Lewat jadwal');
      expect(label(NadaStatus.lulus, -2), 'Berlaku');
      // Status yang bukan jadwal tidak membawa hitung mundur.
      expect(label(NadaStatus.tunggu, 5), 'Sedang diproses');
      expect(label(NadaStatus.netral, 5), 'Tidak aktif');
      // Nonaktif: tidak pernah berwaktu, apa pun nadanya.
      expect(label(NadaStatus.netral, 10, nonaktif: true), 'Tidak aktif');
      expect(label(NadaStatus.awas, 10, nonaktif: true), 'Segera jatuh tempo');
    });

    test('keteranganJadwal dan konteksNonaktif', () {
      UbinAlat ubin({int? hari, String? tanggal, bool nonaktif = false}) =>
          UbinAlat(
            nama: 'x',
            status: _status(NadaStatus.gagal),
            hari: hari,
            tanggal: tanggal,
            nonaktif: nonaktif,
          );
      expect(
        ubin(hari: -4, tanggal: '9 Nov 2026').keteranganJadwal,
        'sejak 9 Nov 2026',
      );
      expect(
        ubin(hari: 0, tanggal: '9 Nov 2026').keteranganJadwal,
        'jatuh tempo 9 Nov 2026',
      );
      expect(
        ubin(hari: 12, tanggal: '9 Nov 2026').keteranganJadwal,
        'jatuh tempo 9 Nov 2026',
      );
      expect(ubin(hari: 12).keteranganJadwal, isNull);
      expect(ubin(tanggal: '9 Nov 2026').keteranganJadwal, isNull);
      expect(ubin(hari: 12, tanggal: '').keteranganJadwal, isNull);
      // Nonaktif: konteks menggantikan keterangan jadwal.
      final mati = ubin(hari: 10, tanggal: '9 Nov 2026', nonaktif: true);
      expect(mati.keteranganJadwal, isNull);
      expect(mati.konteksNonaktif, 'Alat nonaktif, jadwal tercatat 9 Nov 2026');
      expect(ubin(nonaktif: true).konteksNonaktif, 'Alat nonaktif');
      expect(ubin(hari: 5).konteksNonaktif, isNull);
    });

    testWidgets('batas baris nama hanya bila diminta: ellipsis + dipotong; '
        'label baca membawa nama utuh', (tester) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 320, tinggi: 900);
      const panjang =
          'Alat Ukur Tekanan Digital Presisi Tinggi Untuk Laboratorium Pusat '
          'Dan Cabang Seluruh Indonesia';
      await tester.pumpWidget(_app(_ubinAlat(nama: panjang, maksBarisNama: 2)));
      var p = tester.renderObject<RenderParagraph>(
        find
            .descendant(of: find.text(panjang), matching: find.byType(RichText))
            .first,
      );
      expect(p.maxLines, 2);
      expect(p.didExceedMaxLines, isTrue);
      expect(find.bySemanticsLabel(RegExp(panjang)), findsOneWidget);
      // Bawaan: nama utuh, membungkus sebanyak perlu.
      await tester.pumpWidget(_app(_ubinAlat(nama: panjang)));
      p = tester.renderObject<RenderParagraph>(
        find
            .descendant(of: find.text(panjang), matching: find.byType(RichText))
            .first,
      );
      expect(p.didExceedMaxLines, isFalse);
      expect(p.size.height, greaterThan(2 * 26));
      semantik.dispose();
    });

    testWidgets('seluruh kartu satu tombol: ketukan di sudut, tengah, lencana, '
        'dan aksi, tepat sekali', (tester) async {
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
        tester.getCenter(find.byType(Stempel)),
        tester.getCenter(find.text('Oven Memmert')),
        tester.getCenter(find.text('Lihat detail')),
      ];
      for (final p in titik) {
        final sebelum = n;
        await tester.tapAt(p);
        expect(n, sebelum + 1, reason: 'ketukan di $p');
      }
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('semantik: kalimat bawaan dari isi, bisa diganti; label tetap '
        'ada pada kartu statis dan tombol berlabel bisa diaktifkan', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      layarHp(tester, lebar: 392, tinggi: 900);
      var n = 0;
      await tester.pumpWidget(
        _app(
          _ubinAlat(
            onTap: () => n++,
            tahap: statusPaket('dikalibrasi', 'Sedang dikalibrasi'),
          ),
        ),
      );
      const kalimat =
          'Oven Memmert. Status: Lewat jadwal 4 hari. Di lab: Sedang '
          'dikalibrasi. Memmert UF55. Nomor seri 0457-2201. Lokasi Gudang 1. '
          'sejak 9 Nov 2026';
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
      // Statis (tanpa onTap) dengan semantik: berlabel, bukan tombol, tanpa
      // "Lihat detail" (tidak ada yang bisa dibuka).
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
      expect(find.text('Lihat detail'), findsNothing);
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
      final g = await tester.startGesture(
        tester.getCenter(find.byType(UbinAlat)),
      );
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
      await tester.pumpWidget(_app(_ubinAlat(urutan: 2)));
      expect(opasitas(), 0);
      await tester.pump(const Duration(milliseconds: 70 + 260));
      expect(opasitas(), 1);
      await tester.pumpWidget(_app(_ubinAlat()));
      expect(
        find.descendant(
          of: find.byType(UbinAlat),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
        reason: 'tanpa urutan = tanpa animasi masuk',
      );
      _kurangiGerak(tester);
      await tester.pumpWidget(_app(_ubinAlat(urutan: 4)));
      expect(opasitas(), 1);
    });

    for (final gelap in [false, true]) {
      testWidgets('cincin fokus di luar kartu, 3:1, Enter mengaktifkan '
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
      testWidgets('320 dp x huruf 1,3, semua nada, dengan tahap dan nonaktif: '
          'tanpa luapan, kontras tetap (${gelap ? 'gelap' : 'terang'})', (
        tester,
      ) async {
        layarHp(tester, lebar: 320, tinggi: 1600);
        for (final n in _nadaSemua) {
          for (final mati in [false, true]) {
            await tester.pumpWidget(
              _app(
                _ubinAlat(
                  nada: n,
                  nama: 'Timbangan Analitik Presisi Tinggi',
                  hari: 128,
                  nonaktif: mati,
                  tahap: statusPaket(
                    'menunggu_pemeriksaan',
                    'Hasil sedang diperiksa',
                  ),
                ),
                gelap: gelap,
                skala: 1.3,
              ),
            );
            expect(tester.takeException(), isNull, reason: '$n mati=$mati');
            expect(
              pelanggaranKontrasTeks(tester, find.byType(UbinAlat)),
              isEmpty,
              reason: '$n mati=$mati',
            );
          }
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
      testWidgets('132, sudut 16, padding 16, warna per nada, kontras '
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
            BorderRadius.circular(16),
          );
          expect(
            pelanggaranKontrasTeks(tester, find.byType(UbinRingkas).first),
            isEmpty,
            reason: '$n gelap=$gelap',
          );
        }
      });
    }

    testWidgets('isi: judul 16, kalimat 13, "Lihat semua" 12 bergaris bawah di '
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
        16,
      );
      expect(
        tester
            .widget<Text>(find.text('Belum ada sertifikat yang terbit.'))
            .style!
            .fontSize,
        13,
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
        _app(
          Row(
            children: [
              Expanded(child: ringkas(onTap: () => n++)),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
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
      _periksaCincin(
        tester,
        tester.getRect(_bahan(find.byType(UbinRingkas))),
        gelap: false,
      );
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
      testWidgets('124, sudut 16, padding 16, warna per nada, kontras '
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
            BorderRadius.circular(16),
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
          expect(
            (bulat.decoration as BoxDecoration).color,
            _w(gelap).tintaUbin,
          );
          expect(
            tester.widget<Icon>(find.byType(Icon)).color,
            _w(gelap).kertasUbin,
          );
        }
      });
    }

    testWidgets('judul 16 maks 2 baris lebar <= 100; penanda 40 di kiri bawah; '
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
      expect(
        tester.getSize(judul).width,
        lessThanOrEqualTo(UkuranUbin.judulMenuMaks),
      );
      expect(tester.widget<Text>(judul).style!.fontSize, 16);
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
        find
            .ancestor(of: find.text('CD'), matching: find.byType(SizedBox))
            .first,
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
        _app(
          Row(
            children: [
              Expanded(child: menu(onTap: () => n++)),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
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
      _periksaCincin(
        tester,
        tester.getRect(_bahan(find.byType(UbinMenu))),
        gelap: false,
      );
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
                ? const PanelSidik(
                    anak: [SizedBox(key: Key('anak'), height: 60)],
                  )
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

      Material bahan() =>
          tester.widget<Material>(_bahan(find.byType(PanelSidik)));
      expect((await isi(null)).left, 0, reason: 'bawaan = tanpa padding');
      expect(
        (bahan().shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(16),
      );
      expect(Bentuk.panel, 16);
      expect(
        (await isi(PanelSidik.paddingBaris)).left,
        UkuranKontrol.panelBaris,
      );
      expect(UkuranKontrol.panelBaris, 4);
      expect((await isi(PanelSidik.paddingIsi)).left, UkuranUbin.paddingAlat);
      expect(UkuranUbin.paddingAlat, 16);
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
        expect(
          ukuranMentah.allMatches(c).map((m) => m.group(0)).toList(),
          isEmpty,
        );
        expect(
          jarakMentah.allMatches(c).map((m) => m.group(0)).toList(),
          isEmpty,
        );
        expect(RegExp(r'\bColors\.(?!transparent)\w+').hasMatch(c), isFalse);
        // Satu pengecualian sadar: baris identitas kartu alat "merk model · SN
        // seri" (REVISI-2 butir 2); berkas lain tetap tanpa pemisah ' · '.
        expect(
          ' · '.allMatches(c).length,
          b == 'lib/widgets/ubin_alat.dart' ? 1 : 0,
        );
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
