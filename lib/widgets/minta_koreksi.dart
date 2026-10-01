import 'package:flutter/material.dart';

import '../core/api_pelanggan.dart';
import '../core/theme/sidik_material.dart';
import '../models/koreksi.dart';
import 'sidik/sidik_tombol.dart';
import 'umum.dart';

/// Satu isian yang boleh dikoreksi. [nilai] = yang TERCETAK / tersimpan
/// sekarang, jadi pelanggan melihat apa yang ia anggap salah.
class FieldKoreksi {
  const FieldKoreksi({
    required this.kunci,
    required this.label,
    this.nilai,
    this.angka = false,
  });

  /// Kunci yang dikirim ke server (`nomor_seri`, `serial_number`, …).
  final String kunci;
  final String label;
  final String? nilai;

  /// `true` → dikirim sebagai angka (koma desimal dibaca sebagai titik).
  final bool angka;
}

typedef KirimKoreksi =
    Future<Koreksi> Function(Map<String, Object?> perubahan, String? catatan);

/// Buka sheet "minta koreksi" dan kembalikan [Koreksi] yang terbuat, atau
/// `null` kalau ditutup. Dipakai sama oleh alat terkunci dan sertifikat:
/// bedanya cuma daftar isian dan fungsi [kirim].
Future<Koreksi?> tampilkanMintaKoreksi(
  BuildContext context, {
  required String judul,
  required String keterangan,
  required List<FieldKoreksi> field,
  required KirimKoreksi kirim,
}) => showModalBottomSheet<Koreksi>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => LembarMintaKoreksi(
    judul: judul,
    keterangan: keterangan,
    field: field,
    kirim: kirim,
  ),
);

class LembarMintaKoreksi extends StatefulWidget {
  const LembarMintaKoreksi({
    super.key,
    required this.judul,
    required this.keterangan,
    required this.field,
    required this.kirim,
  });

  final String judul;
  final String keterangan;
  final List<FieldKoreksi> field;
  final KirimKoreksi kirim;

  @override
  State<LembarMintaKoreksi> createState() => _LembarMintaKoreksiState();
}

class _LembarMintaKoreksiState extends State<LembarMintaKoreksi> {
  final Set<String> _dipilih = {};
  late final Map<String, TextEditingController> _isi = {
    for (final f in widget.field)
      f.kunci: TextEditingController(text: f.nilai ?? ''),
  };
  final _catatan = TextEditingController();
  Map<String, String> _galat = const {};
  String? _galatUmum;
  String? _galatCatatan;
  bool _sibuk = false;

  @override
  void dispose() {
    for (final c in _isi.values) {
      c.dispose();
    }
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final galat = <String, String>{};
    final perubahan = <String, Object?>{};
    if (_dipilih.isEmpty) {
      setState(() {
        _galat = const {};
        _galatCatatan = null;
        _galatUmum = 'Pilih dulu bagian yang salah.';
      });
      return;
    }
    for (final f in widget.field.where((f) => _dipilih.contains(f.kunci))) {
      final teks = _isi[f.kunci]!.text.trim();
      if (teks.isEmpty) {
        galat[f.kunci] = 'Isi nilai yang benar.';
      } else if (f.angka) {
        final n = double.tryParse(teks.replaceAll(',', '.'));
        if (n == null) {
          galat[f.kunci] = 'Isi dengan angka.';
        } else {
          perubahan[f.kunci] = n;
        }
      } else {
        perubahan[f.kunci] = teks;
      }
    }
    if (galat.isNotEmpty) {
      setState(() {
        _galat = galat;
        _galatCatatan = null;
        _galatUmum = null;
      });
      return;
    }

    setState(() {
      _sibuk = true;
      _galat = const {};
      _galatUmum = null;
      _galatCatatan = null;
    });
    final navigator = Navigator.of(context);
    try {
      final k = await widget.kirim(perubahan, _catatan.text);
      navigator.pop(k);
    } on GalatApi catch (e) {
      if (!mounted) return;
      // Galat validasi datang sebagai `perubahan.<kunci>`; galat keadaan
      // (sudah ada koreksi menunggu, sertifikat sudah digantikan) hanya
      // `message`.
      final g = <String, String>{};
      final lain = <String>[];
      String? catatan;
      for (final en in e.isian.entries) {
        final k = en.key.startsWith('perubahan.')
            ? en.key.substring('perubahan.'.length)
            : en.key;
        if (widget.field.any((f) => f.kunci == k)) {
          g[k] = en.value;
        } else if (k == 'catatan') {
          catatan = en.value;
        } else {
          lain.add(en.value);
        }
      }
      setState(() {
        _galat = g;
        _galatCatatan = catatan;
        _galatUmum = lain.isNotEmpty
            ? lain.join(' ')
            : (g.isEmpty && catatan == null ? e.pesan : null);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _galatUmum = 'Permintaan belum terkirim. Coba lagi.');
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
            Text(widget.judul, style: t.titleMedium),
            const SizedBox(height: 4),
            Text(widget.keterangan, style: t.bodySmall),
            const SizedBox(height: 8),
            for (final f in widget.field) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _dipilih.contains(f.kunci),
                onChanged: _sibuk
                    ? null
                    : (v) => setState(() {
                        if (v == true) {
                          _dipilih.add(f.kunci);
                        } else {
                          _dipilih.remove(f.kunci);
                        }
                      }),
                title: Text(f.label),
                subtitle: Text(
                  'Sekarang: ${(f.nilai == null || f.nilai!.isEmpty) ? '—' : f.nilai}',
                ),
              ),
              if (_dipilih.contains(f.kunci))
                Padding(
                  padding: const EdgeInsets.only(left: 40, bottom: 8),
                  child: TextField(
                    controller: _isi[f.kunci],
                    enabled: !_sibuk,
                    keyboardType: f.angka
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: '${f.label} yang benar',
                      errorText: _galat[f.kunci],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 4),
            TextField(
              controller: _catatan,
              enabled: !_sibuk,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Catatan untuk lab (opsional)',
                errorText: _galatCatatan,
              ),
            ),
            if (_galatUmum != null) ...[
              const SizedBox(height: 10),
              Text(_galatUmum!, style: TextStyle(color: m.gagal)),
            ],
            const SizedBox(height: 14),
            SidikTombol(
              label: 'Kirim ke lab',
              ikon: Icons.send_outlined,
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
