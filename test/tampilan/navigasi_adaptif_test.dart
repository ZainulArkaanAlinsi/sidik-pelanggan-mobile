// Navigasi utama lima tab: bawah di HP, rel samping di tablet (>= 600 dp), dan
// isi dibatasi ±720 dp di tengah. Semua tanpa dependensi layout tambahan.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/spasi.dart';
import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/screens/rangka.dart';
import 'package:sidik_pelanggan/widgets/navigasi_utama.dart';

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

  // P4: navigasi bawah menjadi dock melayang (DockNavigasi). Label hanya di
  // butir aktif (KOMPONEN.md §Dock), jadi "lima label satu baris" diganti:
  // tiap butir tetap punya tooltip dan sentuh >= 48 dp, dan label aktif satu
  // baris. Detail dock ada di test/widgets/dock_navigasi_test.dart.
  testWidgets('HP 320 dp, huruf 1,3×: lima butir bertooltip, sentuh >= 48 dp', (
    tester,
  ) async {
    layarHp(tester, lebar: 320, tinggi: 640);
    await tester.pumpWidget(_rangka());
    await tester.pumpAndSettle();

    expect(find.byType(DockNavigasi), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
    for (final nama in _tab) {
      final butir = find.descendant(
        of: find.byType(DockNavigasi),
        matching: find.byTooltip(nama),
      );
      expect(butir, findsOneWidget, reason: 'tooltip $nama');
      final ukuran = tester.getSize(butir);
      expect(ukuran.height, greaterThanOrEqualTo(48), reason: nama);
      expect(ukuran.width, greaterThanOrEqualTo(48), reason: nama);
    }
  });

  testWidgets('HP 360 dp, huruf 1,3×: label butir aktif satu baris', (
    tester,
  ) async {
    layarHp(tester);
    await tester.pumpWidget(_rangka());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final label = find.descendant(
      of: find.byType(DockNavigasi),
      matching: find.text('Beranda'),
    );
    expect(label, findsOneWidget);
    // 14 sp / 20 dp: satu baris, tidak ikut membesar oleh huruf sistem 1,3×.
    expect(tester.getSize(label).height, lessThan(24));
  });

  testWidgets('HP 360 dp: pindah tab lewat navigasi bawah', (tester) async {
    layarHp(tester);
    await tester.pumpWidget(_rangka());
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(DockNavigasi),
        matching: find.byTooltip('Alat'),
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
    expect(find.byType(DockNavigasi), findsNothing);
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
    // Beranda (yang aktif) dua kolom di tablet: boleh selebar Spasi.lebarLebar,
    // tetapi tidak melewatinya.
    final beranda = find.byType(ListView).hitTestable().first;
    expect(tester.getSize(beranda).width, lessThanOrEqualTo(Spasi.lebarLebar));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Sertifikat'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('CAL/ALFA/0001'), findsOneWidget);
    // Layar daftar lain tetap tidak melebar melewati 720 dp.
    final daftar = find.byType(ListView).hitTestable().first;
    expect(tester.getSize(daftar).width, lessThanOrEqualTo(Spasi.lebarKonten));
  });

  testWidgets('batas ganti bentuk: 599 dp bawah, 600 dp rel', (tester) async {
    layarHp(tester, lebar: 599, tinggi: 800);
    await tester.pumpWidget(_rangka());
    await tester.pumpAndSettle();
    expect(find.byType(DockNavigasi), findsOneWidget);

    layarHp(tester, lebar: 600, tinggi: 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
