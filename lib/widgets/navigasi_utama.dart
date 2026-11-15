import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/tema/bentuk.dart';
import '../core/tema/elevasi.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'dasar/kontrol_ketuk.dart';
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

  /// [latarLencana] dan [tintaLencana] hanya diisi dock (lencana koral); rel
  /// memakai warna bawaan `Badge`.
  Widget _ikon(IconData data, {Color? latarLencana, Color? tintaLencana}) {
    final isi = Icon(data);
    if (lencana <= 0) return isi;
    return Badge(
      backgroundColor: latarLencana,
      textColor: tintaLencana,
      label: Text(lencana > 99 ? '99+' : '$lencana'),
      child: isi,
    );
  }
}

/// Navigasi utama yang menyesuaikan lebar layar, tanpa dependensi tambahan.
///
/// - Lebar < [Spasi.batasLebar] (HP): isi di atas, [DockNavigasi] navy
///   melayang di bawah (KOMPONEN.md §Dock). Isi berakhir DI ATAS pita dock
///   (16 + 64 + 16 + tepi sistem), jadi tidak ada isi yang tertutup dock.
/// - Lebar >= [Spasi.batasLebar] (tablet): [NavigationRail] di kiri berlogo,
///   isi di sebelah kanan (isinya sendiri dipusatkan dan dibatasi lebarnya
///   oleh `HalamanSidik`).
///
/// [penutup] = widget di dasar area isi (banner pembaruan); di HP ia duduk di
/// atas dock, bukan di bawahnya.
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
    // Tepi bawah sistem dipakai pita dock di bawah: isi tab tidak boleh
    // menambahkannya lagi.
    final tepi = MediaQuery.paddingOf(context).bottom;
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: isi,
          ),
        ),
        ?penutup,
        // Pita dock: 16 di atas, dock 64, lalu 16 + tepi sistem di bawah.
        Padding(
          padding: EdgeInsets.fromLTRB(
            Spasi.sm,
            Spasi.lg,
            Spasi.sm,
            UkuranDock.dariBawah + tepi,
          ),
          child: Center(
            child: DockNavigasi(
              indeks: indeks,
              onPilih: onPilih,
              tujuan: tujuan,
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

/// Susunan dock pada satu lebar layar. Dipilih SEKALI untuk semua tujuan
/// (menurut label terpanjang) supaya jarak antar-butir tidak melompat saat tab
/// berganti.
@immutable
class _Susunan {
  const _Susunan({
    required this.padPil,
    required this.jarakIkon,
    required this.jarakButir,
    required this.label,
  });

  /// Padding mendatar pil aktif, jarak ikon ke label, jarak antar-butir.
  final double padPil;
  final double jarakIkon;
  final double jarakButir;

  /// False = pil aktif hanya ikon (label tidak muat; tetap dibaca pembaca
  /// layar dan tooltip).
  final bool label;

  /// Spesifikasi KOMPONEN.md §Dock: padding 16, ikon-label 8, jarak 4.
  static const normal = _Susunan(
    padPil: Spasi.lg,
    jarakIkon: Spasi.sm,
    jarakButir: Spasi.xs,
    label: true,
  );

  /// Layar sempit (360 dp): padding 12, ikon-label 4, butir berimpit.
  static const rapat = _Susunan(
    padPil: Spasi.md,
    jarakIkon: Spasi.xs,
    jarakButir: 0,
    label: true,
  );

  /// Layar tersempit (320 dp): pil hanya berisi ikon.
  static const ikonSaja = _Susunan(
    padPil: 0,
    jarakIkon: 0,
    jarakButir: Spasi.xs,
    label: false,
  );

  double lebarAktif(double lebarLabel) => label
      ? 2 * padPil + UkuranDock.ikonAktif + jarakIkon + lebarLabel
      : UkuranDock.butir;

  /// Lebar dock bila tujuan aktifnya berlabel selebar [lebarLabel].
  double lebarDock(int jumlah, double lebarLabel) =>
      2 * Spasi.sm +
      (jumlah - 1) * (UkuranDock.butir + jarakButir) +
      lebarAktif(lebarLabel);
}

/// Dock navigasi navy melayang untuk HP (KOMPONEN.md §Dock): tinggi 64, sudut
/// [Bentuk.dock], padding 8, bayangan navy ([Elevasi.dockGeser] dan kawan-kawan).
/// Butir 48 x 48 berikon putih; butir aktif = pil kuning berikon + label.
/// Pil meluncur ke butir baru selama [AppMotion.sedang] ("kurangi gerak" =
/// langsung).
///
/// Tiap butir adalah satu simpul pembaca layar berlabel (`tooltip ?? label`)
/// dengan `selected` benar, area sentuh >= 48 dp, dan tooltip: butir tidak
/// aktif tidak menampilkan label. Label aktif tidak ikut membesar melebihi
/// 1,0x (sama dengan navigasi bawah sebelumnya); bila label terpanjang tidak
/// muat di lebar yang ada, jarak dirapatkan, lalu pil aktif hanya berikon.
///
/// Dock tidak menempatkan dirinya: [NavigasiUtama] memberinya pita (jarak dari
/// tepi sistem) dan batas lebar.
class DockNavigasi extends StatelessWidget {
  const DockNavigasi({
    super.key,
    required this.indeks,
    required this.onPilih,
    required this.tujuan,
  });

  final int indeks;
  final ValueChanged<int> onPilih;
  final List<TujuanNavigasi> tujuan;

  /// Kunci pil kuning, untuk tes.
  @visibleForTesting
  static const Key kunciPil = ValueKey<String>('dock-pil');

  static double _ukurLebar(BuildContext context, String teks, TextStyle gaya) {
    final ukur = TextPainter(
      text: TextSpan(
        text: teks,
        style: DefaultTextStyle.of(context).style.merge(gaya),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final lebar = ukur.width;
    ukur.dispose();
    return lebar;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      indeks >= 0 && indeks < tujuan.length,
      'indeks dock di luar daftar tujuan',
    );
    final w = context.warna;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1,
      child: LayoutBuilder(
        builder: (context, batas) {
          final durasi = AppMotion.hormati(context, AppMotion.sedang);
          final gaya = (context.teks.bodySmall ?? const TextStyle()).copyWith(
            fontWeight: TipografiSidik.beratTebal,
            color: w.tintaUbin,
          );
          final lebarLabel = [
            for (final t in tujuan) _ukurLebar(context, t.label, gaya),
          ];
          final terpanjang = lebarLabel.fold<double>(0, math.max);
          final susunan = [_Susunan.normal, _Susunan.rapat].firstWhere(
            (s) => s.lebarDock(tujuan.length, terpanjang) <= batas.maxWidth,
            orElse: () => _Susunan.ikonSaja,
          );
          final lebarAktif = susunan.lebarAktif(lebarLabel[indeks]);
          return DecoratedBox(
            decoration: BoxDecoration(
              color: w.tintaUbin,
              borderRadius: Bentuk.sudutDock,
              boxShadow: [
                BoxShadow(
                  color: w.tintaUbin.withValues(alpha: Elevasi.dockOpasitas),
                  offset: const Offset(0, Elevasi.dockGeser),
                  blurRadius: Elevasi.dockBlur,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spasi.sm),
              child: Stack(
                // Susunan berganti (lebar layar berubah): bangun ulang tanpa
                // meluncur; lebar butir yang masih menyusut di susunan baru
                // akan membuat baris meluap sesaat.
                key: ValueKey<_Susunan>(susunan),
                children: [
                  AnimatedPositioned(
                    duration: durasi,
                    curve: AppMotion.masuk,
                    left: indeks * (UkuranDock.butir + susunan.jarakButir),
                    top: 0,
                    width: lebarAktif,
                    height: UkuranDock.butir,
                    child: ExcludeSemantics(
                      child: DecoratedBox(
                        key: kunciPil,
                        decoration: BoxDecoration(
                          color: w.ubinAwas,
                          borderRadius: Bentuk.sudutPil,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < tujuan.length; i++) ...[
                        if (i > 0) SizedBox(width: susunan.jarakButir),
                        _ButirDock(
                          tujuan: tujuan[i],
                          terpilih: i == indeks,
                          onTap: () => onPilih(i),
                          susunan: susunan,
                          lebar: i == indeks ? lebarAktif : UkuranDock.butir,
                          durasi: durasi,
                          gaya: gaya,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Satu butir dock: kontrol ketuk Bento ([KontrolKetuk]: semantik tombol,
/// `selected`, area sentuh >= 48 dp, umpan balik tekan, cincin fokus) yang
/// transparan di atas pil kuning, ditambah tooltip.
class _ButirDock extends StatelessWidget {
  const _ButirDock({
    required this.tujuan,
    required this.terpilih,
    required this.onTap,
    required this.susunan,
    required this.lebar,
    required this.durasi,
    required this.gaya,
  });

  final TujuanNavigasi tujuan;
  final bool terpilih;
  final VoidCallback onTap;
  final _Susunan susunan;
  final double lebar;
  final Duration durasi;
  final TextStyle gaya;

  @override
  Widget build(BuildContext context) {
    final w = context.warna;
    final tema = Theme.of(context);
    final nama = tujuan.tooltip ?? tujuan.label;
    final isi = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Warna ikon ikut meluncur bersama pil: putih di atas navy, navy di
        // atas kuning.
        TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: terpilih ? w.tintaUbin : w.kertasUbin),
          duration: durasi,
          builder: (context, warna, _) => IconTheme(
            data: IconThemeData(
              size: terpilih ? UkuranDock.ikonAktif : UkuranDock.ikon,
              color: warna,
            ),
            child: tujuan._ikon(
              terpilih ? tujuan.ikonAktif : tujuan.ikon,
              // Lencana koral dengan angka navy (kontras > 4,5:1).
              latarLencana: w.ubinGagal,
              tintaLencana: w.tintaUbin,
            ),
          ),
        ),
        if (terpilih && susunan.label) ...[
          SizedBox(width: susunan.jarakIkon),
          Text(
            tujuan.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: gaya,
          ),
        ],
      ],
    );
    return Tooltip(
      message: nama,
      preferBelow: false,
      // Pembaca layar sudah menerima `nama` dari KontrolKetuk: tooltip tidak
      // boleh membacakannya dua kali.
      excludeFromSemantics: true,
      child: Theme(
        // Cincin fokus memakai `primary`: navy di atas dock navy tidak
        // terlihat. Putih di atas navy = 15:1, di dua tema.
        data: tema.copyWith(
          colorScheme: tema.colorScheme.copyWith(primary: w.kertasUbin),
        ),
        child: KontrolKetuk(
          onTap: onTap,
          semantik: nama,
          terpilih: terpilih,
          warna: Colors.transparent,
          sudut: Bentuk.sudutPil,
          child: AnimatedContainer(
            duration: durasi,
            curve: AppMotion.masuk,
            width: lebar,
            height: UkuranDock.butir,
            child: ClipRect(
              child: OverflowBox(
                minWidth: 0,
                maxWidth: double.infinity,
                child: isi,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
