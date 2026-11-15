import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'status_tampil.dart';

/// Stempel status Bento Lab: pil setinggi 30 (radius 15), ikon 14 + kata 12/700
/// pada latar warna status dengan tinta navy. Pengganti `ChipStatus`.
///
/// Normal diam di baris daftar padat: stempel berlatar hanya untuk pengecualian
/// ("Lewat jadwal", "Tidak memenuhi toleransi"); keadaan normal memakai
/// [tenang] (tanpa latar, ikon + kata tetap ada) atau tidak ditampilkan. Di
/// ubin alat stempel selalu tampil (ubinnya sudah berwarna) dengan
/// [diAtasUbin]: navy + putih untuk gagal, putih + navy untuk lainnya
/// (KOMPONEN.md §Status).
///
/// Status SELALU ikon + kata, tidak pernah warna saja (buta warna, cetakan
/// hitam-putih). Pasangan warna dari [StatusTampil], hasil SATU pemetaan
/// (`pemetaan_status.dart`). Pil berlatar memakai warna UBIN (pastel bertinta
/// navy, sama di terang dan gelap); [tenang] memakai tinta halaman (pastel di
/// tema gelap). Kata panjang membungkus dan pil tumbuh ke bawah (tinggi 30
/// adalah minimum); pembaca layar menerima "Status: kata". Stempel bukan tombol.
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

  /// Stempel ditaruh di atas ubin berwarna: navy + putih (gagal) atau putih +
  /// navy (lainnya). Diabaikan bila [tenang].
  final bool diAtasUbin;

  @override
  Widget build(BuildContext context) {
    final (tinta, latar) = tenang
        ? status.warna(context)
        : (diAtasUbin ? status.diAtasUbin(context) : status.ubin(context));
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
                    horizontal: Spasi.md,
                    vertical: Spasi.xs,
                  ),
                  child: isi,
                ),
              ),
      ),
    );
  }
}
