import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'status_tampil.dart';

/// Stempel status: persegi sudut 4 ([Bentuk.kecil]), ikon + kata pada latar
/// tipis nadanya. Pengganti `ChipStatus` (pil) di tiap baris.
///
/// "Normal diam, pengecualian bersuara": pakai stempel berlatar hanya untuk
/// pengecualian ("Lewat jadwal", "Tidak memenuhi toleransi") atau di lembar
/// detail. Keadaan normal memakai [tenang] (tanpa latar, ikon + kata tetap
/// ada) atau tidak ditampilkan sama sekali.
///
/// Status SELALU ikon + kata, tidak pernah warna saja (buta warna, cetakan
/// hitam-putih). Pasangan tinta/latar dari [StatusTampil.warna], hasil SATU
/// pemetaan (`pemetaan_status.dart`). Kata panjang membungkus (tidak dipotong);
/// pembaca layar menerima "Status: kata". Stempel bukan tombol.
class Stempel extends StatelessWidget {
  const Stempel(this.status, {super.key, this.tenang = false});

  final StatusTampil status;

  /// Tanpa latar dan tanpa bantalan: untuk keadaan normal.
  final bool tenang;

  @override
  Widget build(BuildContext context) {
    final (tinta, latar) = status.warna(context);
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tenang ? null : latar,
          borderRadius: Bentuk.sudutKecil,
        ),
        child: Padding(
          padding: tenang
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(
                  horizontal: Spasi.sm,
                  vertical: Spasi.xs,
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(status.ikon, size: UkuranIkon.kecil, color: tinta),
              const SizedBox(width: Spasi.xs),
              Flexible(
                child: Text(
                  status.label,
                  style: context.teks.labelMedium?.copyWith(color: tinta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
