import 'dart:async';

import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';

/// Kolom cari dengan jeda ketik: [onCari] dipanggil sekali per kata (350 ms
/// sesudah ketikan terakhir), bukan sekali per huruf, supaya satu permintaan
/// ke server per pencarian. Kata sudah dipangkas ([String.trim]).
class KolomCari extends StatefulWidget {
  const KolomCari({super.key, required this.petunjuk, required this.onCari});

  final String petunjuk;
  final ValueChanged<String> onCari;

  /// Jeda sesudah ketikan terakhir.
  static const Duration jeda = Duration(milliseconds: 350);

  @override
  State<KolomCari> createState() => _KolomCariState();
}

class _KolomCariState extends State<KolomCari> {
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
    _tunda = Timer(KolomCari.jeda, () => widget.onCari(teks.trim()));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Spasi.lg, Spasi.md, Spasi.lg, 0),
    child: TextField(
      controller: _kontrol,
      onChanged: _ketik,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: widget.petunjuk,
      ),
    ),
  );
}
