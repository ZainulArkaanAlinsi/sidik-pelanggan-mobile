import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/motion/gerak_bento.dart';
import '../core/tema/bentuk.dart';
import '../core/tema/elevasi.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'dasar/cincin_fokus.dart';

/// Segmen pil Bento Lab untuk 2 sampai beberapa pilihan setara (mis. "Daftar |
/// Arsip"): wadah putih setinggi 56 (padding 6, bentuk pil) berisi pil navy
/// setinggi 44 (radius 22) yang BERGESER ke pilihan baru dalam 240 ms
/// (`AppMotion.sedang`; langsung bila "kurangi gerak" menyala).
///
/// Tinggi 56 dan 44 adalah minimum: pada huruf besar segmen tumbuh. Kata 14/700,
/// membungkus bila perlu, tidak dipotong. Seluruh wadah dapat diketuk: tiap
/// pilihan mendengar ketukan di bagiannya dari tepi ke tepi (tinggi 56, >= 48).
/// Pembaca layar menerima tiap pilihan sebagai tombol dengan `selected`; warna
/// bukan satu-satunya penanda. [onPilih] null = semua mati.
///
/// Lapisan: kata tak terpilih di dasar, pil navy bergeser di atasnya membawa
/// salinan kata putih (dipotong oleh pil), lalu lapisan ketuk transparan. Salinan
/// kata digambar dengan `RichText` (bukan `Text`) dan keluar dari pembaca layar,
/// jadi `find.text` dan semantik hanya melihat satu kata per pilihan.
class SegmenPil extends StatelessWidget {
  const SegmenPil({
    super.key,
    required this.pilihan,
    required this.terpilih,
    this.onPilih,
  }) : assert(pilihan.length >= 2, 'segmen butuh sedikitnya dua pilihan');

  final List<String> pilihan;
  final int terpilih;
  final ValueChanged<int>? onPilih;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final aktif = onPilih != null;
    final n = pilihan.length;
    final gaya = context.teks.bodySmall?.copyWith(
      fontWeight: TipografiSidik.beratLabel,
    );
    final tintaDasar = aktif
        ? s.onSurface
        : s.onSurface.withValues(alpha: _alfaMati);
    final isiGeser = aktif
        ? s.primary
        : s.onSurface.withValues(alpha: _alfaIsiMati);
    final tintaGeser = aktif ? s.onPrimary : tintaDasar;
    final skalaHuruf = MediaQuery.textScalerOf(context);

    Widget kata(int i, {required bool salinan}) {
      final c = Center(
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spasi.sm),
          child: salinan
              ? RichText(
                  textAlign: TextAlign.center,
                  textScaler: skalaHuruf,
                  text: TextSpan(
                    text: pilihan[i],
                    style: gaya?.copyWith(color: tintaGeser),
                  ),
                )
              // Kata dasar hanya gambar: pembaca layar menerima label dari
              // sel ketuk (kalau tidak, tiap kata terbaca dua kali).
              : ExcludeSemantics(
                  child: Text(
                    pilihan[i],
                    textAlign: TextAlign.center,
                    style: gaya?.copyWith(color: tintaDasar),
                  ),
                ),
        ),
      );
      return Expanded(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: UkuranKontrol.segmenDalam),
          child: c,
        ),
      );
    }

    final dasar = Row(
      children: [for (var i = 0; i < n; i++) kata(i, salinan: false)],
    );

    final geser = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: terpilih.toDouble()),
      duration: AppMotion.hormati(context, AppMotion.sedang),
      curve: AppMotion.masuk,
      builder: (context, v, _) {
        // Alignment x yang sama untuk pil dan salinan kata: salinan diimbangi
        // persis sebesar geseran pil, jadi kata putih tepat di atas kata dasar.
        final a = Alignment(-1 + 2 * v / (n - 1), 0);
        return LayoutBuilder(
          builder: (context, b) => Align(
            alignment: a,
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: ClipRRect(
                borderRadius: Bentuk.sudutKapsul,
                child: ColoredBox(
                  color: isiGeser,
                  child: OverflowBox(
                    alignment: a,
                    minWidth: b.maxWidth,
                    maxWidth: b.maxWidth,
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          for (var i = 0; i < n; i++) kata(i, salinan: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    final lapisKetuk = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < n; i++)
          Expanded(
            child: _Sel(
              label: pilihan[i],
              terpilih: i == terpilih,
              onTap: aktif ? () => onPilih!(i) : null,
              // Pil sel ke-i ada di [6 + i*(L-12)/n, 6 + (i+1)*(L-12)/n]; sel
              // ketuk ada di [i*L/n, (i+1)*L/n]. Selisihnya = jarak cincin
              // dan sorot dari tepi sel ketuk, supaya cincin tepat di pil.
              // Tiga pilihan atau lebih: sorot sel tengah bisa sedikit lebih
              // lebar dari sel ketuk (<= 2 dp); jarak tidak boleh negatif.
              kiri: _tidakNegatif(
                UkuranKontrol.segmenPadding * (1 - 2 * i / n),
              ),
              kanan: _tidakNegatif(
                UkuranKontrol.segmenPadding * (2 * (i + 1) / n - 1),
              ),
            ),
          ),
      ],
    );

    return Material(
      color: s.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Bentuk.sudutPil,
        side: BorderSide(color: s.outline, width: Elevasi.garis),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: UkuranKontrol.segmenLuar),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(UkuranKontrol.segmenPadding),
              child: Stack(
                fit: StackFit.passthrough,
                children: [dasar, Positioned.fill(child: geser)],
              ),
            ),
            Positioned.fill(child: lapisKetuk),
          ],
        ),
      ),
    );
  }

  static double _tidakNegatif(double v) => v < 0 ? 0 : v;

  /// Opasitas kata dan pil saat mati (pola Material 3: 38 % dan 12 %).
  static const double _alfaMati = 0.38;
  static const double _alfaIsiMati = 0.12;
}

/// Satu sel ketuk: seluruh bagian wadah milik pilihan ini, dari tepi ke tepi.
class _Sel extends StatelessWidget {
  const _Sel({
    required this.label,
    required this.terpilih,
    required this.onTap,
    required this.kiri,
    required this.kanan,
  });

  final String label;
  final bool terpilih;
  final VoidCallback? onTap;

  /// Jarak pil ke tepi kiri dan kanan sel ketuk (dp).
  final double kiri;
  final double kanan;

  @override
  Widget build(BuildContext context) {
    final aktif = onTap != null;
    return Semantics(
      button: true,
      enabled: aktif,
      selected: terpilih,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: TekanSkala(
        aktif: aktif,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AreaSentuh.minimum),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                kiri,
                UkuranKontrol.segmenPadding,
                kanan,
                UkuranKontrol.segmenPadding,
              ),
              child: CincinFokus(
                sudut: Bentuk.sudutKapsul,
                child: InkWell(
                  onTap: onTap,
                  customBorder: RoundedRectangleBorder(
                    borderRadius: Bentuk.sudutKapsul,
                  ),
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
