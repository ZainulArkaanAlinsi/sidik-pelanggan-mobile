import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';

/// Kolom sempit (maks. 440 dp) di tengah layar, bergulir bila isinya lebih
/// tinggi dari layar: dasar layar Sambutan, Masuk, dan layar keadaan penuh
/// (pemeliharaan, wajib perbarui).
class KolomFormulir extends StatelessWidget {
  const KolomFormulir({super.key, required this.children});

  static const double lebarMaks = 440;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: lebarMaks),
        child: ListView(
          padding: const EdgeInsets.all(Spasi.xl),
          shrinkWrap: true,
          children: children,
        ),
      ),
    ),
  );
}
