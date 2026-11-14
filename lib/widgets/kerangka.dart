import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import 'kartu_sidik.dart';

/// Keadaan memuat: KERANGKA berdenyut, bukan pemutar kosong. [Memuat.new]
/// untuk daftar, [Memuat.detail] untuk layar detail.
class Memuat extends StatelessWidget {
  const Memuat({super.key}) : _detail = false;

  const Memuat.detail({super.key}) : _detail = true;

  final bool _detail;

  @override
  Widget build(BuildContext context) =>
      _detail ? const KerangkaDetail() : const KerangkaDaftar();
}

/// Daftar kartu kerangka. Bentuknya meniru kartu yang akan datang supaya layar
/// tidak melompat waktu data tiba. Denyut mati bila HP meminta animasi
/// dikurangi.
class KerangkaDaftar extends StatelessWidget {
  const KerangkaDaftar({super.key, this.jumlah = 5, this.padding});

  final int jumlah;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Memuat',
    liveRegion: true,
    child: ListView.separated(
      // Tetap bisa ditarik (RefreshIndicator) selama memuat.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding ?? Spasi.daftar(context),
      itemCount: jumlah,
      separatorBuilder: (_, _) => const SizedBox(height: Spasi.md),
      itemBuilder: (_, _) => const KerangkaKartu(),
    ),
  );
}

/// Satu kartu kerangka.
class KerangkaKartu extends StatelessWidget {
  const KerangkaKartu({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: KartuSidik(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BalokKerangka(tinggi: 16, lebar: 180),
          SizedBox(height: Spasi.sm),
          BalokKerangka(tinggi: 12, lebar: 220),
          SizedBox(height: Spasi.md),
          BalokKerangka(tinggi: 24, lebar: 96, pil: true),
        ],
      ),
    ),
  );
}

/// Kerangka layar detail: satu kartu besar berisi baris label dan nilai.
class KerangkaDetail extends StatelessWidget {
  const KerangkaDetail({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Memuat',
    liveRegion: true,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Spasi.daftar(context),
      children: [
        ExcludeSemantics(
          child: KartuSidik(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BalokKerangka(tinggi: 20, lebar: 200),
                const SizedBox(height: Spasi.md),
                const BalokKerangka(tinggi: 28, lebar: 150),
                const SizedBox(height: Spasi.xl),
                for (var i = 0; i < 5; i++) ...const [
                  Row(
                    children: [
                      BalokKerangka(tinggi: 12, lebar: 100),
                      SizedBox(width: Spasi.xl),
                      Expanded(child: BalokKerangka(tinggi: 12)),
                    ],
                  ),
                  SizedBox(height: Spasi.lg),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: Spasi.lg),
        const KerangkaKartu(),
      ],
    ),
  );
}

/// Satu balok abu-abu berdenyut. Sudutnya dari token (`Bentuk.sudutKecil`,
/// atau `Bentuk.sudutPil` bila [pil]), bukan angka radius.
class BalokKerangka extends StatefulWidget {
  const BalokKerangka({
    super.key,
    this.tinggi = 12,
    this.lebar,
    this.pil = false,
  });

  final double tinggi;
  final double? lebar;
  final bool pil;

  @override
  State<BalokKerangka> createState() => _BalokKerangkaState();
}

class _BalokKerangkaState extends State<BalokKerangka>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
    upperBound: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c
        ..stop()
        ..value = 0.8;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        height: widget.tinggi,
        width: widget.lebar,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: widget.pil ? Bentuk.sudutPil : Bentuk.sudutKecil,
        ),
      ),
    );
  }
}
