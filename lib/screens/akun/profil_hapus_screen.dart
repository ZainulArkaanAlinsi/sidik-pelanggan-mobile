import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/theme/sidik_material.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';

/// Ubah profil sendiri: nama, nomor HP, jabatan (`PATCH /saya`). Email tidak
/// bisa diganti di sini — email adalah alamat undangan dan kunci masuk.
class ProfilSayaScreen extends ConsumerStatefulWidget {
  const ProfilSayaScreen({super.key});

  @override
  ConsumerState<ProfilSayaScreen> createState() => _ProfilSayaScreenState();
}

class _ProfilSayaScreenState extends ConsumerState<ProfilSayaScreen> {
  late final _akun = ref.read(sesiProvider).value?.akun;
  late final _nama = TextEditingController(text: _akun?.nama ?? '');
  late final _telepon = TextEditingController(text: _akun?.telepon ?? '');
  late final _jabatan = TextEditingController(text: _akun?.jabatan ?? '');
  bool _sibuk = false;
  Map<String, String> _galatIsian = const {};
  String? _galat;

  @override
  void dispose() {
    _nama.dispose();
    _telepon.dispose();
    _jabatan.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    setState(() {
      _sibuk = true;
      _galat = null;
      _galatIsian = const {};
    });
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(sesiProvider.notifier)
          .perbaruiProfil(
            nama: _nama.text,
            telepon: _telepon.text,
            jabatan: _jabatan.text,
          );
      messenger.showSnackBar(const SnackBar(content: Text('Profil disimpan.')));
      navigator.pop();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Profil saya')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            enabled: false,
            initialValue: _akun?.email ?? '',
            decoration: const InputDecoration(
              labelText: 'Email',
              helperText: 'Email tidak bisa diganti dari aplikasi',
            ),
          ),
          const SizedBox(height: jarak),
          TextField(
            controller: _nama,
            decoration: InputDecoration(
              labelText: 'Nama lengkap',
              errorText: _galatIsian['nama'],
            ),
          ),
          const SizedBox(height: jarak),
          TextField(
            controller: _telepon,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Nomor HP',
              errorText: _galatIsian['telepon'],
            ),
          ),
          const SizedBox(height: jarak),
          TextField(
            controller: _jabatan,
            decoration: InputDecoration(
              labelText: 'Jabatan (opsional)',
              errorText: _galatIsian['jabatan'],
            ),
          ),
          if (_galat != null) ...[
            const SizedBox(height: 12),
            Text(_galat!, style: TextStyle(color: m.gagal)),
          ],
          const SizedBox(height: 24),
          SidikTombol(
            label: 'Simpan',
            ragam: RagamTombol.utama,
            penuh: true,
            sibuk: _sibuk,
            onPressed: _simpan,
          ),
        ],
      ),
    );
  }
}

/// Hapus akun (REQ-AUTH-11, UU PDP). Dua pengaman: sandi + centang
/// konfirmasi — sama persis dengan yang diminta server. Sesudah berhasil,
/// yang ditampilkan adalah daftar DARI SERVER: apa yang dihapus dan apa yang
/// tetap disimpan lab (sertifikat adalah rekaman lab terakreditasi).
class HapusAkunScreen extends ConsumerStatefulWidget {
  const HapusAkunScreen({super.key});

  @override
  ConsumerState<HapusAkunScreen> createState() => _HapusAkunScreenState();
}

class _HapusAkunScreenState extends ConsumerState<HapusAkunScreen> {
  final _sandi = TextEditingController();
  bool _yakin = false;
  bool _sibuk = false;
  String? _galat;

  @override
  void dispose() {
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _hapus() async {
    setState(() {
      _sibuk = true;
      _galat = null;
    });
    final navigator = Navigator.of(context);
    try {
      final hasil = await ref
          .read(sesiProvider.notifier)
          .hapusAkun(_sandi.text);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (d) => AlertDialog(
          title: const Text('Akun sudah dihapus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dihapus: ${hasil.dihapus.join(', ')}.'),
              const SizedBox(height: 8),
              Text('Tetap disimpan laboratorium: ${hasil.tetap.join(', ')}.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(d).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      navigator.popUntil((r) => r.isFirst);
    } on GalatApi catch (e) {
      if (mounted) setState(() => _galat = e.isian['konfirmasi'] ?? e.pesan);
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hapus akun')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Nama, email, nomor HP, dan jabatan Anda dihapus, dan semua perangkat dikeluarkan. '
            'Data perusahaan, alat, dan sertifikat TETAP disimpan laboratorium karena itu rekaman '
            'kalibrasi terakreditasi.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _sandi,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Sandi Anda'),
          ),
          CheckboxListTile(
            value: _yakin,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => setState(() => _yakin = v ?? false),
            title: const Text(
              'Saya mengerti penghapusan ini tidak bisa dibatalkan.',
            ),
          ),
          if (_galat != null) ...[
            const SizedBox(height: 8),
            Text(_galat!, style: TextStyle(color: m.gagal)),
          ],
          const SizedBox(height: 20),
          SidikTombol(
            label: 'Hapus akun saya',
            ragam: RagamTombol.bahaya,
            penuh: true,
            sibuk: _sibuk,
            onPressed: _yakin && _sandi.text.isNotEmpty ? _hapus : null,
          ),
        ],
      ),
    );
  }
}
