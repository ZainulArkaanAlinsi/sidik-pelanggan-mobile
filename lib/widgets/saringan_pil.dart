import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';
import '../core/tema/bentuk.dart';
import '../core/tema/elevasi.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'dasar/kontrol_ketuk.dart';
import 'status_tampil.dart';

/// Satu pilihan pada [SaringanPil]: kata, jumlah (bila ada), dan nada status
/// untuk bulatan jumlahnya saat tidak terpilih ("Lewat jadwal" = koral).
@immutable
class PilihanPil {
  const PilihanPil(this.label, {this.jumlah, this.nada});

  final String label;
  final int? jumlah;

  /// Warna bulatan jumlah saat pilihan TIDAK terpilih; null = latar halaman.
  /// Warna hanya pengiring: katanya sudah menyebut statusnya.
  final NadaStatus? nada;

  /// Kalimat untuk pembaca layar: "Lewat jadwal, 1".
  String get semantik => jumlah == null ? label : '$label, $jumlah';
}

/// Saringan pil Bento Lab (pengganti deretan `ChoiceChip`/`SaringanTeks`):
/// pil setinggi 44 (radius 22), kata 14/700 + bulatan jumlah 32. Terpilih =
/// navy + kata putih + bulatan kuning; tidak terpilih = putih bertepi tegas +
/// bulatan berwarna status atau `latar`. Terpilih juga dibawa `selected` ke
/// pembaca layar, jadi pilihan tidak hanya dibedakan warna.
///
/// Baris bergulir mendatar dengan margin halamannya sendiri; pilihan terpilih
/// digulirkan seminimal mungkin ke dalam layar. Tiap pil memakai area sentuh 48
/// ([KontrolKetuk]); warna berubah 120 ms (`AppMotion.kilat`) dan nol bila
/// "kurangi gerak" menyala. [onPilih] null = semua mati.
class SaringanPil extends StatefulWidget {
  const SaringanPil({
    super.key,
    required this.pilihan,
    required this.terpilih,
    this.onPilih,
  });

  final List<PilihanPil> pilihan;
  final int terpilih;
  final ValueChanged<int>? onPilih;

  @override
  State<SaringanPil> createState() => _SaringanPilState();
}

class _SaringanPilState extends State<SaringanPil> {
  List<GlobalKey> _kunci = const [];

  @override
  void initState() {
    super.initState();
    _sinkronKunci();
    _sesudahFrame(_gulirKeTerpilih);
  }

  @override
  void didUpdateWidget(SaringanPil lama) {
    super.didUpdateWidget(lama);
    _sinkronKunci();
    if (lama.terpilih != widget.terpilih ||
        lama.pilihan.length != widget.pilihan.length) {
      _sesudahFrame(_gulirKeTerpilih);
    }
  }

  void _sinkronKunci() {
    if (_kunci.length != widget.pilihan.length) {
      _kunci = [for (var i = 0; i < widget.pilihan.length; i++) GlobalKey()];
    }
  }

