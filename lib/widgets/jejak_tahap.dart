import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import '../models/paket.dart';
import 'status_tampil.dart';

/// Posisi (indeks 0) tahap sekarang di [garis] (`garis_waktu` dari server), atau
/// `null` bila tidak ada tahap "sekarang".
///
/// Tanpa [kode]: ikuti penanda server (`sekarang`; cadangan: langkah terakhir
/// yang `lewat`). Dengan [kode] (kode tahap SATU alat, mis. `dikalibrasi`):
/// cari kode itu di [garis]. Server menggabungkan `menunggu_pengesahan` ke
/// `menunggu_pemeriksaan` hanya di `garis_waktu`, jadi alias itu dipetakan di
/// sini, SATU aturan. Kode yang tidak ada di [garis] (tahap baru dari server
/// yang belum dikenal) menghasilkan `null`: tidak ada tik "sekarang" yang
/// dikarang.
int? posisiTahap(List<LangkahPaket> garis, {String? kode}) {
  if (garis.isEmpty) return null;
  if (kode != null) {
    final dicari = kode == 'menunggu_pengesahan'
        ? 'menunggu_pemeriksaan'
        : kode;
    final i = garis.indexWhere((l) => l.kode == dicari);
    return i < 0 ? null : i;
  }
  final sekarang = garis.indexWhere((l) => l.sekarang);
  if (sekarang >= 0) return sekarang;
  final lewat = garis.lastIndexWhere((l) => l.lewat);
  return lewat < 0 ? null : lewat;
}

/// Jejak tahap satu alat atau paket: SATU TIK per langkah `garis_waktu` dari
/// server. Tik sampai tahap sekarang berwarna kobalt, tik "sekarang" lebih
/// tinggi, sisanya garis halus (dekoratif).
///
/// Jumlah tik = `garisWaktu.length`, tidak pernah angka 6 yang dikeraskan:
/// server menyisipkan "Sedang dikerjakan ulang" hanya saat terjadi, jadi 6
/// atau 7. KATA ([kata], mis. "Di lab: Sedang dikalibrasi") WAJIB dan tampil di
/// bawah tik: tik bukan satu-satunya pembawa arti. Pembaca layar menerima
/// "Tahap 2 dari 6: kata".
class JejakTahap extends StatelessWidget {
  const JejakTahap({
    super.key,
    required this.garisWaktu,
    required this.kata,
    this.kodeTahap,
    this.nadaKata,
  });

  final List<LangkahPaket> garisWaktu;
  final String kata;

  /// Kode tahap satu alat; `null` = ikuti penanda `sekarang` di [garisWaktu].
  final String? kodeTahap;

  /// Warna kata ("Siap diambil" = `lulus`); `null` = tinta biasa.
  final NadaStatus? nadaKata;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final w = context.warna;
    final posisi = posisiTahap(garisWaktu, kode: kodeTahap);
    final jumlah = garisWaktu.length;
    final tintaKata = switch (nadaKata) {
      NadaStatus.lulus => w.lulus,
      NadaStatus.awas => w.awas,
      NadaStatus.gagal => w.gagal,
      _ => s.onSurface,
    };
    final teksKata = Text(
      kata,
      style: t.bodySmall?.copyWith(
        color: tintaKata,
        fontWeight: FontWeight.w600,
      ),
    );
    // `garis_waktu` kosong (server belum mengirim langkah): tanpa tik, tetapi
    // kata yang wajib tetap tampil. Kata tidak boleh hilang bersama tiknya.
    if (garisWaktu.isEmpty) {
      return Semantics(label: kata, excludeSemantics: true, child: teksKata);
    }
    return Semantics(
      label: posisi == null
          ? 'Tahap: $kata'
          : 'Tahap ${posisi + 1} dari $jumlah: $kata',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: UkuranTik.tinggiSekarang,
            child: Row(
              children: [
                for (var i = 0; i < jumlah; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: i == jumlah - 1 ? 0 : UkuranTik.jarak,
                      ),
                      child: Align(
                        child: SizedBox(
                          width: double.infinity,
                          height: i == posisi
                              ? UkuranTik.tinggiSekarang
                              : UkuranTik.tinggi,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: posisi != null && i <= posisi
                                  ? s.primary
                                  : s.outlineVariant,
                              borderRadius: Bentuk.sudutKecil,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spasi.xs),
          teksKata,
        ],
      ),
    );
  }
}
