// Pemotret PNG untuk DRAF "terima undangan, email yang sudah punya akun"
// (kontrak server 12 Nov 2026). Hanya memotret bila `SIDIK_PNG_DIR` diisi
// (folder di luar repo); tanpa itu semua tes di sini dilewati.
//
//   SIDIK_PNG_DIR=<folder> SIDIK_PNG_AWALAN=sesudah \
//     flutter test test/tampilan/draf_undangan_akun_lama_test.dart
//
// `SIDIK_PNG_AWALAN` (bawaan `sesudah`) menjadi awalan nama berkas, supaya
// kode yang sama bisa dijalankan di pohon `origin/main` untuk gambar `sebelum`.
// Berkas ini hanya memakai API yang sudah ada di `origin/main`.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/screens/auth/terima_undangan_screen.dart';
import 'package:sidik_pelanggan/widgets/kolom_isian.dart';
import 'package:sidik_pelanggan/widgets/logo_sidik.dart';

import '../dukungan/dukungan.dart';
import '../dukungan/fixture_fitur.dart';
import '../dukungan/font_ikon.dart';
import '../dukungan/layar_uji.dart';

class _Sesi extends SesiController {
  _Sesi({this.galat, this.akunSudahAda = false});

  final GalatApi? galat;
  final bool akunSudahAda;

  @override
  Future<Sesi?> build() async => null;

  @override
  Future<bool> terimaUndangan({
    required String email,
    required String kode,
    required String nama,
    required String telepon,
    String? jabatan,
    required String sandi,
    required bool setujuSyarat,
  }) async {
    if (galat != null) throw galat!;
    return akunSudahAda;
  }
}

const _kontak = InfoAplikasi(
  email: 'lab@ptsidik.example',
  whatsapp: '+62 812-0000-0285',
);

Finder _kolom(String label) => find.descendant(
  of: find.widgetWithText(KolomIsian, label, skipOffstage: false),
  matching: find.byType(TextField),
  skipOffstage: false,
);

Future<void> _isi(WidgetTester tester) async {
  Future<void> isi(String label, String nilai) async {
    await tester.ensureVisible(_kolom(label));
    await tester.enterText(_kolom(label), nilai);
    await tester.pump();
  }

  await isi('Email', 'budi@contoh.example');
  await isi('Kode undangan', 'K7M2QP4R');
  await isi('Nama lengkap', 'Budi Hartono');
  await isi('Nomor HP', '081234567890');
  await isi('Buat sandi', 'Kalibrasi#2026Sidik');
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pump();
}

Future<void> _kirim(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(FilledButton));
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
}

void main() {
  final folder = Platform.environment['SIDIK_PNG_DIR'];
  final awalan = Platform.environment['SIDIK_PNG_AWALAN'] ?? 'sesudah';
  final lewati = folder == null
      ? 'hanya memotret bila SIDIK_PNG_DIR diisi'
      : null;

  setUpAll(() async {
    await siapkanTesFitur();
    await muatFontIkonMaterial();
    if (folder != null) Directory(folder).createSync(recursive: true);
  });

  Future<void> potret(
    WidgetTester tester,
    String nama, {
    required _Sesi sesi,
    Future<void> Function(WidgetTester)? langkah,
    InfoAplikasi info = InfoAplikasi.kosong,
  }) async {
    layarHp(tester, lebar: 392, tinggi: 1500);
    final kunci = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrideDasar(
          tambahan: [
            sesiProvider.overrideWith(() => sesi),
            infoAplikasiProvider.overrideWith((ref) async => info),
            layananProvider.overrideWithValue(LayananUji()),
          ],
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TemaSidik.terang,
          builder: (context, child) => RepaintBoundary(
            key: kunci,
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.0,
              child: child!,
            ),
          ),
          home: const TerimaUndanganScreen(),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage(LogoSidik.aset),
        tester.element(find.byType(MaterialApp)),
      ),
    );
    await tester.pumpAndSettle();
    if (langkah != null) await langkah(tester);
    expect(tester.takeException(), isNull);
    final batas = tester.renderObject<RenderRepaintBoundary>(find.byKey(kunci));
    await tester.runAsync(() async {
      final gambar = await batas.toImage(pixelRatio: 2.0);
      final data = await gambar.toByteData(format: ui.ImageByteFormat.png);
      File(
        '$folder/${awalan}_$nama.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  testWidgets('1 formulir awal', skip: lewati != null, (tester) async {
    await potret(tester, '1_formulir_awal', sesi: _Sesi(), info: _kontak);
  });

  testWidgets('2 sandi akun lama salah', skip: lewati != null, (tester) async {
    await potret(
      tester,
      '2_sandi_akun_lama_salah',
      sesi: _Sesi(
        galat: const GalatApi(
          status: 422,
          kode: 'sandi_akun_lama_salah',
          pesan:
              'Email ini sudah punya akun SIDIK Pelanggan. Isi kolom sandi '
              'dengan sandi akun Anda yang sudah ada, bukan sandi baru.',
        ),
      ),
      info: _kontak,
      langkah: (t) async {
        await _isi(t);
        await _kirim(t);
      },
    );
  });

  testWidgets('3 akun terdaftar di lab lain', skip: lewati != null, (
    tester,
  ) async {
    await potret(
      tester,
      '3_organisasi_berbeda',
      sesi: _Sesi(
        galat: const GalatApi(
          status: 422,
          kode: 'undangan_organisasi_berbeda',
          pesan:
              'Akun Anda terdaftar di laboratorium lain, jadi undangan ini '
              'tidak bisa ditukar di akun itu. Hubungi PT Sidik.',
        ),
      ),
      info: _kontak,
      langkah: (t) async {
        await _isi(t);
        await _kirim(t);
      },
    );
  });

  testWidgets('4 dialog akun sudah ada', skip: lewati != null, (tester) async {
    await potret(
      tester,
      '4_dialog_akun_sudah_ada',
      sesi: _Sesi(akunSudahAda: true),
      info: _kontak,
      langkah: (t) async {
        await _isi(t);
        await _kirim(t);
        expect(find.text('Email ini sudah punya akun'), findsOneWidget);
      },
    );
  });
}
