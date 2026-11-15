// Nilai untuk DITEMPEL ke lib/core/tema/palet_sidik.dart (satu-satunya berkas
// yang boleh menulis Color(0x...)). Bukan berkas untuk di-import apa adanya.
import 'package:flutter/painting.dart';

abstract final class PaletBento {
  // Merek
  static const Color navy = Color(0xFF0B1F4B);
  static const Color navyLembut = Color(0xFF2B4380);
  static const Color navyTeks = Color(0xFFC9D3EA);
  static const Color kobaltLogo = Color(0xFF043EA1); // hanya LogoSidik

  // Ubin status (latar). Tinta di atasnya selalu navy.
  static const Color koral = Color(0xFFF2957A); // gagal / lewat jadwal
  static const Color kuning = Color(0xFFF6D36B); // awas + aksen
  static const Color hijau = Color(0xFFCBE7B8); // lulus / berlaku
  static const Color langit = Color(0xFFBCE0F0); // tunggu / info

  // Netral
  static const Color latar = Color(0xFFEEF0F3);
  static const Color kartu = Color(0xFFFFFFFF);
  static const Color teksKedua = Color(0xFF4A5672);
  static const Color garis = Color(0xFFD5DAE3);
}

// ColorScheme terang (tema_sidik.dart):
//   primary: navy, onPrimary: kartu, secondary: kuning, onSecondary: navy,
//   surface: kartu, onSurface: navy, onSurfaceVariant: teksKedua,
//   surfaceContainerLowest..Highest: kartu / latar, outlineVariant: garis.
// Scaffold background: latar.
//
// WarnaSidik.terang:
//   lulus: navy, lulusLatar: hijau, awas: navy, awasLatar: kuning,
//   gagal: navy, gagalLatar: koral, tunggu: navy, tungguLatar: langit.
