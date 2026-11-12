import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pdfx/pdfx.dart';

/// Kendali penampil PDF yang dipegang layar pratinjau: halaman, jumlah
/// halaman, dan tiga aksi (pindah halaman, perbesar/perkecil). Dipisah dari
/// plugin supaya layar dan tes tidak bergantung pada `pdfx`; penampil sungguhan
/// ([bangunPenampilPdfx]) mengisi dan memasang aksinya.
class KontrolPenampilPdf extends ChangeNotifier {
  int _halaman = 1;
  int _jumlah = 0;
  Object? _galat;
  bool _dibuang = false;

  Future<void> Function(int halaman)? _keHalaman;
  void Function(double faktor)? _zoom;
  Object? _pemilikAksi;

  /// Halaman yang sedang terlihat (mulai 1).
  int get halaman => _halaman;

  /// 0 sampai dokumen selesai dibuka.
  int get jumlahHalaman => _jumlah;

  bool get siap => _jumlah > 0 && _galat == null;

  /// Galat membuka/menampilkan PDF; `null` = baik-baik saja.
  Object? get galat => _galat;

  bool get adaSebelumnya => siap && _halaman > 1;
  bool get adaBerikutnya => siap && _halaman < _jumlah;

  // ── Diisi penampil ───────────────────────────────────────────────────

  void dokumenSiap(int jumlah, {int halaman = 1}) {
    _jumlah = jumlah;
    _halaman = halaman.clamp(1, jumlah < 1 ? 1 : jumlah);
    _galat = null;
    _kabari();
  }

  void halamanBerganti(int halaman) {
    if (halaman == _halaman) return;
    _halaman = halaman;
    _kabari();
  }

  void dokumenGagal(Object galat) {
    _galat = galat;
    _kabari();
  }

  /// [pemilik] = penampil yang memasang. Saat putar, penampil baru memasang
  /// aksinya SEBELUM yang lama dibuang; [lepasAksi] hanya berlaku untuk
  /// pemiliknya supaya aksi yang baru tidak ikut terhapus.
  void pasangAksi(
    Object pemilik, {
    required Future<void> Function(int halaman) keHalaman,
    required void Function(double faktor) zoom,
  }) {
    _pemilikAksi = pemilik;
    _keHalaman = keHalaman;
    _zoom = zoom;
  }

  void lepasAksi(Object pemilik) {
    if (!identical(_pemilikAksi, pemilik)) return;
    _pemilikAksi = null;
    _keHalaman = null;
    _zoom = null;
  }

  // ── Dipakai layar ────────────────────────────────────────────────────

  Future<void> keHalaman(int halaman) async {
    if (!siap || halaman < 1 || halaman > _jumlah) return;
    await _keHalaman?.call(halaman);
  }

  Future<void> berikutnya() => keHalaman(_halaman + 1);

  Future<void> sebelumnya() => keHalaman(_halaman - 1);

  /// Satu ketukan = skala dikali (atau dibagi) [zoomLangkah].
  void perbesar() => _zoom?.call(zoomLangkah);

  void perkecil() => _zoom?.call(1 / zoomLangkah);

  static const zoomLangkah = 1.5;

  @override
  void dispose() {
    _dibuang = true;
    super.dispose();
  }

  /// Penampil mengabari dari callback plugin, yang bisa jatuh di tengah fase
  /// bangun; `notifyListeners` saat itu membuat `setState` di tengah build.
  void _kabari() {
    // Plugin bisa memanggil balik sesudah layarnya ditutup.
    if (_dibuang) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_dibuang && hasListeners) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }
}

/// Masukan pembangun penampil. [putaran] = kelipatan 90° searah jarum jam.
typedef ArgumenPenampilPdf = ({
  String path,
  int putaran,
  KontrolPenampilPdf kontrol,
});

/// Pembangun penampil PDF; bawaannya [bangunPenampilPdfx]. Tes memasang
/// pembangun palsu lewat `penampilPdfProvider`.
typedef PembangunPenampilPdf =
    Widget Function(BuildContext context, ArgumenPenampilPdf arg);

