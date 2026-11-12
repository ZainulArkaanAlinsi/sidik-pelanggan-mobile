import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';

/// Lencana akreditasi laboratorium: "KAN LK-285-IDN".
///
/// Hanya dipasang di tempat yang menyangkut akreditasi (sambutan dan detail
/// sertifikat). Merah check mark mengikuti logo KAN dan SATU-SATUNYA pemakaian
/// warna itu; galat memakai merah galat tema. Bukan reproduksi logo KAN: tanda
/// resminya ada di PDF sertifikat.
class LencanaKan extends StatelessWidget {
  const LencanaKan({super.key});

  /// Nomor akreditasi laboratorium PT Sidik.
  static const String nomor = 'LK-285-IDN';

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final t = context.teks;
    return Semantics(
      label: 'Terakreditasi KAN, nomor $nomor',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spasi.md,
          vertical: Spasi.xs + 2,
        ),
        decoration: BoxDecoration(
          color: s.surface,
          borderRadius: Bentuk.sudutPil,
          border: Border.all(color: s.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              size: UkuranIkon.sedang - 4,
              color: context.warna.kanMerah,
            ),
            const SizedBox(width: Spasi.sm),
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'KAN',
                      style: TextStyle(
                        color: s.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: ' $nomor',
                      style: TextStyle(color: s.onSurfaceVariant),
                    ),
                  ],
                ),
                style: t.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
