import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/foto_pelat.dart';
import '../../widgets/minta_koreksi.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';
import '../koreksi/koreksi_detail_screen.dart';

/// Ubah alat (PL_Ubah_Alat).
///
/// - Alat BELUM punya sertifikat terbit: identitas boleh disunting lewat
///   `PATCH /alat/{id}` yang sama dengan lokasi & catatan.
/// - Alat TERKUNCI (`terkunci`): identitas dibaca saja, karena sudah tercetak
///   di sertifikat. Yang salah dikoreksi lewat lab (`minta-koreksi`). Lokasi,
///   catatan, dan foto tetap bisa diubah.
///
/// Terkunci atau tidak adalah keputusan server; kalau keadaannya berubah
/// selagi layar terbuka (sertifikat baru terbit), server menjawab 422
/// `field_terkunci` dan layar menarik ulang alatnya.
class UbahAlatScreen extends ConsumerWidget {
  const UbahAlatScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detailAlatProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text('Ubah ${async.value?.nama ?? 'alat'}')),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const Memuat(),
        error: (e, _) => KeadaanGalat(
          galat: e,
          cobaLagi: () => ref.invalidate(detailAlatProvider(id)),
        ),
        data: (a) => FormUbahAlat(alat: a),
      ),
    );
  }
}

/// Kunci identitas → label, dalam urutan tampil (sama dengan `field_terkunci`
/// di kontrak §B2).
const labelIdentitasAlat = <String, String>{
  'nama_alat': 'Nama alat',
  'merk': 'Merk',
  'model': 'Model',
  'serial_number': 'Nomor seri',
  'no_identifikasi': 'No. identifikasi',
  'range_min': 'Rentang min.',
  'range_max': 'Rentang maks.',
  'satuan': 'Satuan',
  'resolusi': 'Resolusi',
};

const _angka = {'range_min', 'range_max', 'resolusi'};

class FormUbahAlat extends ConsumerStatefulWidget {
  const FormUbahAlat({super.key, required this.alat});

  final Alat alat;

  @override
  ConsumerState<FormUbahAlat> createState() => _FormUbahAlatState();
}

class _FormUbahAlatState extends ConsumerState<FormUbahAlat> {
  late final Map<String, TextEditingController> _identitas = {
    for (final k in labelIdentitasAlat.keys)
      k: TextEditingController(text: _nilaiAwal(k) ?? ''),
  };
  late final _lokasi = TextEditingController(text: widget.alat.lokasi ?? '');
  late final _catatan = TextEditingController(text: widget.alat.catatan ?? '');

  Map<String, String> _galat = const {};
  String? _galatUmum;
  bool _sibuk = false;

  Alat get _a => widget.alat;

  String? _nilaiAwal(String kunci, [Alat? alat]) {
    final a = alat ?? widget.alat;
    return switch (kunci) {
      'nama_alat' => a.nama,
      'merk' => a.merk,
      'model' => a.model,
      'serial_number' => a.serial,
      'no_identifikasi' => a.noIdentifikasi,
      'range_min' => a.rentangMin,
      'range_max' => a.rentangMaks,
      'satuan' => a.satuan,
      'resolusi' => a.resolusi,
      _ => null,
    };
  }

