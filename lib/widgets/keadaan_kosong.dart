import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';

/// Keadaan kosong layar penuh: ikon, judul, satu kalimat yang bilang apa
/// artinya, dan bila ada satu ajakan tindakan ([aksi]). Berupa `ListView`
/// supaya tarik-untuk-muat-ulang tetap jalan.
class KeadaanKosong extends StatelessWidget {
  const KeadaanKosong({
    super.key,
    required this.ikon,
    required this.judul,
    required this.keterangan,
    this.aksi,
  });

  final IconData ikon;
  final String judul;
  final String keterangan;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: Spasi.denganTepiBawah(
      context,
      const EdgeInsets.all(Spasi.xl),
    ).copyWith(top: Spasi.xxl),
    children: [
      KeadaanKosongIsi(ikon: ikon, judul: judul, keterangan: keterangan),
      if (aksi != null) ...[
        const SizedBox(height: Spasi.lg),
        Center(child: aksi),
      ],
    ],
  );
}

/// Isi [KeadaanKosong] tanpa daftar bergulir, untuk ditaruh di dalam kartu atau
/// daftar lain.
class KeadaanKosongIsi extends StatelessWidget {
  const KeadaanKosongIsi({
    super.key,
    required this.ikon,
    required this.judul,
    required this.keterangan,
  });

  final IconData ikon;
  final String judul;
  final String keterangan;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    return Column(
      children: [
        ExcludeSemantics(
          child: Container(
            width: UkuranIkon.ilustrasi + Spasi.xl,
            height: UkuranIkon.ilustrasi + Spasi.xl,
            decoration: BoxDecoration(
              color: s.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ikon,
              size: UkuranIkon.besar,
              color: s.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: Spasi.lg),
        Text(judul, textAlign: TextAlign.center, style: t.titleMedium),
        const SizedBox(height: Spasi.xs),
        Text(
          keterangan,
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        ),
      ],
    );
  }
}
