import 'package:flutter/material.dart';

import 'status_tampil.dart';
import 'stempel.dart';

/// Lencana status di layar detail (alat, paket, sertifikat, anggota): ikon +
/// kata pada latar tipis nadanya, TANPA bentuk sendiri.
///
/// Sejak R1b ini hanya nama lama dari [Stempel], lencana bersama (tinggi 24,
/// sudut 6, ikon 14, kata 12/600): satu bentuk lencana di seluruh aplikasi,
/// jadi status yang sama tidak tampil beda di daftar dan di detail. Dulu pil
/// (sudut 999) berikon 16. Nama dan bentuk panggilannya tetap supaya pemakai
/// lama tidak berubah; kode baru memakai [Stempel] langsung.
///
/// Tidak diketuk (bukan tombol). Kata panjang membungkus dan lencana tumbuh ke
/// bawah (dulu dipotong elipsis: kata status tidak boleh hilang di layar
/// sempit atau huruf besar); pembaca layar menerima "Status: kata".
class ChipStatus extends StatelessWidget {
  const ChipStatus(this.status, {super.key});

  final StatusTampil status;

  @override
  Widget build(BuildContext context) => Stempel(status);
}
