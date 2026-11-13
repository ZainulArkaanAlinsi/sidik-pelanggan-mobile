import 'package:flutter/material.dart';

import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';

enum _Mode { apaAdanya, mengecil, membungkus }

/// Nomor (order, sertifikat, seri) yang tidak pernah putus di tengah angka.
///
/// Digit selebar tetap dengan nol bergaris ([GayaAngka.nomor]). Urutan usaha:
///
/// 1. Muat satu baris pada ukuran aslinya: tampil apa adanya.
/// 2. Tidak muat, tetapi bisa dikecilkan tanpa turun di bawah
///    [SkalaHuruf.nomorMinimum] sp efektif: satu baris yang mengecil
///    (`FittedBox`).
/// 3. Masih tidak muat: membungkus pada pemisah alami (garis miring) dengan
///    ukuran asli. Tidak dipotong dan tidak diberi elipsis: angka yang
///    terpotong lebih buruk daripada angka yang membungkus. Nomor tanpa
///    pemisah alami yang lebih lebar dari baris patah per karakter; pemanggil
///    yang tahu lebarnya sempit memberi nomor itu baris sendiri
///    ([muatSatuBaris]).
///
/// Dipakai `BarisSidik` (judul bergaya nomor), `Fakta`, dan `PlatNama`, serta
/// langsung untuk nomor order di kepala layar paket.
class NomorSidik extends StatelessWidget {
  const NomorSidik(this.nomor, {super.key, this.gaya, this.rataTengah = false});

  final String nomor;

  /// Dasar gaya; bawaan `bodyLarge`. Fitur nomor ditambahkan di sini.
  final TextStyle? gaya;

  final bool rataTengah;

  /// Apakah [nomor] bergaya [gaya] muat dalam [lebar] sebagai SATU baris:
  /// apa adanya atau mengecil tidak di bawah [SkalaHuruf.nomorMinimum] sp
  /// efektif. Untuk pemanggil yang memilih tata letak (mis. `Fakta`: sebaris
  /// dengan labelnya atau di bawahnya).
  static bool muatSatuBaris(
    BuildContext context,
    String nomor,
    TextStyle gaya,
    double lebar,
  ) =>
      _mode(context, _gayaNomor(context, gaya), nomor, lebar) !=
      _Mode.membungkus;

  static TextStyle _gayaNomor(BuildContext context, TextStyle dasar) =>
      DefaultTextStyle.of(context).style.merge(dasar).nomor;

  static _Mode _mode(
    BuildContext context,
    TextStyle gayaNomor,
    String nomor,
    double lebar,
  ) {
    final skala = MediaQuery.textScalerOf(context);
    final pengukur = TextPainter(
      text: TextSpan(text: nomor, style: gayaNomor),
      textDirection: Directionality.of(context),
      textScaler: skala,
      maxLines: 1,
    )..layout();
    final asli = pengukur.width;
    pengukur.dispose();
    if (asli <= lebar) return _Mode.apaAdanya;
    final efektif = skala.scale(gayaNomor.fontSize ?? 0) * (lebar / asli);
    return efektif >= SkalaHuruf.nomorMinimum
        ? _Mode.mengecil
        : _Mode.membungkus;
  }

  @override
  Widget build(BuildContext context) {
    final gayaNomor = _gayaNomor(context, gaya ?? context.teks.bodyLarge!);
    final perataan = rataTengah
        ? Alignment.center
        : AlignmentDirectional.centerStart;

    return LayoutBuilder(
      builder: (context, batas) {
        final teks = Text(
          nomor,
          style: gayaNomor,
          textAlign: rataTengah ? TextAlign.center : TextAlign.start,
        );
        if (!batas.hasBoundedWidth) return teks;
        return switch (_mode(context, gayaNomor, nomor, batas.maxWidth)) {
          _Mode.mengecil => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: perataan,
            child: teks,
          ),
          _ => teks,
        };
      },
    );
  }
}
