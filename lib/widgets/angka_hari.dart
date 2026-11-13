import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'status_tampil.dart';

/// Sisa hari menuju jadwal kalibrasi ulang sebagai BINTANG baris: angka besar
/// selebar tetap + kata ("hari lagi", "hari lewat"). Pengganti ikon kalender
/// dan teks "12 hari lagi" kecil di kartu alat.
///
/// Tinta menurut kemendesakan: lewat = `gagal`, 0 sampai [batasAwas] hari =
/// `awas`, selebihnya tinta biasa, belum ada jadwal = tinta kedua. Angka
/// SELALU ditemani kata, jadi warna bukan satu-satunya pembawa arti. Pembaca
/// layar menerima kalimat dari [Format.sisaHari] ("Lewat 4 hari").
///
/// Tiga bentuk: kolom (bawaan; angka 28 di atas kata 12, untuk `awal` baris),
/// [kompak] (satu baris: angka 22 + kata 16, di atas judul pada layar sempit),
/// dan [bintang] (angka 44 + kalimat, satu-satunya pemakai `displayLarge`,
/// untuk kepala detail alat). Angka 28 sp ke atas dijepit
/// [SkalaHuruf.batasBesar] terhadap skala huruf sistem.
class AngkaHari extends StatelessWidget {
  const AngkaHari(
    this.hari, {
    super.key,
    this.kompak = false,
    this.bintang = false,
  });

  /// Hari menuju jadwal; negatif = lewat; `null` = belum ada jadwal.
  final int? hari;

  final bool kompak;
  final bool bintang;

  /// Sampai sekian hari lagi angka berwarna `awas`.
  static const int batasAwas = 30;

  /// Nada tinta untuk [hari]: `gagal` bila lewat, `awas` sampai [batasAwas]
  /// hari, selebihnya `null` (tinta biasa; bukan status).
  static NadaStatus? nadaDari(int? hari) {
    if (hari == null) return null;
    if (hari < 0) return NadaStatus.gagal;
    if (hari <= batasAwas) return NadaStatus.awas;
    return null;
  }

  /// Angka yang ditampilkan ("4" untuk lewat 4 hari; "–" tanpa jadwal).
  static String angkaDari(int? hari) => hari == null ? '–' : '${hari.abs()}';

  /// Kata di bawah/di samping angka.
  static String kataDari(int? hari, {bool panjang = false}) {
    if (hari == null) {
      return panjang ? 'belum ada jadwal kalibrasi ulang' : 'belum ada jadwal';
    }
    if (hari < 0) return panjang ? 'hari lewat dari jadwal' : 'hari lewat';
    if (hari == 0) {
      return panjang ? 'jadwal kalibrasi ulang hari ini' : 'hari ini';
    }
    return panjang ? 'hari lagi sampai jadwal' : 'hari lagi';
  }

  Color _tinta(BuildContext context) {
    final w = context.warna;
    final s = context.skema;
    if (hari == null) return s.onSurfaceVariant;
    return switch (nadaDari(hari)) {
      NadaStatus.gagal => w.gagal,
      NadaStatus.awas => w.awas,
      _ => s.onSurface,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final tinta = _tinta(context);
    final angka = angkaDari(hari);

    final Widget isi;
    if (bintang) {
      isi = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: SkalaHuruf.batasBesar,
            child: Text(angka, style: t.displayLarge?.copyWith(color: tinta)),
          ),
          const SizedBox(width: Spasi.md),
          Expanded(
            child: Text(
              kataDari(hari, panjang: true),
              style: t.titleMedium?.copyWith(color: tinta),
            ),
          ),
        ],
      );
    } else {
      isi = _AngkaKata(
        angka: angka,
        kata: kataDari(hari),
        tinta: tinta,
        kompak: kompak,
      );
    }

    return Semantics(
      label: Format.sisaHari(hari),
      excludeSemantics: true,
      child: isi,
    );
  }
}

/// Angka + kata di kolom awal baris untuk hitungan selain sisa hari (mis. "2
/// alat" pada "Paket siap diambil"). Bentuk dan ukuran sama dengan
/// [AngkaHari] supaya kolom angka di satu panel lurus. Warna dari [nada]
/// (`gagal`, `awas`, `lulus`; lainnya tinta biasa); angka SELALU ditemani
/// [kata]. Pembaca layar menerima [semantik], bawaannya "angka kata".
class AngkaKata extends StatelessWidget {
  const AngkaKata(
    this.angka,
    this.kata, {
    super.key,
    this.nada,
    this.kompak = false,
    this.semantik,
  });

  final String angka;
  final String kata;
  final NadaStatus? nada;
  final bool kompak;
  final String? semantik;

  @override
  Widget build(BuildContext context) {
    final w = context.warna;
    final tinta = switch (nada) {
      NadaStatus.gagal => w.gagal,
      NadaStatus.awas => w.awas,
      NadaStatus.lulus => w.lulus,
      _ => context.skema.onSurface,
    };
    return Semantics(
      label: semantik ?? '$angka $kata',
      excludeSemantics: true,
      child: _AngkaKata(angka: angka, kata: kata, tinta: tinta, kompak: kompak),
    );
  }
}

/// Isi kolom/kompak yang dipakai bersama [AngkaHari] dan [AngkaKata].
class _AngkaKata extends StatelessWidget {
  const _AngkaKata({
    required this.angka,
    required this.kata,
    required this.tinta,
    required this.kompak,
  });

  final String angka;
  final String kata;
  final Color tinta;
  final bool kompak;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    if (kompak) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(angka, style: t.headlineSmall?.tabular.copyWith(color: tinta)),
          const SizedBox(width: Spasi.sm),
          Flexible(
            child: Text(kata, style: t.labelLarge?.copyWith(color: tinta)),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: SkalaHuruf.batasBesar,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              angka,
              style: t.displaySmall?.tabular.copyWith(color: tinta),
            ),
          ),
        ),
        Text(kata, style: t.labelMedium?.copyWith(color: tinta)),
      ],
    );
  }
}
