// Pratinjau PDF: kepala layar dan bilah aksi (P5d-B, REVISI-2 butir 6). Isi PDF
// beku (penampilnya palsu di sini, sama seperti pratinjau_pdf_test); yang dijaga
// di sini hanya kepala layar (judul tidak meluber, unduh di tempat tetap) dan
// bilah (halaman terlihat, navigasi dan tampilan dikelompokkan), serta jalan
// keluar tiap keadaan memuat dan gagal.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/api_pelanggan.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/models/akun.dart';
import 'package:sidik_pelanggan/models/data_pelanggan.dart';
import 'package:sidik_pelanggan/providers/pdf_provider.dart';
import 'package:sidik_pelanggan/providers/sesi_provider.dart';
import 'package:sidik_pelanggan/providers/tautan_provider.dart';
import 'package:sidik_pelanggan/screens/sertifikat/pratinjau_pdf_screen.dart';
import 'package:sidik_pelanggan/widgets/lembar_tanya_admin.dart';
import 'package:sidik_pelanggan/widgets/penampil_pdf.dart';
import 'package:sidik_pelanggan/widgets/tombol_sidik.dart';

import 'dukungan/dukungan.dart';
import 'dukungan/fixture_fitur.dart';
import 'dukungan/layar_uji.dart';

/// Penampil palsu: dokumen siap (atau gagal) sesudah dibuka, [jumlah] halaman.
PembangunPenampilPdf _penampil({int jumlah = 3, bool gagal = false}) =>
    (context, arg) => _Palsu(arg: arg, jumlah: jumlah, gagal: gagal);

class _Palsu extends StatefulWidget {
  const _Palsu({required this.arg, required this.jumlah, required this.gagal});

  final ArgumenPenampilPdf arg;
  final int jumlah;
  final bool gagal;

  @override
  State<_Palsu> createState() => _PalsuState();
}

class _PalsuState extends State<_Palsu> {
  @override
  void initState() {
    super.initState();
    final k = widget.arg.kontrol;
    k.pasangAksi(
      this,
      keHalaman: (h) async => k.halamanBerganti(h),
      zoom: (_) {},
    );
    Future<void>.microtask(() {
      if (widget.gagal) {
        k.dokumenGagal(Exception('rusak'));
      } else {
        k.dokumenSiap(widget.jumlah, halaman: k.halaman);
      }
    });
  }

