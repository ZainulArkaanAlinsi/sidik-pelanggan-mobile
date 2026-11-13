import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/warna_sidik.dart';
import 'nomor_sidik.dart';

/// Plat nama alat: nomor seri sebagai IDENTITAS utama (22 sp, selebar tetap,
/// nol bergaris), fakta lain kecil di bawahnya. Bingkai persegi sudut 4 dengan
/// garis tegas (4,6:1), seperti pelat pada alat ukur. Pengganti tujuh pasang
/// `BarisInfo` di detail alat, empat di antaranya berisi "—".
///
/// Hanya fakta yang terisi yang tampil: pasangan ber-nilai kosong dibuang,
/// tanpa baris "—". Nomor seri sangat panjang mengecil ke satu baris atau
/// membungkus di pemisah, tidak pernah putus di tengah ([NomorSidik]). Seri
/// kosong tampil "Belum tercatat" (redup), bukan "—". Pembaca layar menerima
/// satu kalimat gabungan.
class PlatNama extends StatelessWidget {
  const PlatNama({
    super.key,
    required this.seri,
    this.fakta = const [],
    this.labelSeri = 'No. seri',
  });

  final String? seri;
  final String labelSeri;

  /// Pasangan (label, nilai); yang nilainya kosong tidak digambar.
  final List<(String, String?)> fakta;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final nomor = seri?.trim() ?? '';
    final terisi = [
      for (final (label, nilai) in fakta)
        if (nilai != null && nilai.trim().isNotEmpty) (label, nilai.trim()),
    ];
    final kalimat = [
      '$labelSeri ${nomor.isEmpty ? 'belum tercatat' : nomor}',
      for (final (label, nilai) in terisi) '$label $nilai',
    ].join('. ');

    return Semantics(
      label: 'Plat nama alat. $kalimat',
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: s.surface,
            border: Border.all(color: s.outline),
            borderRadius: Bentuk.sudutKecil,
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spasi.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(labelSeri, style: t.labelMedium),
                const SizedBox(height: Spasi.xs),
                if (nomor.isEmpty)
                  Text(
                    'Belum tercatat',
                    style: t.headlineSmall?.copyWith(color: s.onSurfaceVariant),
                  )
                else
                  NomorSidik(nomor, gaya: t.headlineSmall),
                if (terisi.isNotEmpty) ...[
                  const SizedBox(height: Spasi.md),
                  const Divider(),
                  const SizedBox(height: Spasi.md),
                  Wrap(
                    spacing: Spasi.xl,
                    runSpacing: Spasi.md,
                    children: [
                      for (final (label, nilai) in terisi)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label, style: t.labelMedium),
                            Text(
                              nilai,
                              style: t.bodyMedium?.nomor.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
