import 'package:flutter/material.dart';

import '../../core/tema/bentuk.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';

/// Lebar area isi mulai mana Beranda dua kolom (lebar area isi, bukan layar:
/// di tablet 840 dp rel navigasi memakan sekitar 80 dp). Dipakai layar dan
/// kerangkanya supaya bentuknya sama.
const double batasDuaKolomBeranda = 680;

/// Jarak kepala layar ke kalimat utama dan kalimat utama ke ubin besar (20).
const double jarakKalimatBeranda = Spasi.lg + Spasi.xs;

/// Kerangka Beranda saat memuat: bentuknya meniru isi yang akan datang
/// (kepala, kalimat dua baris, ubin alat 160, tombol, panel kapsul, dua ubin
/// pasangan, baris bantuan), bukan kartu kosong.
///
/// STATIS: tanpa denyut dan tanpa animasi apa pun (GERAK.md: kerangka tetap,
/// "kurangi gerak" tidak perlu menanganinya). Tetap bisa ditarik
/// (`RefreshIndicator` di pemanggil); pembaca layar menerima satu kabar
/// "Memuat".
class KerangkaBeranda extends StatelessWidget {
  const KerangkaBeranda({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Memuat',
    liveRegion: true,
    child: LayoutBuilder(
      builder: (context, batas) {
        final duaKolom = batas.maxWidth >= batasDuaKolomBeranda;
        const kepala = _KepalaKerangka();
        const kalimat = _KalimatKerangka();
        const ubinAlat = _UbinKerangka(tinggi: UkuranUbin.alatBeranda);
        const tombol = _Balok(
          tinggi: UkuranBaris.tombolUtama,
          sudut: Bentuk.tombol,
          tinggiPenuh: true,
        );
        const panel = _PanelKerangka();
        const pasangan = _PasanganKerangka();
        const bantuan = _Balok(
          tinggi: UkuranKontrol.tombolBulatBesar + 2 * Spasi.md,
          sudut: Bentuk.tombol,
          tinggiPenuh: true,
        );
        const jarak = SizedBox(height: Spasi.antarUbin);
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: Spasi.denganTepiBawah(
            context,
            const EdgeInsets.fromLTRB(
              Spasi.sisi,
              Spasi.lg,
              Spasi.sisi,
              Spasi.xxl,
            ),
          ),
          children: [
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  kepala,
                  const SizedBox(height: jarakKalimatBeranda),
                  kalimat,
                  const SizedBox(height: jarakKalimatBeranda),
                  if (duaKolom)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [ubinAlat, jarak, tombol],
                          ),
                        ),
                        SizedBox(width: Spasi.xl),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [panel, jarak, pasangan],
                          ),
                        ),
                      ],
                    )
                  else ...const [
                    ubinAlat,
                    jarak,
                    tombol,
                    jarak,
                    panel,
                    jarak,
                    pasangan,
                  ],
                  jarak,
                  bantuan,
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// Ubin alat Beranda yang daftar alatnya MASIH dimuat (hitungan server sudah
/// ada, alat yang mendesak belum): bentuknya ubin 160, STATIS, dengan satu
/// kabar "Memuat daftar alat" untuk pembaca layar. Bukan "tidak ada alat".
class UbinAlatMemuat extends StatelessWidget {
  const UbinAlatMemuat({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Memuat daftar alat',
    liveRegion: true,
    excludeSemantics: true,
    child: const _UbinKerangka(tinggi: UkuranUbin.alatBeranda),
  );
}

/// Satu balok kerangka: diam, warna permukaan tinggi tema. [tinggiPenuh] =
/// selebar induk (tombol, baris); lainnya selebar [lebar].
class _Balok extends StatelessWidget {
  const _Balok({
    required this.tinggi,
    this.lebar,
    this.sudut = Bentuk.kecil,
    this.tinggiPenuh = false,
    this.diAtasPutih = false,
  });

  final double tinggi;
  final double? lebar;
  final double sudut;
  final bool tinggiPenuh;

  /// Balok di dalam ubin putih memakai warna latar halaman; di atas halaman
  /// memakai warna yang lebih tegas supaya tetap terlihat.
  final bool diAtasPutih;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    return SizedBox(
      height: tinggi,
      width: tinggiPenuh ? double.infinity : lebar,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: diAtasPutih
              ? s.surfaceContainerHigh
              : s.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(sudut),
        ),
      ),
    );
  }
}

