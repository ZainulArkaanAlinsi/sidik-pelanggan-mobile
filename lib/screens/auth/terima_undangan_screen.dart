import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/tombol_sidik.dart';
import '../akun/bantuan_screen.dart';

/// Pesan untuk email undangan yang SUDAH punya akun. Sengaja tidak menyebut
/// nama akun lama, perusahaan lain, atau nomor apa pun — hanya apa yang
/// terjadi dan apa yang harus dilakukan kalau lupa sandi lama.
class DialogAkunSudahAda extends StatelessWidget {
  const DialogAkunSudahAda({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.info_outline),
    title: const Text('Email ini sudah punya akun'),
    content: const SingleChildScrollView(
      child: Text(
        'Anda masuk ke akun SIDIK Pelanggan yang sudah ada, dan perusahaan '
        'dari undangan ini ditambahkan ke akun itu.\n\n'
        'Nama dan sandi yang baru Anda isi tidak dipakai: sandi Anda tetap '
        'sandi akun yang lama. Kalau lupa, keluar lalu pilih "Lupa sandi?" '
        'di layar Masuk.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Mengerti'),
      ),
    ],
  );
}

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
      final akunLama = await ref
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
      // Email yang sudah punya akun dipakai TANPA membuat akun baru; isian
      // nama & sandi diabaikan server. Beri tahu sebelum layar ini menyingkir
      // — orang yang mengira sandinya baru saja diganti akan gagal masuk
      // besok dan tidak tahu sebabnya.
      if (akunLama && mounted) {
        // Pemutar di tombol berhenti dulu: pesannya dibaca tanpa layar yang
        // terlihat masih "memproses".
        setState(() => _sibuk = false);
        await showDialog<void>(
          context: context,
          builder: (_) => const DialogAkunSudahAda(),
        );
      }
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
    padding: const EdgeInsets.only(bottom: Spasi.lg),
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
    final s = context.skema;
    final info = ref.watch(infoAplikasiProvider).value;
    final galatKode = _galatIsian['kode'] != null || _galat != null;
    return HalamanSidik(
      judul: 'Pakai kode undangan',
      latarPutih: true,
      isi: ListView(
        padding: Spasi.denganTepiBawah(context, const EdgeInsets.all(Spasi.xl)),
        children: [
          Text(
            'Masukkan email yang menerima undangan dan kodenya, lalu lengkapi data Anda.',
            style: context.teks.bodyMedium?.copyWith(color: s.onSurfaceVariant),
          ),
          const SizedBox(height: Spasi.xl),
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
                    style: TextStyle(color: s.error),
                  ),
          ),
          // REQ-PRV-01: dokumen yang disetujui harus bisa dibaca dulu.
          if (info?.kebijakanPrivasiUrl != null || info?.syaratUrl != null)
            Wrap(
              spacing: 8,
              children: [
                if (info?.kebijakanPrivasiUrl != null)
                  TextButton(
                    onPressed: () =>
                        bukaTautanLuar(Uri.parse(info!.kebijakanPrivasiUrl!)),
                    child: const Text('Baca kebijakan privasi'),
                  ),
                if (info?.syaratUrl != null)
                  TextButton(
                    onPressed: () =>
                        bukaTautanLuar(Uri.parse(info!.syaratUrl!)),
                    child: const Text('Baca syarat & ketentuan'),
                  ),
              ],
            ),
          if (_galat != null) ...[
            const SizedBox(height: Spasi.sm),
            Text(_galat!, style: TextStyle(color: s.error)),
          ],
          // Flow A: kode salah / kedaluwarsa → minta kode baru ke lab.
          if (galatKode && (info?.adaKontak ?? false))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.support_agent),
                label: const Text('Minta kode baru ke PT Sidik'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BantuanScreen(),
                  ),
                ),
              ),
            ),
          const SizedBox(height: Spasi.xl),
          TombolSidik(
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
