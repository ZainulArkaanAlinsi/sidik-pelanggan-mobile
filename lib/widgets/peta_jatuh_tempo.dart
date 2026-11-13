import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'baris_sidik.dart';
import 'panel_sidik.dart';
import 'status_tampil.dart';

/// Satu zona pada [PetaJatuhTempo]: label ("Lewat jadwal", "Dalam 30 hari"),
/// jumlah alat, dan nadanya.
@immutable
class ZonaTempo {
  const ZonaTempo({
    required this.label,
    required this.jumlah,
    this.nada = NadaStatus.netral,
  });

  final String label;
  final int jumlah;

  /// `gagal` = lewat jadwal, `awas` = segera; lainnya tinta biasa.
  final NadaStatus nada;
}

/// Satu penggaris, beberapa zona (lewat jadwal, 0 sampai 30 hari, 31 sampai 60,
/// 61 sampai 90 hari): angka 28 di atas batang 6 dp bernada status. Pengganti
/// empat ubin KPI yang identik. Zona berjumlah nol abu-abu (tanpa warna
/// status), jadi yang berwarna selalu berarti ada yang perlu dilihat.
///
/// Semua zona sebaris di HP biasa. Pada tata letak kompak ([tataLetakKompak]:
/// lebar di bawah 340 dp atau huruf di atas 1,15x) zona disusun dua kolom:
/// empat kolom di 320 dp x huruf 1,3 hanya menyisakan sekitar 40 dp per sel,
/// dan label patah di tengah kata ("jadwa" / "l").
///
/// Tiap zona bisa diketuk ([onZona], indeks zona) untuk membuka daftar alat
/// yang tersaring; tinggi sentuhnya lebih dari 48 dp. Warna batang bukan satu-
/// satunya pembawa arti: label zona selalu berupa kata, dan pembaca layar
/// menerima "Lewat jadwal: 1 alat". Angka 28 sp dijepit
/// [SkalaHuruf.batasBesar].
class PetaJatuhTempo extends StatelessWidget {
  const PetaJatuhTempo({super.key, required this.zona, this.onZona});

  final List<ZonaTempo> zona;
  final ValueChanged<int>? onZona;

  /// Kolom pada tata letak kompak.
  static const int kolomKompak = 2;

  Color _tinta(BuildContext context, ZonaTempo z) {
    final s = context.skema;
    final w = context.warna;
    if (z.jumlah == 0) return s.onSurfaceVariant;
    return switch (z.nada) {
      NadaStatus.gagal => w.gagal,
      NadaStatus.awas => w.awas,
      _ => s.onSurface,
    };
  }

  Widget _sel(BuildContext context, int i) {
    final t = context.teks;
    final s = context.skema;
    final z = zona[i];
    return Semantics(
      button: onZona != null,
      onTap: onZona == null ? null : () => onZona!(i),
      label: '${z.label}: ${z.jumlah} alat',
      excludeSemantics: true,
      child: InkWell(
        onTap: onZona == null ? null : () => onZona!(i),
        borderRadius: Bentuk.sudutKecil,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AreaSentuh.minimum),
          child: Padding(
            padding: const EdgeInsets.all(Spasi.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: SkalaHuruf.batasBesar,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '${z.jumlah}',
                      style: t.displaySmall?.tabular.copyWith(
                        color: _tinta(context, z),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spasi.xs),
                SizedBox(
                  height: UkuranTik.tinggi,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      // Zona netral berbatang garis tegas (abu sedang), bukan
                      // tinta penuh: di tema gelap tinta jauh lebih terang
                      // daripada batang status dan merebut perhatian.
                      color: z.jumlah == 0
                          ? s.outlineVariant
                          : (z.nada == NadaStatus.gagal ||
                                z.nada == NadaStatus.awas)
                          ? _tinta(context, z)
                          : s.outline,
                      borderRadius: Bentuk.sudutKecil,
                    ),
                  ),
                ),
                const SizedBox(height: Spasi.sm),
                Text(z.label, style: t.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (zona.isEmpty) return const SizedBox.shrink();
    final kolom = tataLetakKompak(context)
        ? math.min(kolomKompak, zona.length)
        : zona.length;
    return PanelSidik(
      anak: [
        Padding(
          padding: const EdgeInsets.all(Spasi.sm),
          child: Column(
            children: [
              for (var awal = 0; awal < zona.length; awal += kolom)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var k = 0; k < kolom; k++)
                      Expanded(
                        child: awal + k < zona.length
                            ? _sel(context, awal + k)
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
