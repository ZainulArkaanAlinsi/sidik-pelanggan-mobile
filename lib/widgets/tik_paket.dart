import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';

/// Keadaan satu alat di dalam paket, untuk [TikPaket].
enum TahapTik {
  /// Baru diterima: tik kosong berbingkai.
  baru,

  /// Sedang dikerjakan (dikalibrasi, diperiksa, dikerjakan ulang): berisi
  /// tipis berbingkai kobalt.
  jalan,

  /// Sertifikat sudah terbit (atau lebih jauh): terisi kobalt.
  selesai,
}

/// Satu tik per ALAT dalam satu paket, urut dari yang paling maju: terisi
/// kobalt = sertifikat sudah terbit, berisi tipis = sedang dikerjakan, kosong
/// berbingkai = baru diterima. Kata ("1 dari 4 alat selesai") selalu tampil di
/// bawahnya dan menjadi label pembaca layar.
///
/// Dua pintu masuk: [TikPaket.dariTahap] (kode tahap tiap alat, bila server
/// mengirimnya) dan [TikPaket.dariJumlah] (jatuh balik ke "N dari M": hanya
/// jumlah alat dan jumlah selesai; yang selesai terisi lebih dulu).
///
/// Paket dengan alat lebih dari [UkuranTik.tikPaketMaksimum] digambar sebagai
/// satu batang bersegmen supaya tik tidak lebih sempit dari jaraknya.
class TikPaket extends StatelessWidget {
  const TikPaket({super.key, required this.tik, this.kata});

  /// Dari kode tahap tiap alat (`alat[].tahap`).
  factory TikPaket.dariTahap(
    List<String> kodeTahap, {
    Key? key,
    String? kata,
  }) => TikPaket(
    key: key,
    tik: [for (final k in kodeTahap) tahapDari(k)],
    kata: kata,
  );

  /// Dari jumlah saja (`jumlah_alat`, `jumlah_selesai`).
  factory TikPaket.dariJumlah({
    Key? key,
    required int jumlahAlat,
    required int jumlahSelesai,
    String? kata,
  }) {
    final total = jumlahAlat < 0 ? 0 : jumlahAlat;
    final selesai = jumlahSelesai.clamp(0, total);
    return TikPaket(
      key: key,
      tik: [
        for (var i = 0; i < total; i++)
          i < selesai ? TahapTik.selesai : TahapTik.baru,
      ],
      kata: kata,
    );
  }

  final List<TahapTik> tik;

  /// Menggantikan kalimat bawaan "N dari M alat selesai".
  final String? kata;

  /// Pemetaan kode tahap alat. Kode yang tidak dikenal dianggap
  /// [TahapTik.jalan]: ia ada di jalur lab, tetapi tidak terbukti selesai.
  static TahapTik tahapDari(String kode) => switch (kode) {
    'diterima' => TahapTik.baru,
    'sertifikat_terbit' || 'siap_diambil' || 'diserahkan' => TahapTik.selesai,
    _ => TahapTik.jalan,
  };

  @override
  Widget build(BuildContext context) {
    if (tik.isEmpty) return const SizedBox.shrink();
    final t = context.teks;
    final s = context.skema;
    final urut = [...tik]..sort((a, b) => b.index.compareTo(a.index));
    final selesai = urut.where((x) => x == TahapTik.selesai).length;
    final kalimat = kata ?? '$selesai dari ${urut.length} alat selesai';

    BoxDecoration hias(TahapTik x) => BoxDecoration(
      color: switch (x) {
        TahapTik.selesai => s.primary,
        TahapTik.jalan => s.primaryContainer,
        TahapTik.baru => null,
      },
      border: x == TahapTik.selesai
          ? null
          : Border.all(color: x == TahapTik.jalan ? s.primary : s.outline),
      borderRadius: Bentuk.sudutKecil,
    );

    final Widget batang;
    if (urut.length <= UkuranTik.tikPaketMaksimum) {
      batang = Row(
        children: [
          for (var i = 0; i < urut.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: i == urut.length - 1 ? 0 : UkuranTik.jarak,
                ),
                child: SizedBox(
                  height: UkuranTik.tinggiSekarang,
                  child: DecoratedBox(decoration: hias(urut[i])),
                ),
              ),
            ),
        ],
      );
    } else {
      batang = Row(
        children: [
          for (final x in TahapTik.values.reversed)
            if (urut.contains(x))
              Expanded(
                flex: urut.where((y) => y == x).length,
                child: SizedBox(
                  height: UkuranTik.tinggiSekarang,
                  child: DecoratedBox(decoration: hias(x)),
                ),
              ),
        ],
      );
    }

    return Semantics(
      label: kalimat,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          batang,
          const SizedBox(height: Spasi.xs),
          Text(
            kalimat,
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
