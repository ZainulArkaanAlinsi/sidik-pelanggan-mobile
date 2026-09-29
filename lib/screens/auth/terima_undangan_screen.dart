import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/theme/sidik_material.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';

/// Tukar kode undangan jadi akun. Satu layar, urutan kolom sama dengan yang
/// diminta server (`TerimaUndanganRequest`), galat ditampilkan DI BAWAH
/// kolomnya masing-masing.
class TerimaUndanganScreen extends ConsumerStatefulWidget {
  const TerimaUndanganScreen({super.key});

  @override
  ConsumerState<TerimaUndanganScreen> createState() =>
      _TerimaUndanganScreenState();
}

class _TerimaUndanganScreenState extends ConsumerState<TerimaUndanganScreen> {
  final _email = TextEditingController();
  final _kode = TextEditingController();
  final _nama = TextEditingController();
  final _telepon = TextEditingController();
  final _jabatan = TextEditingController();
  final _sandi = TextEditingController();
  bool _setuju = false;
  bool _sibuk = false;
  Map<String, String> _galatIsian = const {};
  String? _galat;

  @override
  void dispose() {
    for (final c in [_email, _kode, _nama, _telepon, _jabatan, _sandi]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _kirim() async {
    setState(() {
      _sibuk = true;
      _galat = null;
      _galatIsian = const {};
    });
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(sesiProvider.notifier)
          .terimaUndangan(
            email: _email.text,
            kode: _kode.text,
            nama: _nama.text,
            telepon: _telepon.text,
            jabatan: _jabatan.text,
            sandi: _sandi.text,
            setujuSyarat: _setuju,
          );
      // Gerbang di akar aplikasi yang memindahkan ke beranda; layar ini
      // cukup menyingkir.
      navigator.popUntil((r) => r.isFirst);
    } on GalatApi catch (e) {
      if (mounted) {
        setState(() {
          _galat = e.isian.isEmpty ? e.pesan : null;
          _galatIsian = e.isian;
        });
      }
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Widget _isian(
    TextEditingController c,
    String label,
    String kunci, {
    TextInputType? keyboard,
    bool rahasia = false,
    String? bantuan,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: jarak),
    child: TextField(
      controller: c,
      keyboardType: keyboard,
      obscureText: rahasia,
      textCapitalization: kunci == 'kode'
          ? TextCapitalization.characters
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        helperText: bantuan,
        errorText: _galatIsian[kunci],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pakai kode undangan')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Masukkan email yang menerima undangan dan kodenya, lalu lengkapi data Anda.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _isian(
            _email,
            'Email',
            'email',
            keyboard: TextInputType.emailAddress,
          ),
          _isian(
            _kode,
            'Kode undangan',
            'kode',
            bantuan: 'Ada di email undangan',
          ),
          _isian(_nama, 'Nama lengkap', 'nama'),
          _isian(
            _telepon,
            'Nomor HP',
            'telepon',
            keyboard: TextInputType.phone,
            bantuan: 'Contoh: 0812 3456 7890',
          ),
          _isian(_jabatan, 'Jabatan (opsional)', 'jabatan'),
          _isian(
            _sandi,
            'Buat sandi',
            'sandi',
            rahasia: true,
            bantuan: 'Minimal 10 karakter',
          ),
          CheckboxListTile(
            value: _setuju,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => setState(() => _setuju = v ?? false),
            title: const Text(
              'Saya menyetujui syarat penggunaan dan kebijakan privasi.',
            ),
            subtitle: _galatIsian['setuju_syarat'] == null
                ? null
                : Text(
                    _galatIsian['setuju_syarat']!,
                    style: TextStyle(color: m.gagal),
                  ),
          ),
          if (_galat != null) ...[
            const SizedBox(height: 8),
            Text(_galat!, style: TextStyle(color: m.gagal)),
          ],
          const SizedBox(height: 20),
          SidikTombol(
            label: 'Buat akun & masuk',
            ragam: RagamTombol.utama,
            penuh: true,
            sibuk: _sibuk,
            onPressed: _setuju ? _kirim : null,
          ),
        ],
      ),
    );
  }
}
