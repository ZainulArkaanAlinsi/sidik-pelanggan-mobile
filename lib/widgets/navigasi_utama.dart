import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/warna_sidik.dart';
import 'logo_sidik.dart';

/// Satu tujuan di navigasi utama: ikon (dan ikon terpilih), label satu baris,
/// tooltip, dan angka lencana opsional (mis. notifikasi belum dibaca).
@immutable
class TujuanNavigasi {
  const TujuanNavigasi({
    required this.ikon,
    required this.ikonAktif,
    required this.label,
    this.tooltip,
    this.lencana = 0,
  });

  final IconData ikon;
  final IconData ikonAktif;
  final String label;

  /// Tooltip dan label pembaca layar; bawaannya [label].
  final String? tooltip;

  /// Jumlah pada lencana; 0 = tanpa lencana.
  final int lencana;

  Widget _ikon(IconData data) {
    final isi = Icon(data);
    if (lencana <= 0) return isi;
    return Badge(label: Text(lencana > 99 ? '99+' : '$lencana'), child: isi);
  }
}

/// Navigasi utama yang menyesuaikan lebar layar, tanpa dependensi tambahan.
///
/// - Lebar < [Spasi.batasLebar] (HP): isi di atas, [NavigationBar] di bawah.
/// - Lebar >= [Spasi.batasLebar] (tablet): [NavigationRail] di kiri berlogo,
///   isi di sebelah kanan (isinya sendiri dipusatkan dan dibatasi lebarnya
///   oleh `HalamanSidik`).
///
/// [penutup] = widget di dasar area isi (banner pembaruan). Label navigasi
/// bawah tidak ikut membesar melebihi 1,0× supaya tetap satu baris di layar
/// 320 dp dengan lima tujuan; ikon dan tooltip menjaga keterbacaannya.
class NavigasiUtama extends StatelessWidget {
  const NavigasiUtama({
    super.key,
    required this.indeks,
    required this.onPilih,
    required this.tujuan,
    required this.isi,
    this.penutup,
  });

  final int indeks;
  final ValueChanged<int> onPilih;
  final List<TujuanNavigasi> tujuan;
  final Widget isi;
  final Widget? penutup;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, batas) {
        if (batas.maxWidth >= Spasi.batasLebar) return _rel(context);
        return _bawah(context);
      },
    );
  }

  Widget _bawah(BuildContext context) {
    final garis = context.skema.outlineVariant;
    return Column(
      children: [
        Expanded(
          // Tepi bawah sistem sudah dipakai NavigationBar di bawah: isi tab
          // tidak boleh menambahkannya lagi.
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: isi,
          ),
        ),
        ?penutup,
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: garis)),
          ),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1,
            child: NavigationBar(
              selectedIndex: indeks,
              onDestinationSelected: onPilih,
              destinations: [
                for (final t in tujuan)
                  NavigationDestination(
                    icon: t._ikon(t.ikon),
                    selectedIcon: t._ikon(t.ikonAktif),
                    label: t.label,
                    tooltip: t.tooltip ?? t.label,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _rel(BuildContext context) {
    final garis = context.skema.outlineVariant;
    return Row(
      children: [
        SafeArea(
          right: false,
          child: NavigationRail(
            selectedIndex: indeks,
            onDestinationSelected: onPilih,
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: Spasi.lg),
              child: LogoSidik(tinggi: 56),
            ),
            destinations: [
              for (final t in tujuan)
                NavigationRailDestination(
                  icon: Tooltip(
                    message: t.tooltip ?? t.label,
                    child: t._ikon(t.ikon),
                  ),
                  selectedIcon: Tooltip(
                    message: t.tooltip ?? t.label,
                    child: t._ikon(t.ikonAktif),
                  ),
                  label: Text(t.label),
                ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: garis),
        Expanded(
          child: Column(
            children: [
              Expanded(child: isi),
              ?penutup,
            ],
          ),
        ),
      ],
    );
  }
}
