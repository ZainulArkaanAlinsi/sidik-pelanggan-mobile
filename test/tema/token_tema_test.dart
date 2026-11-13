import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/bentuk.dart';
import 'package:sidik_pelanggan/core/tema/elevasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/tipografi.dart';
import 'package:sidik_pelanggan/core/tema/ukuran.dart';
import 'package:sidik_pelanggan/models/status_berlaku.dart';
import 'package:sidik_pelanggan/widgets/chip_status.dart';
import 'package:sidik_pelanggan/widgets/pemetaan_status.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';

/// Gerbang desain Pelanggan, pelengkap: aturan token yang bukan kontras.
///
/// - Huruf: minimum 12 sp di semua slot `TextTheme`, keluarga Inter. Daftar izin
///   ukuran huruf ada di `tema_sidik_test.dart` (satu tempat).
/// - Ukuran sentuh: aksi utama (FilledButton) 56 dp, semua aksi lain 48 dp.
/// - Bentuk: radius tema hanya dari set `Bentuk` (4, 10, 16, 20, 999).
/// - Datar: kartu, app bar, dan navigasi tanpa elevasi.
/// - Status: tiap stempel membawa ikon DAN kata, tidak hanya warna; istilah
///   "Lewat jadwal"/"Masa berlaku berakhir", bukan "kedaluwarsa".
void main() {
  // Nilai yang HARUS dipegang token. Mengubahnya = keputusan desain, bukan
  // penyesuaian tes: jelaskan di PR.
  const tinggiAksiUtama = 56.0;
  const tinggiAksi = 48.0;
  const nilaiBentuk = <String, double>{
    'kecil': 4,
    'kontrol': 10,
    'kartu': 16,
    'utama': 16,
    'lembar': 20,
    'pil': 999,
  };

  final tema = <(String, ThemeData Function())>[
    ('terang', () => TemaSidik.terang),
    ('gelap', () => TemaSidik.gelap),
  ];

  group('huruf: minimum 12 sp, keluarga Inter', () {
    for (final (nama, bangun) in tema) {
      test('tema $nama', () {
        final t = bangun().textTheme;
        final slot = <String, TextStyle?>{
          'displayLarge': t.displayLarge,
          'displayMedium': t.displayMedium,
          'displaySmall': t.displaySmall,
          'headlineLarge': t.headlineLarge,
          'headlineMedium': t.headlineMedium,
          'headlineSmall': t.headlineSmall,
          'titleLarge': t.titleLarge,
          'titleMedium': t.titleMedium,
          'titleSmall': t.titleSmall,
          'bodyLarge': t.bodyLarge,
          'bodyMedium': t.bodyMedium,
          'bodySmall': t.bodySmall,
          'labelLarge': t.labelLarge,
          'labelMedium': t.labelMedium,
          'labelSmall': t.labelSmall,
        };
        for (final e in slot.entries) {
          expect(e.value, isNotNull, reason: '${e.key} tidak diatur');
          expect(
            e.value!.fontSize,
            greaterThanOrEqualTo(12),
            reason: '${e.key} di bawah 12 sp',
          );
          expect(e.value!.fontFamily, TipografiSidik.keluarga);
        }
      });
    }

    test('gaya komponen yang menurunkan teks tema tetap >= 12 sp', () {
      for (final (_, bangun) in tema) {
        final t = bangun();
        final gaya = <String, TextStyle?>{
          'chip label': t.chipTheme.labelStyle,
          'chip label terpilih': t.chipTheme.secondaryLabelStyle,
          'list judul': t.listTileTheme.titleTextStyle,
          'list subjudul': t.listTileTheme.subtitleTextStyle,
          'input hint': t.inputDecorationTheme.hintStyle,
          'input bantuan': t.inputDecorationTheme.helperStyle,
          'input galat': t.inputDecorationTheme.errorStyle,
          'tooltip': t.tooltipTheme.textStyle,
          'snack': t.snackBarTheme.contentTextStyle,
          'nav label': t.navigationBarTheme.labelTextStyle!.resolve({}),
        };
        for (final e in gaya.entries) {
          expect(e.value?.fontSize, isNotNull, reason: '${e.key} tanpa ukuran');
          expect(
            e.value!.fontSize,
            greaterThanOrEqualTo(12),
            reason: '${e.key} di bawah 12 sp',
          );
        }
      }
    });
  });

  group('ukuran sentuh: aksi utama 56, sisanya 48', () {
    for (final (nama, bangun) in tema) {
      test('tema $nama', () {
        final t = bangun();
        double tinggi(ButtonStyle? s) => s!.minimumSize!.resolve({})!.height;
        expect(tinggi(t.filledButtonTheme.style), tinggiAksiUtama);
        expect(tinggi(t.outlinedButtonTheme.style), tinggiAksi);
        expect(tinggi(t.textButtonTheme.style), tinggiAksi);
        expect(tinggi(t.iconButtonTheme.style), tinggiAksi);
        expect(tinggi(t.segmentedButtonTheme.style), tinggiAksi);
        expect(AreaSentuh.minimum, tinggiAksi);
        expect(
          t.textButtonTheme.style!.minimumSize!.resolve({})!.width,
          greaterThanOrEqualTo(48),
        );
      });
    }
  });

  group('bentuk: radius hanya dari set Bentuk', () {
    test('nilai token Bentuk', () {
      expect(<String, double>{
        'kecil': Bentuk.kecil,
        'kontrol': Bentuk.kontrol,
        'kartu': Bentuk.kartu,
        'utama': Bentuk.utama,
        'lembar': Bentuk.lembar,
        'pil': Bentuk.pil,
      }, nilaiBentuk);
    });

    // Set radius yang boleh dipakai tema = nilai di tabel `nilaiBentuk` (yang
    // sudah dibuktikan sama dengan token di tes sebelumnya).
    final set = nilaiBentuk.values.toSet();

    double radius(ShapeBorder? b, String apa) {
      if (b is StadiumBorder) return Bentuk.pil;
      expect(b, isA<RoundedRectangleBorder>(), reason: '$apa bukan persegi');
      return (b! as RoundedRectangleBorder).borderRadius
          .resolve(TextDirection.ltr)
          .topLeft
          .x;
    }

    double radiusInput(InputBorder? b, String apa) {
      expect(b, isA<OutlineInputBorder>(), reason: '$apa bukan outline');
      return (b! as OutlineInputBorder).borderRadius
          .resolve(TextDirection.ltr)
          .topLeft
          .x;
    }

    for (final (nama, bangun) in tema) {
      test('tema $nama', () {
        final t = bangun();
        final dipakai = <String, double>{
          'FilledButton': radius(
            t.filledButtonTheme.style!.shape!.resolve({}),
            'FilledButton',
          ),
          'OutlinedButton': radius(
            t.outlinedButtonTheme.style!.shape!.resolve({}),
            'OutlinedButton',
          ),
          'TextButton': radius(
            t.textButtonTheme.style!.shape!.resolve({}),
            'TextButton',
          ),
          'Card': radius(t.cardTheme.shape, 'Card'),
          'Dialog': radius(t.dialogTheme.shape, 'Dialog'),
          'BottomSheet': radius(t.bottomSheetTheme.shape, 'BottomSheet'),
          'Chip': radius(t.chipTheme.shape, 'Chip'),
          'SnackBar': radius(t.snackBarTheme.shape, 'SnackBar'),
          'Input': radiusInput(t.inputDecorationTheme.border, 'Input'),
          'Input fokus': radiusInput(
            t.inputDecorationTheme.focusedBorder,
            'Input fokus',
          ),
          'Tooltip': (t.tooltipTheme.decoration! as BoxDecoration).borderRadius!
              .resolve(TextDirection.ltr)
              .topLeft
              .x,
        };
        for (final e in dipakai.entries) {
          expect(
            set,
            contains(e.value),
            reason: '${e.key} memakai radius ${e.value}, di luar set Bentuk',
          );
        }
        expect(dipakai['FilledButton'], Bentuk.utama);
        expect(dipakai['OutlinedButton'], Bentuk.kontrol);
        expect(dipakai['Card'], Bentuk.kartu);
        expect(dipakai['Dialog'], Bentuk.lembar);
        expect(dipakai['BottomSheet'], Bentuk.lembar);
        expect(dipakai['Input'], Bentuk.kontrol);
        expect(dipakai['Tooltip'], Bentuk.kecil);
      });
    }
  });

  group('datar: kartu, app bar, dan navigasi tanpa elevasi', () {
    for (final (nama, bangun) in tema) {
      test('tema $nama', () {
        final t = bangun();
        expect(t.cardTheme.elevation, Elevasi.datar);
        expect(t.appBarTheme.elevation, Elevasi.datar);
        expect(t.appBarTheme.scrolledUnderElevation, Elevasi.datar);
        expect(t.navigationBarTheme.elevation, Elevasi.datar);
        expect(t.navigationRailTheme.elevation, Elevasi.datar);
        expect(
          t.filledButtonTheme.style!.elevation!.resolve({}),
          Elevasi.datar,
        );
        // Tanpa warna tint permukaan M3 (membuat permukaan keunguan/berwarna).
        expect(t.colorScheme.surfaceTint, Colors.transparent);
        expect(t.cardTheme.surfaceTintColor, Colors.transparent);
      });
    }
  });

  group('status: ikon dan kata, tidak hanya warna', () {
    for (final (nama, bangun) in tema) {
      testWidgets('semua status berlaku dan keputusan, tema $nama', (
        tester,
      ) async {
        final semua = <StatusTampil>[
          for (final s in StatusBerlaku.values) statusBerlaku(s),
          statusKeputusan('PASS')!,
          statusKeputusan('FAIL')!,
          for (final kode in [
            'diterima',
            'dikalibrasi',
            'perlu_diulang',
            'menunggu_pemeriksaan',
            'sertifikat_terbit',
            'siap_diambil',
            'diserahkan',
          ])
            statusPaket(kode, 'Tahap $kode'),
        ];
        await tester.pumpWidget(
          MaterialApp(
            theme: bangun(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(children: [for (final s in semua) ChipStatus(s)]),
              ),
            ),
          ),
        );
        for (final s in semua) {
          expect(s.label.trim(), isNotEmpty);
          expect(find.text(s.label), findsWidgets, reason: 'kata: ${s.label}');
          expect(
            find.byIcon(s.ikon),
            findsWidgets,
            reason: 'ikon untuk ${s.label}',
          );
        }
        expect(tester.takeException(), isNull);
      });
    }

    test(
      'istilah: "Lewat jadwal" dan "Masa berlaku berakhir", bukan kedaluwarsa',
      () {
        expect(StatusBerlaku.lewatJadwal.label, 'Lewat jadwal');
        expect(StatusBerlaku.berakhir.label, 'Masa berlaku berakhir');
        for (final s in StatusBerlaku.values) {
          expect(
            s.label.toLowerCase(),
            isNot(anyOf(contains('daluwarsa'), contains('adaluarsa'))),
            reason: 'istilah terlarang (keputusan K3): ${s.label}',
          );
        }
      },
    );

    test('FAIL tidak dilunakkan', () {
      expect(statusKeputusan('FAIL')!.label, 'Tidak memenuhi toleransi');
      expect(statusKeputusan('FAIL')!.nada, NadaStatus.gagal);
    });
  });
}
