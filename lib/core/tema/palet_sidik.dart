import 'package:flutter/painting.dart';

/// Palet mentah SIDIK Pelanggan. SATU-SATUNYA berkas yang boleh menulis
/// `Color(0x...)`; layar dan widget membaca warna lewat `Theme.of(context)`
/// (`ColorScheme`) atau [WarnaSidik]. Dijaga `test/tema/token_tema_test.dart`.
///
/// Semua pasangan teks/latar yang dipakai sudah dihitung ke WCAG AA (teks
/// 4,5:1, garis dan ikon penting 3:1) di `test/tema/kontras_tema_test.dart`.
/// Ubah satu nilai di sini = jalankan tes itu lagi.
abstract final class PaletSidik {
  // ── Merek ───────────────────────────────────────────────────────────────
  /// Kobalt logo PT Sidik.
  static const Color kobalt = Color(0xFF043EA1);
  static const Color kobaltTipis = Color(0xFFDCE6FA);
  static const Color kobaltTua = Color(0xFF0A2A6B);

  /// Kobalt versi tema gelap (lebih terang agar terbaca di atas permukaan gelap).
  static const Color kobaltTerang = Color(0xFF8CB0FF);
  static const Color kobaltTerangTua = Color(0xFF04265F);
  static const Color kobaltGelapTipis = Color(0xFF14306F);
  static const Color kobaltGelapTeks = Color(0xFFD6E3FF);

  /// Kertas halaman PDF: putih di dua tema (halaman cetak tidak ikut gelap).
  static const Color kertasPdf = Color(0xFFFFFFFF);

  /// Latar berkas logo (putih): ubin di belakang logo pada tema gelap.
  static const Color latarLogo = Color(0xFFFFFFFF);

  /// Merah check mark logo KAN. KHUSUS lencana akreditasi: bukan warna galat.
  static const Color kanMerah = Color(0xFFD32F2F);
  static const Color kanMerahGelap = Color(0xFFFF6B6B);

  // ── Netral dingin, tema terang ──────────────────────────────────────────
  static const Color latarTerang = Color(0xFFF2F4F8);
  static const Color permukaanTerang = Color(0xFFFFFFFF);
  static const Color permukaanRendahTerang = Color(0xFFF8F9FC);
  static const Color permukaanTinggiTerang = Color(0xFFE9EDF4);
  static const Color permukaanTertinggiTerang = Color(0xFFDFE4EE);
  static const Color teksTerang = Color(0xFF111827);
  static const Color teksKeduaTerang = Color(0xFF475467);
  static const Color garisTerang = Color(0xFF6B7588);
  static const Color garisHalusTerang = Color(0xFFDDE2EB);

  // ── Netral dingin, tema gelap ───────────────────────────────────────────
  static const Color latarGelap = Color(0xFF0E1320);
  static const Color permukaanGelap = Color(0xFF171D2B);
  static const Color permukaanRendahGelap = Color(0xFF131927);
  static const Color permukaanTinggiGelap = Color(0xFF1E2535);
  static const Color permukaanTertinggiGelap = Color(0xFF283044);
  static const Color teksGelap = Color(0xFFE6EAF2);
  static const Color teksKeduaGelap = Color(0xFFA9B2C3);
  static const Color garisGelap = Color(0xFF7C879B);
  static const Color garisHalusGelap = Color(0xFF2C3548);

  // ── Status, tema terang: tinta + latar tipis ────────────────────────────
  // Lulus, awas, dan gagal harus beda TERANGNYA (luminans relatif > 0,02),
  // bukan cuma beda rona: merah, hijau, dan amber duduk di sumbu yang hilang
  // untuk mata deuteranopia dan fotokopi hitam-putih. Amber lama (`#7A4F08`,
  // `#F2B655`) nyaris sama terangnya dengan merah (terang, beda 0,004) dan
  // dengan hijau (gelap, beda 0,005). Amber di bawah sama dengan milik Lab.
  static const Color lulusTerang = Color(0xFF125739);
  static const Color lulusLatarTerang = Color(0xFFE1F0E8);
  static const Color awasTerang = Color(0xFF8C5C0A);
  static const Color awasLatarTerang = Color(0xFFFBF0DA);
  static const Color gagalTerang = Color(0xFFA81B33);
  static const Color gagalLatarTerang = Color(0xFFFBE4E8);
  static const Color tungguTerang = Color(0xFF344054);
  static const Color tungguLatarTerang = Color(0xFFE6EAF2);

  // ── Status, tema gelap ──────────────────────────────────────────────────
  static const Color lulusGelap = Color(0xFF6FD3A0);
  static const Color lulusLatarGelap = Color(0xFF12301F);
  static const Color awasGelap = Color(0xFFDB9A2B);
  static const Color awasLatarGelap = Color(0xFF33260C);
  static const Color gagalGelap = Color(0xFFFF8FA0);
  static const Color gagalLatarGelap = Color(0xFF3A1720);
  static const Color tungguGelap = Color(0xFFC3CAD8);
  static const Color tungguLatarGelap = Color(0xFF262E40);

  // ── Bayangan ────────────────────────────────────────────────────────────
  static const Color bayangan = Color(0xFF000000);
}
