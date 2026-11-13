import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import '../models/paket.dart';

/// Garis waktu tegak satu paket: simpul persegi per langkah `garis_waktu`
/// (urutan, label, dan penanda `lewat`/`sekarang` dari server; aplikasi hanya
/// menggambar).
///
/// Simpul: terisi kobalt + centang = sudah lewat; terisi kobalt berlingkar
/// tipis dan judul tebal = sekarang; berbingkai tegas, kosong = belum. Bentuk
/// dan tebal judul berbeda di tiap keadaan, jadi arti tidak bergantung pada
/// warna. Pembaca layar menerima satu kalimat per langkah ("Sedang
/// dikalibrasi, tahap sekarang. Menunggu: ...").
///
/// [catatan] tampil di bawah langkah "sekarang", mis. alasan paket belum maju
/// ([menunggu]): "Menunggu: Jangka Sorong Digital dan Mikrometer Sekrup".
class GarisWaktuTahap extends StatelessWidget {
  const GarisWaktuTahap({super.key, required this.langkah, this.catatan});

  final List<LangkahPaket> langkah;
  final String? catatan;

  /// Kalimat "Menunggu: A dan B" dari nama alat yang menahan paket, atau
  /// `null` bila tidak ada nama. Nama kosong dibuang; nama kembar digabung
  /// ("Termometer Digital (2 unit)"), karena dua alat berbeda dengan nama sama
  /// tetap dua alat. Sampai [maksimum] butir disebut utuh ("A", "A dan B",
  /// "A, B, dan C"); selebihnya diringkas ("A, B, dan 3 alat lain"). Paling
  /// sedikit satu nama selalu disebut, jadi `maksimum: 1` menghasilkan "A dan 2
  /// alat lain", bukan kalimat tanpa nama.
  static String? menunggu(List<String> nama, {int maksimum = 3}) {
    final urut = <String>[];
    final jumlah = <String, int>{};
    for (final n in nama) {
      final bersih = n.trim();
      if (bersih.isEmpty) continue;
      if (!jumlah.containsKey(bersih)) urut.add(bersih);
      jumlah[bersih] = (jumlah[bersih] ?? 0) + 1;
    }
    if (urut.isEmpty) return null;
    String sebut(String n) => jumlah[n]! > 1 ? '$n (${jumlah[n]} unit)' : n;

    final batas = maksimum < 1 ? 1 : maksimum;
    final List<String> bagian;
    if (urut.length <= batas) {
      bagian = [for (final n in urut) sebut(n)];
    } else {
      final tampil = urut.sublist(0, batas > 1 ? batas - 1 : 1);
      final total = jumlah.values.fold<int>(0, (a, b) => a + b);
      final disebut = tampil.fold<int>(0, (a, n) => a + jumlah[n]!);
      bagian = [
        for (final n in tampil) sebut(n),
        '${total - disebut} alat lain',
      ];
    }
    final daftar = switch (bagian.length) {
      1 => bagian.single,
      2 => '${bagian[0]} dan ${bagian[1]}',
      _ =>
        '${bagian.sublist(0, bagian.length - 1).join(', ')}, '
            'dan ${bagian.last}',
    };
    return 'Menunggu: $daftar';
  }

  @override
  Widget build(BuildContext context) {
    if (langkah.isEmpty) return const SizedBox.shrink();
    final t = context.teks;
    final s = context.skema;
    return Column(
      children: [
        for (var i = 0; i < langkah.length; i++)
          _Langkah(
            langkah: langkah[i],
            terakhir: i == langkah.length - 1,
            catatan: langkah[i].sekarang ? catatan : null,
            gayaJudul: langkah[i].sekarang
                ? t.titleMedium!
                : t.bodyLarge!.copyWith(
                    color: langkah[i].lewat ? s.onSurface : s.onSurfaceVariant,
                  ),
          ),
      ],
    );
  }
}

class _Langkah extends StatelessWidget {
  const _Langkah({
    required this.langkah,
    required this.terakhir,
    required this.catatan,
    required this.gayaJudul,
  });

  final LangkahPaket langkah;
  final bool terakhir;
  final String? catatan;
  final TextStyle gayaJudul;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final lewat = langkah.lewat && !langkah.sekarang;
    final sekarang = langkah.sekarang;

    final Widget simpul;
    if (sekarang) {
      simpul = DecoratedBox(
        decoration: BoxDecoration(
          color: s.primary,
          border: Border.all(
            color: s.primaryContainer,
            width: UkuranTik.lingkar,
          ),
          borderRadius: Bentuk.sudutKecil,
        ),
        child: const SizedBox.square(dimension: UkuranTik.simpulSekarang),
      );
    } else if (lewat) {
      simpul = Padding(
        padding: const EdgeInsets.only(top: Spasi.xs),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: s.primary,
            borderRadius: Bentuk.sudutKecil,
          ),
          child: SizedBox.square(
            dimension: UkuranTik.simpul,
            child: Icon(
              Icons.check,
              size: UkuranTik.simpul - UkuranTik.batang,
              color: s.onPrimary,
            ),
          ),
        ),
      );
    } else {
      simpul = Padding(
        padding: const EdgeInsets.only(top: Spasi.xs),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: s.outline, width: UkuranTik.batang),
            borderRadius: Bentuk.sudutKecil,
          ),
          child: const SizedBox.square(dimension: UkuranTik.simpul),
        ),
      );
    }

    final status = sekarang
        ? 'tahap sekarang'
        : lewat
        ? 'selesai'
        : 'belum';
    final kalimat =
        '${langkah.label}, $status'
        '${catatan == null ? '' : '. $catatan'}';

    return Semantics(
      label: kalimat,
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: UkuranTik.simpulSekarang,
              child: Column(
                children: [
                  simpul,
                  if (!terakhir)
                    Expanded(
                      child: SizedBox(
                        width: UkuranTik.batang,
                        child: ColoredBox(
                          color: lewat ? s.primary : s.outlineVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Spasi.md),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: terakhir ? 0 : Spasi.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(langkah.label, style: gayaJudul),
                    if (catatan != null)
                      Padding(
                        padding: const EdgeInsets.only(top: Spasi.xs),
                        child: Text(catatan!, style: t.bodyMedium),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
