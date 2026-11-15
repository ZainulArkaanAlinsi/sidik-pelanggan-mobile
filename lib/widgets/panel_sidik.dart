import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/elevasi.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';

/// Satu panel permukaan berisi baris-baris yang dipisah garis halus.
///
/// Pengganti "satu kartu per butir daftar": satu butir = satu baris
/// (`BarisSidik`), kartu hanya untuk GRUP butir. Sudut 28 ([Bentuk.panel]),
/// garis halus, tanpa bayangan. Ripple baris terpotong mengikuti sudut panel.
///
/// [padding] mengatur jarak isi ke tepi panel: [paddingBaris] (6) untuk panel
/// berisi baris, [paddingIsi] (18) untuk isi bebas, atau nol (bawaan: baris
/// selebar panel, seperti sebelum Bento Lab).
///
/// Tanpa anak, panel tidak menggambar apa pun (tidak ada kotak kosong).
class PanelSidik extends StatelessWidget {
  const PanelSidik({
    super.key,
    required this.anak,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> anak;
  final EdgeInsets padding;

  /// Panel berisi baris: jarak 6 dp ke tepi (KOMPONEN.md §Ubin, Panel).
  static const EdgeInsets paddingBaris = EdgeInsets.all(
    UkuranKontrol.panelBaris,
  );

  /// Panel berisi isi bebas: jarak 18 dp ke tepi.
  static const EdgeInsets paddingIsi = EdgeInsets.all(UkuranUbin.paddingAlat);

  @override
  Widget build(BuildContext context) {
    if (anak.isEmpty) return const SizedBox.shrink();
    final s = context.skema;
    return Material(
      color: s.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Bentuk.sudutPanel,
        side: BorderSide(color: s.outlineVariant, width: Elevasi.garis),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < anak.length; i++) ...[
              if (i > 0) const Divider(indent: Spasi.lg, endIndent: Spasi.lg),
              anak[i],
            ],
          ],
        ),
      ),
    );
  }
}
