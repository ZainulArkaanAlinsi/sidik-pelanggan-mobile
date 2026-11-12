import 'package:flutter/widgets.dart';

/// Token sudut (radius). Datar dan konsisten: kartu 12, kontrol 10, chip penuh.
abstract final class Bentuk {
  /// 6 dp: penanda kecil (titik, balok kerangka).
  static const double kecil = 6;

  /// 10 dp: tombol, isian, ubin ikon.
  static const double kontrol = 10;

  /// 12 dp: kartu dan lembar.
  static const double kartu = 12;

  /// 20 dp: lembar bawah dan dialog.
  static const double lembar = 20;

  /// Pil penuh: chip status, lencana.
  static const double pil = 999;

  static final BorderRadius sudutKecil = BorderRadius.circular(kecil);
  static final BorderRadius sudutKontrol = BorderRadius.circular(kontrol);
  static final BorderRadius sudutKartu = BorderRadius.circular(kartu);
  static final BorderRadius sudutPil = BorderRadius.circular(pil);
}
