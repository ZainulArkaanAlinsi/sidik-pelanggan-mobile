import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';

/// Memusatkan isi dan membatasi lebarnya ([Spasi.lebarKonten], ±720 dp) di
/// layar lebar (tablet), supaya garis baca tidak melebar sampai ke tepi.
/// Di HP lebarnya tidak terbatas, jadi tidak ada efeknya.
class KontenTengah extends StatelessWidget {
  const KontenTengah({
    super.key,
    required this.child,
    this.lebarMaks = Spasi.lebarKonten,
  });

  final Widget child;
  final double lebarMaks;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: lebarMaks),
      child: child,
    ),
  );
}
