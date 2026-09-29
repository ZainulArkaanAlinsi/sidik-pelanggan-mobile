import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/theme/sidik_material.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';
import 'lupa_sandi_screen.dart';
import 'terima_undangan_screen.dart';

/// Layar masuk. Dua pintu saja: MASUK (sudah punya akun) dan PAKAI KODE
/// UNDANGAN (baru diundang). Tidak ada "Daftar" — akun pelanggan hanya lahir
/// dari undangan (keputusan 18 Sep 2026).
class MasukScreen extends ConsumerStatefulWidget {
  const MasukScreen({super.key});

  @override
  ConsumerState<MasukScreen> createState() => _MasukScreenState();
}

class _MasukScreenState extends ConsumerState<MasukScreen> {
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  bool _sibuk = false;
  bool _lihatSandi = false;
  String? _galat;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (_email.text.trim().isEmpty || _sandi.text.isEmpty) {
      setState(() => _galat = 'Isi email dan sandi Anda.');
      return;
    }
    setState(() {
      _sibuk = true;
      _galat = null;
    });
    try {
      await ref.read(sesiProvider.notifier).masuk(_email.text, _sandi.text);
    } on GalatApi catch (e) {
      if (mounted) setState(() => _galat = e.pesan);
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Text('SIDIK PELANGGAN', style: m.gayaEtsa(ukuran: 12)),
                const SizedBox(height: 8),
                Text('Masuk', style: t.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'Lihat status kalibrasi alat, unduh sertifikat, dan lacak paket Anda di laboratorium PT Sidik.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: jarak),
                TextField(
                  controller: _sandi,
                  obscureText: !_lihatSandi,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _masuk(),
                  decoration: InputDecoration(
                    labelText: 'Sandi',
                    suffixIcon: IconButton(
                      tooltip: _lihatSandi
                          ? 'Sembunyikan sandi'
                          : 'Tampilkan sandi',
                      icon: Icon(
                        _lihatSandi
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _lihatSandi = !_lihatSandi),
                    ),
                  ),
                ),
                if (_galat != null) ...[
                  const SizedBox(height: 12),
                  Text(_galat!, style: TextStyle(color: m.gagal)),
                ],
                const SizedBox(height: 20),
                SidikTombol(
                  label: 'Masuk',
                  ragam: RagamTombol.utama,
                  penuh: true,
                  sibuk: _sibuk,
                  onPressed: _masuk,
                ),
                const SizedBox(height: 8),
                SidikTombol(
                  label: 'Lupa sandi?',
                  ragam: RagamTombol.teks,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LupaSandiScreen(emailAwal: _email.text),
                    ),
                  ),
                ),
                const Divider(height: 40),
                Text('Baru diundang?', style: t.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'PIC perusahaan Anda atau admin lab mengirim kode undangan ke email Anda.',
                  style: t.bodySmall,
                ),
                const SizedBox(height: 12),
                SidikTombol(
                  label: 'Pakai kode undangan',
                  ikon: Icons.mark_email_read_outlined,
                  penuh: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TerimaUndanganScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
