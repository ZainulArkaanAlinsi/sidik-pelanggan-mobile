import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/tema/bentuk.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../widgets/dasar/kontrol_ketuk.dart';
import '../../widgets/status_tampil.dart';

/// Satu kolom pada [KapsulJatuhTempo]: label yang tampil, jumlah alat, dan
/// nada warna isinya (lewat jadwal koral, segera kuning, 31–60 hari langit,
/// 61–90 hari hijau: KOMPONEN.md §Grafik). [semantik] = nama lengkap untuk
/// pembaca layar bila label di layar sengaja pendek ("≤ 30 hari" dibaca
/// "Dalam 30 hari").
@immutable
class ZonaKapsul {
  const ZonaKapsul({
    required this.label,
    required this.jumlah,
    required this.nada,
    this.semantik,
  });

  final String label;
  final int jumlah;
  final NadaStatus nada;
  final String? semantik;
}

/// Isi paling tinggi bila hanya SATU kolom bernilai (88, bukan setinggi rel:
/// angka tetap di dalam kapsul): dua kali isi paling pendek.
const double isiSatuKolomKapsul = UkuranUbin.kapsulMin * 2;

/// Tinggi isi satu kolom (KOMPONEN.md §Grafik): 44 + 80 x (jumlah / terbesar);
/// jumlah 0 = 44; bila hanya satu kolom bernilai > 0 isinya 88. [terbesar]
/// adalah jumlah paling besar di antara semua kolom.
double tinggiIsiKapsul({
  required int jumlah,
  required int terbesar,
  required int kolomBernilai,
}) {
  if (jumlah <= 0 || terbesar <= 0) return UkuranUbin.kapsulMin;
  if (kolomBernilai == 1) return isiSatuKolomKapsul;
  return UkuranUbin.kapsulMin +
      (UkuranUbin.kapsulRel - UkuranUbin.kapsulMin) * jumlah / terbesar;
}

/// Kapsul jatuh tempo Beranda (pengganti `PetaJatuhTempo`): satu rel kapsul
/// per zona, isinya tumbuh dari bawah setinggi jumlahnya, label di bawah rel.
///
/// Tiap kolom satu tombol (area sentuh >= 48 dp lewat [KontrolKetuk]) bila
/// [onZona] ada; pembaca layar menerima "Lewat jadwal: 1 alat". Angka bukan
/// satu-satunya pembawa arti: label selalu kata, warna isi hanya penguat.
/// Kolom yang tidak terbaca TIDAK digambar oleh pemanggil (bukan angka nol).
///
/// [animasi] = isi tumbuh 0 -> tinggi, 240 ms, berurutan 35 ms per kolom,
/// SEKALI saat dibangun; "kurangi gerak" menyalakan keadaan akhir langsung.
/// Teks dijepit [SkalaHuruf.batasBesar] supaya empat kolom muat di 320 dp.
class KapsulJatuhTempo extends StatelessWidget {
  const KapsulJatuhTempo({
    super.key,
    required this.zona,
    this.onZona,
    this.animasi = false,
  });

  final List<ZonaKapsul> zona;
  final ValueChanged<int>? onZona;
  final bool animasi;

  @override
  Widget build(BuildContext context) {
    if (zona.isEmpty) return const SizedBox.shrink();
    final terbesar = zona.map((z) => z.jumlah).reduce(math.max);
    final bernilai = zona.where((z) => z.jumlah > 0).length;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: SkalaHuruf.batasBesar,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, z) in zona.indexed) ...[
            if (i > 0) const SizedBox(width: Spasi.sm),
            Expanded(
              child: _Kolom(
                zona: z,
                indeks: i,
                tinggiIsi: tinggiIsiKapsul(
                  jumlah: z.jumlah,
                  terbesar: terbesar,
                  kolomBernilai: bernilai,
                ),
                animasi: animasi,
                onTap: onZona == null ? null : () => onZona!(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Kolom extends StatelessWidget {
  const _Kolom({
    required this.zona,
    required this.indeks,
    required this.tinggiIsi,
    required this.animasi,
    required this.onTap,
  });

  final ZonaKapsul zona;
  final int indeks;
  final double tinggiIsi;
  final bool animasi;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final t = context.teks;
    final bernilai = zona.jumlah > 0;
    return Semantics(
      container: true,
      child: KontrolKetuk(
        onTap: onTap,
        semantik: '${zona.semantik ?? zona.label}: ${zona.jumlah} alat',
        warna: s.surface,
        sudut: Bentuk.sudutKapsul,
        child: Padding(
          // Bawah: label tidak boleh menyentuh sudut bulat sel.
          padding: const EdgeInsets.only(bottom: Spasi.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Rel(
                zona: zona,
                indeks: indeks,
                tinggiIsi: tinggiIsi,
                animasi: animasi,
              ),
              const SizedBox(height: Spasi.sm),
              Text(
                zona.label,
                textAlign: TextAlign.center,
                style: t.labelMedium?.copyWith(
                  color: bernilai ? s.onSurface : s.onSurfaceVariant,
                  fontWeight: bernilai ? null : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rel extends StatefulWidget {
  const _Rel({
    required this.zona,
    required this.indeks,
    required this.tinggiIsi,
    required this.animasi,
  });

  final ZonaKapsul zona;
  final int indeks;
  final double tinggiIsi;
  final bool animasi;

  @override
  State<_Rel> createState() => _RelState();
}

class _RelState extends State<_Rel> {
  /// Diputuskan SEKALI saat kolom lahir: kolom yang sudah ada tidak berganti
  /// susunan (tidak loncat) bila [KapsulJatuhTempo.animasi] berubah kemudian.
  late final bool _animasi = widget.animasi;

  @override
  Widget build(BuildContext context) {
    final zona = widget.zona;
    final indeks = widget.indeks;
    final tinggiIsi = widget.tinggiIsi;
    final s = context.skema;
    final t = context.teks;
    final (tinta, latarIsi) = StatusTampil.ubinDari(context, zona.nada);
    final bernilai = zona.jumlah > 0;
    final tunda = AppMotion.tunda(context, indeks);
    final isi = AppMotion.hormati(context, AppMotion.sedang);
    final total = tunda + isi;
    final bergerak = _animasi && total > Duration.zero;

    final angka = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '${zona.jumlah}',
        style: (bernilai ? t.displaySmall : t.titleMedium)?.copyWith(
          color: tinta,
        ),
      ),
    );

    Widget isiKolom(double faktor) => ClipRRect(
      borderRadius: Bentuk.sudutKapsul,
      child: SizedBox(
        key: ValueKey<String>('kapsul-isi-$indeks'),
        height: tinggiIsi * faktor,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(color: latarIsi),
          child: bernilai
              ? Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spasi.xs,
                      Spasi.md,
                      Spasi.xs,
                      0,
                    ),
                    child: angka,
                  ),
                )
              : Center(child: angka),
        ),
      ),
    );

    return SizedBox(
      height: UkuranUbin.kapsulRel,
      child: ClipRRect(
        borderRadius: Bentuk.sudutKapsul,
        child: ColoredBox(
          color: s.surfaceContainerHigh,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: bergerak
                ? TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: total,
                    curve: Interval(
                      tunda.inMicroseconds / total.inMicroseconds,
                      1,
                      curve: AppMotion.masuk,
                    ),
                    builder: (_, faktor, _) => isiKolom(faktor),
                  )
                : isiKolom(1),
          ),
        ),
      ),
    );
  }
}
