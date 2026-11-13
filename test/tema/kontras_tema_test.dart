import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/pelapor_galat.dart';
import 'package:sidik_pelanggan/core/tema/palet_sidik.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/core/tema/warna_sidik.dart';
import 'package:sidik_pelanggan/widgets/tombol_sidik.dart';

/// Gerbang desain Pelanggan, bagian 2: KONTRAS pasangan token (WCAG 2.x), tema
/// terang DAN gelap.
///
/// Tiga lapis:
/// 1. Token mentah `PaletSidik` (tinta di atas permukaan, kobalt, status di atas
///    latar tipisnya, garis tegas). Ini menjaga NILAI palet.
/// 2. `ThemeData` yang dibangun `TemaSidik` (skema warna, tombol, isian,
///    navigasi, chip, segmen, snack): apa yang BENAR-BENAR dipakai widget.
/// 3. Tombol yang digambar `TombolSidik` (label terhadap isinya), semua ragam.
///
/// Ambang: teks biasa 4,5:1; komponen UI (tepi isian, ikon penting, isi tombol
/// terhadap latarnya, tepi kontrol) 3:1. Garis halus (`outlineVariant`, panel
/// terhadap latar) sengaja TIDAK diuji: itu pemisah dekoratif, tidak boleh
/// membawa makna sendiri (arti selalu diulang oleh kata, panah, atau tautan).
///
/// Kalau ada warna digeser dan tes ini berteriak: betulkan warnanya. Jangan
/// menurunkan ambang.
void main() {
  const ambangTeks = 4.5;
  const ambangKomponen = 3.0;

  for (final (nama, tema, w) in <(String, ThemeData, WarnaSidik)>[
    ('terang', TemaSidik.terang, WarnaSidik.terang),
    ('gelap', TemaSidik.gelap, WarnaSidik.gelap),
  ]) {
    final s = tema.colorScheme;
    final terang = nama == 'terang';

    void cek(String apa, Color depan, Color belakang, {double? ambang}) {
      final batas = ambang ?? ambangTeks;
      final r = _rasio(depan, belakang);
      expect(
        r,
        greaterThanOrEqualTo(batas),
        reason:
            '$apa di tema $nama cuma ${r.toStringAsFixed(2)}:1 '
            '(minimal $batas:1)',
      );
    }

    void cekUi(String apa, Color depan, Color belakang) =>
        cek(apa, depan, belakang, ambang: ambangKomponen);

    group('kontras token mentah, tema $nama', () {
      final permukaan = terang
          ? <(String, Color)>[
              ('permukaan', PaletSidik.permukaanTerang),
              ('latar', PaletSidik.latarTerang),
              ('permukaanRendah', PaletSidik.permukaanRendahTerang),
              ('permukaanTinggi', PaletSidik.permukaanTinggiTerang),
              ('permukaanTertinggi', PaletSidik.permukaanTertinggiTerang),
            ]
          : <(String, Color)>[
              ('permukaan', PaletSidik.permukaanGelap),
              ('latar', PaletSidik.latarGelap),
              ('permukaanRendah', PaletSidik.permukaanRendahGelap),
              ('permukaanTinggi', PaletSidik.permukaanTinggiGelap),
              ('permukaanTertinggi', PaletSidik.permukaanTertinggiGelap),
            ];
      final tinta = terang ? PaletSidik.teksTerang : PaletSidik.teksGelap;
      final tinta2 = terang
          ? PaletSidik.teksKeduaTerang
          : PaletSidik.teksKeduaGelap;
      final garis = terang ? PaletSidik.garisTerang : PaletSidik.garisGelap;
      final kobalt = terang ? PaletSidik.kobalt : PaletSidik.kobaltTerang;
      final kobaltTipis = terang
          ? PaletSidik.kobaltTipis
          : PaletSidik.kobaltGelapTipis;
      final kobaltTeks = terang
          ? PaletSidik.kobaltTua
          : PaletSidik.kobaltGelapTeks;
      final padaKobalt = terang
          ? PaletSidik.permukaanTerang
          : PaletSidik.kobaltTerangTua;

      test('tinta dan tinta kedua di semua permukaan', () {
        for (final (apa, p) in permukaan) {
          cek('tinta/$apa', tinta, p);
          cek('tinta kedua/$apa', tinta2, p);
        }
      });

      test('kobalt: teks, tombol utama, dan tik di atas kobalt tipis', () {
        for (final (apa, p) in permukaan) {
          cek('kobalt/$apa', kobalt, p);
        }
        cek('kobalt/kobalt tipis', kobalt, kobaltTipis);
        cek('teks kobalt/kobalt tipis', kobaltTeks, kobaltTipis);
        cek('label tombol utama/kobalt', padaKobalt, kobalt);
        // Komponen UI: isi tombol utama terhadap latar tempat ia berdiri.
        for (final (apa, p) in permukaan.take(2)) {
          cekUi('isi tombol utama/$apa', kobalt, p);
        }
      });

      test('empat nada status di atas latar tipis, permukaan, dan latar', () {
        final nada = terang
            ? <(String, Color, Color)>[
                ('lulus', PaletSidik.lulusTerang, PaletSidik.lulusLatarTerang),
                ('awas', PaletSidik.awasTerang, PaletSidik.awasLatarTerang),
                ('gagal', PaletSidik.gagalTerang, PaletSidik.gagalLatarTerang),
                (
                  'tunggu',
                  PaletSidik.tungguTerang,
                  PaletSidik.tungguLatarTerang,
                ),
              ]
            : <(String, Color, Color)>[
                ('lulus', PaletSidik.lulusGelap, PaletSidik.lulusLatarGelap),
                ('awas', PaletSidik.awasGelap, PaletSidik.awasLatarGelap),
                ('gagal', PaletSidik.gagalGelap, PaletSidik.gagalLatarGelap),
                ('tunggu', PaletSidik.tungguGelap, PaletSidik.tungguLatarGelap),
              ];
        for (final (apa, ink, latarTipis) in nada) {
          cek('stempel $apa/latar tipis', ink, latarTipis);
          for (final (nm, p) in permukaan.take(2)) {
            cek('$apa/$nm', ink, p);
          }
        }
      });

      test('garis tegas (tepi isian, plat, tik menunggu) 3:1', () {
        for (final (apa, p) in permukaan.take(2)) {
          cekUi('garis tegas/$apa', garis, p);
        }
        cekUi('garis tegas/permukaanTinggi', garis, permukaan[3].$2);
      });

      test('merah KAN terbaca di atas permukaan (lencana, 3:1)', () {
        cekUi(
          'merah KAN/permukaan',
          terang ? PaletSidik.kanMerah : PaletSidik.kanMerahGelap,
          permukaan.first.$2,
        );
      });

      test('lulus, gagal, dan awas beda terangnya, bukan cuma ronanya', () {
        // Hijau, merah, dan amber semuanya duduk di sumbu merah-hijau, sumbu
        // yang hilang buat mata deuteranopia dan buat fotokopi hitam-putih.
        // Jadi ketiganya wajib beda TERANGNYA (luminans relatif > 0,02), bukan
        // cuma beda warnanya. `tunggu` dikecualikan: dia abu tanpa rona,
        // kebeda lewat kejenuhan, dan memaksanya ikut aturan ini mendorongnya
        // jadi nyaris putih ("menunggu" yang paling menyala itu salah arti).
        //
        // Pengaman utamanya tetap bukan warna: tiap stempel SELALU membawa
        // ikon + kata (diuji di `token_tema_test.dart`). Aturan ini lapis
        // kedua. Aturannya sama dengan Lab, dan amber Pelanggan sama dengan
        // amber Lab (terang `#8C5C0A`, gelap `#DB9A2B`).
        final berona = <String, double>{
          'lulus': _luminansi(w.lulus),
          'gagal': _luminansi(w.gagal),
          'awas': _luminansi(w.awas),
        };
        final kunci = berona.keys.toList();
        for (var a = 0; a < kunci.length; a++) {
          for (var b = a + 1; b < kunci.length; b++) {
            final beda = (berona[kunci[a]]! - berona[kunci[b]]!).abs();
            expect(
              beda,
              greaterThan(0.02),
              reason:
                  '${kunci[a]} dan ${kunci[b]} di tema $nama terangnya nyaris '
                  'sama (beda ${beda.toStringAsFixed(4)})',
            );
          }
        }
      });
    });

    group('kontras dari ThemeData, tema $nama', () {
      final latar = tema.scaffoldBackgroundColor;
      final permukaan = <(String, Color)>[
        ('surface', s.surface),
        ('scaffold', latar),
        ('surfaceContainerLowest', s.surfaceContainerLowest),
        ('surfaceContainerLow', s.surfaceContainerLow),
        ('surfaceContainer', s.surfaceContainer),
        ('surfaceContainerHigh', s.surfaceContainerHigh),
        ('surfaceContainerHighest', s.surfaceContainerHighest),
      ];

      test('WarnaSidik di ThemeData sama dengan yang diuji', () {
        expect(tema.extension<WarnaSidik>(), w);
      });

      test('teks utama dan kedua di semua permukaan', () {
        for (final (apa, p) in permukaan) {
          cek('onSurface/$apa', s.onSurface, p);
          cek('onSurfaceVariant/$apa', s.onSurfaceVariant, p);
        }
      });

      test('primary sebagai TEKS/ikon (tautan, label navigasi terpilih)', () {
        for (final (apa, p) in permukaan) {
          cek('primary/$apa', s.primary, p);
        }
        cek('primary/primaryContainer', s.primary, s.primaryContainer);
      });

      test('outline (tepi kontrol) 3:1 di surface dan latar', () {
        cekUi('outline/surface', s.outline, s.surface);
        cekUi('outline/scaffold', s.outline, latar);
        cekUi(
          'outline/surfaceContainerHigh',
          s.outline,
          s.surfaceContainerHigh,
        );
      });

      test('pasangan on* terhadap wadahnya', () {
        cek('onPrimary/primary', s.onPrimary, s.primary);
        cek(
          'onPrimaryContainer/primaryContainer',
          s.onPrimaryContainer,
          s.primaryContainer,
        );
        cek('onSecondary/secondary', s.onSecondary, s.secondary);
        cek(
          'onSecondaryContainer/secondaryContainer',
          s.onSecondaryContainer,
          s.secondaryContainer,
        );
        cek('onError/error', s.onError, s.error);
        cek(
          'onErrorContainer/errorContainer',
          s.onErrorContainer,
          s.errorContainer,
        );
        cek('error/surface', s.error, s.surface);
        cek('error/scaffold', s.error, latar);
        cek(
          'onInverseSurface/inverseSurface',
          s.onInverseSurface,
          s.inverseSurface,
        );
        cek(
          'inversePrimary/inverseSurface',
          s.inversePrimary,
          s.inverseSurface,
        );
      });

      test('status WarnaSidik di latar tipis, permukaan, dan latar', () {
        for (final (apa, ink, tipis) in <(String, Color, Color)>[
          ('lulus', w.lulus, w.lulusLatar),
          ('awas', w.awas, w.awasLatar),
          ('gagal', w.gagal, w.gagalLatar),
          ('tunggu', w.tunggu, w.tungguLatar),
        ]) {
          cek('$apa/latar tipis', ink, tipis);
          cek('$apa/surface', ink, s.surface);
          cek('$apa/scaffold', ink, latar);
        }
        // Nada netral: onSurfaceVariant di atas surfaceContainerHigh.
        cek('netral/latar netral', s.onSurfaceVariant, s.surfaceContainerHigh);
        cekUi('merah KAN/surface', w.kanMerah, s.surface);
      });

      test('tombol: label terhadap isinya', () {
        // FilledButton: tema tidak menimpa warna, jadi M3 memakai onPrimary di
        // atas primary. Pemakaian nyata dibuktikan di grup TombolSidik bawah.
        final isi = tema.filledButtonTheme.style!;
        expect(isi.foregroundColor, isNull, reason: 'tema menimpa warna isi');
        expect(isi.backgroundColor, isNull, reason: 'tema menimpa warna isi');
        cek('label FilledButton (onPrimary)', s.onPrimary, s.primary);

        final garis = tema.outlinedButtonTheme.style!;
        final isiGaris = garis.backgroundColor == null
            ? s.surface
            : _w(garis.backgroundColor, 'background OutlinedButton');
        cek(
          'label OutlinedButton',
          _w(garis.foregroundColor, 'foreground OutlinedButton'),
          isiGaris,
        );
        cekUi(
          'tepi OutlinedButton/latar',
          _tepi(garis.side, 'side OutlinedButton'),
          latar,
        );
        cekUi(
          'tepi OutlinedButton/permukaan',
          _tepi(garis.side, 'side OutlinedButton'),
          s.surface,
        );

        final teks = tema.textButtonTheme.style!;
        for (final (apa, p) in [('surface', s.surface), ('scaffold', latar)]) {
          cek(
            'label TextButton/$apa',
            _w(teks.foregroundColor, 'foreground TextButton'),
            p,
          );
        }
      });

      test('tombol utama: isi terhadap latar (komponen UI 3:1)', () {
        cekUi('isi FilledButton/surface', s.primary, s.surface);
        cekUi('isi FilledButton/scaffold', s.primary, latar);
      });

      test('isian: placeholder, label, bantuan, galat terhadap isiannya', () {
        final d = tema.inputDecorationTheme;
        final isi = d.fillColor!;
        cek('hint', _gaya(d.hintStyle, 'hintStyle'), isi);
        cek('label', _gaya(d.labelStyle, 'labelStyle'), isi);
        cek('helper', _gaya(d.helperStyle, 'helperStyle'), isi);
        cek('error', _gaya(d.errorStyle, 'errorStyle'), isi);
        cek('hint/surface', _gaya(d.hintStyle, 'hintStyle'), s.surface);
        cek('hint/scaffold', _gaya(d.hintStyle, 'hintStyle'), latar);
      });

      test('isian: tepi dan fokus terhadap isian dan permukaan (3:1)', () {
        final d = tema.inputDecorationTheme;
        final isi = d.fillColor!;
        for (final (apa, b) in [
          ('enabled', d.enabledBorder),
          ('focused', d.focusedBorder),
          ('error', d.errorBorder),
          ('focusedError', d.focusedErrorBorder),
        ]) {
          final warna = b!.borderSide.color;
          cekUi('tepi $apa/isian', warna, isi);
          cekUi('tepi $apa/surface', warna, s.surface);
        }
        cekUi(
          'tepi enabled/scaffold',
          d.enabledBorder!.borderSide.color,
          latar,
        );
        // Ikon di dalam isian.
        cekUi('ikon awalan', d.prefixIconColor!, isi);
        cekUi('ikon akhiran', d.suffixIconColor!, isi);
      });

      test('app bar: judul dan ikon terhadap latarnya', () {
        final a = tema.appBarTheme;
        final bg = a.backgroundColor!;
        cek('foreground', a.foregroundColor!, bg);
        cek('judul', a.titleTextStyle!.color!, bg);
        cekUi('ikon', a.iconTheme!.color!, bg);
      });

      test(
        'navigasi bawah dan rail: label serta ikon, terpilih atau tidak',
        () {
          final n = tema.navigationBarTheme;
          final bg = n.backgroundColor!;
          // Indikator bisa transparan (tanpa kapsul): campur dulu ke latarnya.
          final dasarTerpilih = Color.alphaBlend(n.indicatorColor!, bg);
          for (final terpilih in [false, true]) {
            final k = terpilih
                ? <WidgetState>{WidgetState.selected}
                : <WidgetState>{};
            final apa = terpilih ? 'terpilih' : 'biasa';
            final dasar = terpilih ? dasarTerpilih : bg;
            cek('label nav $apa', n.labelTextStyle!.resolve(k)!.color!, dasar);
            cekUi('ikon nav $apa', n.iconTheme!.resolve(k)!.color!, dasar);
          }

          final r = tema.navigationRailTheme;
          final rbg = r.backgroundColor!;
          final rTerpilih = Color.alphaBlend(
            r.indicatorColor ?? s.secondaryContainer,
            rbg,
          );
          cek('label rail biasa', r.unselectedLabelTextStyle!.color!, rbg);
          cek(
            'label rail terpilih',
            r.selectedLabelTextStyle!.color!,
            rTerpilih,
          );
          cekUi('ikon rail biasa', r.unselectedIconTheme!.color!, rbg);
          cekUi('ikon rail terpilih', r.selectedIconTheme!.color!, rTerpilih);
        },
      );

      test('chip: label terhadap isi, tepi terhadap latar', () {
        final c = tema.chipTheme;
        const terpilih = <WidgetState>{WidgetState.selected};
        cek(
          'label chip',
          _dariState(c.labelStyle!.color, {}),
          c.backgroundColor!,
        );
        cek(
          'label chip terpilih',
          _dariState(c.labelStyle!.color, terpilih),
          c.selectedColor!,
        );
        cek(
          'label chip terpilih (secondary)',
          c.secondaryLabelStyle!.color!,
          c.selectedColor!,
        );
        cek('tanda centang chip terpilih', c.checkmarkColor!, c.selectedColor!);
        cekUi('tepi chip/surface', c.side!.color, s.surface);
        cekUi('tepi chip/scaffold', c.side!.color, latar);
      });

      test('segmen (Daftar | Arsip): label dan tepi', () {
        final g = tema.segmentedButtonTheme.style!;
        const terpilih = <WidgetState>{WidgetState.selected};
        const biasa = <WidgetState>{};
        for (final (apa, k) in [('biasa', biasa), ('terpilih', terpilih)]) {
          cek(
            'label segmen $apa',
            g.foregroundColor!.resolve(k)!,
            g.backgroundColor!.resolve(k)!,
          );
        }
        cekUi('tepi segmen/surface', g.side!.resolve(biasa)!.color, s.surface);
        cekUi('tepi segmen/scaffold', g.side!.resolve(biasa)!.color, latar);
      });

      test('snack bar, tooltip, dan progres', () {
        final sb = tema.snackBarTheme;
        cek('teks snack', sb.contentTextStyle!.color!, sb.backgroundColor!);
        cek('aksi snack', sb.actionTextColor!, sb.backgroundColor!);
        final tt = tema.tooltipTheme;
        final tipBg = (tt.decoration! as BoxDecoration).color!;
        cek('tooltip', tt.textStyle!.color!, tipBg);
        final p = tema.progressIndicatorTheme;
        cekUi('progres/jalur', p.color!, p.linearTrackColor!);
        cekUi('progres/surface', p.color!, s.surface);
      });

      test('teks daftar (ListTile) terhadap surface', () {
        final l = tema.listTileTheme;
        cek('judul list', l.textColor!, s.surface);
        cekUi('ikon list', l.iconColor!, s.surface);
        cek('subjudul list', l.subtitleTextStyle!.color!, s.surface);
      });
    });
  }

  group('tombol TombolSidik: label terhadap isinya, semua ragam', () {
    for (final (nama, tema) in <(String, ThemeData)>[
      ('terang', TemaSidik.terang),
      ('gelap', TemaSidik.gelap),
    ]) {
      for (final ragam in RagamTombol.values) {
        testWidgets('${ragam.name}, tema $nama', (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: tema,
              home: Scaffold(
                body: Center(
                  child: TombolSidik(
                    label: 'Lihat PDF',
                    ragam: ragam,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          );
          final paragraf = tester.renderObject<RenderParagraph>(
            find.text('Lihat PDF'),
          );
          final label = (paragraf.text as TextSpan).style!.color!;
          final bahan = tester.widget<Material>(
            find
                .descendant(
                  of: find.bySubtype<ButtonStyleButton>(),
                  matching: find.byType(Material),
                )
                .first,
          );
          // Tombol teks tak berisi: ia duduk di atas surface atau latar layar.
          final dasar = <Color>[
            if (bahan.color != null && bahan.color!.a > 0)
              bahan.color!
            else ...[
              tema.colorScheme.surface,
              tema.scaffoldBackgroundColor,
            ],
          ];
          for (final isi in dasar) {
            expect(
              _rasio(label, isi),
              greaterThanOrEqualTo(4.5),
              reason:
                  'label tombol ${ragam.name} di tema $nama cuma '
                  '${_rasio(label, isi).toStringAsFixed(2)}:1',
            );
          }
        });
      }
    }
  });

  testWidgets('kartu galat darurat (KartuGalatRamah) terbaca', (tester) async {
    // Tanpa Theme sama sekali: warnanya dari PaletSidik, jadi nilai yang
    // digambar widget itulah yang diukur.
    await tester.pumpWidget(const KartuGalatRamah());
    final latar = tester
        .widget<ColoredBox>(
          find.descendant(
            of: find.byType(KartuGalatRamah),
            matching: find.byType(ColoredBox),
          ),
        )
        .color;
    final paragraf = tester.renderObject<RenderParagraph>(
      find.text(KartuGalatRamah.pesan),
    );
    final tinta = (paragraf.text as TextSpan).style!.color!;
    expect(
      _rasio(tinta, latar),
      greaterThanOrEqualTo(4.5),
      reason: 'kartu galat darurat cuma ${_rasio(tinta, latar)}:1',
    );
  });

  test('tidak ada token yang lupa diisi antar-tema', () {
    // lerp harus menghasilkan nilai di antara keduanya, bukan melempar.
    final tengah = WarnaSidik.terang.lerp(WarnaSidik.gelap, 0.5);
    expect(tengah, isA<WarnaSidik>());
    expect(tengah.lulus, isNot(equals(WarnaSidik.terang.lulus)));
  });
}

/// Warna dari `WidgetStateProperty` pada keadaan biasa (tanpa state).
Color _w(WidgetStateProperty<Color?>? p, String apa) {
  final warna = p?.resolve(const <WidgetState>{});
  expect(warna, isNotNull, reason: '$apa tidak diatur di tema');
  return warna!;
}

Color _tepi(WidgetStateProperty<BorderSide?>? p, String apa) {
  final sisi = p?.resolve(const <WidgetState>{});
  expect(sisi, isNotNull, reason: '$apa tidak diatur di tema');
  return sisi!.color;
}

/// Warna yang bisa berupa `WidgetStateColor`, dibaca pada keadaan [state].
Color _dariState(Color? warna, Set<WidgetState> state) {
  expect(warna, isNotNull);
  return WidgetStateProperty.resolveAs<Color>(warna!, state);
}

Color _gaya(TextStyle? g, String apa) {
  expect(g?.color, isNotNull, reason: '$apa tidak punya warna');
  return g!.color!;
}

double _luminansi(Color c) {
  double k(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * k(c.r) + 0.7152 * k(c.g) + 0.0722 * k(c.b);
}

/// Rasio kontras. Warna depan yang tembus pandang dicampur dulu ke latarnya.
double _rasio(Color depan, Color belakang) {
  final a = depan.a < 1 ? Color.alphaBlend(depan, belakang) : depan;
  final la = _luminansi(a);
  final lb = _luminansi(belakang);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
