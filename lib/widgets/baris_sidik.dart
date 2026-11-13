import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'nomor_sidik.dart';

/// Apakah baris daftar memakai tata letak KOMPAK pada konteks ini: lebar layar
/// di bawah [Spasi.batasKompak] ATAU huruf sistem lebih dari
/// [SkalaHuruf.batasBesar] kali. Kompak = kolom angka pindah ke atas judul dan
/// bagian akhir pindah ke bawah teks, supaya judul tidak terjepit jadi tiga
/// baris di HP sempit.
bool tataLetakKompak(BuildContext context) {
  final skala = MediaQuery.textScalerOf(context);
  return MediaQuery.sizeOf(context).width < Spasi.batasKompak ||
      skala.scale(UkuranBaris.kolomAngka) >
          UkuranBaris.kolomAngka * SkalaHuruf.batasBesar;
}

/// Satu baris daftar. Satu butir = satu baris; kartu hanya untuk grup (lihat
/// `PanelSidik`).
///
/// Slot: [awal] (kolom angka, mis. `AngkaHari`), [judul], [baris] keterangan
/// TERPISAH (satu widget per fakta; bukan rangkaian "A · B · C"), [akhir], dan
/// panah. Tinggi minimum 72 dp. Seluruh baris bisa diketuk ([onTap]) dan
/// terbaca pembaca layar sebagai satu tombol dengan [semantik] (kalimat
/// gabungan); tanpa [semantik] pembaca layar membaca isi barisnya berurutan.
///
/// [awal] menerima `kompak` supaya kolom angka memilih bentuknya sendiri.
/// [gayaNomor]: judul adalah nomor (sertifikat, order): digit selebar tetap
/// dan tidak pernah putus di tengah ([NomorSidik]). [panah] dimatikan bila
/// baris punya tautan teks sendiri. [kompak] mengganti keputusan otomatis
/// ([tataLetakKompak]), mis. untuk panel sempit di tablet. Baris statis (tanpa
/// [onTap]) yang punya [semantik] tetap dibaca sebagai satu kalimat.
class BarisSidik extends StatelessWidget {
  const BarisSidik({
    super.key,
    this.awal,
    required this.judul,
    this.baris = const [],
    this.akhir,
    this.onTap,
    this.semantik,
    this.tebalJudul = true,
    this.gayaNomor = false,
    this.panah = true,
    this.kompak,
    this.maksBarisJudul,
  });

  final Widget Function(bool kompak)? awal;
  final String judul;
  final List<Widget> baris;
  final Widget? akhir;
  final VoidCallback? onTap;
  final String? semantik;
  final bool tebalJudul;
  final bool gayaNomor;
  final bool panah;
  final bool? kompak;

  /// Judul dipotong dengan elipsis di ujung sesudah sekian baris (nama alat:
  /// 2). `null` = membungkus tanpa batas. Pembaca layar tetap menerima judul
  /// utuh lewat [semantik].
  final int? maksBarisJudul;

  /// Jarak antar-baris keterangan: setengah [Spasi.xs] (2 dp).
  static const double _antarBaris = Spasi.xs / 2;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final sempit = kompak ?? tataLetakKompak(context);
    final adaAwal = awal != null;
    final awalDiAtas = adaAwal && sempit;
    final lebarAwal = MediaQuery.textScalerOf(
      context,
    ).scale(UkuranBaris.kolomAngka);

    final gayaJudul = gayaNomor
        ? t.titleMedium!
        : (tebalJudul ? t.titleMedium! : t.bodyLarge!);
    final judulTeks = gayaNomor
        ? NomorSidik(judul, gaya: gayaJudul)
        : Text(
            judul,
            style: gayaJudul,
            maxLines: maksBarisJudul,
            overflow: maksBarisJudul == null ? null : TextOverflow.ellipsis,
          );

    final isi = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: UkuranBaris.minimum),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spasi.lg,
          vertical: Spasi.md,
        ),
        child: Row(
          children: [
            if (adaAwal && !sempit) ...[
              SizedBox(width: lebarAwal, child: awal!(false)),
              const SizedBox(width: Spasi.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (awalDiAtas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spasi.xs),
                      child: awal!(true),
                    ),
                  judulTeks,
                  for (final b in baris)
                    Padding(
                      padding: const EdgeInsets.only(top: _antarBaris),
                      child: b,
                    ),
                  if (sempit && akhir != null)
                    Padding(
                      padding: const EdgeInsets.only(top: _antarBaris),
                      child: akhir!,
                    ),
                ],
              ),
            ),
            if (akhir != null && !sempit) ...[
              const SizedBox(width: Spasi.sm),
              akhir!,
            ],
            if (onTap != null && panah) ...[
              const SizedBox(width: Spasi.xs),
              ExcludeSemantics(
                child: Icon(Icons.chevron_right, color: s.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) {
      // Baris statis dengan [semantik] tetap dibaca SATU kalimat (BarisAlat
      // yang belum bisa diketuk), bukan kepingan teks anaknya.
      return semantik == null
          ? isi
          : Semantics(
              container: true,
              label: semantik,
              excludeSemantics: true,
              child: isi,
            );
    }
    // Dengan [semantik], isi baris dibuang dari pohon semantik
    // (`excludeSemantics`) berikut aksi ketuk milik InkWell; aksinya harus
    // dipasang lagi di sini, kalau tidak pembaca layar menemukan tombol
    // berlabel yang tidak bisa diaktifkan. Tanpa [semantik], InkWell
    // menyumbang aksinya sendiri (dipasang dua kali, node-nya terbelah dan
    // tombolnya kehilangan label).
    return Semantics(
      button: true,
      label: semantik,
      onTap: semantik == null ? null : onTap,
      excludeSemantics: semantik != null,
      child: InkWell(onTap: onTap, child: isi),
    );
  }
}
