import 'dart:async';

import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/elevasi.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'tombol_bulat.dart';

/// Kolom cari Bento Lab dengan petunjuk UTUH: pil putih setinggi 56 (padding 20
/// kiri, 6 kanan), petunjuk 14/400 `teksKedua`, dan tombol bulat 44 navy di
/// kanan. Pada 320 dp dengan huruf 1,3x, petunjuk "Cari nama, merk, atau nomor
/// seri" di `KolomCari` terpotong menjadi "Cari nama, merk, at...". Di sini
/// petunjuk boleh membungkus sampai dua baris ([petunjukBaris]) dan kolom
/// tumbuh mengikutinya; 56 dp adalah minimum. Pembaca layar menerima
/// [petunjuk] penuh sebagai label (dari `hintText`; satu node text-field).
///
/// Jeda ketik seperti `KolomCari`: [onCari] dipanggil sekali per kata, 350 ms
/// sesudah ketikan terakhir, dengan kata yang sudah dipangkas. Tombol bulat
/// (label "Cari", area sentuh 48) dan tombol cari di papan ketik memanggilnya
/// SEKARANG tanpa menunggu jeda, kecuali kata itu sudah dikirim. [aktif] false
/// mematikan isian dan tombolnya (`TextField.enabled`, simpul semantik mati).
///
/// Tepinya garis tegas 3:1 (`ColorScheme.outline`, 2 dp bernavy saat fokus),
/// bukan `garis` halus (1,4:1) yang tidak cukup menandai tepi kontrol.
class KolomCariUtuh extends StatefulWidget {
  const KolomCariUtuh({
    super.key,
    required this.petunjuk,
    required this.onCari,
    this.aktif = true,
  });

  final String petunjuk;
  final ValueChanged<String> onCari;
  final bool aktif;

  /// Jeda sesudah ketikan terakhir.
  static const Duration jeda = Duration(milliseconds: 350);

  /// Petunjuk membungkus sampai sekian baris sebelum dipotong.
  static const int petunjukBaris = 2;

  /// Opasitas teks isian saat mati (pola Material 3: 38 %).
  static const double _alfaMati = 0.38;

  @override
  State<KolomCariUtuh> createState() => _KolomCariUtuhState();
}

class _KolomCariUtuhState extends State<KolomCariUtuh> {
  final _kontrol = TextEditingController();
  Timer? _tunda;

  /// Kata terakhir yang dikirim ke [KolomCariUtuh.onCari]; mencegah kirim ganda
  /// (jeda berakhir lalu tombol ditekan untuk kata yang sama).
  String? _terakhir;

  @override
  void dispose() {
    _tunda?.cancel();
    _kontrol.dispose();
    super.dispose();
  }

  void _kirim(String kata) {
    _terakhir = kata;
    widget.onCari(kata);
  }

  void _ketik(String teks) {
    _tunda?.cancel();
    _tunda = Timer(KolomCariUtuh.jeda, () => _kirim(teks.trim()));
  }

  /// Cari sekarang, tanpa menunggu jeda.
  void _cariSekarang() {
    _tunda?.cancel();
    final kata = _kontrol.text.trim();
    if (kata != _terakhir) _kirim(kata);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final t = context.teks;
    final gaya = t.bodySmall?.copyWith(fontWeight: FontWeight.w400);
    OutlineInputBorder tepi(Color warna, [double tebal = Elevasi.garis]) =>
        OutlineInputBorder(
          borderRadius: Bentuk.sudutPil,
          borderSide: BorderSide(color: warna, width: tebal),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spasi.sisi,
        Spasi.lg,
        Spasi.sisi,
        Spasi.md,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Tanpa `Semantics` pembungkus: `TextField` sudah memberi label dari
          // `hintText`, dan pembungkus kedua membuat DUA node text-field
          // berlabel sama (TalkBack fokus dua kali).
          TextField(
            controller: _kontrol,
            enabled: widget.aktif,
            onChanged: _ketik,
            onSubmitted: (_) => _cariSekarang(),
            textInputAction: TextInputAction.search,
            style: gaya?.copyWith(
              color: widget.aktif
                  ? s.onSurface
                  : s.onSurface.withValues(alpha: KolomCariUtuh._alfaMati),
            ),
            decoration: InputDecoration(
              hintText: widget.petunjuk,
              hintMaxLines: KolomCariUtuh.petunjukBaris,
              hintStyle: gaya?.copyWith(color: s.onSurfaceVariant),
              constraints: const BoxConstraints(
                minHeight: UkuranKontrol.kolomCari,
              ),
              // Ruang untuk tombol bulat di kanan: celah 4 + kotak sentuh 48 +
              // jarak ke teks.
              // `InputDecorator` menambah 4 dp di awal isian (diukur oleh
              // tes): dikurangkan supaya petunjuk mulai tepat 20 dp dari tepi.
              contentPadding: const EdgeInsetsDirectional.only(
                start: UkuranKontrol.kolomCariAwal - Spasi.xs,
                end: Spasi.xs + AreaSentuh.minimum + Spasi.sm,
                top: Spasi.md,
                bottom: Spasi.md,
              ),
              border: tepi(s.outline),
              enabledBorder: tepi(s.outline),
              focusedBorder: tepi(s.primary, UkuranFokus.tebal),
              disabledBorder: tepi(s.outlineVariant),
            ),
          ),
          // Kotak sentuh 48 berpusat; lingkaran 44 jatuh 6 dp dari tepi kanan.
          PositionedDirectional(
            end: Spasi.xs,
            top: 0,
            bottom: 0,
            child: Center(
              child: TombolBulat.cari(
                onTap: widget.aktif ? _cariSekarang : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
