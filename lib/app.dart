import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/sidik_theme.dart';
import 'screens/gerbang.dart';

/// Aplikasi pelanggan memakai tema "Meja Kerja Lab" yang SAMA dengan aplikasi
/// lab (berkas `core/theme/*` disalin apa adanya dari `sidik-calibration-mobile`).
/// Terang/gelap mengikuti setelan HP — pelanggan tidak butuh sakelar tema.
class SidikPelangganApp extends StatelessWidget {
  const SidikPelangganApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIDIK Pelanggan',
      debugShowCheckedModeBanner: false,
      theme: SidikTheme.terang,
      darkTheme: SidikTheme.gelap,
      themeMode: ThemeMode.system,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Gerbang(),
    );
  }
}
