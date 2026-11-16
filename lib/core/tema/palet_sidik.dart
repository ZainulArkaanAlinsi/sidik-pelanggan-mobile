import 'package:flutter/painting.dart';

/// Palet mentah SIDIK Pelanggan, arah "tenang-formal-ringkas" (REVISI 16 Nov
/// 2026, menggantikan "Bento Lab"): latar abu kebiruan sangat muda, permukaan
/// putih, navy untuk judul, biru untuk aksi dan pilihan aktif, dan empat pasang
/// status (tinta gelap di atas warna muda). Warna hanya untuk status dan
/// tindakan. SATU-SATUNYA berkas yang boleh menulis `Color(0x...)`; layar dan
/// widget membaca warna lewat `Theme.of(context)` (`ColorScheme`) atau
/// [WarnaSidik]. Dijaga `test/tema/token_tema_test.dart`.
///
/// Sumber nilai: `docs/desain-ulang/tokens.json` (diselaraskan ke REVISI-1 dan
/// REVISI-2). Semua pasangan teks/latar yang dipakai sudah dihitung ke WCAG AA
/// (teks 4,5:1, garis dan ikon penting 3:1) di
/// `test/tema/kontras_tema_test.dart`. Ubah satu nilai di sini = jalankan tes
/// itu lagi.
///
/// Nama lama dipertahankan agar PR ini tidak menyentuh puluhan pemakai
/// (`navy`, `kuning`, `koral`, `hijau`, `langit`): sekarang artinya warna MUDA
/// status ("kuning" = latar awas, bukan kuning terang). Pembersihan nama di PR
/// berikutnya.
abstract final class PaletSidik {
  // ── Teks, aksi, dan pilihan aktif ───────────────────────────────────────
  /// Navy: judul dan teks utama (#102A43). BUKAN lagi warna tombol.
  static const Color navy = Color(0xFF102A43);

  /// Biru aksi: tombol utama, tautan, penanda tab aktif (#1769C2). Putih di
  /// atasnya 5,5:1.
  static const Color biru = Color(0xFF1769C2);

  /// Biru muda: pilihan aktif, ubin ikon, banner informasi (#EAF3FF).
  /// Dipadukan dengan tepi atau indikator, tidak berdiri sendiri.
  static const Color biruMuda = Color(0xFFEAF3FF);

  /// Rel dan jejak di atas navy (tema gelap, titik kursi kosong).
  static const Color navyLembut = Color(0xFF2B4380);

  /// Teks kedua di atas navy.
  static const Color navyTeks = Color(0xFFC9D3EA);

  /// Kobalt logo PT Sidik. HANYA untuk `LogoSidik`/aset merek; bukan warna
  /// aksi, tautan, atau status (warna aksi app adalah [biru]).
  static const Color kobaltLogo = Color(0xFF043EA1);

  // ── Status, tema terang: latar MUDA. Tinta gelapnya di bawah ─────────────
  /// Gagal / lewat jadwal / tidak memenuhi: merah muda.
  static const Color koral = Color(0xFFFDE8E6);

  /// Awas (segera jatuh tempo, perlu diperiksa): krem.
  static const Color kuning = Color(0xFFFFF3D6);

  /// Lulus / berlaku / selesai: hijau muda.
  static const Color hijau = Color(0xFFE3F3E8);

  /// Tunggu / diproses / info: biru kelabu muda.
  static const Color langit = Color(0xFFE6F0FA);

  // ── Tinta status, tema terang (gelap di atas warna muda, >= 5,6:1) ───────
  // Terangnya sengaja berjenjang (biru < hijau < merah < amber, selisih > 0,02):
  // status tidak hanya dibedakan rona, tetap lewat ikon + kata.
  static const Color hijauTinta = Color(0xFF124D2C);
  static const Color kuningTinta = Color(0xFF8A5500);
  static const Color langitTinta = Color(0xFF0A3560);
  // Tinta gagal = [galat] (merah tua, di bawah).

  // ── Netral, tema terang ─────────────────────────────────────────────────
  /// Latar halaman (#F4F7FB).
  static const Color latar = Color(0xFFF4F7FB);

  /// Panel dan kontrol (putih).
  static const Color kartu = Color(0xFFFFFFFF);

  /// Permukaan netral sedikit lebih gelap dari [latar]: lintasan progres,
  /// kerangka pemuatan, lencana netral, kapsul kosong (#E9EFF6).
  static const Color latarTinggi = Color(0xFFE9EFF6);

  /// Teks kedua (#526477): keterangan, metadata. 6,1:1 di atas putih.
  static const Color teksKedua = Color(0xFF526477);

  /// Garis halus dan pemisah (#DCE5EE; dekoratif, 1,2:1 di atas putih, jadi
  /// TIDAK boleh jadi satu-satunya penanda tepi kontrol).
  static const Color garis = Color(0xFFDCE5EE);

  /// Tepi kontrol yang wajib terlihat (isian, tombol sekunder, sakelar mati):
  /// >= 3:1 di atas putih, [latar], dan [garis] (4,5:1 di atas putih).
  static const Color garisTegas = Color(0xFF66788A);

  /// Merah tua untuk galat isian, tindakan merusak, dan tinta status gagal.
  static const Color galat = Color(0xFFA3261A);

  // ── Netral, tema gelap (titik awal, belum final) ────────────────────────
  static const Color latarGelap = Color(0xFF0A1226);
  static const Color kartuGelap = Color(0xFF131E3A);
  static const Color permukaanRendahGelap = Color(0xFF0F192F);
  static const Color permukaanTinggiGelap = Color(0xFF1B2A4D);
  static const Color permukaanTertinggiGelap = Color(0xFF26385F);
  static const Color teksGelap = Color(0xFFE8ECF6);
  static const Color teksKeduaGelap = Color(0xFFC9D3EA);
  static const Color garisTegasGelap = Color(0xFF7C879B);
  static const Color garisHalusGelap = Color(0xFF26385F);

  /// Biru aksi di atas latar gelap (tombol utama, tautan, tab aktif).
  static const Color biruDiGelap = Color(0xFF8EC2F7);

  // ── Status, tema gelap ──────────────────────────────────────────────────
  // Di tema gelap latar status menjadi gelap bernada sama dan tintanya pastel
  // (dipakai langsung sebagai teks/ikon di atas halaman gelap).
  static const Color lulusLatarGelap = Color(0xFF12301F);
  static const Color awasLatarGelap = Color(0xFF33260C);
  static const Color gagalLatarGelap = Color(0xFF3A1720);
  static const Color tungguLatarGelap = Color(0xFF262E40);
  static const Color hijauTintaGelap = Color(0xFF8ED1A5);
  static const Color kuningTintaGelap = Color(0xFFF0C36A);
  static const Color koralTintaGelap = Color(0xFFF4A39B);

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

  /// Alias [kuning]: latar kartu galat darurat (krem awas).
  static const Color awasLatarTerang = kuning;
}
