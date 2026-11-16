import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/motion/gerak_bento.dart';
import '../../core/tema/elevasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import 'cincin_fokus.dart';

/// Kerangka bersama ubin ([UbinAlat], [UbinRingkas], [UbinMenu]): latar
/// (putih netral, atau warna muda status untuk ubin ringkasan), garis halus 1 dp,
/// sudut 16, tinggi MINIMUM (tumbuh bersama huruf; jangan dikunci), visual di
/// sudut kanan bawah yang keluar dari tepi dan dipotong sudut ubin, satu simpul
/// tombol untuk pembaca layar, umpan balik tekan, dan cincin fokus.
///
/// - [visual] digambar DI BAWAH teks dan tanpa semantik: murni hiasan, tidak
///   pernah menutupi teks. Ukurannya [ukuranVisual]; keluar dari tepi kanan
///   [keluarSamping] dan tepi bawah [keluarBawah]. Masuk dengan pudar +
///   membesar 0,92 → 1 setelah ubinnya ([VisualMasuk]).
/// - [onTap] null = ubin statis (bukan tombol). Bila [semantik] ada, pembaca
///   layar menerima SATU kalimat itu dan isi ubin dibuang dari pohon semantik,
///   dengan aksi ketuk dipasang lagi pada simpul berlabel (kalau tidak, tombol
///   berlabel tidak bisa diaktifkan). Label yang diberikan SELALU dipasang,
///   termasuk pada ubin statis.
/// - [urutan] non-null = ubin masuk layar berurutan ([MasukBerurutan]); null =
///   tanpa animasi masuk (layar memilih, sesuai aturan "hanya saat pertama
///   dibangun").
class DasarUbin extends StatelessWidget {
  const DasarUbin({
    super.key,
    required this.latar,
    required this.sudut,
    required this.tinggiMin,
    required this.padding,
    required this.child,
    this.visual,
    this.ukuranVisual = 0,
    this.keluarSamping = UkuranVisual.keluarKecil,
    this.keluarBawah = UkuranVisual.keluarKecil,
    this.onTap,
    this.semantik,
    this.urutan,
  }) : assert(tinggiMin >= AreaSentuh.minimum);

  final Color latar;
  final BorderRadius sudut;
  final double tinggiMin;
  final EdgeInsets padding;
  final Widget child;
  final Widget? visual;
  final double ukuranVisual;
  final double keluarSamping;
  final double keluarBawah;
  final VoidCallback? onTap;
  final String? semantik;
  final int? urutan;

  @override
  Widget build(BuildContext context) {
    final bentuk = RoundedRectangleBorder(
      borderRadius: sudut,
      side: BorderSide(
        color: context.skema.outlineVariant,
        width: Elevasi.garis,
      ),
    );
    final isi = ConstrainedBox(
      constraints: BoxConstraints(minHeight: tinggiMin),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (visual != null)
            Positioned(
              right: -keluarSamping,
              bottom: -keluarBawah,
              width: ukuranVisual,
              height: ukuranVisual,
              child: ExcludeSemantics(child: VisualMasuk(child: visual!)),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    Widget ubin = Material(
      color: latar,
      animationDuration: AppMotion.hormati(context, AppMotion.kilat),
      shape: bentuk,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? isi
          : InkWell(onTap: onTap, customBorder: bentuk, child: isi),
    );
    ubin = CincinFokus(sudut: sudut, child: ubin);

    if (onTap == null) {
      if (semantik != null) {
        ubin = Semantics(
          container: true,
          label: semantik,
          excludeSemantics: true,
          child: ubin,
        );
      }
    } else {
      ubin = Semantics(
        button: true,
        label: semantik,
        onTap: semantik == null ? null : onTap,
        excludeSemantics: semantik != null,
        child: TekanSkala(child: ubin),
      );
    }
    return urutan == null ? ubin : MasukBerurutan(indeks: urutan!, child: ubin);
  }
}
