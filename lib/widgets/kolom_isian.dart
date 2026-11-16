import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';

/// Isian formulir dengan LABEL PERMANEN di atas kolom (REVISI-1 §5 dan §9,
/// REVISI-2 butir 1): kata labelnya tidak pernah hilang waktu kolom diketuk
/// atau diisi (bukan petunjuk yang menguap), satuan atau persyaratan ada di
/// [bantuan] di bawah kolom, dan pesan galat ([galat]) tampil TEPAT di bawah
/// kolomnya, menggantikan [bantuan], dengan garis kolom merah.
///
/// Tinggi kolom 48 dp ([UkuranKontrol.kolomCari]). Pembaca layar menerima
/// SATU simpul: label + isi + bantuan atau galat (label di atas digabung ke
/// kolomnya lewat [MergeSemantics], bukan dibaca dua kali). [petunjuk] hanya
/// contoh isi ("nama@perusahaan.com"), bukan pengganti label. Bila kolom di
/// bawah layar dan papan ketik terbuka, kolom diberi ruang tambahan
/// ([ruangTombol]) supaya tombol utama di bawahnya tetap terlihat di atas
/// papan ketik.
///
/// Hanya bentuk. Pengendali, validasi, dan apa yang dilakukan isiannya milik
/// layar pemakai.
class KolomIsian extends StatelessWidget {
  const KolomIsian({
    super.key,
    required this.label,
    required this.pengendali,
    this.petunjuk,
    this.bantuan,
    this.galat,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.rahasia = false,
    this.aktif = true,
    this.onSubmitted,
    this.ikonAkhir,
  });

  final String label;
  final TextEditingController pengendali;

  /// Contoh isi (hint); BUKAN label.
  final String? petunjuk;

  /// Persyaratan atau contoh di bawah kolom ("Minimal 10 karakter").
  final String? bantuan;

  /// Pesan galat untuk kolom ini; non-null menggantikan [bantuan].
  final String? galat;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool rahasia;
  final bool aktif;
  final ValueChanged<String>? onSubmitted;

  /// Tombol di ujung kolom (mis. tampilkan sandi); wajib punya tooltip.
  final Widget? ikonAkhir;

  /// Ruang di bawah kolom yang dijaga terlihat saat kolom fokus dan papan ketik
  /// terbuka: tombol utama (48) + jarak ke tombol (24) + napas (16).
  static const double ruangTombol =
      UkuranBaris.tombolUtama + Spasi.xl + Spasi.lg;

  /// Jarak label ke kolom.
  static const double jarakLabel = Spasi.sm;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: t.labelLarge?.copyWith(
              color: aktif ? s.onSurface : s.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: jarakLabel),
          TextField(
            controller: pengendali,
            enabled: aktif,
            obscureText: rahasia,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            textCapitalization: textCapitalization,
            onSubmitted: onSubmitted,
            scrollPadding: const EdgeInsets.fromLTRB(
              Spasi.xl,
              Spasi.xl,
              Spasi.xl,
              ruangTombol,
            ),
            decoration: InputDecoration(
              hintText: petunjuk,
              helperText: bantuan,
              helperMaxLines: 3,
              errorText: galat,
              errorMaxLines: 3,
              suffixIcon: ikonAkhir,
              constraints: const BoxConstraints(
                minHeight: UkuranKontrol.kolomCari,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