/// Penampil sungguhan di atas `pdfx` (`PdfViewPinch`): cubit untuk zoom,
/// seret untuk menggeser, halaman bergulir menurun. Halaman dirender ulang
/// pada ukuran sebenarnya saat diperbesar, jadi huruf kecil di tabel hasil
/// tetap tajam.
///
/// Putar = `RotatedBox` di sekeliling penampil. Setiap putaran membangun
/// penampil baru (kunci = putaran) dan membuka dokumen sekali lagi dari
/// berkas lokal di halaman yang sedang dibaca: lebih sederhana dan lebih tahan
/// salah daripada mengutak-atik matriks tampilan yang sedang berjalan.
Widget bangunPenampilPdfx(BuildContext context, ArgumenPenampilPdf arg) =>
    _PenampilPdfx(
      key: ValueKey('pdf-${arg.path}-${arg.putaran}'),
      path: arg.path,
      putaran: arg.putaran,
      kontrol: arg.kontrol,
    );

class _PenampilPdfx extends StatefulWidget {
  const _PenampilPdfx({
    super.key,
    required this.path,
    required this.putaran,
    required this.kontrol,
  });

  final String path;
  final int putaran;
  final KontrolPenampilPdf kontrol;

  @override
  State<_PenampilPdfx> createState() => _PenampilPdfxState();
}

class _PenampilPdfxState extends State<_PenampilPdfx> {
  late final Future<PdfDocument> _dokumen;
  late final PdfControllerPinch _pengendali;
  Size _ukuranIsi = Size.zero;

  @override
  void initState() {
    super.initState();
    _dokumen = PdfDocument.openFile(widget.path);
    _pengendali = PdfControllerPinch(
      document: _dokumen,
      initialPage: widget.kontrol.halaman < 1 ? 1 : widget.kontrol.halaman,
    );
    widget.kontrol.pasangAksi(this, keHalaman: _keHalaman, zoom: _zoom);
  }

  @override
  void dispose() {
    widget.kontrol.lepasAksi(this);
    _pengendali.dispose();
    // Berkas ditutup SESUDAH tekstur halaman dilepas.
    unawaited(
      _dokumen.then((d) => d.close()).then<void>((_) {}, onError: (_) {}),
    );
    super.dispose();
  }

  Future<void> _keHalaman(int halaman) => _pengendali.animateToPage(
    pageNumber: halaman,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeInOut,
  );

  /// Perbesar/perkecil terhadap titik tengah layar. Skala dijaga 1×–6×; di 1×
  /// halaman kembali selebar layar (geser mendatar dinolkan).
  void _zoom(double faktor) {
    final m = _pengendali.value;
    final sekarang = m.getMaxScaleOnAxis();
    final baru = (sekarang * faktor).clamp(1.0, 6.0);
    if ((baru - sekarang).abs() < 1e-3 || _ukuranIsi.isEmpty) return;
    final k = baru / sekarang;
    final tx = _ukuranIsi.width / 2;
    final ty = _ukuranIsi.height / 2;
    final tujuan =
        Matrix4.translationValues(tx, ty, 0) *
        Matrix4.diagonal3Values(k, k, 1) *
        Matrix4.translationValues(-tx, -ty, 0) *
        m;
    if (baru <= 1.001) tujuan.setEntry(0, 3, 0);
    unawaited(_pengendali.goTo(destination: tujuan));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        // Penampil di dalam RotatedBox melihat ukuran yang ditukar.
        _ukuranIsi = widget.putaran.isOdd
            ? Size(c.maxHeight, c.maxWidth)
            : c.biggest;
        return SizedBox.expand(
          child: RotatedBox(
            quarterTurns: widget.putaran,
            child: PdfViewPinch(
              controller: _pengendali,
              padding: 8,
              maxScale: 6,
              backgroundDecoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              onDocumentLoaded: (d) => widget.kontrol.dokumenSiap(
                d.pagesCount,
                halaman: widget.kontrol.halaman,
              ),
              onPageChanged: widget.kontrol.halamanBerganti,
              onDocumentError: widget.kontrol.dokumenGagal,
              builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                pageLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                // Galatnya ditampilkan layar pratinjau sendiri (pesan
                // berbahasa Indonesia + jalan keluar), bukan teks plugin.
                errorBuilder: (_, _) => ColoredBox(color: tema.canvasColor),
              ),
            ),
          ),
        );
      },
    );
  }
}
