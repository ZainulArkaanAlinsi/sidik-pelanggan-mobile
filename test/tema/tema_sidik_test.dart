// Tema SIDIK Pelanggan: token tunggal (tanpa warna/ukuran liar di layar),
// skala tipografi sembilan tingkat (daftar izin eksplisit), dan kontras WCAG AA
// di terang dan gelap. Gerbang desain yang lebih lengkap ada di
// token_only_test.dart, kontras_tema_test.dart, token_tema_test.dart, dan
// anti_slop_test.dart (folder yang sama).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/palet_sidik.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
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
        reason: 'kobalt logo adalah warna utama',
      );
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

  group('tipografi: Inter, sembilan tingkat', () {
    for (final (nama, tema) in [
      ('terang', TemaSidik.terang),
      ('gelap', TemaSidik.gelap),
    ]) {
      test('tema $nama memakai Inter dan hanya sembilan ukuran huruf', () {
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
        // Daftar izin eksplisit (Paket 1, token "Jejak"): tiga tingkat baru
        // masing-masing dipakai satu peran. 44 angka bintang (sisa hari di
        // detail alat), 32 kalimat utama Beranda dan paket, 17 judul baris.
        // Tingkat lama 15 dan 13 diganti 16 dan 14 (pembaca santai di meja);
        // 22 menggantikan 20 untuk judul layar, 20 tinggal untuk app bar.
        // Ukuran di luar daftar ini tetap tertolak; minimum 12 sp.
        expect(
          {for (final g in gaya) g!.fontSize},
          {44, 32, 28, 22, 20, 17, 16, 14, 12},
        );
        expect(gaya.every((g) => g!.fontFamily == 'Inter'), isTrue);
        expect(tema.useMaterial3, isTrue);
      });
    }
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

      test('$nama: tombol dan kobalt >= 4,5:1', () {
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
      expect(PaletSidik.kanMerah, isNot(PaletSidik.gagalTerang));
    });
  });
}
