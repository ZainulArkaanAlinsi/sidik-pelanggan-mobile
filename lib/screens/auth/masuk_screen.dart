import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kolom_formulir.dart';
import '../../widgets/logo_sidik.dart';
import '../../widgets/panel_pemberitahuan.dart';
import '../../widgets/status_tampil.dart';
import '../../widgets/tombol_sidik.dart';
import 'lupa_sandi_screen.dart';
import 'terima_undangan_screen.dart';

/// Layar masuk. Dua pintu saja: MASUK (sudah punya akun) dan PAKAI KODE
/// UNDANGAN (baru diundang). Tidak ada "Daftar": akun pelanggan hanya lahir
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
    final t = context.teks;
    final s = context.skema;

    return HalamanSidik(
      latarPutih: true,
      isi: KolomFormulir(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: LogoSidik(tinggi: 64),
          ),
          const SizedBox(height: Spasi.lg),
          Text('Masuk', style: t.displaySmall),
          const SizedBox(height: Spasi.xs),
          Text(
            'Lihat status kalibrasi alat, unduh sertifikat, dan lihat riwayat kalibrasi alat Anda di PT Sidik.',
            style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
          ),
          if (ref.watch(sesiBerakhirProvider)) ...[
            const SizedBox(height: Spasi.lg),
            const PanelPemberitahuan(
              nada: NadaStatus.awas,
              ikon: Icons.lock_clock_outlined,
              judul: 'Sesi Anda berakhir. Silakan masuk lagi.',
            ),
          ],
          const SizedBox(height: Spasi.xl),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: Spasi.lg),
          TextField(
            controller: _sandi,
            obscureText: !_lihatSandi,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _masuk(),
            decoration: InputDecoration(
              labelText: 'Sandi',
              suffixIcon: IconButton(
                tooltip: _lihatSandi ? 'Sembunyikan sandi' : 'Tampilkan sandi',
                icon: Icon(
                  _lihatSandi
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _lihatSandi = !_lihatSandi),
              ),
            ),
          ),
          if (_galat != null) ...[
            const SizedBox(height: Spasi.md),
            Text(_galat!, style: t.bodyMedium?.copyWith(color: s.error)),
          ],
          const SizedBox(height: Spasi.xl),
          TombolSidik(
            label: 'Masuk',
            ragam: RagamTombol.utama,
            penuh: true,
            sibuk: _sibuk,
            onPressed: _masuk,
          ),
          const SizedBox(height: Spasi.sm),
          Align(
            child: TombolSidik(
              label: 'Lupa sandi?',
              ragam: RagamTombol.teks,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LupaSandiScreen(emailAwal: _email.text),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spasi.lg),
          const Divider(),
          const SizedBox(height: Spasi.lg),
          Text('Baru diundang?', style: t.titleSmall),
          const SizedBox(height: Spasi.xs),
          Text(
            'PIC perusahaan Anda atau admin lab mengirim kode undangan ke email Anda.',
            style: t.bodySmall,
          ),
          const SizedBox(height: Spasi.md),
          TombolSidik(
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
    );
  }
}
