import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/permintaan.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/foto_pelat.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';
import 'permintaan_detail_screen.dart';

/// Satu alat baru beserta foto pelat namanya yang menunggu diunggah.
class KelompokFotoAlat {
  const KelompokFotoAlat({
    required this.itemId,
    required this.nama,
    required this.foto,
  });

  /// Id BARIS permintaan (`alat[].id`) — bukan id alat.
  final int itemId;
  final String nama;
  final List<Uint8List> foto;
}

/// Petakan alat baru yang DIKIRIM (urutan formulir) ke baris `alat[]` di
/// respons `POST /permintaan`: entri dengan `baru == true && alat_id == null`,
/// dalam urutan yang sama (kontrak §B3). Alat baru tanpa foto dilewati.
///
/// Kalau server mengembalikan lebih sedikit baris daripada yang dikirim,
/// sisanya dibuang — fotonya tetap bisa ditambah dari detail permintaan.
List<KelompokFotoAlat> petakanFotoAlatBaru(
  Permintaan p,
  List<AlatBaru> alatBaru,
) {
  final baris = p.alat.where((a) => a.baru && a.alatId == null).toList();
  return [
    for (var i = 0; i < alatBaru.length && i < baris.length; i++)
      if (alatBaru[i].foto.isNotEmpty)
        KelompokFotoAlat(
          itemId: baris[i].id,
          nama: alatBaru[i].namaAlat,
          foto: alatBaru[i].foto,
        ),
  ];
}

enum _Tahap { menunggu, unggah, ok, gagal }

class _Tugas {
  _Tugas(this.itemId, this.byte);

  final int itemId;
  final Uint8List byte;
  _Tahap tahap = _Tahap.menunggu;
  String? galat;
}

/// Layar sesudah "Kirim permintaan" bila ada foto pelat nama.
///
/// Permintaannya SUDAH terkirim — alat baru baru punya id setelah
/// `POST /permintaan`, jadi foto menyusul ke
/// `/permintaan/{id}/item/{item}/foto`. Foto yang gagal tidak membatalkan
/// apa pun: tiap foto bisa diulang sendiri di sini, atau nanti dari detail
/// permintaan.
class FotoSusulanScreen extends ConsumerStatefulWidget {
  const FotoSusulanScreen({
    super.key,
    required this.permintaan,
    required this.kelompok,
  });

  final Permintaan permintaan;
  final List<KelompokFotoAlat> kelompok;

  @override
  ConsumerState<FotoSusulanScreen> createState() => _FotoSusulanScreenState();
}

class _FotoSusulanScreenState extends ConsumerState<FotoSusulanScreen> {
  late final Map<int, List<_Tugas>> _tugas = {
    for (final k in widget.kelompok)
      k.itemId: [for (final b in k.foto) _Tugas(k.itemId, b)],
  };
  bool _berjalan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unggahSemua());
  }

  Iterable<_Tugas> get _semua => _tugas.values.expand((x) => x);

  /// Berurutan, bukan serempak: HP di jaringan lemah lebih andal dengan satu
  /// unggahan sekali jalan, dan urutan memudahkan membaca mana yang gagal.
  Future<void> _unggahSemua() async {
    if (_berjalan) return;
    setState(() => _berjalan = true);
    for (final t in _semua.where(
      (t) => t.tahap == _Tahap.menunggu || t.tahap == _Tahap.gagal,
    )) {
      if (!mounted) return;
      await _unggah(t);
    }
    if (mounted) setState(() => _berjalan = false);
  }

  Future<void> _unggah(_Tugas t) async {
    setState(() {
      t.tahap = _Tahap.unggah;
      t.galat = null;
    });
    try {
      await ref
          .read(layananProvider)
          .unggahFotoItem(widget.permintaan.id, t.itemId, t.byte);
      if (mounted) setState(() => t.tahap = _Tahap.ok);
    } on GalatApi catch (e) {
      if (mounted) {
        setState(() {
          t.tahap = _Tahap.gagal;
          t.galat = e.isian['foto'] ?? e.pesan;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          t.tahap = _Tahap.gagal;
          t.galat = 'Gagal mengunggah.';
        });
      }
    }
  }

  Future<void> _ulangi(_Tugas t) async {
    if (_berjalan) return;
    setState(() => _berjalan = true);
    await _unggah(t);
    if (mounted) setState(() => _berjalan = false);
  }

  void _lihat() => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => PermintaanDetailScreen(id: widget.permintaan.id),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);
    final gagal = _semua.where((x) => x.tahap == _Tahap.gagal).length;

    return PopScope(
      // Permintaannya sudah terkirim; tombol kembali membawa ke detail,
      // bukan ke formulir yang sudah tidak berlaku.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_berjalan) _lihat();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Permintaan terkirim'),
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
          children: [
            Kertas(
              warna: m.lulusTipis,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: m.lulus),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Permintaan ${widget.permintaan.nomor} sudah terkirim. '
                      'Tim lab akan meninjaunya.',
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const JudulSeksi('Foto pelat nama'),
            for (final k in widget.kelompok) ...[
              Text(k.nama, style: t.titleSmall),
              const SizedBox(height: 8),
              for (final tugas in _tugas[k.itemId]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      FotoMiniatur(byte: tugas.byte, sisi: 56),
                      const SizedBox(width: 12),
                      Expanded(child: _Status(tugas: tugas)),
                      if (tugas.tahap == _Tahap.gagal)
                        TextButton(
                          onPressed: _berjalan ? null : () => _ulangi(tugas),
                          child: const Text('Ulangi'),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
            if (gagal > 0 && !_berjalan)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '$gagal foto belum terunggah. Permintaannya tidak terpengaruh; '
                  'foto bisa diulang di sini atau ditambah lagi dari detail '
                  'permintaan.',
                  style: t.bodySmall,
                ),
              ),
            SidikTombol(
              label: 'Lihat permintaan',
              ragam: RagamTombol.utama,
              penuh: true,
              sibuk: _berjalan,
              onPressed: _lihat,
            ),
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.tugas});

  final _Tugas tugas;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);
    return switch (tugas.tahap) {
      _Tahap.menunggu => Text('Menunggu giliran', style: t.bodySmall),
      _Tahap.unggah => Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('Mengunggah…', style: t.bodySmall),
        ],
      ),
      _Tahap.ok => Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: m.lulus),
          const SizedBox(width: 6),
          Text('Terunggah', style: t.bodySmall),
        ],
      ),
      _Tahap.gagal => Text(
        'Gagal unggah${tugas.galat == null ? '' : ': ${tugas.galat}'}',
        style: t.bodySmall?.copyWith(color: m.gagal),
      ),
    };
  }
}