class _KepalaKerangka extends StatelessWidget {
  const _KepalaKerangka();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _Balok(
        tinggi: UkuranUbin.avatar,
        lebar: UkuranUbin.avatar,
        sudut: Bentuk.pil,
      ),
      SizedBox(width: Spasi.md),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Balok(tinggi: Spasi.md, lebar: 72),
          SizedBox(height: Spasi.xs),
          _Balok(tinggi: Spasi.lg, lebar: 120),
        ],
      ),
    ],
  );
}

class _KalimatKerangka extends StatelessWidget {
  const _KalimatKerangka();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Balok(tinggi: Spasi.xl + Spasi.sm, lebar: 280),
      SizedBox(height: Spasi.sm),
      _Balok(tinggi: Spasi.xl + Spasi.sm, lebar: 220),
    ],
  );
}

/// Ubin putih setinggi [tinggi] berisi garis-garis isinya: ubin alat (stempel,
/// nama, merk, angka) atau, bila [ringkas], ubin pasangan (judul, kalimat,
/// tautan).
class _UbinKerangka extends StatelessWidget {
  const _UbinKerangka({required this.tinggi, this.ringkas = false});

  final double tinggi;
  final bool ringkas;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: tinggi,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.skema.surface,
        borderRadius: Bentuk.sudutUbin,
      ),
      child: Padding(
        padding: const EdgeInsets.all(UkuranUbin.paddingAlat),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: ringkas
              ? const [
                  _Balok(tinggi: Spasi.lg, lebar: 112, diAtasPutih: true),
                  SizedBox(height: Spasi.sm),
                  _Balok(tinggi: Spasi.md, lebar: 88, diAtasPutih: true),
                  Spacer(),
                  _Balok(tinggi: Spasi.md, lebar: 72, diAtasPutih: true),
                ]
              : const [
                  _Balok(
                    tinggi: UkuranKontrol.stempel,
                    lebar: 96,
                    sudut: Bentuk.stempel,
                    diAtasPutih: true,
                  ),
                  SizedBox(height: Spasi.md),
                  _Balok(tinggi: Spasi.lg, lebar: 200, diAtasPutih: true),
                  SizedBox(height: Spasi.xs),
                  _Balok(tinggi: Spasi.md, lebar: 140, diAtasPutih: true),
                  Spacer(),
                  _Balok(tinggi: Spasi.xl, lebar: 96, diAtasPutih: true),
                ],
        ),
      ),
    ),
  );
}

/// Panel putih "Jatuh tempo kalibrasi": judul dan empat rel kapsul.
class _PanelKerangka extends StatelessWidget {
  const _PanelKerangka();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.skema.surface,
      borderRadius: Bentuk.sudutPanel,
    ),
    child: Padding(
      padding: const EdgeInsets.all(UkuranUbin.paddingAlat),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Balok(tinggi: Spasi.lg, lebar: 160, diAtasPutih: true),
          const SizedBox(height: Spasi.md),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: Spasi.sm),
                const Expanded(
                  child: _Balok(
                    tinggi: UkuranUbin.kapsulRel,
                    sudut: Bentuk.kapsul,
                    tinggiPenuh: true,
                    diAtasPutih: true,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

/// Dua ubin pasangan (132) berdampingan; di bawah 340 dp bertumpuk.
class _PasanganKerangka extends StatelessWidget {
  const _PasanganKerangka();

  @override
  Widget build(BuildContext context) {
    const satu = Expanded(
      child: _UbinKerangka(tinggi: UkuranUbin.pasangan, ringkas: true),
    );
    if (MediaQuery.sizeOf(context).width < Spasi.batasKompak) {
      return const Column(
        children: [
          _UbinKerangka(tinggi: UkuranUbin.pasangan, ringkas: true),
          SizedBox(height: Spasi.antarUbin),
          _UbinKerangka(tinggi: UkuranUbin.pasangan, ringkas: true),
        ],
      );
    }
    return const Row(
      children: [
        satu,
        SizedBox(width: Spasi.antarUbin),
        satu,
      ],
    );
  }
}
