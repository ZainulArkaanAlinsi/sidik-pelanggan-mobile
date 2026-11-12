import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/warna_sidik.dart';

/// Satu baris "label, nilai" di lembar detail. Nilai kosong tampil "—".
///
/// Di lebar sempit (HP 320 dp, huruf diperbesar) label pindah ke atas nilai,
/// supaya nilai panjang (alamat, nomor sertifikat) tidak terjepit kolom label.
class BarisInfo extends StatelessWidget {
  const BarisInfo(this.label, this.nilai, {super.key, this.angka = false});

  final String label;
  final String? nilai;

  /// Nilai berupa angka/nomor: digit selebar tetap.
  final bool angka;

  /// Lebar kolom label di tata letak mendatar.
  static const double _lebarLabel = 132;

  /// Di bawah lebar ini tata letak menumpuk.
  static const double _batasTumpuk = 300;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    var gayaNilai = t.bodyMedium!.copyWith(fontWeight: FontWeight.w500);
    if (angka) gayaNilai = gayaNilai.tabular;
    final isi = Text(
      (nilai == null || nilai!.isEmpty) ? '—' : nilai!,
      style: gayaNilai,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spasi.xs * 1.5),
      child: LayoutBuilder(
        builder: (context, batas) {
          if (batas.maxWidth < _batasTumpuk) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.bodySmall),
                const SizedBox(height: Spasi.xs / 2),
                isi,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _lebarLabel,
                child: Text(label, style: t.bodySmall),
              ),
              Expanded(child: isi),
            ],
          );
        },
      ),
    );
  }
}
