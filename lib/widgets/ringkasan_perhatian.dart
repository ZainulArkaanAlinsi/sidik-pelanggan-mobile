import 'package:flutter/material.dart';

import 'bagian.dart';
import 'panel_sidik.dart';
import 'tautan_baris.dart';

/// Ringkasan jawaban "Perlu perhatian" di Beranda: judul bagian dengan
/// jumlahnya, satu panel berisi paling banyak [maksimum] butir ([butir], mis.
/// `BarisAlat` lewat jadwal dan jatuh tempo, lalu paket siap diambil), dan
/// tautan "Lihat semua alat (9)". Jawaban turun dari sekitar 450 dp ke sekitar
/// 230 dp dibanding empat ubin KPI.
///
/// Urutan butir ditentukan pemanggil (lewat jadwal terlama dulu, lalu paling
/// dekat jatuh tempo, lalu paket siap diambil). Tanpa butir, bagian ini TIDAK
/// digambar sama sekali: kalimat utama ("Semua alat Anda berlaku.") sudah
/// menjawab, dan judul di atas panel kosong hanya mengganggu. [total] =
/// jumlah sebenarnya di server bila butir sudah dipotong; bawaannya
/// `butir.length`.
class RingkasanPerhatian extends StatelessWidget {
  const RingkasanPerhatian({
    super.key,
    required this.butir,
    this.total,
    this.judul = 'Perlu perhatian',
    this.teksLihatSemua,
    this.onLihatSemua,
    this.semantikLihatSemua,
  });

  final List<Widget> butir;
  final int? total;
  final String judul;

  /// "Lihat semua alat (9)" dan aksinya; keduanya harus diisi agar tampil.
  final String? teksLihatSemua;
  final VoidCallback? onLihatSemua;
  final String? semantikLihatSemua;

  /// Butir paling banyak yang ditampilkan.
  static const int maksimum = 3;

  @override
  Widget build(BuildContext context) {
    if (butir.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Bagian(judul, jumlah: total ?? butir.length),
        PanelSidik(anak: butir.take(maksimum).toList()),
        if (teksLihatSemua != null && onLihatSemua != null)
          TautanBaris(
            teksLihatSemua!,
            onTap: onLihatSemua,
            semantik: semantikLihatSemua,
          ),
      ],
    );
  }
}
