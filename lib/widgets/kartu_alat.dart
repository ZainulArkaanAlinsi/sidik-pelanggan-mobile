import 'package:flutter/material.dart';

import '../core/format.dart';
import '../models/data_pelanggan.dart';
import 'pemetaan_status.dart';
import 'ubin_alat.dart';

/// Satu alat di daftar "Alat saya": pembungkus tipis `Alat` -> [UbinAlat]
/// (Bento Lab). Hanya dipakai layar daftar alat; namanya dipertahankan supaya
/// layar dan tes yang mencari `KartuAlat` tetap menemukannya.
///
/// Status dari `pemetaan_status.dart` (satu pemetaan; ikon + kata), sisa hari
/// dari hitungan server (`hariKeJatuhTempo`, bukan jam HP), tanggal dari
/// `Format.tanggal`. Alat tanpa jadwal (`jatuhTempo` null) tidak membawa angka
/// hari dan tanggal: ubinnya menyebut "belum ada jadwal". Lokasi dan nomor
/// identifikasi tidak punya tempat di ubin; keduanya tetap ada di detail alat.
///
/// [urutan] = urutan masuk layar (35 ms per indeks); null = tanpa animasi.
class KartuAlat extends StatelessWidget {
  const KartuAlat({
    super.key,
    required this.alat,
    required this.onTap,
    this.urutan,
  });

  final Alat alat;
  final VoidCallback onTap;
  final int? urutan;

  /// "Merk Model" dalam satu baris; null bila keduanya kosong.
  String? get _merkTipe {
    final teks = [
      alat.merk,
      alat.model,
    ].where((x) => x != null && x.isNotEmpty).join(' ');
    return teks.isEmpty ? null : teks;
  }

  @override
  Widget build(BuildContext context) {
    final serial = alat.serial;
    final jatuhTempo = alat.jatuhTempo;
    return UbinAlat(
      nama: alat.nama,
      status: statusAlat(alat.status),
      merkTipe: _merkTipe,
      serial: serial == null || serial.isEmpty ? null : 'SN $serial',
      hari: jatuhTempo == null ? null : alat.hariKeJatuhTempo,
      tanggal: jatuhTempo == null ? null : Format.tanggal(jatuhTempo),
      onTap: onTap,
      urutan: urutan,
    );
  }
}
