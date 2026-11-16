// Ikon `AlertDialog` harus terlihat. Bawaan Material 3 mewarnai ikon dialog
// dengan `ColorScheme.secondary`; sejak R1 secondary = putih (terang) atau
// latar gelap (gelap), jadi tanpa `dialogTheme.iconColor` ikon menghilang
// (1,00:1 di terang, 1,13:1 di gelap). Diuji pada dialog sungguhan aplikasi
// (pembaruan wajib, akun sudah ada) dan satu dialog setara notifikasi.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sidik_pelanggan/core/tema/tema_sidik.dart';
import 'package:sidik_pelanggan/screens/auth/terima_undangan_screen.dart';
import 'package:sidik_pelanggan/widgets/pembaruan.dart';

import '../dukungan/fixture_fitur.dart';
import '../dukungan/ukur_komponen.dart';

Widget _app(Widget isi, {required bool gelap}) => ProviderScope(
  child: MaterialApp(
    theme: TemaSidik.terang,
    darkTheme: TemaSidik.gelap,
    themeMode: gelap ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(body: isi),
  ),
);

/// Warna yang BENAR-BENAR dipakai ikon bawaan [AlertDialog] ([IconTheme]).
Color _warnaIkonDialog(WidgetTester tester) {
  final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
  expect(dialog.icon, isNotNull, reason: 'dialog ini harus berikon');
  final ikon = find.byWidget(dialog.icon!);
  expect(ikon, findsOneWidget);
  final warna = IconTheme.of(tester.element(ikon)).color;
  expect(warna, isNotNull);
  return warna!;
}

void main() {
  setUpAll(siapkanTesFitur);

  final dialog = <(String, Widget)>[
    ('DialogPembaruanWajib', const DialogPembaruanWajib()),
    ('DialogAkunSudahAda', const DialogAkunSudahAda()),
    (
      'dialog notifikasi (setara tawarkanNotifikasi)',
      AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: const Text('Nyalakan notifikasi?'),
        content: const Text('Kami kabari saat sertifikat terbit.'),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Nanti saja')),
        ],
      ),
    ),
  ];

  for (final gelap in [false, true]) {
    for (final (nama, isi) in dialog) {
      testWidgets('$nama: ikon >= 3:1 di atas permukaan dialog, bukan '
          'secondary (${gelap ? 'gelap' : 'terang'})', (tester) async {
        await tester.pumpWidget(_app(isi, gelap: gelap));
        await tester.pumpAndSettle();
        final tema = gelap ? TemaSidik.gelap : TemaSidik.terang;
        final warna = _warnaIkonDialog(tester);
        final permukaan = tema.dialogTheme.backgroundColor!;
        expect(
          rasioKontras(warna, permukaan),
          greaterThanOrEqualTo(3),
          reason: '$nama: ikon dialog ${rasioKontras(warna, permukaan)}:1',
        );
        expect(warna, tema.colorScheme.primary);
        expect(
          warna,
          isNot(tema.colorScheme.secondary),
          reason: 'secondary = putih/gelap: ikon tak terlihat',
        );
      });
    }
  }

  test('dialogTheme.iconColor diatur eksplisit di dua tema', () {
    for (final tema in [TemaSidik.terang, TemaSidik.gelap]) {
      expect(tema.dialogTheme.iconColor, tema.colorScheme.primary);
    }
  });
}
