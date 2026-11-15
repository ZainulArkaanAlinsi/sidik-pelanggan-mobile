import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/motion/gerak_bento.dart';
import '../../core/tema/ukuran.dart';
import 'cincin_fokus.dart';

/// Dasar kontrol ketuk KECIL Bento (tombol bulat, saringan pil, sel segmen):
/// satu tempat untuk semantik, area sentuh, umpan balik tekan, dan fokus.
///
/// - Area sentuh SELALU >= 48 x 48 dp ([AreaSentuh.minimum]) walau isi visualnya
///   lebih kecil (tombol bulat 44, saringan 44): kotak 48 itu sendiri yang
///   mendengar ketukan (`GestureDetector` buram), jadi ketukan di tepi kotak,
///   di luar pil, tetap sampai. Ketukan di dalam pil ditangani `InkWell`
///   (ripple); hanya satu yang menang, tidak pernah dua kali.
/// - Pembaca layar menerima SATU simpul tombol dengan [semantik]; bila [onTap]
///   null simpulnya `enabled: false` dan tidak punya aksi ketuk. Label selalu
///   dipasang walau kontrolnya mati.
/// - Skala tekan 0,97 ([TekanSkala]); cincin fokus di luar isi ([CincinFokus]).
///
/// [warna] dan [sisi] menggambar latar pil; pemanggil memberi warna yang sudah
/// memperhitungkan keadaan mati.
class KontrolKetuk extends StatelessWidget {
  const KontrolKetuk({
    super.key,
    required this.child,
    required this.onTap,
    required this.semantik,
    required this.warna,
    required this.sudut,
    this.sisi = BorderSide.none,
    this.terpilih,
  });

  final Widget child;

  /// Null = kontrol mati.
  final VoidCallback? onTap;
  final String semantik;
  final Color warna;
  final BorderRadius sudut;
  final BorderSide sisi;

  /// Dipasang ke `Semantics.selected` bila tidak null (saringan, segmen).
  final bool? terpilih;

  @override
  Widget build(BuildContext context) {
    final bentuk = RoundedRectangleBorder(borderRadius: sudut, side: sisi);
    final aktif = onTap != null;
    return Semantics(
      button: true,
      enabled: aktif,
      selected: terpilih,
      label: semantik,
      onTap: onTap,
      excludeSemantics: true,
      child: TekanSkala(
        aktif: aktif,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AreaSentuh.minimum,
              minHeight: AreaSentuh.minimum,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: CincinFokus(
                sudut: sudut,
                child: Material(
                  color: warna,
                  animationDuration: AppMotion.hormati(
                    context,
                    AppMotion.kilat,
                  ),
                  shape: bentuk,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    customBorder: bentuk,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
