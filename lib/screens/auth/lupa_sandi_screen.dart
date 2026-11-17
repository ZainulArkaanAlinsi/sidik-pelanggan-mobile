import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/kolom_isian.dart';
import '../../widgets/tombol_sidik.dart';
import 'kerangka_auth.dart';

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
    final s = context.skema;
    final layanan = ref.read(layananProvider);
    final t = context.teks;

    return KerangkaAuth(
      ringkas: true,
      kartu: [
        const JudulAuth('Atur ulang sandi'),
        const SizedBox(height: Spasi.sm),
        Text(
          _kodeTerkirim
              ? 'Kalau ${_email.text.trim()} terdaftar, kode 6 digit sudah dikirim ke sana. Berlaku 10 menit.'
              : 'Masukkan email akun Anda. Kami kirim kode untuk membuat sandi baru.',
          style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        ),
        const SizedBox(height: Spasi.xl),
        KolomIsian(
          label: 'Email',
          pengendali: _email,
          aktif: !_kodeTerkirim,
          keyboardType: TextInputType.emailAddress,
          galat: _galatIsian['email'],
        ),
        if (_kodeTerkirim) ...[
          const SizedBox(height: Spasi.lg),
          KolomIsian(
            label: 'Kode dari email',
            pengendali: _otp,
            keyboardType: TextInputType.number,
            galat: _galatIsian['otp'],
          ),
          const SizedBox(height: Spasi.lg),
          KolomIsian(
            label: 'Sandi baru',
            pengendali: _sandi,
            rahasia: true,
            bantuan: 'Minimal 10 karakter',
            galat: _galatIsian['sandi'],
          ),
        ],
        if (_galat != null) ...[
          const SizedBox(height: Spasi.md),
          PesanGalatAuth(_galat!),
        ],
        const SizedBox(height: Spasi.xl),
        if (!_kodeTerkirim)
          TombolSidik(
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
          TombolSidik(
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
          TombolSidik(
            label: 'Kirim ulang kode',
            ragam: RagamTombol.teks,
            onPressed: _sibuk
                ? null
                : () => _jalankan(() => layanan.lupaSandi(_email.text)),
          ),
        ],
      ],
    );
  }
}
