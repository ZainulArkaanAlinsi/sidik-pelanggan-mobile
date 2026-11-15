import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/elevasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'dasar/kontrol_ketuk.dart';

/// Ukuran tombol bulat (KOMPONEN.md §Aksi dan masukan): 44 di dalam kolom
/// cari, 48 di kepala layar, 52 untuk aksi di ubin; [ubin] (40) hanya untuk
/// penanda dekoratif di ubin menu.
enum UkuranTombolBulat {
  ubin(UkuranKontrol.tombolBulatUbin, UkuranIkon.tombol),
  kecil(UkuranKontrol.tombolBulatKecil, UkuranIkon.tombol),
  sedang(UkuranKontrol.tombolBulat, UkuranIkon.tombol),
  besar(UkuranKontrol.tombolBulatBesar, UkuranIkon.tombolBesar);

  const UkuranTombolBulat(this.sisi, this.ikon);

  /// Diameter lingkaran (dp).
  final double sisi;

  /// Ukuran ikon di dalamnya (dp).
  final double ikon;
}

/// Warna tombol bulat: [navy] (cari), [putih] (kembali), [kuning] (aksi ubin).
/// [navy] mengikuti `ColorScheme.primary`, jadi di tema gelap menjadi biru muda
/// (terbaca di atas halaman gelap). [navyUbin] tetap navy dengan ikon putih di
/// dua tema: untuk tombol yang duduk di atas UBIN pastel (ubin tidak ikut gelap).
enum NadaTombolBulat { navy, putih, kuning, navyUbin }

/// Tombol bulat Bento Lab: ikon di lingkaran, tanpa teks. Karena tanpa teks,
/// [semantik] (label baca) WAJIB: pembaca layar menerima "Cari, tombol".
///
/// Area sentuh selalu >= 48 dp walau lingkarannya 44 ([KontrolKetuk]): ketukan
/// di mana pun dalam kotak 48 diterima. [onTap] null = mati: warna meredup
/// (latar dan ikon dari `onSurface`), simpul semantik `enabled: false`, tidak
/// ada aksi ketuk. Papan ketik: Enter/Spasi mengaktifkan dan cincin fokus
/// muncul di luar lingkaran.
///
/// Nama bentuk: [TombolBulat.cari] (44 navy), [TombolBulat.kembali] (48 putih),
/// [TombolBulat.aksi] (52 kuning atau navy), [TombolBulat.hiasan] (penanda
/// tanpa aksi di dalam ubin yang seluruhnya bisa diketuk).
class TombolBulat extends StatelessWidget {
  const TombolBulat({
    super.key,
    required this.ikon,
    required this.semantik,
    required this.onTap,
    this.ukuran = UkuranTombolBulat.sedang,
    this.nada = NadaTombolBulat.putih,
  }) : _hiasan = false;

  /// 44 navy: tombol cari di dalam kolom cari.
  const TombolBulat.cari({
    super.key,
    this.ikon = Icons.search,
    this.semantik = 'Cari',
    required this.onTap,
  }) : ukuran = UkuranTombolBulat.kecil,
       nada = NadaTombolBulat.navy,
       _hiasan = false;

  /// 48 putih bergaris halus: kembali di kepala layar anak.
  const TombolBulat.kembali({
    super.key,
    this.ikon = Icons.arrow_back,
    this.semantik = 'Kembali',
    required this.onTap,
  }) : ukuran = UkuranTombolBulat.sedang,
       nada = NadaTombolBulat.putih,
       _hiasan = false;

  /// 52: aksi di ubin, kuning (bawaan), [NadaTombolBulat.navyUbin], atau navy.
  const TombolBulat.aksi({
    super.key,
    this.ikon = Icons.north_east,
    required this.semantik,
    required this.onTap,
    this.nada = NadaTombolBulat.kuning,
  }) : ukuran = UkuranTombolBulat.besar,
       _hiasan = false;

  /// Hanya gambar (tanpa semantik, tanpa ketukan): penanda di dalam ubin yang
  /// seluruhnya sudah menjadi satu tombol, supaya tombol tidak bersarang.
  const TombolBulat.hiasan({
    super.key,
    this.ikon = Icons.north_east,
    this.ukuran = UkuranTombolBulat.ubin,
    this.nada = NadaTombolBulat.navyUbin,
  }) : semantik = '',
       onTap = null,
       _hiasan = true;

  final IconData ikon;
  final String semantik;
  final VoidCallback? onTap;
  final UkuranTombolBulat ukuran;
  final NadaTombolBulat nada;
  final bool _hiasan;

  /// Pasangan (isi, ikon, garis) menurut [nada] dan keadaan [aktif].
  static (Color, Color, BorderSide) warnaDari(
    BuildContext context,
    NadaTombolBulat nada, {
    required bool aktif,
  }) {
    final s = context.skema;
    if (!aktif) {
      return (
        s.onSurface.withValues(alpha: _alfaIsiMati),
        s.onSurface.withValues(alpha: _alfaIkonMati),
        BorderSide.none,
      );
    }
    return switch (nada) {
      NadaTombolBulat.navy => (s.primary, s.onPrimary, BorderSide.none),
      NadaTombolBulat.putih => (
        s.surface,
        s.onSurface,
        BorderSide(color: s.outlineVariant, width: Elevasi.garis),
      ),
      NadaTombolBulat.kuning => (s.secondary, s.onSecondary, BorderSide.none),
      NadaTombolBulat.navyUbin => (
        context.warna.tintaUbin,
        context.warna.kertasUbin,
        BorderSide.none,
      ),
    };
  }

  /// Opasitas isi dan ikon saat mati (pola Material 3: 12 % dan 38 %).
  static const double _alfaIsiMati = 0.12;
  static const double _alfaIkonMati = 0.38;

  @override
  Widget build(BuildContext context) {
    // Hiasan tidak punya ketukan tetapi TIDAK mati: warnanya penuh.
    final aktif = _hiasan || onTap != null;
    final (isi, tintaIkon, garis) = warnaDari(context, nada, aktif: aktif);
    final gambar = SizedBox.square(
      dimension: ukuran.sisi,
      child: Center(child: Icon(ikon, size: ukuran.ikon, color: tintaIkon)),
    );
    if (_hiasan) {
      return ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isi,
            shape: BoxShape.circle,
            border: garis == BorderSide.none
                ? null
                : Border.fromBorderSide(garis),
          ),
          child: gambar,
        ),
      );
    }
    return KontrolKetuk(
      onTap: onTap,
      semantik: semantik,
      warna: isi,
      sudut: Bentuk.sudutPil,
      sisi: garis,
      child: gambar,
    );
  }
}
