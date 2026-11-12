import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/tema/tema_sidik.dart';
import 'providers/perangkat_provider.dart';
import 'screens/gerbang.dart';
import 'widgets/banner.dart';

/// Rentang skala huruf yang dihormati aplikasi (lihat `builder` di bawah).
const batasSkalaHuruf = (min: 0.8, max: 1.3);

/// Aplikasi pelanggan memakai tema sendiri ([TemaSidik]): Material 3 datar,
/// kobalt merek PT Sidik, netral dingin. Token dan komponennya dijelaskan di
/// `lib/core/tema/README.md` dan `lib/widgets/README.md`. Terang/gelap
/// default-nya ikut setelan HP; pilihan di Akun > Preferensi disimpan per
/// perangkat (`temaProvider`).
class SidikPelangganApp extends ConsumerWidget {
  const SidikPelangganApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SIDIK Pelanggan',
      debugShowCheckedModeBanner: false,
      theme: TemaSidik.terang,
      darkTheme: TemaSidik.gelap,
      themeMode: ref.watch(temaProvider).value ?? ThemeMode.system,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Banner offline menempel di atas semua layar, termasuk yang didorong
      // di atas Rangka (detail, formulir).
      //
      // Skala huruf HP dijepit ke [batasSkalaHuruf]. HP murah sering dipasang "huruf sangat besar" (1,5–2,0×); di
      // layar 320 dp tombol dan kartu lalu meluap keluar layar. Sampai 1,3×
      // tetap dihormati — diuji `skala_huruf_layar_sempit_test.dart`.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: batasSkalaHuruf.min,
        maxScaleFactor: batasSkalaHuruf.max,
        child: BingkaiAplikasi(child: child ?? const SizedBox.shrink()),
      ),
      home: const Gerbang(),
    );
  }
}
