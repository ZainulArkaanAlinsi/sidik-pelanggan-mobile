import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'angka_hari.dart';
import 'dasar/dasar_ubin.dart';
import 'status_tampil.dart';
import 'stempel.dart';

/// Ubin alat Bento Lab: satu alat, satu ubin berwarna menurut statusnya (gagal
/// koral, awas kuning, lulus hijau, tunggu langit, tanpa jadwal putih).
/// Pengganti `BarisAlat`/`KartuAlat` di Beranda dan daftar alat.
///
/// Isi dari atas: [Stempel] di atas ubin (SELALU tampil: ubinnya sudah berwarna
/// dan stempel menyebut katanya; istilah dari `pemetaan_status.dart`) → [nama]
/// 22/28 (paling banyak dua baris) → [merkTipe] 14 → [serial] 14 `.nomor` di
/// baris sendiri → [lokasi] 14 (paling banyak dua baris; pembeda dua alat
/// sejenis tanpa nomor seri, hanya bila terisi) → (didorong ke bawah) angka sisa
/// hari 44 (Beranda: 64) + kata "hari lewat" / "hari lagi" 12/700 + [tanggal]
/// 12/500. Kata dan angka dari `AngkaHari` (satu sumber istilah dengan seluruh
/// app).
///
/// Tinggi 196 (Beranda 232) adalah MINIMUM: ubin tumbuh bersama huruf. Teks
/// SELALU navy di atas pastel (kontras > 7:1), tidak pernah `teksKedua` (3,3:1
/// di atas koral). [visual] (gambar alat, 160; Beranda 176; 120 di lebar < 340)
/// duduk di kanan bawah, keluar 10 dari kanan dan 20 dari bawah, dipotong
/// sudut ubin, di BAWAH teks; teks di bawah stempel diberi ruang agar tidak
/// bertumpuk dengannya. Tanpa [visual] ubin polos.
///
/// Seluruh ubin satu tombol bila [onTap] ada. Pembaca layar menerima [semantik]
/// atau, bila kosong, kalimat susunan dari isi ubin.
class UbinAlat extends StatelessWidget {
  const UbinAlat({
    super.key,
    required this.nama,
    required this.status,
    this.merkTipe,
    this.serial,
    this.awalanSerial,
    this.lokasi,
    this.hari,
    this.tanggal,
    this.visual,
    this.beranda = false,
    this.onTap,
    this.semantik,
    this.urutan,
    this.maksBarisNama = 2,
  });

  final String nama;
  final StatusTampil status;
  final String? merkTipe;

  /// Nomor seri apa adanya (tanpa awalan).
  final String? serial;

  /// Awalan yang HANYA tampil di depan [serial] (mis. "SN"); pembaca layar
  /// menerima nomornya saja, supaya tidak terbaca "S N" dua kali.
  final String? awalanSerial;

  /// Lokasi alat. Dua alat sejenis tanpa nomor seri dan berjadwal sama hanya
  /// terbedakan oleh baris ini; kosong atau spasi saja = tidak ada baris.
  final String? lokasi;

  /// Sisa hari menuju jadwal; negatif = lewat; null = belum ada jadwal.
  final int? hari;

  /// Tanggal jadwal yang sudah diformat pemanggil (mis. `Format.tanggal`).
  final String? tanggal;

  /// Gambar alat; digambar persegi sebesar ukuran visual ubin ini.
  final Widget? visual;

  /// Varian Beranda: tinggi 232, angka 64, visual 176.
  final bool beranda;
  final VoidCallback? onTap;
  final String? semantik;

  /// Urutan masuk layar (35 ms per indeks); null = tanpa animasi masuk.
  final int? urutan;
  final int maksBarisNama;

  /// [lokasi] tanpa spasi pinggir; null bila kosong, jadi tidak ada baris dan
  /// tidak ada kata "Lokasi" di kalimat pembaca layar.
  String? get _lokasiTampil {
    final l = lokasi?.trim();
    return l == null || l.isEmpty ? null : l;
  }

  /// Kalimat bawaan untuk pembaca layar, dari isi ubin.
  String get kalimat => [
    nama,
    'Status: ${status.label}',
    if (merkTipe != null && merkTipe!.isNotEmpty) merkTipe!,
    if (serial != null && serial!.isNotEmpty) 'Nomor seri $serial',
    if (_lokasiTampil != null) 'Lokasi $_lokasiTampil',
    Format.sisaHari(hari),
    if (tanggal != null && tanggal!.isNotEmpty) tanggal!,
  ].join('. ');

  @override
  Widget build(BuildContext context) {
    final (tinta, latar) = status.ubin(context);
    final t = context.teks;
    final kompak = MediaQuery.sizeOf(context).width < Spasi.batasKompak;
    final ukuranVisual = kompak
        ? UkuranVisual.alatKompak
        : (beranda ? UkuranVisual.alatBeranda : UkuranVisual.alat);
    // Teks di bawah stempel mundur dari tepi kanan sebesar bagian visual yang
    // ada di dalam ubin, ditambah satu jarak.
    final ruangVisual = visual == null
        ? 0.0
        : ukuranVisual - UkuranVisual.keluarSamping + Spasi.sm;

    final gayaAngka = beranda
        ? TipografiSidik.angkaSorot(teks: tinta)
        : t.displayLarge!.copyWith(color: tinta);
    final gayaKata = t.labelMedium?.copyWith(color: tinta);
    final gayaTanggal = gayaKata?.copyWith(
      fontWeight: TipografiSidik.beratKeterangan,
    );
    final gayaKet = t.bodySmall?.copyWith(color: tinta);

    final atas = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stempel(status, diAtasUbin: true),
        const SizedBox(height: Spasi.md),
        Padding(
          padding: EdgeInsets.only(right: ruangVisual),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nama,
                maxLines: maksBarisNama,
                overflow: TextOverflow.ellipsis,
                style: t.headlineMedium?.copyWith(color: tinta),
              ),
              if (merkTipe != null && merkTipe!.isNotEmpty)
                Text(merkTipe!, style: gayaKet),
              if (serial != null && serial!.isNotEmpty)
                Text(
                  awalanSerial == null || awalanSerial!.isEmpty
                      ? serial!
                      : '$awalanSerial $serial',
                  style: gayaKet?.nomor,
                ),
              if (_lokasiTampil != null)
                Text(
                  _lokasiTampil!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: gayaKet,
                ),
            ],
          ),
        ),
      ],
    );

    final bawah = Padding(
      padding: EdgeInsets.only(right: ruangVisual),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: Spasi.sm,
        children: [
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: SkalaHuruf.batasBesar,
            child: Text(AngkaHari.angkaDari(hari), style: gayaAngka),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AngkaHari.kataDari(hari), style: gayaKata),
              if (tanggal != null && tanggal!.isNotEmpty)
                Text(tanggal!, style: gayaTanggal),
            ],
          ),
        ],
      ),
    );

    return DasarUbin(
      latar: latar,
      sudut: Bentuk.sudutUbin,
      tinggiMin: beranda ? UkuranUbin.alatBeranda : UkuranUbin.alat,
      padding: const EdgeInsets.all(UkuranUbin.paddingAlat),
      visual: visual,
      ukuranVisual: ukuranVisual,
      keluarSamping: UkuranVisual.keluarSamping,
      keluarBawah: UkuranVisual.keluarBawah,
      onTap: onTap,
      semantik: semantik ?? (onTap == null ? null : kalimat),
      urutan: urutan,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [atas, bawah],
      ),
    );
  }
}
