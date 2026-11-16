// Tema SIDIK Pelanggan (arah tenang-formal, REVISI 16 Nov): token tunggal
// (tanpa warna/ukuran liar di layar), skala tipografi sembilan ukuran (daftar
// izin eksplisit, termasuk 32 angka sorot), dan kontras WCAG AA di terang dan
// gelap. Gerbang desain yang
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
      // Kobalt logo BUKAN warna aksi. Warna utama kedua tema adalah biru aksi
      // (terang) atau biruDiGelap (gelap), tidak pernah kobaltLogo.
      for (final tema in [TemaSidik.terang, TemaSidik.gelap]) {
        expect(tema.colorScheme.primary, isNot(PaletSidik.kobaltLogo));
        expect(tema.colorScheme.inversePrimary, isNot(PaletSidik.kobaltLogo));
      }
      expect(TemaSidik.terang.colorScheme.primary, PaletSidik.biru);
      expect(TemaSidik.gelap.colorScheme.primary, PaletSidik.biruDiGelap);
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

  // Daftar izin ukuran huruf (sp). 32 = angka sorot (BUKAN slot TextTheme:
  // lihat TipografiSidik.angkaSorot).
  final ukuranIzin = <double>{32, 28, 24, 20, 18, 16, 14, 13, 12};

  group('tipografi: Inter + IBM Plex Mono untuk angka, sembilan ukuran', () {
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
        // Daftar izin eksplisit. Slot TextTheme: 28 angka kartu, 24 kalimat
        // utama dan judul layar, 20 nama, 18 judul bar, 16 judul bagian dan
        // isi bacaan, 14 label dan isi, 13 keterangan, 12 lencana. Angka sorot
        // (32) hidup di luar TextTheme dan diuji terpisah di bawah. Ukuran di
        // luar daftar ini tetap tertolak; minimum 12 sp.
        expect(
          {for (final g in gaya) g!.fontSize},
          {28, 24, 20, 18, 16, 14, 13, 12},
        );
        expect(
          ukuranIzin,
          containsAll({for (final g in gaya) g!.fontSize!}),
          reason: 'semua slot TextTheme harus ada di daftar izin',
        );
        // Semua Inter, kecuali angka kartu (IBM Plex Mono).
        expect(
          gaya.where((g) => g!.fontFamily != 'Inter').map((g) => g!.fontSize),
          [28],
        );
        expect(t.displayLarge!.fontFamily, TipografiSidik.keluargaAngka);
        expect(tema.useMaterial3, isTrue);
      });
    }
  });

  group('tipografi: angka sorot, spasi huruf, berat', () {
    test('angka sorot 32/36, selebar tetap, hanya ukuran yang diizinkan', () {
      final g = TipografiSidik.angkaSorot(teks: PaletSidik.navy);
      expect(g.fontSize, 32);
      expect(ukuranIzin, contains(g.fontSize));
      expect(g.height! * g.fontSize!, closeTo(36, 1e-9));
      expect(g.fontFamily, TipografiSidik.keluargaAngka);
      expect(g.color, PaletSidik.navy);
      expect(g.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('tanpa spasi huruf negatif (judul besar tidak dirapatkan)', () {
      final t = TemaSidik.terang.textTheme;
      for (final (apa, g) in <(String, TextStyle?)>[
        ('angka sorot', TipografiSidik.angkaSorot(teks: PaletSidik.navy)),
        ('angka kartu', t.displayLarge),
        ('kalimat', t.displayMedium),
        ('judul layar', t.displaySmall),
        ('nama', t.headlineMedium),
        ('judul bar', t.titleLarge),
        ('judul bagian', t.titleMedium),
        ('isi', t.bodyMedium),
        ('keterangan', t.bodySmall),
        ('lencana', t.labelMedium),
      ]) {
        expect(g!.letterSpacing ?? 0, 0, reason: apa);
      }
    });

    test('tinggi baris sesuai tokens.json', () {
      final t = TemaSidik.terang.textTheme;
      double baris(TextStyle? g) => g!.height! * g.fontSize!;
      expect(baris(t.displayLarge), closeTo(32, 1e-9));
      expect(baris(t.displayMedium), closeTo(30, 1e-9));
      expect(baris(t.displaySmall), closeTo(30, 1e-9));
      expect(baris(t.headlineMedium), closeTo(26, 1e-9));
      expect(baris(t.titleLarge), closeTo(24, 1e-9));
      expect(baris(t.titleMedium), closeTo(22, 1e-9));
      expect(baris(t.labelLarge), closeTo(20, 1e-9));
      expect(baris(t.bodyLarge), closeTo(24, 1e-9));
      expect(baris(t.bodyMedium), closeTo(20, 1e-9));
      expect(baris(t.bodySmall), closeTo(18, 1e-9));
      expect(baris(t.labelMedium), closeTo(16, 1e-9));
    });

    test('semua berat yang diminta punya berkas font; judul semibold', () {
      // Inter yang dibundel punya 400/500/600/700 dan IBM Plex Mono punya
      // 400/500/600. Tak ada TextStyle yang boleh meminta berat tanpa
      // berkasnya (kalau diminta, mesin huruf diam-diam jatuh ke berat lain).
      // Revisi: regular untuk isi, medium untuk label, semibold untuk judul;
      // bold tidak dipakai.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      Set<int> berat(String keluarga) => RegExp(
        r'asset:\s*assets/fonts/' + keluarga + r'-\w+\.ttf\s*weight:\s*(\d+)',
      ).allMatches(pubspec).map((m) => int.parse(m.group(1)!)).toSet();
      final inter = berat('Inter');
      final plex = berat('IBMPlexMono');
      expect(inter, containsAll({400, 500, 600}));
      expect(plex, containsAll({400, 500, 600}));
      expect(
        File('assets/fonts/LICENSE-IBMPlexMono.txt').existsSync(),
        isTrue,
        reason: 'font OFL wajib dibundel bersama lisensinya',
      );

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
        t.bodyMedium,
        t.bodySmall,
        t.labelLarge,
        t.labelMedium,
      ];
      for (final g in semua) {
        final b = (g!.fontWeight ?? FontWeight.w400).value;
        final ada = g.fontFamily == TipografiSidik.keluargaAngka ? plex : inter;
        expect(
          ada,
          contains(b),
          reason: '${g.fontSize} sp meminta berat $b tanpa berkas fontnya',
        );
        expect(
          b,
          lessThan(700),
          reason: '${g.fontSize} sp: bold tidak dipakai',
        );
      }
      expect(TipografiSidik.beratTebal, FontWeight.w600);
      expect(TipografiSidik.beratLabel, FontWeight.w500);
      expect(TipografiSidik.beratKeterangan, FontWeight.w400);
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
