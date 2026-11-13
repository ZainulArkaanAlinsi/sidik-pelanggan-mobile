import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/warna_sidik.dart';

/// Judul bagian layar: kalimat biasa 17/24 (600), jumlah redup di sebelahnya,
/// dan tautan teks [aksi] di ujung kanan ("Lihat semua"). Jarak 32 di atas
/// ([Spasi.bagian]) dan 12 di bawah, kecuali [tanpaJarakAtas]. Pengganti
/// `BagianSidik` (jarak atas 24, tanpa jumlah).
///
/// Judul boleh membungkus (huruf besar di layar sempit); tautan tetap setinggi
/// sentuh 48 dp (tombol teks dari tema) dan tidak terjepit. [semantikAksi]
/// adalah kalimat lengkap untuk pembaca layar ("Lihat semua alat") sementara
/// tulisan di layar sengaja pendek.
class Bagian extends StatelessWidget {
  const Bagian(
    this.judul, {
    super.key,
    this.jumlah,
    this.aksi,
    this.onAksi,
    this.semantikAksi,
    this.tanpaJarakAtas = false,
  }) : assert(
         (aksi == null) == (onAksi == null),
         'aksi dan onAksi harus diisi bersama',
       );

  final String judul;
  final int? jumlah;
  final String? aksi;
  final VoidCallback? onAksi;
  final String? semantikAksi;
  final bool tanpaJarakAtas;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    return Padding(
      padding: EdgeInsets.only(
        top: tanpaJarakAtas ? 0 : Spasi.bagian,
        bottom: Spasi.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text.rich(
                TextSpan(
                  text: judul,
                  children: [
                    if (jumlah != null)
                      TextSpan(
                        text: '  $jumlah',
                        style: t.titleMedium?.tabular.copyWith(
                          color: context.skema.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                style: t.titleMedium,
              ),
            ),
          ),
          if (aksi != null)
            TextButton(
              onPressed: onAksi,
              child: Text(aksi!, semanticsLabel: semantikAksi),
            ),
        ],
      ),
    );
  }
}
