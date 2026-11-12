import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/palet_sidik.dart';
import '../core/tema/spasi.dart';

/// Logo resmi PT Sidik (lencana kobalt). Berkas gambarnya berlatar putih;
/// di tema gelap logo ditaruh di ubin putih bersudut supaya tidak tampil
/// sebagai kotak putih yang kasar di atas permukaan gelap.
///
/// [tinggi] = tinggi logo di layar (dp). Berkasnya kecil (308 × 430 px,
/// 46 KB), jadi dekode dan memorinya ringan di HP murah.
class LogoSidik extends StatelessWidget {
  const LogoSidik({super.key, this.tinggi = 72});

  /// Berkas logo.
  static const String aset = 'assets/images/logo_sidik.png';

  /// Rasio lebar/tinggi berkasnya (308 × 430 px).
  static const double rasio = 308 / 430;

  final double tinggi;

  @override
  Widget build(BuildContext context) {
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final gambar = Image.asset(
      aset,
      height: tinggi,
      width: tinggi * rasio,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Logo PT Sidik',
    );
    if (!gelap) return gambar;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PaletSidik.latarLogo,
        borderRadius: BorderRadius.circular(Bentuk.kontrol),
      ),
      child: Padding(padding: const EdgeInsets.all(Spasi.xs), child: gambar),
    );
  }
}
