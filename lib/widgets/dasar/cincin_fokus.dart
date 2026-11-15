import 'package:flutter/material.dart';

import '../../core/tema/bentuk.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';

/// Cincin fokus papan ketik: garis [UkuranFokus.tebal] di LUAR [child], dengan
/// celah [UkuranFokus.celah], jadi tidak menutupi isi dan tidak menggeser tata
/// letak (digambar di luar kotak anak; induk yang memotong anak, mis. daftar
/// bergulir, harus memberi ruang [UkuranFokus.jarakLuar]).
///
/// Muncul hanya bila ada anak yang berfokus DAN pengguna sedang memakai papan
/// ketik (mode sorot tradisional): ketukan jari tidak memunculkan cincin.
/// Warnanya `ColorScheme.primary`: navy di tema terang dan biru muda di gelap,
/// keduanya >= 3:1 terhadap halaman (dijaga `test/widgets/komponen_bento_test`).
///
/// [sudut] = sudut ISI yang dibungkus; cincin memakai sudut itu ditambah jarak
/// luarnya. Cincin tidak ikut pembaca layar dan tidak menangkap ketukan.
class CincinFokus extends StatefulWidget {
  const CincinFokus({super.key, required this.sudut, required this.child});

  final BorderRadius sudut;
  final Widget child;

  /// Kunci cincin, untuk tes.
  @visibleForTesting
  static const Key kunciCincin = ValueKey<String>('cincin-fokus');

  @override
  State<CincinFokus> createState() => _CincinFokusState();
}

class _CincinFokusState extends State<CincinFokus> {
  bool _berfokus = false;
  bool _papanKetik =
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_ubahMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_ubahMode);
    super.dispose();
  }

  void _ubahMode(FocusHighlightMode mode) {
    final papan = mode == FocusHighlightMode.traditional;
    if (mounted && papan != _papanKetik) setState(() => _papanKetik = papan);
  }

  void _ubahFokus(bool fokus) {
    if (mounted && fokus != _berfokus) setState(() => _berfokus = fokus);
  }

  @override
  Widget build(BuildContext context) {
    const luar = UkuranFokus.jarakLuar;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: _ubahFokus,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_berfokus && _papanKetik)
            Positioned(
              left: -luar,
              top: -luar,
              right: -luar,
              bottom: -luar,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    key: CincinFokus.kunciCincin,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.skema.primary,
                        width: UkuranFokus.tebal,
                      ),
                      borderRadius: widget.sudut + Bentuk.sudutKecil,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
