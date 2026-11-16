import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'dasar/dasar_ubin.dart';
import 'status_tampil.dart';
import 'stempel.dart';

/// Ubin pasangan (dua kolom, jarak [Spasi.antarUbin]): judul 16/22 (paling
/// banyak dua baris) → [kalimat] pendek 13 → (didorong ke bawah) [aksi]
/// "Lihat semua" 12 bergaris bawah. Dipakai untuk ringkasan di Beranda
/// (sertifikat terbaru, paket) dan menggantikan kartu kecil.
///
/// Tinggi 132 adalah MINIMUM dan sudut 16; warna dari [nada] (bawaan netral =
/// permukaan putih tema; krem, biru kelabu, hijau muda, merah muda dari
/// status). Teks navy di atas warna muda. [visual] 112 di kanan bawah, keluar
/// 10, dipotong sudut
/// ubin, di BAWAH teks: teks tidak pernah ditutupinya. Di lebar < 340 dp
/// pemasang menaruhnya satu kolom (`Spasi.batasKompak`).
///
/// [aksi] bukan tombol sendiri: seluruh ubin satu tombol (bila [onTap] ada),
/// jadi tombol tidak bersarang. Pembaca layar menerima [semantik] atau
/// kalimat "judul. kalimat. aksi".
class UbinRingkas extends StatelessWidget {
  const UbinRingkas({
    super.key,
    required this.judul,
    this.kalimat,
    this.stempel = const [],
    this.aksi,
    this.nada = NadaStatus.netral,
    this.visual,
    this.onTap,
    this.semantik,
    this.urutan,
  });

  final String judul;
  final String? kalimat;

  /// Pengecualian yang harus bersuara (mis. "Tidak memenuhi toleransi"): satu
  /// [Stempel] (ikon + kata, istilah dari `pemetaan_status.dart`) per status,
  /// di bawah [kalimat]. Kosong = tanpa stempel. Status tidak pernah hanya
  /// warna ubin: katanya selalu ikut tertulis.
  final List<StatusTampil> stempel;

  /// Teks tautan di bawah, mis. "Lihat semua". Null = tanpa tautan.
  final String? aksi;
  final NadaStatus nada;
  final Widget? visual;
  final VoidCallback? onTap;
  final String? semantik;

  /// Urutan masuk layar (35 ms per indeks); null = tanpa animasi masuk.
  final int? urutan;

  String get _kalimat => [
    judul,
    if (kalimat != null && kalimat!.isNotEmpty) kalimat!,
    for (final s in stempel) 'Status: ${s.label}',
    if (aksi != null && aksi!.isNotEmpty) aksi!,
  ].join('. ');

  @override
  Widget build(BuildContext context) {
    final (tinta, latar) = StatusTampil.ubinDari(context, nada);
    final t = context.teks;
    return DasarUbin(
      latar: latar,
      sudut: Bentuk.sudutPanel,
      tinggiMin: UkuranUbin.pasangan,
      padding: const EdgeInsets.all(Spasi.lg),
      visual: visual,
      ukuranVisual: UkuranVisual.ubinKecil,
      keluarSamping: UkuranVisual.keluarKecil,
      keluarBawah: UkuranVisual.keluarKecil,
      onTap: onTap,
      semantik: semantik ?? (onTap == null ? null : _kalimat),
      urutan: urutan,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.titleMedium?.copyWith(color: tinta),
              ),
              if (kalimat != null && kalimat!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Spasi.xs),
                  child: Text(
                    kalimat!,
                    style: t.bodySmall?.copyWith(color: tinta),
                  ),
                ),
              if (stempel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Spasi.sm),
                  child: Wrap(
                    spacing: Spasi.sm,
                    runSpacing: Spasi.xs,
                    children: [
                      for (final s in stempel) Stempel(s, diAtasUbin: true),
                    ],
                  ),
                ),
            ],
          ),
          if (aksi != null && aksi!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Spasi.sm),
              child: Text(
                aksi!,
                style: t.labelMedium?.copyWith(
                  color: tinta,
                  decoration: TextDecoration.underline,
                  decorationColor: tinta,
                  fontWeight: TipografiSidik.beratTebal,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
