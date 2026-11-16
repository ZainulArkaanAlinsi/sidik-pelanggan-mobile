import 'package:flutter/widgets.dart';

/// Token sudut (radius), arah tenang-formal (REVISI 16 Nov 2026): kartu 12-16,
/// tombol dan isian 8-12, tidak ada sudut ekstrem kecuali lingkaran sungguhan
/// (avatar, titik, lencana angka). Nilai dari `docs/desain-ulang/tokens.json`.
///
/// | Token    | dp  | Pakai                                              |
/// |----------|-----|----------------------------------------------------|
/// | `stempel`| 6   | lencana status kecil                               |
/// | `tombol` | 10  | tombol, kolom cari, segmen                         |
/// | `ikon`   | 12  | ubin ikon persegi, isian                           |
/// | `kapsul` | 12  | saringan, sel segmen, toast                        |
/// | `panel`  | 16  | kartu, panel putih, dialog                         |
/// | `ubin`   | 16  | ubin ringkasan, sudut atas lembar bawah            |
/// | `penanda`| 8   | penanda pilihan di dalam segmen                    |
/// | `pil`    | 999 | lingkaran: avatar, titik, lencana angka            |
abstract final class Bentuk {
  /// 12 dp: ubin ikon persegi, isian.
  static const double ikon = 12;

  /// 10 dp: tombol, kolom cari, segmen.
  static const double tombol = 10;

  /// 12 dp: saringan, sel segmen, toast.
  static const double kapsul = 12;

  /// 16 dp: kartu, panel putih, dialog.
  static const double panel = 16;

  /// 16 dp: ubin ringkasan, sudut atas lembar bawah.
  static const double ubin = 16;

  /// 8 dp: penanda pilihan di dalam wadah segmen (sudut wadah [kapsul] 12
  /// dikurangi padding 4, supaya konsentris).
  static const double penanda = 8;

  /// Pil penuh: HANYA untuk lingkaran sungguhan (avatar, titik, lencana angka,
  /// tombol bulat). Tombol dan kolom cari memakai [tombol].
  static const double pil = 999;

  /// 6 dp: lencana status kecil (tinggi 24).
  static const double stempel = 6;

  // ── Nama lama, dipertahankan agar widget yang ada tetap memakai token yang
  //    sama tanpa diubah. Hapus di paket bersih-bersih. ──

  /// 4 dp: tik, penanda kecil, tooltip, balok kerangka.
  static const double kecil = 4;

  /// Alias [ikon]: isian, ubin ikon, latar logo, area ketuk bilah.
  static const double kontrol = ikon;

  /// Alias [panel]: panel dan banner.
  static const double kartu = panel;

  /// Alias [tombol] (dulu pil): tombol utama.
  static const double utama = tombol;

  /// Alias [panel]: dialog. Lembar bawah memakai [ubin].
  static const double lembar = panel;

  static final BorderRadius sudutIkon = BorderRadius.circular(ikon);
  static final BorderRadius sudutTombol = BorderRadius.circular(tombol);
  static final BorderRadius sudutKapsul = BorderRadius.circular(kapsul);
  static final BorderRadius sudutPanel = BorderRadius.circular(panel);
  static final BorderRadius sudutUbin = BorderRadius.circular(ubin);
  static final BorderRadius sudutPenanda = BorderRadius.circular(penanda);
  static final BorderRadius sudutStempel = BorderRadius.circular(stempel);

  static final BorderRadius sudutKecil = BorderRadius.circular(kecil);
  static final BorderRadius sudutKontrol = BorderRadius.circular(kontrol);
  static final BorderRadius sudutUtama = BorderRadius.circular(utama);
  static final BorderRadius sudutKartu = BorderRadius.circular(kartu);
  static final BorderRadius sudutPil = BorderRadius.circular(pil);
}
