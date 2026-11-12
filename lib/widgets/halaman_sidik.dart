import 'package:flutter/material.dart';

import 'konten_tengah.dart';

/// Kerangka satu layar: `Scaffold` + `AppBar` bertema + isi yang dipusatkan dan
/// dibatasi lebarnya di layar lebar ([KontenTengah]). Semua layar memakainya,
/// jadi aturan tata letak (batas lebar, app bar) ada di satu tempat.
///
/// [judul] teks sederhana; [judulKustom] untuk judul berupa widget (mis. logo
/// + nama). Tanpa keduanya, layar tidak punya app bar (layar penuh seperti
/// Sambutan dan Masuk).
class HalamanSidik extends StatelessWidget {
  const HalamanSidik({
    super.key,
    this.judul,
    this.judulKustom,
    this.aksi = const [],
    this.otomatisKembali = true,
    this.latarPutih = false,
    this.bawah,
    required this.isi,
  });

  final String? judul;
  final Widget? judulKustom;
  final List<Widget> aksi;
  final bool otomatisKembali;

  /// Latar putih (permukaan) alih-alih abu dingin: layar sambutan dan formulir.
  final bool latarPutih;

  /// Widget di bawah isi (mis. bilah aksi), di luar area bergulir.
  final Widget? bawah;
  final Widget isi;

  @override
  Widget build(BuildContext context) {
    final adaBar = judul != null || judulKustom != null;
    return Scaffold(
      backgroundColor: latarPutih
          ? Theme.of(context).colorScheme.surface
          : null,
      appBar: adaBar
          ? AppBar(
              title: judulKustom ?? Text(judul!),
              actions: aksi,
              automaticallyImplyLeading: otomatisKembali,
            )
          : null,
      body: KontenTengah(child: isi),
      bottomNavigationBar: bawah,
    );
  }
}
