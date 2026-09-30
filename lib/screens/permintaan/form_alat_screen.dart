import 'package:flutter/material.dart';

import '../../models/permintaan.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';

/// Alat yang belum terdaftar (PL_Form_Alat). Hasilnya dikembalikan lewat
/// `Navigator.pop` sebagai [AlatBaru] — alatnya BARU lahir di daftar
/// perusahaan setelah lab menerima permintaan, jadi di sini tidak ada yang
/// disimpan ke server.
///
/// Semua controller dimiliki State layar ini sendiri dan dibuang bersama
/// layarnya (membuangnya tepat setelah `push` kembali akan crash).
class FormAlatScreen extends StatefulWidget {
  const FormAlatScreen({super.key, this.awal});

  final AlatBaru? awal;

  @override
  State<FormAlatScreen> createState() => _FormAlatScreenState();
}

class _FormAlatScreenState extends State<FormAlatScreen> {
  late final _nama = TextEditingController(text: widget.awal?.namaAlat);
  late final _merk = TextEditingController(text: widget.awal?.merk);
  late final _model = TextEditingController(text: widget.awal?.model);
  late final _serial = TextEditingController(text: widget.awal?.serialNumber);
  late final _noId = TextEditingController(text: widget.awal?.noIdentifikasi);
  late final _min = TextEditingController(
    text: _angka(widget.awal?.rentangMin),
  );
  late final _maks = TextEditingController(
    text: _angka(widget.awal?.rentangMaks),
  );
  late final _satuan = TextEditingController(text: widget.awal?.satuan);
  late final _resolusi = TextEditingController(
    text: _angka(widget.awal?.resolusi),
  );
  late final _lokasi = TextEditingController(text: widget.awal?.lokasi);
  late final _catatan = TextEditingController(text: widget.awal?.catatan);

  Map<String, String> _galat = const {};

  static String _angka(double? v) => v == null
      ? ''
      : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  @override
  void dispose() {
    for (final c in [
      _nama,
      _merk,
      _model,
      _serial,
      _noId,
      _min,
      _maks,
      _satuan,
      _resolusi,
      _lokasi,
      _catatan,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Kosong → `null`; bukan angka → `double.nan` supaya ditandai salah.
  /// Koma desimal dibaca sebagai titik — pengguna Indonesia mengetik "0,01".
  double? _baca(TextEditingController c) {
    final s = c.text.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s) ?? double.nan;
  }

  void _simpan() {
    final galatAngka = <String, String>{};
    double? angka(String kunci, TextEditingController c) {
      final v = _baca(c);
      if (v != null && v.isNaN) {
        galatAngka[kunci] = 'Isi dengan angka.';
        return null;
      }
      return v;
    }

    String? isi(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    final alat = AlatBaru(
      namaAlat: _nama.text,
      merk: isi(_merk),
      model: isi(_model),
      serialNumber: isi(_serial),
      noIdentifikasi: isi(_noId),
      rentangMin: angka('rentang_min', _min),
      rentangMaks: angka('rentang_maks', _maks),
      satuan: isi(_satuan),
      resolusi: angka('resolusi', _resolusi),
      lokasi: isi(_lokasi),
      catatan: isi(_catatan),
    );
    final galat = {...alat.galat(), ...galatAngka};
    setState(() => _galat = galat);
    if (galat.isEmpty) Navigator.of(context).pop(alat);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah alat')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
        children: [
          Text(
            'Tim PT Sidik akan memeriksa data ini. Alat baru masuk ke daftar '
            'alat perusahaan setelah permintaannya diterima.',
            style: t.bodySmall,
          ),
          const JudulSeksi('Identitas'),
          _isian(
            _nama,
            'Nama alat *',
            'nama_alat',
            bantu: 'Sebut jenisnya, mis. pH Meter atau Timbangan Analitik.',
          ),
          _isian(_merk, 'Merk', 'merk'),
          _isian(_model, 'Model', 'model'),
          _isian(
            _serial,
            'Nomor seri',
            'serial_number',
            bantu:
                'Ada di pelat nama alat. Boleh kosong; lab yang melengkapinya.',
          ),
          _isian(
            _noId,
            'No. identifikasi internal',
            'no_identifikasi',
            bantu: 'Kode aset di perusahaan Anda, kalau ada.',
          ),
          const JudulSeksi('Spesifikasi'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _isian(_min, 'Rentang min.', 'rentang_min', angka: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isian(
                  _maks,
                  'Rentang maks.',
                  'rentang_maks',
                  angka: true,
                ),
              ),
            ],
          ),
          _isian(
            _satuan,
            'Satuan',
            'satuan',
            bantu: 'Wajib kalau rentang diisi, mis. °C, mm, atau pH.',
          ),
          _isian(_resolusi, 'Resolusi', 'resolusi', angka: true),
          _isian(
            _lokasi,
            'Lokasi alat',
            'lokasi',
            bantu: 'Membantu teknisi menemukan alatnya.',
          ),
          _isian(_catatan, 'Catatan (opsional)', 'catatan', baris: 3),
          const SizedBox(height: 8),
          SidikTombol(
            label: 'Simpan alat',
            ragam: RagamTombol.utama,
            penuh: true,
            onPressed: _simpan,
          ),
        ],
      ),
    );
  }
}
