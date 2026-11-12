import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/warna_sidik.dart';

/// Judul satu bagian layar (kalimat biasa, bukan huruf besar), dengan [aksi]
/// opsional di ujung kanan (mis. [AksiBagian] "Lihat semua").
class BagianSidik extends StatelessWidget {
  const BagianSidik(this.judul, {super.key, this.aksi});

  final String judul;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spasi.xl, bottom: Spasi.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(judul, style: context.teks.titleMedium),
            ),
          ),
          ?aksi,
        ],
      ),
    );
  }
}

/// Tombol teks di ujung [BagianSidik]. [semantik] = kalimat lengkap untuk
/// pembaca layar; tulisan di layar sengaja pendek supaya judul di sebelahnya
/// (yang boleh membungkus) tidak terjepit di layar sempit.
class AksiBagian extends StatelessWidget {
  const AksiBagian({
    super.key,
    required this.label,
    required this.onTap,
    this.semantik,
  });

  final String label;
  final VoidCallback onTap;
  final String? semantik;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    child: Text(label, semanticsLabel: semantik),
  );
}
