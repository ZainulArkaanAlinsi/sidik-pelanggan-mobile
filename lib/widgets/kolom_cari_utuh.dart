import 'dart:async';

import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';

/// Kolom cari yang petunjuknya UTUH: pada 320 dp dengan huruf 1,3x, petunjuk
/// "Cari nama, merk, atau nomor seri" di `KolomCari` terpotong menjadi "Cari
/// nama, merk, at...". Di sini petunjuk boleh membungkus sampai dua baris
/// ([petunjukBaris]) dan kolom tumbuh mengikutinya; tinggi minimum tetap 48
/// dp dari tema isian. Pembaca layar menerima [petunjuk] penuh sebagai label
/// (dari `hintText`; satu node text-field).
///
/// Jeda ketik seperti `KolomCari`: [onCari] dipanggil sekali per kata, 350 ms
/// sesudah ketikan terakhir, dengan kata yang sudah dipangkas.
class KolomCariUtuh extends StatefulWidget {
  const KolomCariUtuh({
    super.key,
    required this.petunjuk,
    required this.onCari,
  });

  final String petunjuk;
  final ValueChanged<String> onCari;

  /// Jeda sesudah ketikan terakhir.
  static const Duration jeda = Duration(milliseconds: 350);

  /// Petunjuk membungkus sampai sekian baris sebelum dipotong.
  static const int petunjukBaris = 2;

  @override
  State<KolomCariUtuh> createState() => _KolomCariUtuhState();
}

class _KolomCariUtuhState extends State<KolomCariUtuh> {
  final _kontrol = TextEditingController();
  Timer? _tunda;

  @override
  void dispose() {
    _tunda?.cancel();
    _kontrol.dispose();
    super.dispose();
  }

  void _ketik(String teks) {
    _tunda?.cancel();
    _tunda = Timer(KolomCariUtuh.jeda, () => widget.onCari(teks.trim()));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Spasi.sisi,
      Spasi.lg,
      Spasi.sisi,
      Spasi.md,
    ),
    // Tanpa `Semantics` pembungkus: `TextField` sudah memberi label dari
    // `hintText`, dan pembungkus kedua membuat DUA node text-field berlabel
    // sama (TalkBack fokus dua kali).
    child: TextField(
      controller: _kontrol,
      onChanged: _ketik,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: widget.petunjuk,
        hintMaxLines: KolomCariUtuh.petunjukBaris,
      ),
    ),
  );
}
