import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/theme/sidik_material.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';

/// Lupa sandi: dua langkah di SATU layar — minta kode OTP ke email, lalu
/// masukkan kode + sandi baru. Server selalu menjawab "kode terkirim" walau
/// emailnya tidak terdaftar (tidak membocorkan siapa pelanggan lab).
class LupaSandiScreen extends ConsumerStatefulWidget {
  const LupaSandiScreen({super.key, this.emailAwal = ''});

  final String emailAwal;

  @override
  ConsumerState<LupaSandiScreen> createState() => _LupaSandiScreenState();
}

class _LupaSandiScreenState extends ConsumerState<LupaSandiScreen> {
  late final _email = TextEditingController(text: widget.emailAwal);
  final _otp = TextEditingController();
  final _sandi = TextEditingController();
  bool _kodeTerkirim = false;
  bool _sibuk = false;
  String? _galat;
  Map<String, String> _galatIsian = const {};

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _jalankan(Future<void> Function() aksi) async {
    setState(() {
      _sibuk = true;
      _galat = null;
      _galatIsian = const {};
    });
    try {
      await aksi();
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

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    final layanan = ref.read(layananProvider);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Atur ulang sandi')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _kodeTerkirim
                ? 'Kalau ${_email.text.trim()} terdaftar, kode 6 digit sudah dikirim ke sana. Berlaku 10 menit.'
                : 'Masukkan email akun Anda. Kami kirim kode untuk membuat sandi baru.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            enabled: !_kodeTerkirim,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              errorText: _galatIsian['email'],
            ),
          ),
          if (_kodeTerkirim) ...[
            const SizedBox(height: jarak),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kode dari email',
                errorText: _galatIsian['otp'],
              ),
            ),
            const SizedBox(height: jarak),
            TextField(
              controller: _sandi,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Sandi baru',
                helperText: 'Minimal 10 karakter',
                errorText: _galatIsian['sandi'],
              ),
            ),
          ],
          if (_galat != null) ...[
            const SizedBox(height: 12),
            Text(_galat!, style: TextStyle(color: m.gagal)),
          ],
          const SizedBox(height: 20),
          if (!_kodeTerkirim)
            SidikTombol(
              label: 'Kirim kode',
              ragam: RagamTombol.utama,
              penuh: true,
              sibuk: _sibuk,
              onPressed: () => _jalankan(() async {
                await layanan.lupaSandi(_email.text);
                if (mounted) setState(() => _kodeTerkirim = true);
              }),
            )
          else ...[
            SidikTombol(
              label: 'Simpan sandi baru',
              ragam: RagamTombol.utama,
              penuh: true,
              sibuk: _sibuk,
              onPressed: () => _jalankan(() async {
                await layanan.aturUlangSandi(
                  email: _email.text,
                  otp: _otp.text,
                  sandi: _sandi.text,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Sandi diganti. Silakan masuk dengan sandi baru.',
                    ),
                  ),
                );
                Navigator.of(context).pop();
              }),
            ),
            SidikTombol(
              label: 'Kirim ulang kode',
              ragam: RagamTombol.teks,
              onPressed: _sibuk
                  ? null
                  : () => _jalankan(() => layanan.lupaSandi(_email.text)),
            ),
          ],
        ],
      ),
    );
  }
}