  void _sesudahFrame(VoidCallback f) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) f();
      });

  void _gulirKeTerpilih() {
    final i = widget.terpilih;
    if (i < 0 || i >= _kunci.length) return;
    final konteks = _kunci[i].currentContext;
    if (konteks == null) return;
    Scrollable.ensureVisible(
      konteks,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      duration: Duration.zero,
    );
  }

  /// Tinggi baris: kotak sentuh 48 + ruang cincin fokus di atas dan di bawah.
  /// Gulir mendatar mengambil seluruh tinggi yang ditawarkan induk, jadi
  /// tingginya ditetapkan di sini.
  static const double _tinggiBaris = AreaSentuh.minimum + 2 * Spasi.xs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _tinggiBaris,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Spasi.sisi,
          vertical: Spasi.xs,
        ),
        child: Row(
          children: [
            for (var i = 0; i < widget.pilihan.length; i++) ...[
              if (i > 0) const SizedBox(width: Spasi.sm),
              _Pil(
                key: _kunci[i],
                pilihan: widget.pilihan[i],
                terpilih: i == widget.terpilih,
                onTap: widget.onPilih == null ? null : () => widget.onPilih!(i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pil extends StatelessWidget {
  const _Pil({
    super.key,
    required this.pilihan,
    required this.terpilih,
    required this.onTap,
  });

  final PilihanPil pilihan;
  final bool terpilih;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final aktif = onTap != null;
    final (isi, tinta, bulatIsi, bulatTinta) = _warna(context, aktif);

    final gaya = context.teks.bodySmall?.copyWith(
      color: tinta,
      fontWeight: TipografiSidik.beratLabel,
    );
    final jumlah = pilihan.jumlah;

    return KontrolKetuk(
      onTap: onTap,
      semantik: pilihan.semantik,
      terpilih: terpilih,
      warna: isi,
      sudut: Bentuk.sudutKapsul,
      sisi: terpilih && aktif
          ? BorderSide.none
          : BorderSide(
              color: aktif ? s.outline : Colors.transparent,
              width: Elevasi.garis,
            ),
      child: AnimatedDefaultTextStyle(
        style: gaya ?? const TextStyle(),
        duration: _durasi(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: UkuranKontrol.saringan),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: Spasi.lg,
              end: jumlah == null ? Spasi.lg : UkuranKontrol.saringanAkhir,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pilihan.label, maxLines: 1, softWrap: false),
                if (jumlah != null) ...[
                  const SizedBox(width: Spasi.sm),
                  _Bulatan(
                    jumlah: jumlah,
                    isi: bulatIsi,
                    tinta: bulatTinta,
                    gaya: gaya,
                    durasi: _durasi(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// (isi pil, tinta, isi bulatan, tinta bulatan) menurut keadaan.
  (Color, Color, Color, Color) _warna(BuildContext context, bool aktif) {
    final s = context.skema;
    if (!aktif) {
      final redup = s.onSurface.withValues(alpha: _alfaIsiMati);
      return (redup, s.onSurface.withValues(alpha: _alfaMati), redup,
          s.onSurface.withValues(alpha: _alfaMati));
    }
    if (terpilih) return (s.primary, s.onPrimary, s.secondary, s.onSecondary);
    final (tintaBulat, isiBulat) = pilihan.nada == null
        ? (s.onSurface, s.surfaceContainer)
        : StatusTampil.ubinDari(context, pilihan.nada!);
    return (s.surface, s.onSurface, isiBulat, tintaBulat);
  }

  /// Opasitas teks dan isi saat mati (pola Material 3: 38 % dan 12 %).
  static const double _alfaMati = 0.38;
  static const double _alfaIsiMati = 0.12;

  /// Perubahan warna 120 ms (`AppMotion.kilat`), nol bila "kurangi gerak".
  static Duration _durasi(BuildContext context) =>
      AppMotion.hormati(context, AppMotion.kilat);
}

/// Bulatan jumlah 32: tumbuh menjadi kapsul bila angkanya panjang (tiga digit
/// pada huruf 1,3x), tidak pernah meluap.
class _Bulatan extends StatelessWidget {
  const _Bulatan({
    required this.jumlah,
    required this.isi,
    required this.tinta,
    required this.gaya,
    required this.durasi,
  });

  final int jumlah;
  final Color isi;
  final Color tinta;
  final TextStyle? gaya;
  final Duration durasi;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: durasi,
      constraints: const BoxConstraints(
        minWidth: UkuranKontrol.jumlahSaringan,
        minHeight: UkuranKontrol.jumlahSaringan,
      ),
      decoration: BoxDecoration(color: isi, borderRadius: Bentuk.sudutPil),
      // Pusat yang membungkus anaknya (faktor 1): tanpa itu Center mengisi
      // seluruh tinggi yang ditawarkan baris dan bulatan menjadi lonjong.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spasi.xs),
          child: Text(
            '$jumlah',
            maxLines: 1,
            softWrap: false,
            style: gaya?.copyWith(color: tinta).tabular,
          ),
        ),
      ),
    );
  }
}
