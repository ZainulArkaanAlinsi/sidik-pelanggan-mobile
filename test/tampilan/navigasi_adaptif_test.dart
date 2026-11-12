// Navigasi utama lima tab: bawah di HP, rel samping di tablet (>= 600 dp), dan
// isi dibatasi ±720 dp di tengah. Semua tanpa dependensi layout tambahan.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/screens/rangka.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/layar_uji.dart';

const _tab = ['Beranda', 'Alat', 'Sertifikat', 'Notifikasi', 'Akun'];

Widget _rangka() => ProviderScope(
  overrides: overrideFitur(
    ServerFitur({
      3: DataPerusahaan(
        nama: 'PT Alfa',
        alat: [alatJson(1, 'Jangka Sorong', hari: -5, status: 'lewat_jadwal')],
        sertifikat: [sertifikatJson(11, 'CAL/ALFA/0001')],
      ),
    }),
  ),
  child: MaterialApp(
    theme: TemaSidik.terang,
    builder: (context, child) => MediaQuery.withClampedTextScaling(
      minScaleFactor: 1.3,
      maxScaleFactor: 1.3,
      child: child!,
    ),
    home: const Rangka(),
  ),
);

void main() {
  setUpAll(siapkanTesFitur);

  testWidgets('HP 320 dp, huruf 1,3×: lima label satu baris, ada tooltip', (
    tester,
  ) async {
    layarHp(tester, lebar: 320, tinggi: 640);
    await tester.pumpWidget(_rangka());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
    final satuBaris = tester.getSize(find.text('Akun')).height;
    for (final nama in _tab) {
      final label = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(nama),
      );
      expect(label, findsOneWidget, reason: nama);
      expect(
        tester.getSize(label).height,
        closeTo(satuBaris, 1),
        reason: '$nama harus satu baris',
      );
      expect(find.byTooltip(nama), findsWidgets, reason: 'tooltip $nama');
    }
    // Sentuh >= 48 dp.
    for (final nama in _tab) {
      final tujuan = find.ancestor(
        of: find.text(nama),
        matching: find.byType(NavigationDestination),
      );
      expect(tester.getSize(tujuan).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('HP 360 dp: pindah tab lewat navigasi bawah', (tester) async {
    layarHp(tester);
    await tester.pumpWidget(_rangka());
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Alat'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alat saya'), findsOneWidget);
    expect(find.text('Jangka Sorong'), findsOneWidget);
  });

  testWidgets('tablet 840 dp: rel samping berisi lima tujuan, isi <= 720 dp', (
    tester,
  ) async {
    layarTablet(tester);
    await tester.pumpWidget(_rangka());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    for (final nama in _tab) {
      expect(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text(nama),
        ),
        findsOneWidget,
        reason: nama,
      );
    }
    // Daftar tab Beranda (yang aktif) tidak melebar melewati 720 dp.
    final daftar = find.byType(ListView).hitTestable().first;
    expect(tester.getSize(daftar).width, lessThanOrEqualTo(720));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Sertifikat'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('CAL/ALFA/0001'), findsOneWidget);
  });

  testWidgets('batas ganti bentuk: 599 dp bawah, 600 dp rel', (tester) async {
    layarHp(tester, lebar: 599, tinggi: 800);
    await tester.pumpWidget(_rangka());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    layarHp(tester, lebar: 600, tinggi: 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
