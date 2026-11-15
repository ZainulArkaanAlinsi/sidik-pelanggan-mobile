import 'package:flutter/widgets.dart';

/// Token sudut (radius), arah "Bento Lab": ubin besar membulat, tombol pil.
/// Nilai dari `docs/desain-ulang/tokens.json` (`sudut`) dan `DESIGN.md`.
///
/// | Token    | dp  | Pakai                                              |
/// |----------|-----|----------------------------------------------------|
/// | `ikon`   | 16  | ubin ikon persegi, isian                           |
/// | `kapsul` | 22  | kapsul grafik, segmen, saringan, toast             |
/// | `panel`  | 28  | panel putih, ubin kecil (tinggi sampai 188), dialog |
/// | `ubin`   | 32  | ubin besar, lembar bawah (sudut atas)              |
/// | `dock`   | 36  | dock navigasi                                      |
/// | `pil`    | 999 | tombol, stempel, kolom cari, avatar                |
abstract final class Bentuk {
  /// 16 dp: ubin ikon persegi.
  static const double ikon = 16;

  /// 22 dp: kapsul grafik, segmen, saringan, toast.
  static const double kapsul = 22;

  /// 28 dp: panel putih, ubin kecil, dialog.
  static const double panel = 28;

  /// 32 dp: ubin besar, sudut atas lembar bawah.
  static const double ubin = 32;

  /// 36 dp: dock navigasi.
  static const double dock = 36;

  /// Pil penuh: tombol, stempel, kolom cari, avatar, lencana angka.
  static const double pil = 999;

  /// 15 dp: stempel status (pil setinggi 30). Dipakai komponen `Stempel` mulai
  /// paket komponen (P2); sampai itu `Stempel` masih memakai [kecil].
  static const double stempel = 15;

  // ── Nama lama (arah "Jejak"), dipertahankan agar widget yang ada tetap
  //    memakai token yang sama tanpa diubah. Hapus di paket bersih-bersih. ──

  /// 4 dp: tik, penanda kecil, tooltip, balok kerangka, dan (sementara)
  /// stempel. TIDAK ikut berubah: Bento Lab tidak punya padanan, dan tik
  /// jejak tidak boleh menjadi pil.
  static const double kecil = 4;

  /// Alias [ikon] (dulu 10): isian, ubin ikon, latar logo, area ketuk bilah.
  static const double kontrol = ikon;

  /// Alias [panel] (dulu 16): panel dan banner.
  static const double kartu = panel;

  /// Alias [pil] (dulu 16): tombol utama.
  static const double utama = pil;

  /// Alias [panel] (dulu 20): dialog. Lembar bawah memakai [ubin].
  static const double lembar = panel;

  static final BorderRadius sudutIkon = BorderRadius.circular(ikon);
  static final BorderRadius sudutKapsul = BorderRadius.circular(kapsul);
  static final BorderRadius sudutPanel = BorderRadius.circular(panel);
  static final BorderRadius sudutUbin = BorderRadius.circular(ubin);
  static final BorderRadius sudutDock = BorderRadius.circular(dock);
  static final BorderRadius sudutStempel = BorderRadius.circular(stempel);

  static final BorderRadius sudutKecil = BorderRadius.circular(kecil);
  static final BorderRadius sudutKontrol = BorderRadius.circular(kontrol);
  static final BorderRadius sudutUtama = BorderRadius.circular(utama);
  static final BorderRadius sudutKartu = BorderRadius.circular(kartu);
  static final BorderRadius sudutPil = BorderRadius.circular(pil);
}
