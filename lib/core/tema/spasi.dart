import 'package:flutter/widgets.dart';

/// Token spasi pada grid 4/8 dp. Layar tidak boleh menulis angka jarak
/// sendiri: pakai nama di bawah.
abstract final class Spasi {
  /// 4 dp: jarak rapat antara dua baris teks yang satu kelompok.
  static const double xs = 4;

  /// 8 dp: ikon dengan labelnya, antar-chip.
  static const double sm = 8;

  /// 12 dp: antar-kartu di daftar, padding dalam kartu kecil.
  static const double md = 12;

  /// 16 dp: margin halaman, padding dalam kartu, antar-bagian kecil.
  static const double lg = 16;

  /// 24 dp: antar-bagian.
  static const double xl = 24;

  /// 32 dp: ruang napas di layar sambutan dan keadaan kosong.
  static const double xxl = 32;

  /// 20 dp: margin kiri-kanan halaman (Pelanggan lebih lega dari Lab: 16).
  static const double sisi = 20;

  /// 32 dp: jarak antar-bagian layar.
  static const double bagian = 32;

  /// Di bawah lebar ini (320-339 dp) baris daftar memindahkan kolom angka
  /// ke atas judul.
  static const double batasKompak = 340;

  /// Lebar isi maksimum di layar lebar (tablet): isi dipusatkan.
  static const double lebarKonten = 720;

  /// Lebar isi maksimum untuk layar dua kolom di tablet (Beranda): isi tetap
  /// dipusatkan, tetapi dua kolom tidak dipaksa masuk 720 dp.
  static const double lebarLebar = 1040;

  /// Lebar layar mulai mana tata letak berganti ke rel navigasi samping.
  static const double batasLebar = 600;

  /// Margin kiri-kanan halaman.
  static const EdgeInsets halaman = EdgeInsets.symmetric(horizontal: lg);

  /// Padding standar isi kartu.
  static const EdgeInsets kartu = EdgeInsets.all(lg);

  /// [dasar] ditambah tinggi navigasi sistem di bawah (gesture bar atau tiga
  /// tombol). Android 15+ menggambar sampai ke bawah navigasi sistem, sehingga
  /// isi terakhir daftar tertutup tombol HP bila tidak ditambah ini. Di tab
  /// HP nilainya 0: `NavigasiUtama` sudah memakainya untuk navigasi bawah.
  static EdgeInsets denganTepiBawah(BuildContext context, EdgeInsets dasar) =>
      dasar + EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom);

  /// Padding daftar bergulir: margin halaman, [md] di atas, [xl] di bawah,
  /// plus tepi sistem.
  static EdgeInsets daftar(BuildContext context) =>
      denganTepiBawah(context, const EdgeInsets.fromLTRB(lg, md, lg, xl));
}
