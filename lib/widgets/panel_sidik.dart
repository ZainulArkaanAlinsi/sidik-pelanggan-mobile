import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/elevasi.dart';
import '../core/tema/spasi.dart';
import '../core/tema/warna_sidik.dart';

/// Satu panel permukaan berisi baris-baris yang dipisah garis halus.
///
/// Pengganti "satu kartu per butir daftar": satu butir = satu baris
/// (`BarisSidik`), kartu hanya untuk GRUP butir. Sudut 16 ([Bentuk.kartu]),
/// garis halus, tanpa bayangan. Ripple baris terpotong mengikuti sudut panel.
///
/// Tanpa anak, panel tidak menggambar apa pun (tidak ada kotak kosong).
class PanelSidik extends StatelessWidget {
  const PanelSidik({super.key, required this.anak});

  final List<Widget> anak;

  @override
  Widget build(BuildContext context) {
    if (anak.isEmpty) return const SizedBox.shrink();
    final s = context.skema;
    return Material(
      color: s.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Bentuk.sudutKartu,
        side: BorderSide(color: s.outlineVariant, width: Elevasi.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < anak.length; i++) ...[
            if (i > 0) const Divider(indent: Spasi.lg, endIndent: Spasi.lg),
            anak[i],
          ],
        ],
      ),
    );
  }
}
