import 'package:flutter/widgets.dart';

/// Token sudut (radius). Datar dan konsisten, dan bervariasi dengan alasan:
/// stempel/tik 4, isian dan tombol sekunder 10, panel dan tombol utama 16,
/// lembar bawah dan dialog 20, pil hanya untuk lencana angka.
abstract final class Bentuk {
  /// 4 dp: stempel status, tik, penanda kecil.
  static const double kecil = 4;

  /// 10 dp: tombol, isian, ubin ikon.
  static const double kontrol = 10;

  /// 16 dp: panel (kelompok baris). Lebih lega dari Lab (8): panel di sini
  /// membungkus baris bacaan, bukan sel angka.
  static const double kartu = 16;

  /// 16 dp: tombol utama (satu per layar).
  static const double utama = 16;

  /// 20 dp: lembar bawah dan dialog.
  static const double lembar = 20;

  /// Pil penuh: lencana angka (dan chip saring sampai diganti komponen baru).
  static const double pil = 999;

  static final BorderRadius sudutKecil = BorderRadius.circular(kecil);
  static final BorderRadius sudutKontrol = BorderRadius.circular(kontrol);
  static final BorderRadius sudutUtama = BorderRadius.circular(utama);
  static final BorderRadius sudutKartu = BorderRadius.circular(kartu);
  static final BorderRadius sudutPil = BorderRadius.circular(pil);
}
