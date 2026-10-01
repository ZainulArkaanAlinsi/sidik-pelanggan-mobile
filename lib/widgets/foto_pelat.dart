import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_pelanggan.dart';
import '../core/theme/sidik_material.dart';
import '../models/data_pelanggan.dart';
import '../providers/data_provider.dart';
import '../providers/sesi_provider.dart';
import '../services/pemilih_foto.dart';

/// Foto pelat nama: petak-petak kecil + tombol tambah (maks. 3).
///
/// Dua varian, satu tampilan:
/// - [GridFotoPelat]  — pemiliknya SUDAH ada di server (alat, koreksi): tiap
///   foto langsung diunggah, bisa diulang sendiri kalau gagal, bisa diganti
///   atau dihapus.
/// - [GridFotoLokal]  — pemiliknya BELUM ada (alat baru di formulir ajukan):
///   foto cuma ditampung di HP, diunggah sesudah `POST /permintaan`.

const maksFotoPelat = 3;
const _sisiPetak = 92.0;

Future<SumberFoto?> pilihSumberFoto(BuildContext context) =>
    showModalBottomSheet<SumberFoto>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil dengan kamera'),
              onTap: () => Navigator.pop(c, SumberFoto.kamera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(c, SumberFoto.galeri),
            ),
          ],
        ),
      ),
    );

/// Tawarkan sumber, ambil + kompres. `null` = dibatalkan atau gagal (galat
/// sudah ditampilkan).
Future<Uint8List?> _ambil(BuildContext context, WidgetRef ref) async {
  final sumber = await pilihSumberFoto(context);
  if (sumber == null || !context.mounted) return null;
  final pesan = ScaffoldMessenger.of(context);
  try {
    return await ref.read(pemilihFotoProvider).ambil(sumber);
  } on FormatException catch (e) {
    pesan.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    pesan.showSnackBar(
      const SnackBar(
        content: Text('Foto tidak bisa diambil. Periksa izin kamera/galeri.'),
      ),
    );
  }
  return null;
}

/// Gambar satu foto: dari [byte] kalau ada, kalau tidak diunduh dari server
/// lewat [fotoByteProvider] (header Bearer + `X-Perusahaan-Id`).
class FotoMiniatur extends ConsumerWidget {
  const FotoMiniatur({super.key, this.id, this.byte, this.sisi = _sisiPetak});

  final int? id;
  final Uint8List? byte;
  final double sisi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = SidikMaterial.of(context);
    Widget isi;
    if (byte != null) {
      isi = Image.memory(byte!, fit: BoxFit.cover);
    } else if (id != null) {
      isi = ref
          .watch(fotoByteProvider(id!))
          .when(
            data: (b) => Image.memory(
              b,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Center(child: Icon(Icons.broken_image_outlined)),
            ),
            loading: () => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) =>
                const Center(child: Icon(Icons.broken_image_outlined)),
          );
    } else {
      isi = const SizedBox.shrink();
    }
    return Container(
      width: sisi,
      height: sisi,
      decoration: BoxDecoration(
        color: m.kertas2,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: isi,
    );
  }
}

/// Deretan foto yang hanya DITAMPILKAN (detail koreksi, detail permintaan).
/// Ketukan membuka foto penuh.
class DeretanFoto extends StatelessWidget {
  const DeretanFoto({super.key, required this.foto});

  final List<FotoPelanggan> foto;

  @override
  Widget build(BuildContext context) {
    if (foto.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final f in foto)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                child: InteractiveViewer(
                  child: Consumer(
                    builder: (context, ref, _) => ref
                        .watch(fotoByteProvider(f.id))
                        .when(
                          data: (b) => Image.memory(b),
                          loading: () => const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, _) => const Padding(
                            padding: EdgeInsets.all(48),
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                  ),
                ),
              ),
            ),
            child: FotoMiniatur(id: f.id),
          ),
      ],
    );
  }
}

class _Petak extends StatelessWidget {
  const _Petak({
    super.key,
    required this.anak,
    required this.onTap,
    this.lencana,
    this.label,
  });

  final Widget anak;
  final VoidCallback? onTap;
  final Widget? lencana;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Stack(
        children: [
          anak,
          if (lencana != null) Positioned.fill(child: Center(child: lencana!)),
        ],
      ),
    ),
  );
}

class _TombolTambah extends StatelessWidget {
  const _TombolTambah({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: _sisiPetak,
        height: _sisiPetak,
        decoration: BoxDecoration(
          border: Border.all(color: m.tinta2.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined),
            const SizedBox(height: 4),
            Text('Tambah', style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ── Varian lokal ─────────────────────────────────────────────────────────

class GridFotoLokal extends ConsumerWidget {
  const GridFotoLokal({super.key, required this.foto, required this.onBerubah});

  final List<Uint8List> foto;
  final ValueChanged<List<Uint8List>> onBerubah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;

    Future<void> tambah() async {
      final b = await _ambil(context, ref);
      if (b != null) onBerubah([...foto, b]);
    }

    Future<void> ketuk(int i) async {
      final pilih = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (c) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Ganti foto'),
                onTap: () => Navigator.pop(c, 'ganti'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Hapus foto'),
                onTap: () => Navigator.pop(c, 'hapus'),
              ),
            ],
          ),
        ),
      );
      if (pilih == 'hapus') {
        onBerubah([...foto]..removeAt(i));
      } else if (pilih == 'ganti' && context.mounted) {
        final b = await _ambil(context, ref);
        if (b != null) onBerubah([...foto]..[i] = b);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < foto.length; i++)
              _Petak(
                label: 'Foto ${i + 1}, ketuk untuk ganti atau hapus',
                onTap: () => ketuk(i),
                anak: FotoMiniatur(byte: foto[i]),
              ),
            if (foto.length < maksFotoPelat) _TombolTambah(onTap: tambah),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Foto pelat nama ${foto.length} dari $maksFotoPelat. Ketuk foto untuk '
          'ganti atau hapus. Lokasi GPS di foto dihapus otomatis.',
          style: t.bodySmall,
        ),
      ],
    );
  }
}

