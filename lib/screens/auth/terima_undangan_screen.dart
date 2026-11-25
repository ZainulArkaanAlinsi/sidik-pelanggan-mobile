import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/tautan_luar.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../providers/sesi_provider.dart';
import '../../providers/tautan_provider.dart';
import '../../widgets/kolom_isian.dart';
import '../../widgets/tombol_sidik.dart';
import '../akun/hubungi_screen.dart';
import 'kerangka_auth.dart';
import 'lupa_sandi_screen.dart';

/// Kode galat server yang tidak bisa diselesaikan pengguna sendiri: jalannya
/// lewat PT SIDIK, bukan "minta kode baru" (kontrak §1 `terima-undangan`).
const _kodeHubungiLab = {
  'undangan_organisasi_berbeda',
  'akun_nonaktif',
  'email_belum_diverifikasi',
};

/// Sandi yang diisi bukan sandi akun lama (kontrak §1 `terima-undangan`).
const _kodeSandiLamaSalah = 'sandi_akun_lama_salah';

/// Petunjuk di bawah kolom sandi: kolom yang sama melayani dua kasus.
const _petunjukSandiLama =
    'Sudah punya akun SIDIK Pelanggan dengan email ini? Isi sandi akun Anda '
    'yang sudah ada.';

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
        'Perusahaan dari undangan ini sudah ditambahkan ke akun SIDIK '
        'Pelanggan Anda yang sudah ada. Sandi Anda tidak berubah.\n\n'
        'Kalau lupa sandi, keluar lalu pilih "Lupa sandi?" di layar Masuk.',
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
/// diminta server (`TerimaUndanganRequest`); tiap kolom berlabel permanen di
/// atasnya ([KolomIsian]) dan galatnya ditampilkan DI BAWAH kolomnya masing-
/// masing.
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

  /// `kode` galat server terakhir; cabang tampilan memakai kode, bukan kalimat.
  String? _kodeGalat;

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
      _kodeGalat = null;
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
          // Cabang tampilan memakai `kode`, bukan kalimat server. Kode undangan
          // tetap hidup, jadi isian lain tidak disentuh.
          _kodeGalat = e.kode;
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
    double jarakBawah = Spasi.lg,
  }) => Padding(
    padding: EdgeInsets.only(bottom: jarakBawah),
    child: KolomIsian(
      label: label,
      pengendali: c,
      keyboardType: keyboard,
      rahasia: rahasia,
      textCapitalization: kunci == 'kode'
          ? TextCapitalization.characters
          : TextCapitalization.none,
      bantuan: bantuan,
      galat: _galatIsian[kunci],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final info = ref.watch(infoAplikasiProvider).value;
    // Hanya tautan https yang sah dari server yang ditawarkan.
    final privasi = TautanLuar.web(info?.kebijakanPrivasiUrl);
    final syarat = TautanLuar.web(info?.syaratUrl);
    // Sandi yang diisi bukan sandi akun lama: pesan server ("isi sandi akun
    // Anda yang sudah ada, bukan sandi baru") tampil PENUH tepat di bawah kolom
    // sandi. `errorText` kolom dibatasi tiga baris dan memotong kalimat itu.
    final galatSandiLama = _kodeGalat == _kodeSandiLamaSalah ? _galat : null;
    final galatKode =
        _galatIsian['kode'] != null ||
        (_galat != null && galatSandiLama == null);
    final hubungiLab = _kodeHubungiLab.contains(_kodeGalat);
    return KerangkaAuth(
      ringkas: true,
      kartu: [
        const JudulAuth('Pakai kode undangan'),
        const SizedBox(height: Spasi.sm),
        Text(
          'Masukkan email yang menerima undangan dan kodenya, lalu lengkapi data Anda.',
          style: context.teks.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        ),
        const SizedBox(height: Spasi.xl),
        _isian(_email, 'Email', 'email', keyboard: TextInputType.emailAddress),
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
          jarakBawah: Spasi.sm,
        ),
        if (galatSandiLama != null) ...[
          PesanGalatAuth(galatSandiLama),
          // Jalan keluar kalau sandi lama terlupa (email ikut terbawa).
          Align(
            alignment: Alignment.centerLeft,
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
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: Spasi.lg),
          child: Text(
            _petunjukSandiLama,
            style: context.teks.bodySmall?.copyWith(color: s.onSurfaceVariant),
          ),
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
        if (privasi != null || syarat != null)
          Wrap(
            spacing: 8,
            children: [
              if (privasi != null)
                TextButton(
                  onPressed: () => bukaAtauBeritahu(context, ref, privasi),
                  child: const Text('Baca kebijakan privasi'),
                ),
              if (syarat != null)
                TextButton(
                  onPressed: () => bukaAtauBeritahu(context, ref, syarat),
                  child: const Text('Baca syarat & ketentuan'),
                ),
            ],
          ),
        if (_galat != null && galatSandiLama == null) ...[
          const SizedBox(height: Spasi.sm),
          PesanGalatAuth(_galat!),
        ],
        // Flow A: kode salah / kedaluwarsa → minta kode baru ke lab. Galat yang
        // tidak bisa diselesaikan pengguna (akun nonaktif, laboratorium lain,
        // email belum terverifikasi) → hubungi PT SIDIK, bukan kode baru.
        if ((galatKode || hubungiLab) && (info?.adaKontak ?? false))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.support_agent),
              label: Text(
                hubungiLab ? 'Hubungi PT SIDIK' : 'Minta kode baru ke PT Sidik',
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HubungiScreen()),
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
    );
  }
}
