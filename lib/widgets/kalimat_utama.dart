import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'status_tampil.dart';

/// Satu potongan kalimat pada [KalimatUtama]. Potongan ber-[nada] (`lulus`,
/// `awas`, `gagal`) diberi warna nada itu; nada lain atau `null` memakai tinta
/// biasa.
///
/// Potongan berwarna WAJIB berupa kata ("lewat jadwal", "siap diambil"), bukan
/// angka atau tanda: warna hanya memperkuat kata, tidak pernah menjadi satu-
/// satunya pembawa arti.
@immutable
class PotonganKalimat {
  const PotonganKalimat(this.teks, {this.nada})
    : assert(
        nada == null || teks != '',
        'potongan berwarna tidak boleh kosong: warna tanpa kata',
      );

  final String teks;
  final NadaStatus? nada;

  /// Potongan berwarna harus memuat huruf (kata), bukan hanya angka atau tanda.
  bool get warnaBerkata =>
      nada == null || RegExp(r'\p{L}', unicode: true).hasMatch(teks);
}

/// Kalimat utama Beranda: dateline kecil lalu jawaban "apa yang perlu saya
/// perhatikan" sebagai satu sampai [maksimumKalimat] kalimat besar (32 sp), dengan
/// frasa status berwarna ("1 alat **lewat jadwal**. 1 paket **siap diambil**.").
/// Pengganti sapaan + nama PT + empat ubin KPI.
///
/// Arti tidak bergantung pada warna: frasa berwarna adalah kata statusnya
/// sendiri (kontras 5,2:1 sampai 7,8:1 terhadap latar). Seluruh teks dijepit
/// [SkalaHuruf.batasBesar] terhadap skala huruf sistem; 32 sp x 1,3 memakan
/// empat baris di 320 dp. Keadaan tenang: [KalimatUtama.tenang].
class KalimatUtama extends StatelessWidget {
  const KalimatUtama({
    super.key,
    required this.dateline,
    required this.kalimat,
  });

  /// "Semua alat Anda berlaku." dengan "berlaku" berwarna `lulus`.
  const KalimatUtama.tenang({Key? key, required String dateline})
    : this(
        key: key,
        dateline: dateline,
        kalimat: const [
          [
            PotonganKalimat('Semua alat Anda '),
            PotonganKalimat('berlaku', nada: NadaStatus.lulus),
            PotonganKalimat('.'),
          ],
        ],
      );

  /// Teks kecil di atas kalimat (hari dan tanggal).
  final String dateline;

  /// Kalimat-kalimat; tiap kalimat adalah daftar potongan.
  final List<List<PotonganKalimat>> kalimat;

  /// Lebih dari dua kalimat tidak lagi terbaca sebagai jawaban; sisanya hanya
  /// di daftar "Perlu perhatian".
  static const int maksimumKalimat = 2;

  @override
  Widget build(BuildContext context) {
    assert(
      kalimat.every((k) => k.every((p) => p.warnaBerkata)),
      'frasa berwarna harus kata, bukan hanya angka atau tanda',
    );
    final t = context.teks;
    final w = context.warna;
    Color? warna(NadaStatus? n) => switch (n) {
      NadaStatus.lulus => w.lulus,
      NadaStatus.awas => w.awas,
      NadaStatus.gagal => w.gagal,
      _ => null,
    };
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: SkalaHuruf.batasBesar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateline, style: t.bodySmall),
          const SizedBox(height: Spasi.sm),
          for (final k in kalimat.take(maksimumKalimat))
            Text.rich(
              TextSpan(
                children: [
                  for (final p in k)
                    TextSpan(
                      text: p.teks,
                      style: warna(p.nada) == null
                          ? null
                          : TextStyle(color: warna(p.nada)),
                    ),
                ],
              ),
              style: t.displayMedium,
            ),
        ],
      ),
    );
  }
}
