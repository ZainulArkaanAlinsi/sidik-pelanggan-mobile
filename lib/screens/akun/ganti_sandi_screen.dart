import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/tombol_sidik.dart';

/// Panjang minimum sandi baru — sama dengan aturan server (`Password::min(10)`).
const panjangSandiMinimum = 10;

/// Ganti sandi sendiri (`POST /saya/ganti-sandi`). Sesi di HP ini tetap hidup;
/// sesi di perangkat lain diakhiri server. Kalau lupa sandi lama, jalurnya
/// "Lupa sandi?" di layar Masuk (lewat kode email), bukan layar ini.
///
/// Sandi hanya hidup di kolom isian; tidak disimpan, tidak dicatat, dan
/// dibersihkan begitu layar ditutup.
class GantiSandiScreen extends ConsumerStatefulWidget {
  const GantiSandiScreen({super.key});

  @override
  ConsumerState<GantiSandiScreen> createState() => _GantiSandiScreenState();
}

class _GantiSandiScreenState extends ConsumerState<GantiSandiScreen> {
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _ulang = TextEditingController();
  bool _sibuk = false;
  String? _galat;
  Map<String, String> _galatIsian = const {};

  @override
  void initState() {
    super.initState();
    for (final c in [_lama, _baru, _ulang]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_lama, _baru, _ulang]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _lengkap =>
      _lama.text.isNotEmpty && _baru.text.isNotEmpty && _ulang.text.isNotEmpty;

  /// Pemeriksaan yang tidak perlu ke server. `null` = lolos.
  Map<String, String> _periksaLokal() => {
    if (_baru.text.length < panjangSandiMinimum)
      'sandi': 'Minimal $panjangSandiMinimum karakter.',
    if (_ulang.text != _baru.text) 'ulang': 'Sandi baru tidak sama.',
  };

  Future<void> _simpan() async {
    final lokal = _periksaLokal();
    if (lokal.isNotEmpty) {
      setState(() {
        _galat = null;
        _galatIsian = lokal;
      });
      return;
    }
    setState(() {
      _sibuk = true;
      _galat = null;
      _galatIsian = const {};
    });
    final pesan = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final dicabut = await ref
          .read(layananProvider)
          .gantiSandi(sandiLama: _lama.text, sandiBaru: _baru.text);
      pesan.showSnackBar(
        SnackBar(
          content: Text(
            dicabut > 0
                ? 'Sandi diganti. $dicabut sesi di perangkat lain diakhiri.'
                : 'Sandi diganti.',
          ),
        ),
      );
      // Layar bisa sudah ditutup selagi permintaan jalan.
      if (mounted) navigator.pop();
    } on GalatApi catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.kode == 'sandi_lama_salah') {
          _galatIsian = {'sandi_lama': e.pesan};
        } else if (e.isian.isNotEmpty) {
          _galatIsian = {
            'sandi_lama': ?e.isian['sandi_lama'],
            'sandi': ?e.isian['sandi'],
          };
          if (_galatIsian.isEmpty) _galat = e.pesan;
        } else {
          _galat = e.pesan;
        }
      });
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Widget _isian(
    TextEditingController c,
    String label,
    String kunci, {
    String? bantuan,
    List<String> petunjuk = const [],
  }) => Padding(
    padding: const EdgeInsets.only(bottom: Spasi.lg),
    child: TextField(
      controller: c,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: petunjuk,
      decoration: InputDecoration(
        labelText: label,
        helperText: bantuan,
        errorText: _galatIsian[kunci],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return HalamanSidik(
      judul: 'Ganti sandi',
      latarPutih: true,
      isi: ListView(
        padding: Spasi.denganTepiBawah(context, const EdgeInsets.all(Spasi.xl)),
        children: [
          Text(
            'Sesi Anda di HP ini tetap berjalan. Sesi di perangkat lain '
            'berakhir, jadi di sana Anda perlu masuk lagi dengan sandi baru.',
            style: context.teks.bodyMedium?.copyWith(
              color: context.skema.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spasi.xl),
          _isian(
            _lama,
            'Sandi saat ini',
            'sandi_lama',
            petunjuk: const [AutofillHints.password],
          ),
          _isian(
            _baru,
            'Sandi baru',
            'sandi',
            bantuan: 'Minimal $panjangSandiMinimum karakter',
            petunjuk: const [AutofillHints.newPassword],
          ),
          _isian(
            _ulang,
            'Ulangi sandi baru',
            'ulang',
            petunjuk: const [AutofillHints.newPassword],
          ),
          if (_galat != null) ...[
            Text(_galat!, style: TextStyle(color: context.skema.error)),
            const SizedBox(height: Spasi.md),
          ],
          TombolSidik(
            label: 'Simpan sandi baru',
            ragam: RagamTombol.utama,
            penuh: true,
            sibuk: _sibuk,
            onPressed: _lengkap ? _simpan : null,
          ),
        ],
      ),
    );
  }
}
