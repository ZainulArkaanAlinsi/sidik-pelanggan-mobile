import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'status_tampil.dart';

/// Lencana status kecil (REVISI 16 Nov 2026): setinggi 24 (radius 6), ikon 14 +
/// kata 12/600, tinta GELAP di atas warna MUDA statusnya (hijau gelap di hijau
/// muda, amber gelap di krem, merah gelap di merah muda, biru tua di biru
/// kelabu muda). Pengganti `ChipStatus`.
///
/// Normal diam di baris daftar padat: lencana berlatar hanya untuk pengecualian
/// ("Lewat jadwal", "Tidak memenuhi toleransi"); keadaan normal memakai
/// [tenang] (tanpa latar, ikon + kata tetap ada) atau tidak ditampilkan. Di
/// atas ubin berwarna muda, lencana memakai [diAtasUbin]: navy di atas putih.
///
/// Status SELALU ikon + kata, tidak pernah warna saja (buta warna, cetakan
/// hitam-putih). Pasangan warna dari [StatusTampil], hasil SATU pemetaan
/// (`pemetaan_status.dart`), mengikuti tema (tema gelap: tinta pastel di atas
/// latar gelap). Kata panjang membungkus dan lencana tumbuh ke bawah (tinggi 24
/// adalah minimum); pembaca layar menerima "Status: kata". Lencana bukan
/// tombol.
class Stempel extends StatelessWidget {
  const Stempel(
    this.status, {
    super.key,
    this.tenang = false,
    this.diAtasUbin = false,
  });

  final StatusTampil status;

  /// Tanpa latar dan tanpa bantalan: untuk keadaan normal.
  final bool tenang;

  /// Lencana ditaruh di atas ubin berwarna muda: navy di atas putih.
  /// Diabaikan bila [tenang].
  final bool diAtasUbin;

  @override
  Widget build(BuildContext context) {
    final (tinta, latar) = !tenang && diAtasUbin
        ? status.diAtasUbin(context)
        : status.warna(context);
    final isi = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: tenang
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(status.ikon, size: UkuranIkon.stempel, color: tinta),
        const SizedBox(width: UkuranKontrol.stempelJarak),
        Flexible(
          child: Text(
            status.label,
            style: context.teks.labelMedium?.copyWith(color: tinta),
          ),
        ),
      ],
    );
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tenang ? null : latar,
          borderRadius: Bentuk.sudutStempel,
        ),
        child: tenang
            ? isi
            : ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: UkuranKontrol.stempel,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spasi.sm,
                    vertical: Spasi.xs,
                  ),
                  child: isi,
                ),
              ),
      ),
    );
  }
}
