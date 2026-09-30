import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/data_pelanggan.dart';
import '../../models/permintaan.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';
import 'form_alat_screen.dart';
import 'permintaan_detail_screen.dart';
import 'pilih_alat_screen.dart';

/// Ajukan kalibrasi (PL_Ajukan). Satu layar bergulir, bukan empat langkah
/// terpisah: isiannya cuma lima kelompok dan pelanggan sering kembali
/// menambah satu alat — layar bertahap memaksanya mundur-maju.
///
/// Yang dikirim hanya isian ini. `customer_id` TIDAK pernah ada: perusahaan
/// datang dari header `X-Perusahaan-Id`, dan server memeriksa
/// keanggotaannya sendiri.
class AjukanScreen extends ConsumerStatefulWidget {
  const AjukanScreen({super.key});

  @override
  ConsumerState<AjukanScreen> createState() => _AjukanScreenState();
}

class _AjukanScreenState extends ConsumerState<AjukanScreen> {
  final _catatan = TextEditingController();
  final Map<int, Alat> _alat = {};
  final List<AlatBaru> _alatBaru = [];
  MetodePengantaran? _metode;
  DateTime? _dari;
  DateTime? _sampai;

  /// Galat lokal (sebelum kirim) dan galat dari server (422) dipegang
  /// terpisah: yang lokal hilang begitu diperbaiki, yang server tetap sampai
  /// kirim ulang.
  Map<String, String> _galat = const {};
  String? _pesanServer;
  bool _sibuk = false;

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  DraftPermintaan get _draft => DraftPermintaan(
    metode: _metode,
    dari: _dari,
    sampai: _sampai,
    catatan: _catatan.text,
    alatId: _alat.keys.toList(),
    alatBaru: List.of(_alatBaru),
  );

  Future<void> _pilihAlat() async {
    final hasil = await Navigator.of(context).push<List<Alat>>(
      MaterialPageRoute(
        builder: (_) => PilihAlatScreen(awal: _alat.values.toList()),
      ),
    );
    if (hasil == null) return;
    setState(() {
      _alat
        ..clear()
        ..addEntries(hasil.map((a) => MapEntry(a.id, a)));
    });
  }

  Future<void> _formAlat({int? indeks}) async {
    final hasil = await Navigator.of(context).push<AlatBaru>(
      MaterialPageRoute(
        builder: (_) =>
            FormAlatScreen(awal: indeks == null ? null : _alatBaru[indeks]),
      ),
    );
    if (hasil == null) return;
    setState(() {
      if (indeks == null) {
        _alatBaru.add(hasil);
      } else {
        _alatBaru[indeks] = hasil;
      }
    });
  }

  Future<void> _pilihTanggal({required bool awal}) async {
    final hariIni = DateTime.now();
    final mulai = DateTime(hariIni.year, hariIni.month, hariIni.day);
    final hasil = await showDatePicker(
      context: context,
      initialDate: (awal ? _dari : _sampai) ?? (_dari ?? mulai),
      firstDate: awal ? mulai : (_dari ?? mulai),
      lastDate: mulai.add(const Duration(days: 365)),
    );
    if (hasil == null) return;
    setState(() {
      if (awal) {
        _dari = hasil;
        if (_sampai != null && _sampai!.isBefore(hasil)) _sampai = null;
      } else {
        _sampai = hasil;
      }
    });
  }

