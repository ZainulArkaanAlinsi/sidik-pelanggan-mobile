// Komponen bersama di lib/widgets: chip status, tombol, lencana KAN,
// bagian, dan pemusat isi. Diuji di terang dan gelap, dan pada 320 dp dengan
// huruf 1,3× (batas yang dihormati aplikasi).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/widgets/bagian_sidik.dart';
import 'package:sidik_pelanggan/widgets/chip_status.dart';
import 'package:sidik_pelanggan/widgets/konten_tengah.dart';
import 'package:sidik_pelanggan/widgets/lencana_kan.dart';
import 'package:sidik_pelanggan/widgets/status_tampil.dart';
import 'package:sidik_pelanggan/widgets/tombol_sidik.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/layar_uji.dart';

Widget _app(Widget anak, {bool gelap = false, double skala = 1.0}) =>
    MaterialApp(
      theme: TemaSidik.terang,
      darkTheme: TemaSidik.gelap,
      themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: skala,
        maxScaleFactor: skala,
        child: child!,
      ),
      home: Scaffold(body: anak),
    );

void main() {
  setUpAll(siapkanTesFitur);

  group('ChipStatus dan LencanaKan', () {
    testWidgets('chip: ikon + teks, dan label status untuk pembaca layar', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const ChipStatus(
            StatusTampil('Lewat jadwal', NadaStatus.gagal, Icons.error_outline),
          ),
        ),
      );
      expect(find.text('Lewat jadwal'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.bySemanticsLabel('Status: Lewat jadwal'), findsOneWidget);
      semantik.dispose();
    });

    testWidgets('lencana KAN: "KAN LK-285-IDN", ikon merah KAN, label baca', (
      tester,
    ) async {
      final semantik = tester.ensureSemantics();
      await tester.pumpWidget(_app(const LencanaKan()));
      expect(
        find.textContaining('KAN LK-285-IDN', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Terakreditasi KAN, nomor LK-285-IDN'),
        findsOneWidget,
      );
      semantik.dispose();
    });
  });

  group('TombolSidik', () {
    testWidgets('tinggi sentuh >= 48 dp untuk semua ragam', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              for (final r in RagamTombol.values)
                TombolSidik(
                  label: 'Aksi ${r.name}',
                  ragam: r,
                  onPressed: () {},
                ),
            ],
          ),
        ),
      );
      for (final r in RagamTombol.values) {
        final ukuran = tester.getSize(
          find.widgetWithText(TombolSidik, 'Aksi ${r.name}'),
        );
        expect(ukuran.height, greaterThanOrEqualTo(48), reason: r.name);
      }
    });

    testWidgets('sibuk: pemutar muncul dan ketukan diabaikan', (tester) async {
      var ditekan = 0;
      await tester.pumpWidget(
        _app(
          TombolSidik(
            label: 'Simpan',
            ragam: RagamTombol.utama,
            sibuk: true,
            onPressed: () => ditekan++,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Simpan'));
      expect(ditekan, 0);
    });

    testWidgets('penuh membentang selebar induk; label panjang membungkus', (
      tester,
    ) async {
      layarHp(tester, lebar: 320, tinggi: 640);
      await tester.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: TombolSidik(
              label: 'Buka halaman verifikasi sertifikat laboratorium',
              ikon: Icons.verified_outlined,
              penuh: true,
              onPressed: () {},
            ),
          ),
          skala: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(TombolSidik)).width, 320 - 32);
    });
  });

  group('tata letak', () {
    testWidgets('BagianSidik: aksi menempel di kanan, judul di kiri', (
      tester,
    ) async {
      layarHp(tester);
      var buka = 0;
      await tester.pumpWidget(
        _app(
          BagianSidik(
            'Sertifikat terbaru',
            aksi: AksiBagian(label: 'Lihat semua', onTap: () => buka++),
          ),
        ),
      );
      await tester.tap(find.text('Lihat semua'));
      expect(buka, 1);
      final aksi = tester.getRect(find.byType(AksiBagian));
      expect(aksi.right, lessThanOrEqualTo(360));
      expect(aksi.right, greaterThan(360 - 24), reason: 'di ujung kanan');
      expect(
        tester.getRect(find.text('Sertifikat terbaru')).left,
        lessThan(24),
      );
    });

    testWidgets('KontenTengah: isi dibatasi 720 dp dan dipusatkan', (
      tester,
    ) async {
      layarTablet(tester);
      await tester.pumpWidget(
        _app(const KontenTengah(child: SizedBox.expand(key: Key('isi')))),
      );
      final r = tester.getRect(find.byKey(const Key('isi')));
      expect(r.width, 720);
      expect(r.left, (840 - 720) / 2);
    });
  });
}
