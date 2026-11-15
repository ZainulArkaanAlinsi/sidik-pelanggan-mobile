import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Gerak Bento Lab (docs/desain-ulang/GERAK.md): hanya menandai "ini baru
/// datang" dan "ini yang kamu tekan". Tanpa denyut, kilau berulang, atau
/// pegas memantul. Semua durasi dari [AppMotion] (tidak ada durasi baru) dan
/// semuanya lewat [AppMotion.hormati]: "kurangi gerak" di sistem = langsung
/// keadaan akhir.
///
/// Dasar dari `docs/desain-ulang/flutter/gerak_bento.dart`; beda dari kerangka
/// itu: [MasukBerurutan] memakai `Interval` pada SATU pengendali (tanpa
/// `Timer`, jadi tidak ada pewaktu menggantung di tes dan tidak ada tundaan
/// yang lolos dari `dispose`), dan [AngkaNaik] menghitung SEKALI saja (nilai
/// baru dari penyegaran data tidak menganimasikan ulang).

/// Skala saat ditekan (GERAK.md: 1 → 0,97 → 1).
const double skalaTekan = 0.97;

/// Jarak geser naik ubin saat masuk layar (dp).
const double geserMasuk = 12;

/// Skala awal visual alat saat masuk (0,92 → 1).
const double skalaVisualAwal = 0.92;

/// Ubin/panel yang masuk layar: pudar + naik 12 dp, berurutan menurut
/// [indeks] (35 ms per indeks, paling lama 210 ms; `AppMotion.tunda`).
///
/// Berjalan SEKALI, saat pertama dibangun (bukan tiap `setState` atau tiap data
/// disegarkan). Daftar panjang: hanya enam butir pertama yang berurutan karena
/// tundaan dibatasi; sisanya praktis langsung tampil. Dengan "kurangi gerak"
/// anak langsung di keadaan akhir.
class MasukBerurutan extends StatefulWidget {
  const MasukBerurutan({super.key, required this.indeks, required this.child});

  final int indeks;
  final Widget child;

  @override
  State<MasukBerurutan> createState() => _MasukBerurutanState();
}

class _MasukBerurutanState extends State<MasukBerurutan>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Animation<double> _a = const AlwaysStoppedAnimation<double>(1);
  bool _mulai = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mulai) return;
    _mulai = true;
    final tunda = AppMotion.tunda(context, widget.indeks);
    final isi = AppMotion.hormati(context, AppMotion.sedang);
    if (isi == Duration.zero) {
      _c.value = 1;
      return;
    }
    final total = tunda + isi;
    _c.duration = total;
    _a = CurvedAnimation(
      parent: _c,
      curve: Interval(
        tunda.inMicroseconds / total.inMicroseconds,
        1,
        curve: AppMotion.masuk,
      ),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: AnimatedBuilder(
        animation: _a,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, geserMasuk * (1 - _a.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Umpan balik tekan: skala 0,97 selama ditekan (120 ms, `AppMotion.kilat`).
/// Bungkus di LUAR `InkWell`. [aktif] false (kontrol mati) = tidak ada umpan
/// balik. Tidak menangkap ketukan; `Listener` hanya mengamati.
class TekanSkala extends StatefulWidget {
  const TekanSkala({super.key, required this.child, this.aktif = true});

  final Widget child;
  final bool aktif;

  @override
  State<TekanSkala> createState() => _TekanSkalaState();
}

class _TekanSkalaState extends State<TekanSkala> {
  bool _tekan = false;

  void _atur(bool v) {
    if (_tekan != v && mounted) setState(() => _tekan = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.aktif ? (_) => _atur(true) : null,
      onPointerUp: (_) => _atur(false),
      onPointerCancel: (_) => _atur(false),
      child: AnimatedScale(
        scale: _tekan && widget.aktif ? skalaTekan : 1,
        duration: AppMotion.hormati(context, AppMotion.kilat),
        curve: AppMotion.masuk,
        child: widget.child,
      ),
    );
  }
}

/// Visual alat yang masuk: pudar + membesar 0,92 → 1, mulai setelah ubinnya
/// (tunda `AppMotion.sedang`). Sekali saja; "kurangi gerak" = langsung akhir.
class VisualMasuk extends StatefulWidget {
  const VisualMasuk({super.key, required this.child});

  final Widget child;

  @override
  State<VisualMasuk> createState() => _VisualMasukState();
}

class _VisualMasukState extends State<VisualMasuk>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Animation<double> _a = const AlwaysStoppedAnimation<double>(1);
  bool _mulai = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mulai) return;
    _mulai = true;
    final isi = AppMotion.hormati(context, AppMotion.sedang);
    if (isi == Duration.zero) {
      _c.value = 1;
      return;
    }
    final total = isi * 2;
    _c.duration = total;
    _a = CurvedAnimation(
      parent: _c,
      curve: Interval(0.5, 1, curve: AppMotion.masuk),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: ScaleTransition(
        scale: Tween<double>(begin: skalaVisualAwal, end: 1).animate(_a),
        child: widget.child,
      ),
    );
  }
}

/// Angka sorot yang menghitung naik SEKALI (0 → [nilai], `AppMotion.sedang`)
/// saat pertama dibangun. Nilai yang berubah sesudahnya (penyegaran data)
/// langsung tampil tanpa menghitung ulang. Pembaca layar membaca nilai akhir,
/// bukan hitungan antara.
class AngkaNaik extends StatefulWidget {
  const AngkaNaik({super.key, required this.nilai, this.style});

  final int nilai;
  final TextStyle? style;

  @override
  State<AngkaNaik> createState() => _AngkaNaikState();
}

class _AngkaNaikState extends State<AngkaNaik>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Animation<double> _a = const AlwaysStoppedAnimation<double>(1);
  bool _mulai = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mulai) return;
    _mulai = true;
    final isi = AppMotion.hormati(context, AppMotion.sedang);
    if (isi == Duration.zero) {
      _c.value = 1;
      return;
    }
    _c.duration = isi;
    _a = CurvedAnimation(parent: _c, curve: AppMotion.masuk);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.nilai}',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _a,
        builder: (context, _) => Text(
          '${(widget.nilai * _a.value).round()}',
          style: widget.style,
        ),
      ),
    );
  }
}
