import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import '../providers/tautan_provider.dart';

/// Satu baris "label, nilai" di lembar detail. Nilai kosong tampil "—".
///
/// Di lebar sempit (HP 320 dp, huruf diperbesar) label pindah ke atas nilai,
/// supaya nilai panjang (alamat, nomor sertifikat) tidak terjepit kolom label.
class BarisInfo extends StatelessWidget {
  const BarisInfo(
    this.label,
    this.nilai, {
    super.key,
    this.angka = false,
    this.akhir,
  });

  final String label;
  final String? nilai;

  /// Nilai berupa angka/nomor: digit selebar tetap.
  final bool angka;

  /// Kontrol di ujung kanan baris (tombol salin). Pilihan tata letak mendatar
  /// atau menumpuk memakai lebar SELURUH baris, jadi baris bertombol tetap
  /// sejajar dengan baris tetangganya yang tanpa tombol.
  final Widget? akhir;

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
      (nilai == null || nilai!.isEmpty) ? '\u2014' : nilai!,
      style: gayaNilai,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spasi.xs * 1.5),
      child: LayoutBuilder(
        builder: (context, batas) {
          if (batas.maxWidth < _batasTumpuk) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: t.bodySmall),
                      const SizedBox(height: Spasi.xs / 2),
                      isi,
                    ],
                  ),
                ),
                ?akhir,
              ],
            );
          }
          return Row(
            crossAxisAlignment: akhir == null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _lebarLabel,
                child: Text(label, style: t.bodySmall),
              ),
              Expanded(child: isi),
              ?akhir,
            ],
          );
        },
      ),
    );
  }
}

/// [BarisInfo] dengan tombol salin di kanan (nomor seri, nomor identifikasi,
/// nomor sertifikat): satu ketuk menyalin [nilai] ke papan klip dan memunculkan
/// [konfirmasi] di snackbar. Tombolnya kontrol bersaudara dengan baris (bukan di
/// dalamnya), sasaran sentuh 48 dp, dan hanya ada bila [nilai] terisi: nilai
/// kosong tidak punya apa yang disalin.
class BarisInfoSalin extends StatelessWidget {
  const BarisInfoSalin(
    this.label,
    this.nilai, {
    super.key,
    required this.tooltip,
    required this.konfirmasi,
    this.angka = true,
  });

  final String label;
  final String? nilai;

  /// Nama tombol untuk pembaca layar ("Salin nomor seri").
  final String tooltip;

  /// Teks snackbar sesudah menyalin ("Nomor seri disalin.").
  final String konfirmasi;
  final bool angka;

  @override
  Widget build(BuildContext context) {
    final teks = nilai;
    if (teks == null || teks.isEmpty) return BarisInfo(label, nilai);
    return BarisInfo(
      label,
      teks,
      angka: angka,
      akhir: IconButton(
        tooltip: tooltip,
        icon: const Icon(Icons.copy_outlined, size: UkuranIkon.sedang),
        onPressed: () => salinDenganKonfirmasi(context, teks, konfirmasi),
      ),
    );
  }
}
