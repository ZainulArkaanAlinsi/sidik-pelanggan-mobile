import 'package:flutter/material.dart';

import '../core/tema/elevasi.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';

/// Satu pilihan pada [SaringanTeks]: kata dan, bila ada, jumlahnya.
@immutable
class PilihanSaringan {
  const PilihanSaringan(this.label, {this.jumlah});

  final String label;
  final int? jumlah;

  String get semantik => jumlah == null ? label : '$label, $jumlah';
}

/// Saringan berupa deretan kata + jumlah (pengganti deretan `ChoiceChip` yang
/// terpotong di tepi layar). Terpilih = tebal (700) + garis bawah kobalt 3 dp +
/// `selected` untuk pembaca layar, jadi pilihan tidak hanya dibedakan warna.
/// Juga dipakai sebagai "Daftar | Arsip".
///
/// TIDAK ADA pilihan yang terpotong: tiap kata digambar utuh satu baris (tanpa
/// elipsis), tiap pilihan setinggi bilah 52 dp (lebih dari 48; ikut skala
/// huruf), dan pilihan terpilih digulirkan seminimal mungkin ke dalam layar
/// bila belum terlihat utuh. Hanya bila deretan melebihi lebar, tepi yang
/// masih menyimpan pilihan memudar (`ShaderMask` sebagai topeng, bukan gradien
/// dekoratif) sebagai petunjuk bahwa masih ada yang bisa digeser; bila semua
/// muat (tablet), tidak ada pemudaran.
class SaringanTeks extends StatefulWidget {
  const SaringanTeks({
    super.key,
    required this.pilihan,
    required this.terpilih,
    this.onPilih,
  });

  final List<PilihanSaringan> pilihan;
  final int terpilih;
  final ValueChanged<int>? onPilih;

  @override
  State<SaringanTeks> createState() => _SaringanTeksState();
}

class _SaringanTeksState extends State<SaringanTeks> {
  final _kontrol = ScrollController();

  /// Sisa gulir sekecil ini (dp) dianggap sudah di ujung.
  static const double _toleransi = 0.5;

  List<GlobalKey> _kunci = const [];
  bool _adaLanjut = false;
  bool _adaSebelum = false;

  /// Masih ada pilihan di kanan yang bisa digeser (pemudaran tepi kanan aktif).
  @visibleForTesting
  bool get adaLanjut => _adaLanjut;

  /// Sudah tergulir: ada pilihan di kiri yang tertutup (pemudaran tepi kiri).
  @visibleForTesting
  bool get adaSebelum => _adaSebelum;

  @override
  void initState() {
    super.initState();
    _kontrol.addListener(_perbarui);
    _sinkronKunci();
    _sesudahFrame(() {
      _gulirKeTerpilih();
      _perbarui();
    });
  }

  @override
  void didUpdateWidget(SaringanTeks lama) {
    super.didUpdateWidget(lama);
    _sinkronKunci();
    if (lama.terpilih != widget.terpilih ||
        lama.pilihan.length != widget.pilihan.length) {
      _sesudahFrame(_gulirKeTerpilih);
    }
    _sesudahFrame(_perbarui);
  }

  @override
  void dispose() {
    _kontrol
      ..removeListener(_perbarui)
      ..dispose();
    super.dispose();
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

  void _perbarui() {
    if (!_kontrol.hasClients) return;
    final lanjut = _kontrol.position.extentAfter > _toleransi;
    final sebelum = _kontrol.position.extentBefore > _toleransi;
    if (lanjut != _adaLanjut || sebelum != _adaSebelum) {
      setState(() {
        _adaLanjut = lanjut;
        _adaSebelum = sebelum;
      });
    }
  }

  void _gulirKeTerpilih() {
    final i = widget.terpilih;
    if (i < 0 || i >= _kunci.length) return;
    final konteks = _kunci[i].currentContext;
    if (konteks == null) return;
    // Gulir seminimal mungkin: yang sudah terlihat utuh tidak digeser.
    Scrollable.ensureVisible(
      konteks,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      duration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final tinggi = MediaQuery.textScalerOf(
      context,
    ).scale(AreaSentuh.minimum + Spasi.xs);

    Widget butir(int i) {
      final p = widget.pilihan[i];
      final dipilih = i == widget.terpilih;
      return Semantics(
        key: _kunci[i],
        button: widget.onPilih != null,
        selected: dipilih,
        onTap: widget.onPilih == null ? null : () => widget.onPilih!(i),
        label: p.semantik,
        excludeSemantics: true,
        child: InkWell(
          onTap: widget.onPilih == null ? null : () => widget.onPilih!(i),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: AreaSentuh.minimum),
            child: Padding(
              padding: const EdgeInsets.only(right: Spasi.xl),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: dipilih ? s.primary : Colors.transparent,
                        width: UkuranTik.garisBawah,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Spasi.md),
                    child: Text.rich(
                      TextSpan(
                        text: p.label,
                        children: [
                          if (p.jumlah != null)
                            TextSpan(
                              text: '  ${p.jumlah}',
                              style: t.bodyMedium?.tabular,
                            ),
                        ],
                      ),
                      maxLines: 1,
                      softWrap: false,
                      style: t.bodyLarge?.copyWith(
                        fontWeight: dipilih ? FontWeight.w700 : FontWeight.w500,
                        color: dipilih ? s.onSurface : s.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Topeng SELALU terpasang (pohon tetap sama, posisi gulir tidak hilang);
    // hanya ujung kanannya yang memudar, dan hanya bila masih ada yang bisa
    // digeser.
    final daftar = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => LinearGradient(
        colors: [
          _adaSebelum ? s.surface.withValues(alpha: 0) : s.surface,
          s.surface,
          s.surface,
          _adaLanjut ? s.surface.withValues(alpha: 0) : s.surface,
        ],
        stops: const [0, 0.1, 0.9, 1],
      ).createShader(r),
      child: SizedBox(
        height: tinggi,
        // Semua pilihan dibangun (jumlahnya satu digit): pilihan terpilih
        // yang jauh di kanan tetap punya konteks untuk digulirkan ke dalam.
        child: SingleChildScrollView(
          controller: _kontrol,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: Spasi.sisi),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < widget.pilihan.length; i++) butir(i),
            ],
          ),
        ),
      ),
    );

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _sesudahFrame(_perbarui);
        return false;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: s.outlineVariant, width: Elevasi.garis),
          ),
        ),
        child: daftar,
      ),
    );
  }
}
