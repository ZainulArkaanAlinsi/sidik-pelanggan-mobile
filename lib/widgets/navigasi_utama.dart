import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/elevasi.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'dasar/cincin_fokus.dart';
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

  /// Teks lencana: angka, atau "99+" di atas 99.
  String get _teksLencana => lencana > 99 ? '99+' : '$lencana';

  /// Ikon untuk rel, lencana bawaan `Badge` di sudutnya. Bilah menggambar
  /// lencananya sendiri (merah galat) di [_ButirBilah].
  Widget _ikon(IconData data) {
    final isi = Icon(data);
    if (lencana <= 0) return isi;
    return Badge(label: Text(_teksLencana), child: isi);
  }
}

/// Navigasi utama yang menyesuaikan lebar layar, tanpa dependensi tambahan.
///
/// - Lebar < [Spasi.batasLebar] (HP): isi di atas, [BilahNavigasi] solid di
///   bawah (REVISI-2 butir 13): permukaan putih selebar layar, garis tipis di
///   atasnya, SEMUA menu berlabel, indikator aktif biru muda. Isi berakhir DI
///   ATAS bilah (dan di atas [penutup]), jadi tidak ada isi yang tertutup.
/// - Lebar >= [Spasi.batasLebar] (tablet): [NavigationRail] di kiri berlogo,
///   isi di sebelah kanan (isinya sendiri dipusatkan dan dibatasi lebarnya
///   oleh `HalamanSidik`).
///
/// [penutup] = widget di dasar area isi (banner pembaruan); di HP ia duduk di
/// atas bilah, bukan di bawahnya.
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
    return Column(
      children: [
        Expanded(
          // Tepi bawah sistem dipakai bilah di bawah (di dalam permukaannya):
          // isi tab tidak boleh menambahkannya lagi.
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: isi,
          ),
        ),
        ?penutup,
        BilahNavigasi(indeks: indeks, onPilih: onPilih, tujuan: tujuan),
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

/// Bilah navigasi bawah solid untuk HP (REVISI-2 butir 13): permukaan putih
/// selebar layar dengan garis [Elevasi.garis] di atasnya (tanpa bayangan),
/// SEMUA tujuan berlabel (ikon 24 + satu baris kata 12), butir aktif ditandai
/// indikator biru muda 56 x 32 di belakang ikon, ikon terisi, dan kata
/// semibold navy; butir lain ikon garis dan kata medium berwarna teks kedua.
/// Aktif tidak hanya dibedakan warna: bentuk ikon, berat huruf, dan indikator
/// ikut berubah.
///
/// Tinggi isi minimal [UkuranBilah.tinggi] (64) ditambah tepi sistem (gesture
/// bar) di bawah, di dalam permukaan yang sama. Lima butir sama lebar; label
/// mengikuti huruf sistem sampai [UkuranBilah.skalaLabel] (1,3x), lalu SEMUA
/// label mengecil bersama (satu faktor, ukuran sama di tiap butir) sampai kata
/// terpanjang muat di selnya, jadi tidak pernah terpotong di 320 dp. Butir
/// tertinggi boleh tumbuh; semua butir sama tinggi.
///
/// Tiap butir adalah SATU simpul pembaca layar berlabel (`tooltip ?? label`)
/// dengan `selected` benar dan petunjuk posisi ("Tab 2 dari 5", dari
/// lokalisasi Material, sama dengan `NavigationBar`). Seluruh butir
/// (selebar sepertiga layar, setinggi bilah) menerima ketukan, jadi area sentuh
/// jauh di atas 48 dp. Papan ketik: Tab berpindah butir, Enter/Spasi memilih,
/// cincin fokus muncul. Lencana jumlah (notifikasi) merah galat berangka putih,
/// "99+" di atas 99, keluar dari pembaca layar (hitungannya sudah ada di label).
///
/// Bilah tidak menempatkan dirinya: [NavigasiUtama] meletakkannya di dasar
/// kolom, di bawah banner pembaruan.
class BilahNavigasi extends StatelessWidget {
  const BilahNavigasi({
    super.key,
    required this.indeks,
    required this.onPilih,
    required this.tujuan,
  });

  final int indeks;
  final ValueChanged<int> onPilih;
  final List<TujuanNavigasi> tujuan;

  /// Skala huruf label yang dipakai SEMUA butir pada lebar bilah [lebar]:
  /// huruf sistem (sudah dijepit [UkuranBilah.skalaLabel] oleh pemanggil)
  /// dikali faktor <= 1 supaya kata terpanjang (dalam berat terpilih, yang
  /// terlebar) muat di sel selebar lebar / jumlah dikurangi jarak kiri-kanan.
  double _skalaLabel(BuildContext context, double lebar) {
    final dasar = (context.teks.labelMedium ?? const TextStyle()).copyWith(
      fontWeight: TipografiSidik.beratLencana,
    );
    final ukuran = dasar.fontSize ?? 12;
    final sistem = MediaQuery.textScalerOf(context).scale(ukuran) / ukuran;
    var terlebar = 0.0;
    for (final t in tujuan) {
      final ukur = TextPainter(
        text: TextSpan(text: t.label, style: dasar),
        textDirection: Directionality.of(context),
        textScaler: TextScaler.linear(sistem),
        maxLines: 1,
      )..layout();
      terlebar = math.max(terlebar, ukur.width);
      ukur.dispose();
    }
    // Jarak kiri-kanan tiap kata hanya Spasi.xs / 2: di 320 dp kata terpanjang
    // masih tetap >= 12 sp efektif.
    final muat = lebar / tujuan.length - Spasi.xs;
    final faktor = terlebar <= muat || terlebar == 0 ? 1.0 : muat / terlebar;
    return sistem * faktor;
  }

  /// Kunci indikator biru muda butir aktif, untuk tes.
  @visibleForTesting
  static const Key kunciIndikator = ValueKey<String>('bilah-indikator');

  @override
  Widget build(BuildContext context) {
    assert(
      indeks >= 0 && indeks < tujuan.length,
      'indeks bilah di luar daftar tujuan',
    );
    final s = context.skema;
    final tepi = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: s.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: s.outlineVariant, width: Elevasi.garis),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: tepi),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: UkuranBilah.skalaLabel,
            // LayoutBuilder DI LUAR IntrinsicHeight (ia tidak bisa menjawab
            // ukuran intrinsik).
            child: LayoutBuilder(
              builder: (context, batas) {
                final skala = _skalaLabel(context, batas.maxWidth);
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < tujuan.length; i++)
                        Expanded(
                          child: _ButirBilah(
                            tujuan: tujuan[i],
                            posisi: i,
                            jumlah: tujuan.length,
                            terpilih: i == indeks,
                            skalaLabel: skala,
                            onTap: () => onPilih(i),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu butir bilah: ikon di atas indikator, kata di bawahnya. Lihat
/// [BilahNavigasi] untuk semantik dan ukuran.
class _ButirBilah extends StatelessWidget {
  const _ButirBilah({
    required this.tujuan,
    required this.posisi,
    required this.jumlah,
    required this.terpilih,
    required this.skalaLabel,
    required this.onTap,
  });

  final TujuanNavigasi tujuan;

  /// Urutan butir (mulai 0) dan jumlah butir, untuk petunjuk "Tab n dari m".
  final int posisi;
  final int jumlah;
  final bool terpilih;

  /// Skala huruf label (sama untuk semua butir): huruf sistem (dijepit 1,3x)
  /// dikali faktor pengecil bila kata terpanjang tidak muat.
  final double skalaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final nama = tujuan.tooltip ?? tujuan.label;
    final warnaIkon = terpilih ? s.onPrimaryContainer : s.onSurfaceVariant;
    final gayaLabel = context.teks.labelMedium?.copyWith(
      color: terpilih ? s.onSurface : s.onSurfaceVariant,
      fontWeight: terpilih
          ? TipografiSidik.beratLencana
          : TipografiSidik.beratLabel,
    );

    Widget ikon = Icon(
      terpilih ? tujuan.ikonAktif : tujuan.ikon,
      size: UkuranBilah.ikon,
      color: warnaIkon,
    );
    if (tujuan.lencana > 0) {
      ikon = ExcludeSemantics(
        child: Badge(
          backgroundColor: s.error,
          textColor: s.onError,
          label: Text(tujuan._teksLencana),
          child: ikon,
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: true,
      selected: terpilih,
      label: nama,
      // Petunjuk posisi menyatu ke simpul butir (bukan simpul tambahan),
      // dibacakan setelah label; teksnya dari lokalisasi Material ("Tab 2 dari
      // 5"), sama dengan `NavigationBar`.
      hint: MaterialLocalizations.of(
        context,
      ).tabLabel(tabIndex: posisi + 1, tabCount: jumlah),
      onTap: onTap,
      excludeSemantics: true,
      // Tooltip (tekan lama) memuat nama lengkap, termasuk jumlah belum dibaca;
      // pembaca layar sudah menerimanya dari simpul butir, jadi tidak dobel.
      child: Tooltip(
        message: nama,
        preferBelow: false,
        excludeFromSemantics: true,
        child: CincinFokus(
          sudut: Bentuk.sudutKapsul,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: UkuranBilah.tinggi),
              child: Padding(
                // Tanpa jarak kiri-kanan: kata sudah dimuatkan ke sel dengan
                // sisa Spasi.xs (lihat `_skalaLabel`).
                padding: const EdgeInsets.only(top: Spasi.sm, bottom: Spasi.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: UkuranBilah.indikatorLebar,
                      height: UkuranBilah.indikatorTinggi,
                      child: DecoratedBox(
                        key: terpilih ? BilahNavigasi.kunciIndikator : null,
                        decoration: BoxDecoration(
                          color: terpilih
                              ? s.primaryContainer
                              : Colors.transparent,
                          borderRadius: Bentuk.sudutPil,
                        ),
                        child: Center(child: ikon),
                      ),
                    ),
                    const SizedBox(height: Spasi.xs),
                    Text(
                      tujuan.label,
                      maxLines: 1,
                      softWrap: false,
                      textScaler: TextScaler.linear(skalaLabel),
                      style: gayaLabel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
