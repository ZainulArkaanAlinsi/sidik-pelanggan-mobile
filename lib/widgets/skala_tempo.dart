import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'angka_hari.dart';
import 'status_tampil.dart';

/// Skala jatuh tempo satu alat (detail alat): batang waktu dengan tik "hari
/// ini" yang bergerak ke kanan mendekati tik jadwal.
///
/// Jendela 90 hari sebelum jadwal ([jendelaHari]) adalah KEPUTUSAN DESAIN,
/// bukan data: ia mengikuti pembagian ringkasan jatuh tempo lama, bukan selang
/// kalibrasi sebenarnya (data `kalibrasiTerakhir` sering kosong). Lewat jadwal:
/// jendela bergeser ke 60 hari sebelum dan 30 hari sesudah jadwal, dan ekor
/// setelah tik jadwal berwarna `gagal`.
///
/// Ekor lewat jadwal digambar paling sedikit [ekorMinimum] (8%) lebar batang
/// ([posisiTampak]): lewat 4 hari hanya 4% lebar dan akan tampak sebagai
/// hiasan. Pelebaran ini tidak menyesatkan angka karena batang bukan pembawa
/// arti: KATA ("Lewat 4 hari") dan dua label ("Hari ini", "Jadwal 9 Nov 2026")
/// yang membawanya, dan [posisi] tetap menyatakan posisi yang sebenarnya.
///
/// Label di atas dan di bawah batang, bukan ditumpuk di atasnya, jadi tinggi
/// mengikuti skala huruf; tiap label berpusat pada tiknya dan dijepit supaya
/// tidak keluar dari batang. Pembaca layar menerima satu kalimat ("Lewat 4 hari
/// dari jadwal 9 Nov 2026").
class SkalaTempo extends StatelessWidget {
  const SkalaTempo({
    super.key,
    required this.hari,
    required this.jadwal,
    this.kata = true,
  });

  /// Hari menuju jadwal; negatif = lewat.
  final int hari;

  /// Tanggal jadwal kalibrasi ulang.
  final DateTime jadwal;

  /// Baris kata di atas batang ("Lewat 4 hari" / "12 hari lagi"). Matikan bila
  /// layar sudah memuat `AngkaHari.bintang` di atasnya.
  final bool kata;

  /// Jendela saat belum lewat: sekian hari sebelum jadwal sampai jadwal.
  static const int jendelaHari = 90;

  /// Jendela saat lewat jadwal: mulai sekian hari sebelum jadwal ...
  static const int jendelaLewatSebelum = 60;

  /// ... sampai sekian hari sesudah jadwal.
  static const int jendelaLewatSesudah = 30;

  /// Lebar tampak minimum ekor lewat jadwal (pecahan lebar batang).
  static const double ekorMinimum = 0.08;

  /// Posisi tik "hari ini" dan tik jadwal sepanjang batang, 0 (kiri) sampai 1
  /// (kanan). "Hari ini" menempel di tepi bila [hari] di luar jendela.
  static ({double sekarang, double jadwal}) posisi(int hari) {
    final lewat = hari < 0;
    final awal = lewat ? -jendelaLewatSebelum : -jendelaHari;
    final akhir = lewat ? jendelaLewatSesudah : 0;
    final rentang = akhir - awal;
    final relatif = math.min(math.max(-hari, awal), akhir);
    return (sekarang: (relatif - awal) / rentang, jadwal: (0 - awal) / rentang);
  }

  /// Posisi yang DIGAMBAR: sama dengan [posisi], kecuali ekor lewat jadwal
  /// dilebarkan sampai [ekorMinimum] (dijepit di ujung kanan batang).
  static ({double sekarang, double jadwal}) posisiTampak(int hari) {
    final p = posisi(hari);
    if (hari >= 0) return p;
    return (
      sekarang: math.min(math.max(p.sekarang, p.jadwal + ekorMinimum), 1.0),
      jadwal: p.jadwal,
    );
  }

  /// Penjajaran (`Alignment.x`, -1 kiri sampai 1 kanan) yang memusatkan label
  /// selebar [lebarLabel] pada titik [posisi] (0 sampai 1) di batang selebar
  /// [lebar], dijepit supaya label tidak keluar dari batang.
  @visibleForTesting
  static double biasTengah({
    required double lebar,
    required double lebarLabel,
    required double posisi,
  }) {
    final ruang = lebar - lebarLabel;
    if (ruang <= 0) return -1;
    final kiri = (lebar * posisi - lebarLabel / 2).clamp(0.0, ruang);
    return kiri / ruang * 2 - 1;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final w = context.warna;
    final lewat = hari < 0;
    final p = posisiTampak(hari);
    final tanggal = Format.tanggal(jadwal);
    final tinta = switch (AngkaHari.nadaDari(hari)) {
      NadaStatus.gagal => w.gagal,
      NadaStatus.awas => w.awas,
      _ => s.onSurface,
    };
    final kalimat = hari == 0
        ? 'Jadwal kalibrasi ulang hari ini, $tanggal'
        : lewat
        ? 'Lewat ${-hari} hari dari jadwal $tanggal'
        : '$hari hari lagi sampai jadwal $tanggal';
    const tinggiTrek = UkuranTik.tinggi;
    const atasTrek = (UkuranTik.penanda - tinggiTrek) / 2;
    final gayaLabel = t.labelMedium?.copyWith(color: s.onSurface);
    final skala = MediaQuery.textScalerOf(context);
    final arah = Directionality.of(context);

    return Semantics(
      label: kalimat,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, batas) {
          final lebar = batas.maxWidth;

          Widget label(String teks, double posisi) {
            final pengukur = TextPainter(
              text: TextSpan(
                text: teks,
                style: DefaultTextStyle.of(context).style.merge(gayaLabel),
              ),
              textDirection: arah,
              textScaler: skala,
              maxLines: 1,
            )..layout();
            final lebarLabel = pengukur.width;
            pengukur.dispose();
            return Align(
              alignment: Alignment(
                biasTengah(
                  lebar: lebar,
                  lebarLabel: lebarLabel,
                  posisi: posisi,
                ),
                0,
              ),
              child: Text(teks, style: gayaLabel),
            );
          }

          Widget potong(double dari, double sampai, Color warna) => Positioned(
            left: lebar * dari,
            width: lebar * (sampai - dari),
            top: atasTrek,
            height: tinggiTrek,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: warna,
                borderRadius: Bentuk.sudutKecil,
              ),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (kata) ...[
                Text(
                  Format.sisaHari(hari),
                  style: t.titleMedium?.copyWith(color: tinta),
                ),
                const SizedBox(height: Spasi.sm),
              ],
              label('Hari ini', p.sekarang),
              const SizedBox(height: Spasi.xs),
              SizedBox(
                height: UkuranTik.penanda,
                child: Stack(
                  children: [
                    potong(0, 1, s.outlineVariant),
                    potong(0, lewat ? p.jadwal : p.sekarang, s.primary),
                    if (lewat) potong(p.jadwal, p.sekarang, w.gagal),
                    Positioned(
                      left: (lebar * p.jadwal - UkuranTik.batang / 2).clamp(
                        0.0,
                        lebar - UkuranTik.batang,
                      ),
                      width: UkuranTik.batang,
                      top: 0,
                      height: UkuranTik.penanda,
                      child: ColoredBox(color: s.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spasi.xs),
              label('Jadwal $tanggal', p.jadwal),
            ],
          );
        },
      ),
    );
  }
}
