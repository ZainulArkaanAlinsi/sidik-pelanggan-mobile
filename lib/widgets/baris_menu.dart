import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import 'kartu_sidik.dart';

/// Satu baris menu di dalam [KelompokBaris]: ikon, judul, keterangan opsional,
/// dan penunjuk di kanan ([luar] = membuka aplikasi lain, bukan layar baru).
class BarisMenu extends StatelessWidget {
  const BarisMenu({
    super.key,
    required this.ikon,
    required this.judul,
    this.keterangan,
    this.onTap,
    this.luar = false,
    this.trailing,
  });

  final IconData ikon;
  final String judul;
  final String? keterangan;
  final VoidCallback? onTap;

  /// Tautan ke luar aplikasi: penunjuknya ikon "buka di luar".
  final bool luar;

  /// Pengganti penunjuk bawaan (mis. sakelar).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(ikon, size: UkuranIkon.sedang),
    title: Text(judul),
    subtitle: keterangan == null ? null : Text(keterangan!),
    trailing:
        trailing ??
        (onTap == null
            ? null
            : Icon(
                luar ? Icons.open_in_new : Icons.chevron_right,
                size: UkuranIkon.sedang,
              )),
    onTap: onTap,
    minTileHeight: AreaSentuh.minimum + Spasi.sm,
  );
}

/// Beberapa [BarisMenu] dalam satu kartu, dipisah garis halus yang dimulai
/// sesudah ikon.
class KelompokBaris extends StatelessWidget {
  const KelompokBaris({super.key, required this.baris});

  final List<Widget> baris;

  /// Garis pemisah dimulai di bawah teks (lebar ikon + jarak).
  static const double _indentGaris = Spasi.lg + UkuranIkon.sedang + Spasi.lg;

  @override
  Widget build(BuildContext context) => KartuSidik(
    padding: EdgeInsets.zero,
    child: Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          for (var i = 0; i < baris.length; i++) ...[
            if (i > 0) const Divider(indent: _indentGaris),
            baris[i],
          ],
        ],
      ),
    ),
  );
}
