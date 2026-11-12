import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'status_tampil.dart';

/// Lencana status berbentuk pil: ikon + teks pada latar tipis nadanya.
///
/// Tidak diketuk (bukan tombol). Label panjang di layar sempit atau huruf
/// besar dipotong dengan elipsis; pembaca layar tetap menerima label utuh.
class ChipStatus extends StatelessWidget {
  const ChipStatus(this.status, {super.key});

  final StatusTampil status;

  @override
  Widget build(BuildContext context) {
    final (tinta, latar) = status.warna(context);
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spasi.sm,
          vertical: Spasi.xs,
        ),
        decoration: BoxDecoration(color: latar, borderRadius: Bentuk.sudutPil),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.ikon, size: UkuranIkon.kecil, color: tinta),
            const SizedBox(width: Spasi.xs),
            Flexible(
              child: Text(
                status.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: context.teks.labelMedium?.copyWith(color: tinta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
