// Tema SIDIK Pelanggan (Bento Lab): token tunggal (tanpa warna/ukuran liar di
// layar), skala tipografi sepuluh ukuran (daftar izin eksplisit, termasuk 64
// angka sorot), dan kontras WCAG AA di terang dan gelap. Gerbang desain yang
// lebih lengkap ada di token_only_test.dart, kontras_tema_test.dart,
// token_tema_test.dart, dan anti_slop_test.dart (folder yang sama).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/palet_sidik.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/tipografi.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';

/// Rasio kontras WCAG 2.x antara dua warna buram.
double kontras(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final terang = la > lb ? la : lb;
  final gelap = la > lb ? lb : la;
  return (terang + 0.05) / (gelap + 0.05);
}

/// Semua berkas `.dart` di bawah [folder] (dari akar repo).
Iterable<File> _berkas(String folder) => Directory(folder)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

String _nama(File f) => f.path.replaceAll('\\', '/');

void main() {
  group('token: tidak ada nilai liar di layar dan widget', () {
    final berkasLayar = [..._berkas('lib/screens'), ..._berkas('lib/widgets')];

    test('literal Color(0x...) hanya di palet_sidik.dart', () {
      final pelanggar = <String>[];
      for (final f in [...berkasLayar, ..._berkas('lib/core/tema')]) {
        if (_nama(f).endsWith('lib/core/tema/palet_sidik.dart')) continue;
        if (f.readAsStringSync().contains('Color(0x')) pelanggar.add(_nama(f));
      }
      expect(pelanggar, isEmpty, reason: 'warna harus lewat PaletSidik/tema');
      expect(
        File('lib/core/tema/palet_sidik.dart').readAsStringSync(),
        contains('Color(0xFF043EA1)'),
        reason: 'kobalt logo tetap tercatat di palet (hanya untuk aset merek)',
      );
      // Bento Lab: kobalt BUKAN warna aksi. Warna utama kedua tema adalah
      // navy (terang) atau navyTeks (gelap), tidak pernah kobaltLogo.
      for (final tema in [TemaSidik.terang, TemaSidik.gelap]) {
        expect(tema.colorScheme.primary, isNot(PaletSidik.kobaltLogo));
        expect(tema.colorScheme.inversePrimary, isNot(PaletSidik.kobaltLogo));
      }
      expect(TemaSidik.terang.colorScheme.primary, PaletSidik.navy);
    });

    test('tanpa Colors.* (selain transparent) di layar dan widget', () {
      final pelanggar = <String>[];
      final pola = RegExp(r'\bColors\.(?!transparent)\w+');
      for (final f in berkasLayar) {
        if (pola.hasMatch(f.readAsStringSync())) pelanggar.add(_nama(f));
      }
      expect(pelanggar, isEmpty);
    });

    test('tanpa jarak, sudut, atau ukuran huruf berupa angka telanjang', () {
      final pola = RegExp(
        r'SizedBox\((height|width): \d|BorderRadius\.circular\(\d|fontSize: \d',
      );
      final pelanggar = <String>[];
      for (final f in berkasLayar) {
        if (pola.hasMatch(f.readAsStringSync())) pelanggar.add(_nama(f));
      }
      expect(pelanggar, isEmpty, reason: 'pakai Spasi, Bentuk, TipografiSidik');
    });

    test('tema lama (skeuomorf) sudah tidak ada', () {
      expect(Directory('lib/core/theme').existsSync(), isFalse);
      expect(Directory('lib/widgets/sidik').existsSync(), isFalse);
      expect(File('lib/widgets/umum.dart').existsSync(), isFalse);
    });
  });

  // Daftar izin ukuran huruf (sp), Bento Lab. 64 = angka sorot (satu-satunya
  // ukuran baru, BUKAN slot TextTheme: lihat TipografiSidik.angkaSorot).
  final ukuranIzin = <double>{64, 44, 32, 28, 22, 20, 17, 16, 14, 12};

  group('tipografi: Inter, sepuluh ukuran', () {
    for (final (nama, tema) in [
      ('terang', TemaSidik.terang),
      ('gelap', TemaSidik.gelap),
    ]) {
      test('tema $nama memakai Inter dan hanya ukuran huruf yang diizinkan', () {
        final t = tema.textTheme;
        final gaya = [
          t.displayLarge,
          t.displayMedium,
          t.displaySmall,
          t.headlineLarge,
          t.headlineMedium,
          t.headlineSmall,
          t.titleLarge,
          t.titleMedium,
          t.titleSmall,
          t.bodyLarge,
          t.bodyMedium,
          t.bodySmall,
          t.labelLarge,
          t.labelMedium,
          t.labelSmall,
        ];
        // Daftar izin eksplisit. Slot TextTheme: 44 angka kartu, 32 kalimat
        // utama, 28 judul layar, 22 nama, 20 judul bar, 17 judul bagian, 16
        // label dan isi, 14 keterangan, 12 stempel. Ukuran ke-10 (64, angka
        // sorot) hidup di luar TextTheme dan diuji terpisah di bawah. Ukuran di
        // luar daftar ini tetap tertolak; minimum 12 sp.
        expect(
          {for (final g in gaya) g!.fontSize},
          {44, 32, 28, 22, 20, 17, 16, 14, 12},
        );
        expect(
          ukuranIzin,
          containsAll({for (final g in gaya) g!.fontSize!}),
          reason: 'semua slot TextTheme harus ada di daftar izin',
        );
        expect(gaya.every((g) => g!.fontFamily == 'Inter'), isTrue);
        expect(tema.useMaterial3, isTrue);
      });
    }
  });

  group('tipografi Bento Lab: angka sorot, spasi huruf, berat', () {
    test('angka sorot 64/60, selebar tetap, hanya ukuran yang diizinkan', () {
      final g = TipografiSidik.angkaSorot(teks: PaletSidik.navy);
      expect(g.fontSize, 64);
      expect(ukuranIzin, contains(g.fontSize));
      expect(g.height! * g.fontSize!, closeTo(60, 1e-9));
      expect(g.fontFamily, 'Inter');
      expect(g.color, PaletSidik.navy);
      expect(g.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('spasi huruf mengikuti em di DESIGN.md (dp = ukuran x em)', () {
      final t = TemaSidik.terang.textTheme;
      final harapan = <(String, TextStyle?, double)>[
        (
          'angka sorot 64',
          TipografiSidik.angkaSorot(teks: PaletSidik.navy),
          -0.04,
        ),
        ('angka kartu 44', t.displayLarge, -0.04),
        ('kalimat 32', t.displayMedium, -0.03),
        ('judul layar 28', t.displaySmall, -0.03),
        ('nama 22', t.headlineMedium, -0.02),
        ('judul bar 20', t.titleLarge, -0.02),
        ('judul bagian 17', t.titleMedium, -0.01),
      ];
      for (final (apa, g, em) in harapan) {
        expect(
          g!.letterSpacing,
          closeTo(g.fontSize! * em, 1e-9),
          reason: '$apa: spasi huruf harus ${g.fontSize} x $em',
        );
      }
    });

    test('tinggi baris sesuai DESIGN.md', () {
      final t = TemaSidik.terang.textTheme;
      double baris(TextStyle? g) => g!.height! * g.fontSize!;
      expect(baris(t.displayLarge), closeTo(48, 1e-9));
      expect(baris(t.displayMedium), closeTo(38, 1e-9));
      expect(baris(t.displaySmall), closeTo(34, 1e-9));
      expect(baris(t.headlineMedium), closeTo(28, 1e-9));
      expect(baris(t.titleLarge), closeTo(26, 1e-9));
      expect(baris(t.titleMedium), closeTo(24, 1e-9));
      expect(baris(t.labelLarge), closeTo(24, 1e-9));
      expect(baris(t.bodySmall), closeTo(20, 1e-9));
      expect(baris(t.labelMedium), closeTo(16, 1e-9));
    });

    test('UTANG: berat 800 belum ada; semua berat punya berkas font', () {
      // Bento Lab meminta 800 (ExtraBold) untuk judul dan angka. Inter yang
      // dibundel hanya punya 400/500/600/700 dan font baru dilarang, jadi
      // `TipografiSidik.beratTebal` tampil 700. Tes ini memegang dua hal:
      // (1) tak ada TextStyle yang meminta berat tanpa berkasnya (kalau
      // diminta, mesin huruf diam-diam jatuh ke 700 dan kita lupa utangnya),
      // (2) utangnya tercatat: begitu Inter-ExtraBold.ttf masuk pubspec,
      // tes ini menyuruh `beratTebal` dinaikkan ke 800.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final deklarasi = RegExp(
        r'asset:\s*assets/fonts/Inter-\w+\.ttf\s*weight:\s*(\d+)',
      ).allMatches(pubspec).map((m) => int.parse(m.group(1)!)).toSet();
      expect(deklarasi, containsAll({400, 500, 600, 700}));

      final t = TemaSidik.terang.textTheme;
      final semua = <TextStyle?>[
        TipografiSidik.angkaSorot(teks: PaletSidik.navy),
        t.displayLarge,
        t.displayMedium,
        t.displaySmall,
        t.headlineLarge,
        t.titleLarge,
        t.titleMedium,
        t.titleSmall,
        t.bodyLarge,
        t.bodySmall,
        t.labelLarge,
        t.labelMedium,
      ];
      for (final g in semua) {
        final berat = (g!.fontWeight ?? FontWeight.w400).value;
        expect(
          deklarasi,
          contains(berat),
          reason: '${g.fontSize} sp meminta berat $berat tanpa berkas fontnya',
        );
      }

      final adaExtraBold = deklarasi.contains(800);
      expect(
        TipografiSidik.beratTebal,
        adaExtraBold ? FontWeight.w800 : FontWeight.w700,
        reason: adaExtraBold
            ? 'Inter-ExtraBold sudah ada: naikkan beratTebal ke w800'
            : 'tanpa Inter-ExtraBold, beratTebal harus 700 (utang desain)',
      );
    });
  });

  group('kontras WCAG AA', () {
    for (final (nama, tema) in [
      ('terang', TemaSidik.terang),
      ('gelap', TemaSidik.gelap),
    ]) {
      final s = tema.colorScheme;
      final w = tema.extension<WarnaSidik>()!;

      test('$nama: teks utama dan kedua >= 4,5:1 di permukaan dan latar', () {
        final latar = tema.scaffoldBackgroundColor;
        for (final lapisan in [s.surface, latar, s.surfaceContainerHigh]) {
          expect(kontras(s.onSurface, lapisan), greaterThanOrEqualTo(4.5));
        }
        for (final lapisan in [s.surface, latar]) {
          expect(
            kontras(s.onSurfaceVariant, lapisan),
            greaterThanOrEqualTo(4.5),
          );
        }
      });

      test('$nama: tombol dan warna utama >= 4,5:1', () {
        expect(kontras(s.onPrimary, s.primary), greaterThanOrEqualTo(4.5));
        expect(
          kontras(s.onPrimaryContainer, s.primaryContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(kontras(s.primary, s.surface), greaterThanOrEqualTo(4.5));
        expect(
          kontras(s.primary, tema.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
        expect(kontras(s.onError, s.error), greaterThanOrEqualTo(4.5));
      });

      test('$nama: tiap status terbaca di latar tipisnya dan di kartu', () {
        for (final (tinta, latar) in [
          (w.lulus, w.lulusLatar),
          (w.awas, w.awasLatar),
          (w.gagal, w.gagalLatar),
          (w.tunggu, w.tungguLatar),
        ]) {
          expect(kontras(tinta, latar), greaterThanOrEqualTo(4.5));
          expect(kontras(tinta, s.surface), greaterThanOrEqualTo(4.5));
        }
      });

      test('$nama: garis kontrol dan ikon KAN >= 3:1 (komponen non-teks)', () {
        expect(kontras(s.outline, s.surface), greaterThanOrEqualTo(3));
        expect(
          kontras(s.outline, tema.scaffoldBackgroundColor),
          greaterThan(3),
        );
        expect(kontras(w.kanMerah, s.surface), greaterThanOrEqualTo(3));
      });
    }

    test('merah KAN bukan merah galat', () {
      expect(WarnaSidik.terang.kanMerah, isNot(WarnaSidik.terang.gagal));
      expect(WarnaSidik.gelap.kanMerah, isNot(WarnaSidik.gelap.gagal));
      expect(PaletSidik.kanMerah, isNot(PaletSidik.galat));
      expect(PaletSidik.kanMerahGelap, isNot(PaletSidik.koral));
    });
  });
}
