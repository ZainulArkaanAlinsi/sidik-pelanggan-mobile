import 'package:flutter/material.dart';

import '../core/motion/gerak_bento.dart';
import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'dasar/cincin_fokus.dart';

/// Ragam tombol. Satu layar cuma boleh punya SATU [RagamTombol.utama].
enum RagamTombol {
  /// Isi biru, tinggi 48, sudut 10. Satu aksi dominan per bagian.
  utama,

  /// Putih bergaris tegas, tinggi 48. Aksi pendamping.
  sekunder,

  /// Hanya teks. Aksi tersier (Lupa sandi, Lewati).
  teks,

  /// Garis dan teks merah galat. Aksi merusak.
  bahaya,
}

/// Tombol aplikasi di atas `FilledButton`/`OutlinedButton`/`TextButton`:
/// persegi bersudut 10, ripple standar, tinggi minimal 48 dp (dari tema),
/// tumbuh ke bawah bila label membungkus (huruf besar di layar sempit).
/// Ditekan: skala 0,97 selama 120 ms ([TekanSkala], mati bila tombol mati atau
/// "kurangi gerak" menyala). Papan ketik: cincin fokus di luar tombol
/// ([CincinFokus]).
///
/// [sibuk] mengganti ikon dengan pemutar dan mematikan tombol: per tombol,
/// bukan satu penanda untuk seluruh layar. [penuh] membentang selebar induk.
///
/// [jumlah] (hanya [RagamTombol.utama]): lencana bulat 28 putih bertinta biru
/// di ujung kanan, mis. "Periksa alat" dengan 2 alat menunggu; padding 20 kiri
/// dan 8 kanan. Pembaca layar menerima "label, jumlah" (atau "label, jumlah satuan"
/// bila [satuanJumlah] ada, mis. "Lihat semua alat, 7 alat"). Angka SELALU
/// ditemani label, jadi tombolnya tetap bermakna tanpa warna.
class TombolSidik extends StatelessWidget {
  const TombolSidik({
    super.key,
    required this.label,
    this.onPressed,
    this.ragam = RagamTombol.sekunder,
    this.ikon,
    this.sibuk = false,
    this.penuh = false,
    this.jumlah,
    this.satuanJumlah,
  });

  final String label;
  final VoidCallback? onPressed;
  final RagamTombol ragam;
  final IconData? ikon;
  final bool sibuk;
  final bool penuh;
  final int? jumlah;

  /// Satuan yang disebut pembaca layar sesudah [jumlah] ("alat"); tidak
  /// tampil di lencana.
  final String? satuanJumlah;

  @override
  Widget build(BuildContext context) {
    final aksi = sibuk ? null : onPressed;
    final adaJumlah = jumlah != null && ragam == RagamTombol.utama;
    final isiTeks = adaJumlah
        ? _IsiDenganJumlah(
            label: label,
            jumlah: jumlah!,
            satuan: satuanJumlah,
            aktif: aksi != null,
            penuh: penuh,
          )
        : Text(label, textAlign: TextAlign.center);
    final Widget? penanda = sibuk
        ? const SizedBox.square(
            dimension: UkuranIkon.kecil + Spasi.xs,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (ikon == null ? null : Icon(ikon, size: UkuranIkon.sedang - 4));

    const paddingSekunder = EdgeInsets.symmetric(
      horizontal: UkuranKontrol.tombolSekunder,
    );
    final gayaUtama = adaJumlah
        ? FilledButton.styleFrom(
            padding: const EdgeInsetsDirectional.only(
              start: UkuranKontrol.tombolUtamaAwal,
              end: Spasi.sm,
            ),
          )
        : null;
    final gayaSekunder = OutlinedButton.styleFrom(padding: paddingSekunder);

    final Widget tombol = switch (ragam) {
      RagamTombol.utama =>
        penanda == null
            ? FilledButton(onPressed: aksi, style: gayaUtama, child: isiTeks)
            : FilledButton.icon(
                onPressed: aksi,
                style: gayaUtama,
                icon: penanda,
                label: isiTeks,
              ),
      RagamTombol.sekunder =>
        penanda == null
            ? OutlinedButton(
                onPressed: aksi,
                style: gayaSekunder,
                child: isiTeks,
              )
            : OutlinedButton.icon(
                onPressed: aksi,
                style: gayaSekunder,
                icon: penanda,
                label: isiTeks,
              ),
      RagamTombol.teks =>
        penanda == null
            ? TextButton(onPressed: aksi, child: isiTeks)
            : TextButton.icon(onPressed: aksi, icon: penanda, label: isiTeks),
      RagamTombol.bahaya => _tombolBahaya(context, aksi, isiTeks, penanda),
    };

    final bungkus = CincinFokus(
      sudut: Bentuk.sudutTombol,
      child: TekanSkala(aktif: aksi != null, child: tombol),
    );
    return penuh ? SizedBox(width: double.infinity, child: bungkus) : bungkus;
  }

  Widget _tombolBahaya(
    BuildContext context,
    VoidCallback? aksi,
    Widget isiTeks,
    Widget? penanda,
  ) {
    final galat = Theme.of(context).colorScheme.error;
    final gaya = OutlinedButton.styleFrom(
      foregroundColor: galat,
      side: BorderSide(color: galat),
      padding: const EdgeInsets.symmetric(
        horizontal: UkuranKontrol.tombolSekunder,
      ),
    );
    return penanda == null
        ? OutlinedButton(onPressed: aksi, style: gaya, child: isiTeks)
        : OutlinedButton.icon(
            onPressed: aksi,
            style: gaya,
            icon: penanda,
            label: isiTeks,
          );
  }
}

/// Isi tombol utama berlencana: label di kiri, lencana jumlah di kanan (rata
/// ujung bila [penuh]). Keluar dari semantik anaknya dan menyatukan satu
/// kalimat "label, jumlah".
class _IsiDenganJumlah extends StatelessWidget {
  const _IsiDenganJumlah({
    required this.label,
    required this.jumlah,
    required this.satuan,
    required this.aktif,
    required this.penuh,
  });

  final String label;
  final int jumlah;
  final String? satuan;
  final bool aktif;
  final bool penuh;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final t = context.teks;
    final isi = aktif ? s.secondary : s.onSurface.withValues(alpha: _alfaIsi);
    final tinta = aktif
        ? s.onSecondary
        : s.onSurface.withValues(alpha: _alfaTinta);
    return Semantics(
      label: satuan == null ? '$label, $jumlah' : '$label, $jumlah $satuan',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: penuh ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label)),
          const SizedBox(width: Spasi.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: isi,
              borderRadius: Bentuk.sudutPil,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: UkuranKontrol.lencanaTombol,
                minHeight: UkuranKontrol.lencanaTombol,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spasi.sm),
                  child: Text(
                    '$jumlah',
                    style: t.labelLarge?.tabular.copyWith(
                      color: tinta,
                      fontWeight: TipografiSidik.beratTebal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opasitas isi dan tinta lencana saat tombol mati (12 % dan 38 %).
  static const double _alfaIsi = 0.12;
  static const double _alfaTinta = 0.38;
}
