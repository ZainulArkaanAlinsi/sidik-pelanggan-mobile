import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'dasar/dasar_ubin.dart';
import 'status_tampil.dart';
import 'tombol_bulat.dart';

/// Ubin menu (dua kolom): judul 16/22 (paling banyak dua baris, lebar paling
/// banyak 100) di atas, penanda tombol bulat 40 navy di kiri bawah, dan di
/// kanan bawah [visual] 100 ATAU tumpukan avatar 40 ([inisial], mis. anggota).
/// Dipakai untuk pintu masuk (Pelacakan paket, Sertifikat, Anggota).
///
/// Tinggi 124 adalah MINIMUM, sudut 16, padding 16; warna dari [nada] (putih
/// netral, atau warna muda status). Seluruh
/// ubin SATU tombol bila [onTap] ada: tombol bulat di dalamnya hanya penanda
/// (`TombolBulat.hiasan`, navy tetap di dua tema), tidak punya semantik atau
/// ketukan sendiri, jadi
/// tombol tidak bersarang. Visual dan avatar murni hiasan dan digambar di
/// BAWAH teks. Pembaca layar menerima [semantik] atau judulnya.
class UbinMenu extends StatelessWidget {
  const UbinMenu({
    super.key,
    required this.judul,
    this.nada = NadaStatus.netral,
    this.visual,
    this.inisial = const [],
    this.onTap,
    this.semantik,
    this.urutan,
  });

  final String judul;
  final NadaStatus nada;
  final Widget? visual;

  /// Inisial avatar yang ditumpuk di kanan bawah (paling banyak [maksAvatar]);
  /// dipakai bila [visual] kosong.
  final List<String> inisial;
  final VoidCallback? onTap;
  final String? semantik;

  /// Urutan masuk layar (35 ms per indeks); null = tanpa animasi masuk.
  final int? urutan;

  /// Avatar yang ditumpuk paling banyak.
  static const int maksAvatar = 3;

  @override
  Widget build(BuildContext context) {
    final (tinta, latar) = StatusTampil.ubinDari(context, nada);
    final t = context.teks;
    final avatar = inisial.take(maksAvatar).toList();
    return DasarUbin(
      latar: latar,
      sudut: Bentuk.sudutPanel,
      tinggiMin: UkuranUbin.menu,
      padding: const EdgeInsets.all(Spasi.lg),
      visual: visual,
      ukuranVisual: UkuranVisual.ubinMenu,
      keluarSamping: UkuranVisual.keluarKecil,
      keluarBawah: UkuranVisual.keluarKecil,
      onTap: onTap,
      semantik: semantik ?? (onTap == null ? null : judul),
      urutan: urutan,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: UkuranUbin.judulMenuMaks,
                ),
                child: Text(
                  judul,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium?.copyWith(color: tinta),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: Spasi.sm),
                child: TombolBulat.hiasan(),
              ),
            ],
          ),
          if (visual == null && avatar.isNotEmpty)
            Positioned(
              right: 0,
              bottom: 0,
              child: _TumpukanAvatar(inisial: avatar),
            ),
        ],
      ),
    );
  }
}

/// Avatar 40 yang saling menumpuk (selisih [Spasi.md] ke kiri), inisial navy di
/// atas putih. Tanpa semantik: nama orangnya ada di tempat lain.
class _TumpukanAvatar extends StatelessWidget {
  const _TumpukanAvatar({required this.inisial});

  final List<String> inisial;

  @override
  Widget build(BuildContext context) {
    final w = context.warna;
    final t = context.teks;
    const geser = UkuranUbin.avatarUbin - Spasi.md;
    return ExcludeSemantics(
      child: SizedBox(
        width: UkuranUbin.avatarUbin + geser * (inisial.length - 1),
        height: UkuranUbin.avatarUbin,
        child: Stack(
          children: [
            for (var i = 0; i < inisial.length; i++)
              Positioned(
                left: geser * i,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: w.kertasUbin,
                    shape: BoxShape.circle,
                    border: Border.all(color: w.tintaUbin),
                  ),
                  child: SizedBox.square(
                    dimension: UkuranUbin.avatarUbin,
                    child: Center(
                      child: Text(
                        inisial[i],
                        style: t.labelLarge?.copyWith(color: w.tintaUbin),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
