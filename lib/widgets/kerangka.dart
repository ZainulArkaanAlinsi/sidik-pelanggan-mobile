import 'package:flutter/material.dart';

import '../core/theme/sidik_material.dart';
import 'sidik/sidik_permukaan.dart';

/// Kerangka muat (04-UI-UX §1.2: "memuat = skeleton, bukan spinner kosong").
///
/// Bentuknya meniru kartu yang akan datang — judul, satu baris keterangan,
/// satu baris status — supaya layar tidak "melompat" waktu data tiba. Denyut
/// pelan; mati kalau HP meminta animasi dikurangi.
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
      padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: jumlah,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const KerangkaKartu(),
    ),
  );
}

/// Satu kartu kerangka.
class KerangkaKartu extends StatelessWidget {
  const KerangkaKartu({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: Kertas(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: BalokKerangka(tinggi: 16, lebar: 180)),
              SizedBox(width: 12),
              BalokKerangka(tinggi: 22, lebar: 88, radius: 11),
            ],
          ),
          SizedBox(height: 10),
          BalokKerangka(tinggi: 12, lebar: 220),
          SizedBox(height: 10),
          BalokKerangka(tinggi: 12, lebar: 140),
        ],
      ),
    ),
  );
}

/// Kerangka layar detail: satu lembar besar berisi baris label–nilai.
class KerangkaDetail extends StatelessWidget {
  const KerangkaDetail({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Memuat',
    liveRegion: true,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        ExcludeSemantics(
          child: Kertas(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BalokKerangka(tinggi: 20, lebar: 200),
                const SizedBox(height: 12),
                const BalokKerangka(tinggi: 28, lebar: 150),
                const SizedBox(height: 20),
                for (var i = 0; i < 5; i++) ...const [
                  Row(
                    children: [
                      BalokKerangka(tinggi: 12, lebar: 100),
                      SizedBox(width: 24),
                      Expanded(child: BalokKerangka(tinggi: 12)),
                    ],
                  ),
                  SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const KerangkaKartu(),
        const SizedBox(height: 10),
        const KerangkaKartu(),
      ],
    ),
  );
}

/// Satu balok abu-abu berdenyut.
class BalokKerangka extends StatefulWidget {
  const BalokKerangka({super.key, this.tinggi = 12, this.lebar, this.radius});

  final double tinggi;
  final double? lebar;
  final double? radius;

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
    if (MediaQuery.of(context).disableAnimations) {
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
    final m = SidikMaterial.of(context);
    return FadeTransition(
      opacity: _c,
      child: Container(
        height: widget.tinggi,
        width: widget.lebar,
        decoration: BoxDecoration(
          color: m.kertas2,
          borderRadius: BorderRadius.circular(widget.radius ?? 4),
        ),
      ),
    );
  }
}
