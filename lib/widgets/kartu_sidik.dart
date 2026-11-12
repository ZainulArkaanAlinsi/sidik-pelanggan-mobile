import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';

/// Kartu datar: permukaan putih, garis halus, tanpa bayangan (gaya dari
/// `CardTheme`). Bila [onTap] diisi, seluruh kartu bisa diketuk dengan ripple
/// standar dan terbaca pembaca layar sebagai tombol.
///
/// [warna] mengganti latar kartu (mis. latar tipis status). [padding] nol
/// untuk kartu yang isinya daftar baris sampai tepi ([KelompokBaris]).
class KartuSidik extends StatelessWidget {
  const KartuSidik({
    super.key,
    required this.child,
    this.padding = Spasi.kartu,
    this.onTap,
    this.warna,
    this.labelSemantik,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? warna;

  /// Menggantikan teks anak untuk pembaca layar (kartu yang bisa diketuk).
  final String? labelSemantik;

  @override
  Widget build(BuildContext context) {
    final isi = Padding(padding: padding, child: child);
    return Card(
      color: warna,
      child: onTap == null
          ? isi
          : Semantics(
              button: true,
              label: labelSemantik,
              excludeSemantics: labelSemantik != null,
              child: InkWell(onTap: onTap, child: isi),
            ),
    );
  }
}