// ── Varian server ────────────────────────────────────────────────────────

enum _Tahap { ok, unggah, gagal }

class _Slot {
  _Slot({this.foto, this.byte, this.tahap = _Tahap.ok});

  FotoPelanggan? foto;
  Uint8List? byte;
  _Tahap tahap;
  String? galat;
  final kunci = UniqueKey();
}

class GridFotoPelat extends ConsumerStatefulWidget {
  const GridFotoPelat({
    super.key,
    required this.awal,
    required this.unggah,
    this.onBerubah,
    this.bisaUbah = true,
  });

  final List<FotoPelanggan> awal;

  /// Unggah satu foto ke pemiliknya (alat / koreksi).
  final Future<FotoPelanggan> Function(Uint8List byte) unggah;

  /// Dipanggil sesudah ada foto yang bertambah atau hilang — pemanggil
  /// menyegarkan datanya.
  final VoidCallback? onBerubah;

  /// `false` (mis. koreksi sudah diputus) → hanya tampil.
  final bool bisaUbah;

  @override
  ConsumerState<GridFotoPelat> createState() => _GridFotoPelatState();
}

class _GridFotoPelatState extends ConsumerState<GridFotoPelat> {
  late final List<_Slot> _slot = [for (final f in widget.awal) _Slot(foto: f)];

  Future<void> _kirim(_Slot s) async {
    setState(() {
      s.tahap = _Tahap.unggah;
      s.galat = null;
    });
    try {
      s.foto = await widget.unggah(s.byte!);
      if (mounted) setState(() => s.tahap = _Tahap.ok);
      widget.onBerubah?.call();
    } on GalatApi catch (e) {
      if (mounted) {
        setState(() {
          s.tahap = _Tahap.gagal;
          s.galat = e.isian['foto'] ?? e.pesan;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          s.tahap = _Tahap.gagal;
          s.galat = 'Gagal mengunggah.';
        });
      }
    }
  }

  Future<void> _tambah() async {
    final b = await _ambil(context, ref);
    if (b == null || !mounted) return;
    final s = _Slot(byte: b, tahap: _Tahap.unggah);
    setState(() => _slot.add(s));
    await _kirim(s);
  }

  Future<bool> _hapusDiServer(_Slot s) async {
    final id = s.foto?.id;
    if (id == null) return true;
    final pesan = ScaffoldMessenger.of(context);
    try {
      await ref.read(layananProvider).hapusFoto(id);
      widget.onBerubah?.call();
      return true;
    } on GalatApi catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(e.pesan)));
    } catch (_) {
      pesan.showSnackBar(
        const SnackBar(content: Text('Foto belum terhapus. Coba lagi.')),
      );
    }
    return false;
  }

  Future<void> _hapus(_Slot s) async {
    if (!await _hapusDiServer(s) || !mounted) return;
    setState(() => _slot.remove(s));
  }

  /// Hapus yang lama DULU, baru unggah yang baru: batas 3 foto dihitung
  /// server, jadi mengunggah dulu akan ditolak kalau sudah penuh.
  Future<void> _ganti(_Slot s) async {
    final b = await _ambil(context, ref);
    if (b == null || !mounted) return;
    if (!await _hapusDiServer(s) || !mounted) return;
    setState(() {
      s.foto = null;
      s.byte = b;
    });
    await _kirim(s);
  }

  Future<void> _ketuk(_Slot s) async {
    if (!widget.bisaUbah || s.tahap == _Tahap.unggah) return;
    final gagal = s.tahap == _Tahap.gagal;
    final pilih = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (gagal)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Ulangi unggah'),
                subtitle: s.galat == null ? null : Text(s.galat!),
                onTap: () => Navigator.pop(c, 'ulang'),
              )
            else
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Ganti foto'),
                onTap: () => Navigator.pop(c, 'ganti'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(gagal ? 'Buang foto ini' : 'Hapus foto'),
              onTap: () => Navigator.pop(c, 'hapus'),
            ),
          ],
        ),
      ),
    );
    switch (pilih) {
      case 'ulang':
        await _kirim(s);
      case 'ganti':
        await _ganti(s);
      case 'hapus':
        await _hapus(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    final jumlah = _slot.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in _slot)
              _Petak(
                key: s.kunci,
                label: switch (s.tahap) {
                  _Tahap.gagal => 'Foto gagal diunggah, ketuk untuk mengulang',
                  _Tahap.unggah => 'Foto sedang diunggah',
                  _Tahap.ok => 'Foto pelat nama, ketuk untuk ganti atau hapus',
                },
                onTap: () => _ketuk(s),
                lencana: switch (s.tahap) {
                  _Tahap.unggah => const CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                  _Tahap.gagal => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: m.gagal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ulangi',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  _Tahap.ok => null,
                },
                anak: FotoMiniatur(id: s.foto?.id, byte: s.byte),
              ),
            if (widget.bisaUbah && jumlah < maksFotoPelat)
              _TombolTambah(onTap: _tambah),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.bisaUbah
              ? 'Foto pelat nama $jumlah dari $maksFotoPelat. Ketuk foto untuk '
                    'ganti atau hapus. Lokasi GPS di foto dihapus otomatis.'
              : 'Foto pelat nama $jumlah dari $maksFotoPelat.',
          style: t.bodySmall,
        ),
      ],
    );
  }
}