  @override
  void dispose() {
    for (final c in _identitas.values) {
      c.dispose();
    }
    _lokasi.dispose();
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final badan = <String, Object?>{};
    final galat = <String, String>{};

    void teksBerubah(String kunci, String awal, String sekarang) {
      if (sekarang.trim() != awal.trim()) {
        badan[kunci] = sekarang.trim().isEmpty ? null : sekarang.trim();
      }
    }

    teksBerubah('lokasi', _a.lokasi ?? '', _lokasi.text);
    teksBerubah('catatan', _a.catatan ?? '', _catatan.text);

    if (!_a.terkunci) {
      for (final e in _identitas.entries) {
        final awal = _nilaiAwal(e.key) ?? '';
        final sekarang = e.value.text.trim();
        if (sekarang == awal.trim()) continue;
        if (e.key == 'nama_alat' && sekarang.isEmpty) {
          galat[e.key] = 'Nama alat wajib diisi.';
        } else if (_angka.contains(e.key)) {
          if (sekarang.isEmpty) {
            badan[e.key] = null;
          } else {
            final n = double.tryParse(sekarang.replaceAll(',', '.'));
            if (n == null) {
              galat[e.key] = 'Isi dengan angka.';
            } else {
              badan[e.key] = n;
            }
          }
        } else {
          badan[e.key] = sekarang.isEmpty ? null : sekarang;
        }
      }
    }

    if (galat.isNotEmpty) {
      setState(() {
        _galat = galat;
        _galatUmum = null;
      });
      return;
    }
    if (badan.isEmpty) {
      setState(() {
        _galat = const {};
        _galatUmum = 'Belum ada yang diubah.';
      });
      return;
    }

    setState(() {
      _sibuk = true;
      _galat = const {};
      _galatUmum = null;
    });
    final pesan = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(layananProvider).ubahAlat(_a.id, badan);
      ref.invalidate(detailAlatProvider(_a.id));
      ref.invalidate(daftarAlatProvider);
      pesan.showSnackBar(const SnackBar(content: Text('Perubahan tersimpan.')));
      navigator.pop();
    } on GalatApi catch (e) {
      if (!mounted) return;
      if (e.kode == 'field_terkunci') {
        // Sertifikat terbit sejak layar ini dibuka: ambil keadaan terbaru
        // supaya identitasnya tampil terkunci.
        ref.invalidate(detailAlatProvider(_a.id));
      }
      setState(() {
        _galat = e.isian;
        _galatUmum = e.kode == 'field_terkunci' || e.isian.isEmpty
            ? e.pesan
            : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _galatUmum = 'Perubahan belum tersimpan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _mintaKoreksi() async {
    final kunci = _a.fieldTerkunci.isEmpty
        ? labelIdentitasAlat.keys.toList()
        : _a.fieldTerkunci.where(labelIdentitasAlat.containsKey).toList();
    final hasil = await tampilkanMintaKoreksi(
      context,
      judul: 'Minta koreksi ke lab',
      keterangan:
          'Pilih data alat yang salah dan tulis nilai yang benar. Lab akan '
          'memeriksanya dan memberi kabar lewat notifikasi.',
      field: [
        for (final k in kunci)
          FieldKoreksi(
            kunci: k,
            label: labelIdentitasAlat[k]!,
            nilai: _nilaiAwal(k),
            angka: _angka.contains(k),
          ),
      ],
      kirim: (perubahan, catatan) => ref
          .read(layananProvider)
          .mintaKoreksiAlat(_a.id, perubahan, catatan: catatan),
    );
    if (hasil == null || !mounted) return;
    ref.invalidate(detailAlatProvider(_a.id));
    ref.invalidate(daftarKoreksiProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Koreksi terkirim ke lab.')));
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KoreksiDetailScreen(id: hasil.id),
      ),
    );
  }

  Widget _isian(
    TextEditingController c,
    String label,
    String kunci, {
    String? bantu,
    bool angka = false,
    int baris = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: c,
      enabled: !_sibuk,
      minLines: baris,
      maxLines: baris,
      keyboardType: angka
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        helperText: bantu,
        helperMaxLines: 2,
        errorText: _galat[kunci],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);
    final a = _a;
    final nomor = a.sertifikatTerakhir?.nomor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
      children: [
        if (a.terkunci) ...[
          Kertas(
            warna: m.awasTipis,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, color: m.awas),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identitas terkunci',
                        style: t.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nomor == null
                            ? 'Identitas terkunci — sudah tercetak di sertifikat. '
                                  'Kalau ada yang salah, minta koreksi ke lab.'
                            : 'Identitas terkunci — sudah tercetak di sertifikat '
                                  '$nomor. Kalau ada yang salah, minta koreksi ke lab.',
                        style: t.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Kertas(
            padding: const EdgeInsets.all(jarak),
            child: Column(
              children: [
                for (final k in labelIdentitasAlat.keys)
                  BarisInfo(labelIdentitasAlat[k]!, _nilaiAwal(k)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (a.koreksiMenungguId != null)
            Kertas(
              warna: m.awasTipis,
              padding: const EdgeInsets.all(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => KoreksiDetailScreen(id: a.koreksiMenungguId!),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty, color: m.awas),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Koreksi sedang ditinjau lab',
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            )
          else
            SidikTombol(
              label: 'Minta koreksi ke lab',
              ikon: Icons.edit_note_outlined,
              penuh: true,
              onPressed: _mintaKoreksi,
            ),
        ] else ...[
          const JudulSeksi('Identitas'),
          Text(
            'Setelah alat punya sertifikat, identitasnya terkunci dan cuma '
            'bisa dikoreksi lewat lab.',
            style: t.bodySmall,
          ),
          const SizedBox(height: 12),
          _isian(_identitas['nama_alat']!, 'Nama alat *', 'nama_alat'),
          _isian(_identitas['merk']!, 'Merk', 'merk'),
          _isian(_identitas['model']!, 'Model', 'model'),
          _isian(_identitas['serial_number']!, 'Nomor seri', 'serial_number'),
          _isian(
            _identitas['no_identifikasi']!,
            'No. identifikasi internal',
            'no_identifikasi',
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _isian(
                  _identitas['range_min']!,
                  'Rentang min.',
                  'range_min',
                  angka: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isian(
                  _identitas['range_max']!,
                  'Rentang maks.',
                  'range_max',
                  angka: true,
                ),
              ),
            ],
          ),
          _isian(_identitas['satuan']!, 'Satuan', 'satuan'),
          _isian(_identitas['resolusi']!, 'Resolusi', 'resolusi', angka: true),
        ],
        JudulSeksi(
          a.terkunci ? 'Yang masih bisa kamu ubah' : 'Lokasi dan catatan',
        ),
        _isian(
          _lokasi,
          'Lokasi alat',
          'lokasi',
          bantu: 'Membantu teknisi menemukan alatnya.',
        ),
        _isian(_catatan, 'Catatan (opsional)', 'catatan', baris: 3),
        const JudulSeksi('Foto pelat nama'),
        GridFotoPelat(
          awal: a.foto,
          unggah: (b) => ref.read(layananProvider).unggahFotoAlat(a.id, b),
          onBerubah: () => ref.invalidate(detailAlatProvider(a.id)),
        ),
        if (_galatUmum != null) ...[
          const SizedBox(height: 14),
          Text(_galatUmum!, style: TextStyle(color: m.gagal)),
        ],
        const SizedBox(height: 16),
        SidikTombol(
          label: 'Simpan perubahan',
          ragam: RagamTombol.utama,
          penuh: true,
          sibuk: _sibuk,
          onPressed: _simpan,
        ),
      ],
    );
  }
}
