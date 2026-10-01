import 'package:flutter/material.dart';

import '../core/api_pelanggan.dart';
import '../core/theme/sidik_material.dart';
import '../models/permintaan.dart';
import 'sidik/sidik_tombol.dart';
import 'umum.dart';

/// Sheet "Isi nomor resi": kurir + nomor resi untuk alat yang dikirim sendiri
/// ke lab. Dipakai juga untuk mengganti resi yang salah ketik — server
/// mengizinkannya selama alat belum ditandai tiba.
///
/// Mengembalikan [Permintaan] terbaru dari server, atau `null` kalau ditutup.
Future<Permintaan?> tampilkanIsiResi(
  BuildContext context, {
  ResiPengiriman? awal,
  required Future<Permintaan> Function(String kurir, String nomorResi) kirim,
}) => showModalBottomSheet<Permintaan>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => LembarResi(awal: awal, kirim: kirim),
);

class LembarResi extends StatefulWidget {
  const LembarResi({super.key, this.awal, required this.kirim});

  final ResiPengiriman? awal;
  final Future<Permintaan> Function(String kurir, String nomorResi) kirim;

  @override
  State<LembarResi> createState() => _LembarResiState();
}

class _LembarResiState extends State<LembarResi> {
  late final _kurir = TextEditingController(text: widget.awal?.kurir);
  late final _nomor = TextEditingController(text: widget.awal?.nomor);
  Map<String, String> _galat = const {};
  String? _galatUmum;
  bool _sibuk = false;

  @override
  void dispose() {
    _kurir.dispose();
    _nomor.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final galat = <String, String>{
      if (_kurir.text.trim().isEmpty) 'kurir': 'Isi nama kurirnya.',
      if (_nomor.text.trim().isEmpty) 'nomor_resi': 'Isi nomor resinya.',
    };
    if (galat.isNotEmpty) {
      setState(() {
        _galat = galat;
        _galatUmum = null;
      });
      return;
    }
    setState(() {
      _sibuk = true;
      _galat = const {};
      _galatUmum = null;
    });
    final navigator = Navigator.of(context);
    try {
      final p = await widget.kirim(_kurir.text, _nomor.text);
      navigator.pop(p);
    } on GalatApi catch (e) {
      if (mounted) {
        setState(() {
          _galat = e.isian;
          // Galat keadaan (mis. alat sudah ditandai tiba) hanya `message`.
          _galatUmum = e.isian.isEmpty ? e.pesan : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _galatUmum = 'Nomor resi belum tersimpan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(jarak, 0, jarak, jarak),
          children: [
            Text(
              widget.awal == null ? 'Isi nomor resi' : 'Ubah nomor resi',
              style: t.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Supaya lab tahu alat Anda sedang dalam perjalanan dan bisa '
              'menyiapkan penerimaannya.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _kurir,
              enabled: !_sibuk,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Kurir',
                helperText: 'Mis. JNE, J&T, atau kurir internal perusahaan.',
                helperMaxLines: 2,
                errorText: _galat['kurir'],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nomor,
              enabled: !_sibuk,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Nomor resi',
                errorText: _galat['nomor_resi'],
              ),
            ),
            if (_galatUmum != null) ...[
              const SizedBox(height: 10),
              Text(_galatUmum!, style: TextStyle(color: m.gagal)),
            ],
            const SizedBox(height: 14),
            SidikTombol(
              label: 'Simpan nomor resi',
              ragam: RagamTombol.utama,
              penuh: true,
              sibuk: _sibuk,
              onPressed: _kirim,
            ),
          ],
        ),
      ),
    );
  }
}
