import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/warna_sidik.dart';
import 'nomor_sidik.dart';

/// Satu fakta "label  nilai": label redup (keterangan 14), nilai tegas (isi 16,
/// berat 500). Pengganti `BarisInfo` di baris daftar dan lembar detail.
///
/// `BarisInfo` menumpuk label di atas nilai di bawah 300 dp; padahal lebar isi
/// kartu di HP 360 dp hanya 296 dp, jadi tata letak mendatar tidak pernah
/// muncul di HP standar. [Fakta] mengalir sebagai satu teks yang MEMBUNGKUS
/// (label dan nilai satu paragraf), jadi memuat di 320 dp x huruf 1,3 tanpa
/// ambang ukuran.
///
/// Nilai kosong tidak digambar (tanpa baris "—"), kecuali [kosong] diisi (mis.
/// "Belum dicatat"). [tumpuk]: label di atas, nilai di bawahnya, untuk nilai
/// panjang. Dengan [nomor] nilai berdigit selebar tetap + nol bergaris dan
/// satu baris yang mengecil, tidak putus di tengah ([NomorSidik]): di sebelah
/// label bila muat satu baris, di bawahnya bila tidak (atau pada [tumpuk]). Nilai pendek biasa (tanggal,
/// "0–150 mm") tidak dipatahkan di tengah: bila tidak muat di sisa baris, ia
/// pindah utuh ke baris berikutnya. Pembaca layar menerima "label: nilai".
class Fakta extends StatelessWidget {
  const Fakta(
    this.label,
    this.nilai, {
    super.key,
    this.nomor = false,
    this.tumpuk = false,
    this.kosong,
  });

  final String label;
  final String? nilai;
  final bool nomor;
  final bool tumpuk;

  /// Teks pengganti bila [nilai] kosong; `null` = baris tidak digambar.
  final String? kosong;

  /// Nilai biasa sepanjang ini atau kurang dirangkai dengan spasi tak-putus.
  static const int _batasTakPutus = 24;

  @override
  Widget build(BuildContext context) {
    final bersih = nilai?.trim() ?? '';
    final ada = bersih.isNotEmpty;
    if (!ada && kosong == null) return const SizedBox.shrink();
    final isi = ada ? bersih : kosong!;
    final t = context.teks;
    final s = context.skema;

    var gayaNilai = t.bodyMedium!.copyWith(
      fontWeight: FontWeight.w500,
      color: ada ? null : s.onSurfaceVariant,
    );
    if (nomor && ada) gayaNilai = gayaNilai.nomor;

    final Widget badan = tumpuk
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: t.bodySmall),
              if (nomor && ada)
                NomorSidik(isi, gaya: gayaNilai)
              else
                Text(isi, style: gayaNilai),
            ],
          )
        : (nomor && ada)
        ? LayoutBuilder(
            builder: (context, batas) {
              // Sebaris dengan label bila nomornya muat satu baris di sisa
              // lebar; kalau tidak, nomor dapat baris sendiri di bawah label
              // (bukan patah di tengah angka).
              final pengukur = TextPainter(
                text: TextSpan(text: label, style: t.bodySmall),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: 1,
              )..layout();
              final sisa = batas.maxWidth - pengukur.width - Spasi.sm;
              pengukur.dispose();
              if (batas.hasBoundedWidth &&
                  NomorSidik.muatSatuBaris(context, isi, gayaNilai, sisa)) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(label, style: t.bodySmall),
                    const SizedBox(width: Spasi.sm),
                    Flexible(child: NomorSidik(isi, gaya: gayaNilai)),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: t.bodySmall),
                  NomorSidik(isi, gaya: gayaNilai),
                ],
              );
            },
          )
        : Text.rich(
            TextSpan(
              text: '$label  ',
              style: t.bodySmall,
              children: [
                TextSpan(
                  text: ada && isi.length <= _batasTakPutus
                      ? isi.replaceAll(' ', '\u00A0')
                      : isi,
                  style: gayaNilai,
                ),
              ],
            ),
          );
    return Semantics(
      label: '$label: $isi',
      excludeSemantics: true,
      child: badan,
    );
  }
}