  Future<void> _kirim() async {
    final draft = _draft;
    final lokal = draft.galat();
    setState(() {
      _galat = lokal;
      _pesanServer = null;
    });
    if (lokal.isNotEmpty) return;

    setState(() => _sibuk = true);
    final pesan = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final p = await ref.read(layananProvider).ajukanPermintaan(draft);
      ref.invalidate(daftarPermintaanProvider);
      pesan.showSnackBar(
        const SnackBar(
          content: Text('Permintaan terkirim. Tim lab akan meninjaunya.'),
        ),
      );
      // Ganti layar ini dengan detail, supaya "kembali" dari detail mendarat
      // di daftar dan bukan di formulir yang sudah terkirim.
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PermintaanDetailScreen(id: p.id),
        ),
      );
    } on GalatApi catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _galat = e.isian;
        _pesanServer = e.pesan;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _pesanServer = 'Permintaan belum terkirim. Coba lagi.';
      });
    }
  }

  /// Galat untuk kelompok alat: kunci `alat_id`, `alat_id.N`, dan galat
  /// tiap alat baru (`alat_baru.N.kolom`).
  List<String> get _galatAlat => [
    for (final e in _galat.entries)
      if (e.key == 'alat_id' ||
          e.key.startsWith('alat_id.') ||
          e.key.startsWith('alat_baru'))
        e.value,
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);
    final perusahaan = ref
        .watch(sesiProvider)
        .value
        ?.keanggotaanAktif
        ?.namaPerusahaan;

    Widget galat(String? teks) => teks == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              teks,
              style: t.bodySmall?.copyWith(
                color: m.gagal,
                fontWeight: FontWeight.w600,
              ),
            ),
          );

    Widget tanggal(String label, DateTime? nilai, bool awal) => Expanded(
      child: InkWell(
        onTap: () => _pilihTanggal(awal: awal),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.event_outlined),
          ),
          child: Text(Format.tanggal(nilai, kosong: 'Pilih tanggal')),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan kalibrasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
        children: [
          if (perusahaan != null) Text('Untuk $perusahaan', style: t.bodySmall),
          const JudulSeksi('Alat'),
          Kertas(
            padding: const EdgeInsets.all(14),
            // Material transparan: ListTile melukis di Material terdekat, dan
            // Kertas berlatar warna akan menutupinya.
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_alat.isEmpty && _alatBaru.isEmpty)
                    Text('Belum ada alat dipilih.', style: t.bodyMedium),
                  for (final a in _alat.values)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(a.nama),
                      subtitle: Text(
                        [
                          a.merkModel,
                          if (a.serial != null) 'SN ${a.serial}',
                        ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                      trailing: IconButton(
                        tooltip: 'Hapus ${a.nama}',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _alat.remove(a.id)),
                      ),
                    ),
                  for (var i = 0; i < _alatBaru.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _formAlat(indeks: i),
                      title: Text(_alatBaru[i].namaAlat),
                      subtitle: Text(
                        [
                          'Alat baru',
                          if (_alatBaru[i].merk != null) _alatBaru[i].merk!,
                          if (_alatBaru[i].serialNumber != null)
                            'SN ${_alatBaru[i].serialNumber}',
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        tooltip: 'Hapus ${_alatBaru[i].namaAlat}',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _alatBaru.removeAt(i)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SidikTombol(
                        label: 'Pilih dari daftar alat',
                        ikon: Icons.checklist,
                        kecil: true,
                        onPressed: _pilihAlat,
                      ),
                      SidikTombol(
                        label: 'Tambah alat baru',
                        ikon: Icons.add,
                        kecil: true,
                        onPressed: () => _formAlat(),
                      ),
                    ],
                  ),
                  for (final g in _galatAlat) galat(g),
                ],
              ),
            ),
          ),
          const JudulSeksi('Cara alat sampai ke lab'),
          Kertas(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Material(
              type: MaterialType.transparency,
              child: RadioGroup<MetodePengantaran>(
                groupValue: _metode,
                onChanged: (v) => setState(() => _metode = v),
                child: Column(
                  children: [
                    for (final opsi in MetodePengantaran.values)
                      RadioListTile<MetodePengantaran>(
                        value: opsi,
                        title: Text(opsi.label),
                      ),
                  ],
                ),
              ),
            ),
          ),
          galat(_galat['metode_pengantaran']),
          const JudulSeksi('Tanggal yang diinginkan'),
          Row(
            children: [
              tanggal('Dari', _dari, true),
              const SizedBox(width: 12),
              tanggal('Sampai', _sampai, false),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Opsional. Ini hanya keinginan — Tim PT Sidik yang memutuskan tanggal pastinya.',
            style: t.bodySmall,
          ),
          galat(_galat['tanggal_diinginkan_dari']),
          galat(_galat['tanggal_diinginkan_sampai']),
          const JudulSeksi('Catatan'),
          TextField(
            controller: _catatan,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Mis. tolong diprioritaskan (opsional)',
            ),
          ),
          galat(_galat['catatan']),
          if (_pesanServer != null) ...[
            const SizedBox(height: jarak),
            Text(
              _pesanServer!,
              style: t.bodyMedium?.copyWith(
                color: m.gagal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SidikTombol(
            label: 'Kirim permintaan',
            ragam: RagamTombol.utama,
            penuh: true,
            sibuk: _sibuk,
            onPressed: _kirim,
          ),
        ],
      ),
    );
  }
}
