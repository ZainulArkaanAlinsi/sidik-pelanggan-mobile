import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/tema/spasi.dart';
import '../core/tema/warna_sidik.dart';
import '../models/paket.dart';
import 'angka_hari.dart';
import 'baris_sidik.dart';
import 'fakta.dart';
import 'jejak_tahap.dart';
import 'status_tampil.dart';

/// Satu alat di daftar dan di Beranda: sisa hari sebagai BINTANG baris
/// ([AngkaHari], memimpin), lalu identitas alat di barisnya masing-masing:
/// nama (judul), merk + model, dan nomor seri berdiri sendiri ("No. seri
/// 2201-0457", digit selebar tetap). Pengganti `KartuAlat`: tanpa chip status
/// (angka dan kata sudah membawa status), tanpa rangkaian "A · B · C", tanpa
/// lokasi (data internal tidak dibutuhkan untuk mengenali alat).
///
/// Bila alat sedang di lab ([garisWaktu] dan [labelTahap] terisi), jejak
/// tahapnya tampil di bawah dengan kata "Di lab: label". Tanpa datanya
/// (server belum mengirim tahap per alat) baris dan jejak tidak digambar.
///
/// Seluruh baris bisa diketuk ([onTap]), dan tanpa [onTap] pun dibaca sebagai
/// satu kalimat; pembaca layar menerima:
/// "Jangka Sorong Digital, Mitutoyo CD-15CPX, nomor seri 2201-0457. Lewat 4
/// hari. Di lab: Sedang dikalibrasi". Taruh di dalam `PanelSidik`.
class BarisAlat extends StatelessWidget {
  const BarisAlat({
    super.key,
    required this.nama,
    this.merk,
    this.model,
    this.serial,
    this.hari,
    this.garisWaktu,
    this.kodeTahap,
    this.labelTahap,
    this.onTap,
  });

  final String nama;
  final String? merk;
  final String? model;
  final String? serial;

  /// Hari menuju jadwal kalibrasi ulang; negatif = lewat; `null` = belum ada.
  final int? hari;

  /// `garis_waktu` yang sama dengan paket, kode tahap alat ini, dan labelnya
  /// (versi pelanggan dari server). Ketiganya untuk alat yang sedang di lab.
  final List<LangkahPaket>? garisWaktu;
  final String? kodeTahap;
  final String? labelTahap;

  final VoidCallback? onTap;

  /// Baris paling banyak untuk nama dan merk.
  static const int _maksBaris = 2;

  /// "Mitutoyo CD-15CPX": merk dan model dipisah spasi, bukan titik tengah.
  String get merkModel => [
    for (final x in [merk, model])
      if (x != null && x.trim().isNotEmpty) x.trim(),
  ].join(' ');

  bool get _diLab =>
      garisWaktu != null &&
      garisWaktu!.isNotEmpty &&
      labelTahap != null &&
      labelTahap!.trim().isNotEmpty;

  String get _semantik {
    final seri = serial?.trim() ?? '';
    final identitas = [
      nama,
      if (merkModel.isNotEmpty) merkModel,
      if (seri.isNotEmpty) 'nomor seri $seri',
    ].join(', ');
    return [
      identitas,
      Format.sisaHari(hari),
      if (_diLab) 'Di lab: $labelTahap',
    ].join('. ');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    return BarisSidik(
      awal: (kompak) => AngkaHari(hari, kompak: kompak),
      judul: nama,
      // Nama dan merk paling banyak dua baris (elipsis di ujung): di 320 dp x
      // huruf 1,3 nama panjang tidak boleh mendorong nomor seri jauh ke
      // bawah. Pembaca layar tetap menerima nama utuh lewat `semantik`.
      maksBarisJudul: _maksBaris,
      // Belum ada jadwal: kolom angka sempit (56 dp) memecah "belum ada
      // jadwal" jadi tiga baris. Baris ini memakai tata letak kompak (satu
      // baris di atas nama); alat berjadwal tetap berkolom angka.
      kompak: hari == null ? true : null,
      semantik: _semantik,
      onTap: onTap,
      baris: [
        if (merkModel.isNotEmpty)
          Text(
            merkModel,
            style: t.bodyMedium,
            maxLines: _maksBaris,
            overflow: TextOverflow.ellipsis,
          ),
        Fakta('No. seri', serial, nomor: true),
        if (_diLab)
          Padding(
            padding: const EdgeInsets.only(top: Spasi.sm),
            child: JejakTahap(
              garisWaktu: garisWaktu!,
              kodeTahap: kodeTahap,
              kata: 'Di lab: ${labelTahap!.trim()}',
              nadaKata: kodeTahap == 'siap_diambil' ? NadaStatus.lulus : null,
            ),
          ),
      ],
    );
  }
}
