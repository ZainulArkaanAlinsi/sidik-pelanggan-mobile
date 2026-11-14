import 'package:flutter/material.dart';

import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../widgets/kerangka.dart';
import '../../widgets/panel_sidik.dart';

/// Kerangka Beranda saat memuat: bentuknya meniru isi yang akan datang
/// (dateline, kalimat besar dua baris, lalu panel berisi baris angka + tiga
/// garis), bukan kartu kosong. Tetap bisa ditarik (`RefreshIndicator`).
class KerangkaBeranda extends StatelessWidget {
  const KerangkaBeranda({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Memuat',
    liveRegion: true,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Spasi.denganTepiBawah(
        context,
        const EdgeInsets.fromLTRB(Spasi.sisi, Spasi.lg, Spasi.sisi, Spasi.xl),
      ),
      children: const [
        ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BalokKerangka(tinggi: 14, lebar: 180),
              SizedBox(height: Spasi.md),
              BalokKerangka(tinggi: 32, lebar: 280),
              SizedBox(height: Spasi.sm),
              BalokKerangka(tinggi: 32, lebar: 220),
              SizedBox(height: Spasi.bagian),
              BalokKerangka(tinggi: 20, lebar: 140),
              SizedBox(height: Spasi.md),
              PanelSidik(
                anak: [BarisKerangka(), BarisKerangka(), BarisKerangka()],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Satu baris kerangka: kolom angka di kiri, tiga garis di kanan. Taruh di
/// dalam `PanelSidik`; pemanggil membungkusnya dengan `ExcludeSemantics`.
class BarisKerangka extends StatelessWidget {
  const BarisKerangka({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: Spasi.lg, vertical: Spasi.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: UkuranBaris.kolomAngka,
          child: BalokKerangka(tinggi: 40, lebar: 40),
        ),
        SizedBox(width: Spasi.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BalokKerangka(tinggi: 16, lebar: 180),
              SizedBox(height: Spasi.sm),
              BalokKerangka(tinggi: 12, lebar: 140),
              SizedBox(height: Spasi.sm),
              BalokKerangka(tinggi: 12, lebar: 100),
            ],
          ),
        ),
      ],
    ),
  );
}