  @override
  void dispose() {
    widget.arg.kontrol.lepasAksi(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Center(child: Text('PDF palsu'));
}

/// Layanan palsu: unduhan berhasil atau gagal dengan [galatUnduh]; mencatat
/// sertifikat yang dibuka di aplikasi luar.
class _Layanan extends LayananUji {
  _Layanan({this.galatUnduh});

  final Object? galatUnduh;
  final dibukaLuar = <int>[];

  @override
  Future<Uint8List> unduhPdf(Sertifikat s) async {
    final g = galatUnduh;
    if (g != null) throw g;
    return Uint8List.fromList(ServerFitur.pdf);
  }

  @override
  Future<String> unduhDanBukaPdf(Sertifikat s) async {
    dibukaLuar.add(s.id);
    return 'tidak-dipakai';
  }
}

/// Layanan yang menahan unduhan sampai [lepas]: keadaan memuat tetap tampil.
class _LayananLambat extends _Layanan {
  final _tahan = Completer<Uint8List>();

  @override
  Future<Uint8List> unduhPdf(Sertifikat s) => _tahan.future;

  void lepas() => _tahan.complete(Uint8List.fromList(ServerFitur.pdf));
}

InfoAplikasi _info() => InfoAplikasi.dariJson({
  'kontak': {
    'whatsapp_url': 'https://wa.me/6282260060037',
    'email': 'sidikkalibrasi@pt-sidik.com',
  },
});

Sertifikat _sertifikat({String nomor = 'CAL/ALFA/0011'}) => Sertifikat.dariJson(
  sertifikatJson(11, nomor, namaAlat: 'Jangka Sorong Digital'),
);

Future<_Layanan> _buka(
  WidgetTester tester, {
  Sertifikat? sertifikat,
  Object? galatUnduh,
  bool gagalMembuka = false,
  InfoAplikasi? info,
  double skala = 1.0,
  double lebar = 392,
  List<Uri>? dibuka,
}) async {
  layarHp(tester, lebar: lebar, tinggi: 800);
  final layanan = _Layanan(galatUnduh: galatUnduh);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...overrideFitur(
          ServerFitur({3: DataPerusahaan(nama: 'PT Alfa')}),
          tambahan: [
            penampilPdfProvider.overrideWithValue(
              _penampil(gagal: gagalMembuka),
            ),
            infoAplikasiProvider.overrideWith((ref) async => info ?? _info()),
            pembukaTautanProvider.overrideWithValue((uri) async {
              dibuka?.add(uri);
              return true;
            }),
          ],
        ),
        layananProvider.overrideWithValue(layanan),
      ],
      child: MaterialApp(
        theme: TemaSidik.terang,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: skala,
          maxScaleFactor: skala,
          child: child!,
        ),
        home: PratinjauPdfScreen(sertifikat: sertifikat ?? _sertifikat()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return layanan;
}

void main() {
  setUpAll(siapkanTesFitur);

  group('kepala layar', () {
    testWidgets('nomor sertifikat utuh dan tombol Unduh PDF di kepala', (
      tester,
    ) async {
      final layanan = await _buka(tester);
      final bar = find.byType(AppBar);
      expect(
        find.descendant(of: bar, matching: find.text('CAL/ALFA/0011')),
        findsOneWidget,
      );
      final unduh = find.descendant(
        of: bar,
        matching: find.byTooltip('Unduh PDF'),
      );
      expect(unduh, findsOneWidget);
      expect(tester.getSize(unduh).width, greaterThanOrEqualTo(48));
      await tester.tap(unduh);
      await tester.pumpAndSettle();
      expect(layanan.dibukaLuar, [11], reason: 'jalur yang sama dengan detail');
    });

    testWidgets('nomor panjang di 320 dp x 1,3: mengecil, tidak meluber atau '
        'dipotong', (tester) async {
      await _buka(
        tester,
        sertifikat: _sertifikat(
          nomor: 'CAL/INSTRUMENTASI-PRESISI/2026/11/0001234567',
        ),
        skala: 1.3,
        lebar: 320,
      );
      expect(tester.takeException(), isNull);
      final judul = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(FittedBox),
      );
      expect(judul, findsOneWidget);
      // Teks tetap satu baris dan tidak keluar dari kotak judul.
      final teks = tester.getRect(
        find.descendant(of: judul, matching: find.byType(Text)),
      );
      final kotak = tester.getRect(judul);
      expect(teks.right, lessThanOrEqualTo(kotak.right + 0.5));
      expect(teks.height, lessThan(30));
    });

    testWidgets('Unduh PDF mati saat memuat; tersedia sesudah tampil', (
      tester,
    ) async {
      layarHp(tester, lebar: 392, tinggi: 800);
      final layanan = _LayananLambat();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrideFitur(
              ServerFitur({3: DataPerusahaan(nama: 'PT Alfa')}),
              tambahan: [
                penampilPdfProvider.overrideWithValue(_penampil()),
                infoAplikasiProvider.overrideWith((ref) async => _info()),
              ],
            ),
            layananProvider.overrideWithValue(layanan),
          ],
          child: MaterialApp(
            theme: TemaSidik.terang,
            home: PratinjauPdfScreen(sertifikat: _sertifikat()),
          ),
        ),
      );
      // Belum selesai diunduh: tombol mati, ada "Batal".
      await tester.pump();
      expect(find.text('Menyiapkan PDF…'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      IconButton unduh() => tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.download_outlined),
          matching: find.byType(IconButton),
        ),
      );
      expect(unduh().onPressed, isNull);
      layanan.lepas();
      await tester.pumpAndSettle();
      expect(find.text('Menyiapkan PDF…'), findsNothing);
      expect(unduh().onPressed, isNotNull);
    });

    testWidgets('Batal saat memuat menutup layar', (tester) async {
      layarHp(tester, lebar: 392, tinggi: 800);
      final layanan = _LayananLambat();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...overrideFitur(
              ServerFitur({3: DataPerusahaan(nama: 'PT Alfa')}),
              tambahan: [penampilPdfProvider.overrideWithValue(_penampil())],
            ),
            layananProvider.overrideWithValue(layanan),
          ],
          child: MaterialApp(
            theme: TemaSidik.terang,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          PratinjauPdfScreen(sertifikat: _sertifikat()),
                    ),
                  ),
                  child: const Text('Buka'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Batal'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.byType(PratinjauPdfScreen), findsNothing);
    });
  });

  group('bilah aksi', () {
    testWidgets(
      'halaman terlihat; navigasi dan tampilan dua kelompok bernama',
      (tester) async {
        final semantik = tester.ensureSemantics();
        await _buka(tester);
        expect(find.text('Halaman 1 dari 3'), findsOneWidget);
        final nav = find.bySemanticsLabel('Navigasi halaman');
        final tampil = find.bySemanticsLabel('Tampilan dokumen');
        expect(nav, findsOneWidget);
        expect(tampil, findsOneWidget);
        // Panah halaman di kelompok navigasi, tiga alat di kelompok tampilan.
        for (final k in ['Halaman sebelumnya', 'Halaman berikutnya']) {
          expect(
            find.descendant(of: nav, matching: find.byTooltip(k)),
            findsOneWidget,
            reason: k,
          );
        }
        for (final k in ['Perkecil', 'Perbesar', 'Putar']) {
          expect(
            find.descendant(of: tampil, matching: find.text(k)),
            findsOneWidget,
            reason: k,
          );
        }
        // Kelompok navigasi di atas kelompok tampilan.
        expect(
          tester.getTopLeft(nav).dy,
          lessThan(tester.getTopLeft(tampil).dy),
        );
        semantik.dispose();
      },
    );

    testWidgets('semua target sentuh bilah >= 48 dp di 320 dp x 1,3', (
      tester,
    ) async {
      await _buka(tester, skala: 1.3, lebar: 320);
      expect(tester.takeException(), isNull);
      for (final k in ['Perkecil', 'Perbesar', 'Putar']) {
        final r = tester.getRect(
          find.ancestor(of: find.text(k), matching: find.byType(InkWell)).first,
        );
        expect(r.width, greaterThanOrEqualTo(48), reason: k);
        expect(r.height, greaterThanOrEqualTo(48), reason: k);
      }
    });
  });

  group('jalan keluar saat gagal', () {
    testWidgets('unduh gagal (server): Coba lagi, Buka di aplikasi PDF lain, '
        'dan Tanya admin', (tester) async {
      final dibuka = <Uri>[];
      final layanan = await _buka(
        tester,
        galatUnduh: const GalatApi(status: 500, pesan: 'Server sedang sibuk.'),
        dibuka: dibuka,
      );
      expect(find.text('Server sedang sibuk.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Buka di aplikasi PDF lain'), findsOneWidget);
      expect(find.text('Tanya admin tentang sertifikat ini'), findsOneWidget);
      // Unduh di kepala tetap ada (kecuali dibatalkan).
      expect(find.byTooltip('Unduh PDF'), findsOneWidget);

      await tester.tap(find.text('Buka di aplikasi PDF lain'));
      await tester.pumpAndSettle();
      expect(layanan.dibukaLuar, [11]);

      // Tanya admin: pratinjau pesan berisi nomor, alat, dan status.
      await tester.tap(find.text('Tanya admin tentang sertifikat ini'));
      await tester.pumpAndSettle();
      expect(find.byType(LembarTanyaAdmin), findsOneWidget);
      final pesan = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .data!;
      expect(pesan, contains('- Nomor sertifikat: CAL/ALFA/0011'));
      expect(pesan, contains('- Alat: Jangka Sorong Digital'));
      await tester.tap(find.text('Buka WhatsApp'));
      await tester.pumpAndSettle();
      expect(dibuka.single.host, 'wa.me');
      expect(dibuka.single.queryParameters['text'], pesan);
    });

    testWidgets('dibatalkan (410): tanpa Coba lagi dan tanpa unduh; Tanya '
        'admin tetap ada', (tester) async {
      await _buka(
        tester,
        galatUnduh: const GalatApi(
          status: 410,
          pesan: 'Sertifikat ini sudah dibatalkan lab.',
        ),
      );
      expect(find.text('Sertifikat ini sudah dibatalkan lab.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
      expect(find.text('Buka di aplikasi PDF lain'), findsNothing);
      expect(find.text('Tanya admin tentang sertifikat ini'), findsOneWidget);
      final unduh = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.download_outlined),
          matching: find.byType(IconButton),
        ),
      );
      expect(unduh.onPressed, isNull);
    });

    testWidgets('penampil gagal: Buka di aplikasi PDF lain dan Tanya admin', (
      tester,
    ) async {
      await _buka(tester, gagalMembuka: true);
      expect(
        find.textContaining('tidak bisa ditampilkan di aplikasi'),
        findsOneWidget,
      );
      expect(find.text('Buka di aplikasi PDF lain'), findsOneWidget);
      expect(find.text('Tanya admin tentang sertifikat ini'), findsOneWidget);
    });

    testWidgets('tanpa kontak dari server: tidak ada tombol Tanya admin', (
      tester,
    ) async {
      await _buka(
        tester,
        galatUnduh: const GalatApi(status: 500, pesan: 'Server sedang sibuk.'),
        info: InfoAplikasi.kosong,
      );
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Tanya admin tentang sertifikat ini'), findsNothing);
    });

    testWidgets('tombol-tombol galat >= 48 dp di 320 dp x 1,3', (tester) async {
      await _buka(
        tester,
        galatUnduh: const GalatApi(status: 500, pesan: 'Server sedang sibuk.'),
        skala: 1.3,
        lebar: 320,
      );
      expect(tester.takeException(), isNull);
      for (final tombol in tester.widgetList<TombolSidik>(
        find.byType(TombolSidik),
      )) {
        final r = tester.getRect(
          find.widgetWithText(TombolSidik, tombol.label),
        );
        expect(r.height, greaterThanOrEqualTo(48), reason: tombol.label);
      }
    });
  });
}
