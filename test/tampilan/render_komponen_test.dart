// Harness render komponen bersama "Jejak" (Paket 2): galeri semua komponen dalam
// semua keadaannya, pada tiga ukuran gerbang x dua tema.
//
// Ukuran: HP 392x?, HP sempit 320 dp dengan huruf 1,3x, tablet 840 dp. Font
// Inter dimuat dari aset (`siapkanTesFitur`), jadi lebar teks sama dengan HP.
//
// GAGAL bila: ada luapan atau galat render; ada teks yang kontrasnya < 4,5:1
// (dari pohon widget, bukan sampel piksel); ada sasaran sentuh < 48 dp atau
// sasaran tanpa label (HP 392 dan HP sempit); ada teks "kedaluwarsa" atau
// pemisah " · ". Galeri mengimpor SEMUA komponen, jadi berkas komponen tidak
// pernah yatim dari harness.
//
// PNG hanya bila `SIDIK_PNG_DIR` diisi (folder di luar repo):
//
//   SIDIK_PNG_DIR=/tmp/jejak flutter test test/tampilan/render_komponen_test.dart
//
// Nama: `komponen-<halaman>_<ukuran>_<tema>.png`. Tanpa golden: gambar Windows
// tidak boleh jadi acuan (lihat docs/standar-kualitas-desain.md).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/spasi.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/font_ikon.dart';
import '../dukungan/galeri_komponen.dart';
import '../dukungan/layar_uji.dart';
import '../dukungan/ukur_komponen.dart';

enum _Ukuran {
  hp392('hp392', 392, 1.0, 2.0),
  sempit('sempit', 320, 1.3, 2.0),
  tablet('tablet', 840, 1.0, 1.5);

  const _Ukuran(this.nama, this.lebar, this.skala, this.piksel);
  final String nama;
  final double lebar;
  final double skala;
  final double piksel;

  bool get periksaPedoman => this != tablet;
}

/// Tinggi viewport uji: cukup untuk seluruh halaman galeri sekaligus (daftar
/// tidak malas), supaya pedoman sentuh memeriksa semuanya.
const _tinggi = 7000.0;

void main() {
  setUpAll(() async {
    await siapkanTesFitur();
    await muatFontIkonMaterial();
  });

  final folder = Platform.environment['SIDIK_PNG_DIR'];
  if (folder != null) Directory(folder).createSync(recursive: true);
  final hanya = Platform.environment['SIDIK_HALAMAN']?.split(',').toSet();

  for (final u in _Ukuran.values) {
    for (final gelap in const [false, true]) {
      for (final h in galeriHalaman.entries) {
        if (hanya != null && !hanya.contains(h.key)) continue;
        final tema = gelap ? 'gelap' : 'terang';
        testWidgets('komponen ${h.key} · ${u.nama} · $tema', (tester) async {
          layarHp(tester, lebar: u.lebar, tinggi: _tinggi);
          final semantik = u.periksaPedoman ? tester.ensureSemantics() : null;
          final galat = <String>[];
          final kunci = GlobalKey();
          final bawaan = FlutterError.onError;
          try {
            FlutterError.onError = (d) =>
                galat.add(d.exceptionAsString().split('\n').first);
            try {
              await tester.pumpWidget(
                aplikasiUji(
                  SingleChildScrollView(
                    child: RepaintBoundary(
                      key: kunci,
                      child: Builder(
                        builder: (context) => ColoredBox(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: Spasi.lebarKonten,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  Spasi.sisi,
                                  Spasi.lg,
                                  Spasi.sisi,
                                  Spasi.xxl,
                                ),
                                child: h.value(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  gelap: gelap,
                  skala: u.skala,
                  bergulir: false,
                ),
              );
              await tester.pumpAndSettle();
              if (folder != null) {
                final batas = tester.renderObject<RenderRepaintBoundary>(
                  find.byKey(kunci),
                );
                await tester.runAsync(() async {
                  final gambar = await batas.toImage(pixelRatio: u.piksel);
                  final data = await gambar.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  File(
                    '$folder/komponen-${h.key}_${u.nama}_$tema.png',
                  ).writeAsBytesSync(data!.buffer.asUint8List());
                });
              }
            } finally {
              // Kembalikan SEBELUM expect() apa pun (lihat render_layar_test).
              FlutterError.onError = bawaan;
            }
            expect(tester.takeException(), isNull);
            expect(galat.toSet().toList(), isEmpty, reason: 'galat render');

            final semua = semuaTeks(tester, find.byType(Scaffold));
            expect(
              semua.toLowerCase(),
              isNot(anyOf(contains('daluwarsa'), contains('adaluarsa'))),
              reason:
                  'istilah terlarang (K3): pakai "Lewat jadwal" dan '
                  '"Masa berlaku berakhir"',
            );
            expect(
              semua,
              isNot(contains(' · ')),
              reason: 'rangkaian A · B · C',
            );
            expect(
              pelanggaranKontrasTeks(tester, find.byType(Scaffold)),
              isEmpty,
            );
            if (u.periksaPedoman) await periksaPedomanSentuh(tester);
          } finally {
            semantik?.dispose();
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
