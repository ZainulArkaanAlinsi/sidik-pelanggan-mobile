import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'dasar/dasar_ubin.dart';
import 'status_tampil.dart';

/// Ubin pasangan Bento Lab (dua kolom, jarak [Spasi.antarUbin]): judul 17/24
/// (paling banyak dua baris) → [kalimat] pendek 14 → (didorong ke bawah)
/// [aksi] "Lihat semua" 12 bergaris bawah. Dipakai untuk ringkasan di Beranda
/// (sertifikat terbaru, paket) dan menggantikan kartu kecil.
///
/// Tinggi 188 adalah MINIMUM dan sudut 28; warna dari [nada] (bawaan netral =
/// permukaan putih tema; kuning, langit, hijau, koral dari status). Teks navy
/// di atas pastel. [visual] 112 di kanan bawah, keluar 10, dipotong sudut
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
    this.aksi,
    this.nada = NadaStatus.netral,
    this.visual,
    this.onTap,
    this.semantik,
    this.urutan,
  });

  final String judul;
  final String? kalimat;

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
