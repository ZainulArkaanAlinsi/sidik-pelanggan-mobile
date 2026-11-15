import 'package:flutter/painting.dart';

/// Palet mentah SIDIK Pelanggan, arah "Bento Lab": navy korporat + empat ubin
/// pastel yang masing-masing terikat ke SATU makna status. SATU-SATUNYA berkas
/// yang boleh menulis `Color(0x...)`; layar dan widget membaca warna lewat
/// `Theme.of(context)` (`ColorScheme`) atau [WarnaSidik]. Dijaga
/// `test/tema/token_tema_test.dart`.
///
/// Sumber nilai: `docs/desain-ulang/tokens.json` dan `DESIGN.md`. Semua pasangan
/// teks/latar yang dipakai sudah dihitung ke WCAG AA (teks 4,5:1, garis dan
/// ikon penting 3:1) di `test/tema/kontras_tema_test.dart`. Ubah satu nilai di
/// sini = jalankan tes itu lagi.
abstract final class PaletSidik {
  // ── Merek ───────────────────────────────────────────────────────────────
  /// Navy: teks utama, tombol utama, dock.
  static const Color navy = Color(0xFF0B1F4B);

  /// Rel dan jejak di atas navy.
  static const Color navyLembut = Color(0xFF2B4380);

  /// Teks kedua di atas navy.
  static const Color navyTeks = Color(0xFFC9D3EA);

  /// Kobalt logo PT Sidik. HANYA untuk `LogoSidik`/aset merek; bukan warna
  /// aksi, tautan, atau status (warna utama app adalah [navy]).
  static const Color kobaltLogo = Color(0xFF043EA1);

  // ── Ubin status (latar). Tinta di atasnya selalu [navy] ──────────────────
  /// Gagal / lewat jadwal.
  static const Color koral = Color(0xFFF2957A);

  /// Awas (segera jatuh tempo) dan aksen: butir dock aktif, lencana jumlah.
  static const Color kuning = Color(0xFFF6D36B);

  /// Lulus / berlaku / selesai.
  static const Color hijau = Color(0xFFCBE7B8);

  /// Tunggu / diproses / info.
  static const Color langit = Color(0xFFBCE0F0);

  // ── Netral, tema terang ─────────────────────────────────────────────────
  /// Latar halaman, rel kapsul, pemisah.
  static const Color latar = Color(0xFFEEF0F3);

  /// Panel dan kontrol (putih).
  static const Color kartu = Color(0xFFFFFFFF);

  /// Keterangan. TIDAK dipakai di atas [koral] (3,3:1): pakai [navy].
  static const Color teksKedua = Color(0xFF4A5672);

  /// Garis halus dan pemisah (dekoratif; 1,4:1 di atas putih, jadi TIDAK boleh
  /// jadi satu-satunya penanda tepi kontrol).
  static const Color garis = Color(0xFFD5DAE3);

  /// Tepi kontrol yang wajib terlihat (isian, tombol sekunder, sakelar mati):
  /// 3:1 di atas putih, [latar], dan [garis]. Nilai Jejak yang dipertahankan;
  /// `garis` Bento Lab tidak mencapai 3:1.
  static const Color garisTegas = Color(0xFF6B7588);

  /// Merah tua untuk galat isian dan tindakan merusak (ELEMEN.md: dialog
  /// bahaya #A3261A). BUKAN warna status gagal (itu [koral] + tinta navy).
  static const Color galat = Color(0xFFA3261A);

  // ── Netral, tema gelap (titik awal, belum final: DESIGN.md §Mode gelap) ──
  static const Color latarGelap = Color(0xFF0A1226);
  static const Color kartuGelap = Color(0xFF131E3A);
  static const Color permukaanRendahGelap = Color(0xFF0F192F);
  static const Color permukaanTinggiGelap = Color(0xFF1B2A4D);
  static const Color permukaanTertinggiGelap = Color(0xFF26385F);
  static const Color teksGelap = Color(0xFFE8ECF6);
  static const Color teksKeduaGelap = Color(0xFFC9D3EA);
  static const Color garisTegasGelap = Color(0xFF7C879B);
  static const Color garisHalusGelap = Color(0xFF26385F);

  // ── Status, tema gelap ──────────────────────────────────────────────────
  // Di tema gelap warna ubin menjadi TINTA (hijau, kuning, koral, langit di
  // atas latar gelap bernada sama). Alasannya: tinta status juga dipakai
  // langsung sebagai teks/ikon di atas halaman; tinta navy di atas halaman
  // gelap tidak terbaca. (Catatan desain: DESIGN.md menyarankan ubin tetap
  // terang di mode gelap; itu butuh pemisahan tinta-ubin dan tinta-halaman di
  // `WarnaSidik` dulu. Lihat docs/standar-kualitas-desain.md §3.)
  static const Color lulusLatarGelap = Color(0xFF12301F);
  static const Color awasLatarGelap = Color(0xFF33260C);
  static const Color gagalLatarGelap = Color(0xFF3A1720);
  static const Color tungguLatarGelap = Color(0xFF262E40);

  // ── Akreditasi dan berkas ───────────────────────────────────────────────
  /// Merah check mark logo KAN. KHUSUS lencana akreditasi: bukan warna galat.
  static const Color kanMerah = Color(0xFFD32F2F);
  static const Color kanMerahGelap = Color(0xFFFF6B6B);

  /// Kertas halaman PDF: putih di dua tema (halaman cetak tidak ikut gelap).
  static const Color kertasPdf = Color(0xFFFFFFFF);

  /// Latar berkas logo (putih): ubin di belakang logo pada tema gelap.
  static const Color latarLogo = Color(0xFFFFFFFF);

  // ── Bayangan ────────────────────────────────────────────────────────────
  static const Color bayangan = Color(0xFF000000);

  // ── Alias nama lama (masih dipakai di luar lib/core/tema) ───────────────
  // `KartuGalatRamah` (pelapor_galat.dart) menggambar tanpa Theme, jadi
  // membaca palet langsung. Hapus saat berkas itu pindah ke token baru.
  /// Alias [navy]: tinta teks di kartu galat darurat.
  static const Color teksTerang = navy;

  /// Alias [kuning]: latar kartu galat darurat (dulu amber tipis).
  static const Color awasLatarTerang = kuning;
}
