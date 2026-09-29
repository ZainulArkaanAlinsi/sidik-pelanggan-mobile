import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/format.dart';
import '../../models/anggota.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';

/// Anggota tim perusahaan. Semua peran boleh MELIHAT; yang mengundang dan
/// menonaktifkan hanya PIC utama — tombolnya disembunyikan untuk staf, dan
/// server tetap menolaknya (gerbang `peran:pic_utama`).
class AnggotaScreen extends ConsumerWidget {
  const AnggotaScreen({super.key});

  Future<void> _aksi(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() aksi,
    String berhasil,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await aksi();
      messenger.showSnackBar(SnackBar(content: Text(berhasil)));
    } on GalatApi catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.pesan)));
    }
    ref.invalidate(anggotaProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(anggotaProvider);
    final layanan = ref.read(layananProvider);
    final t = Theme.of(context).textTheme;
    final pic = async.value?.sayaPicUtama ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Anggota tim')),
      floatingActionButton: pic
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Undang'),
              onPressed: () async {
                final hasil = await showModalBottomSheet<(String, String)>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const _LembarUndang(),
                );
                if (hasil != null && context.mounted) {
                  await _aksi(
                    context,
                    ref,
                    () => layanan.undangAnggota(hasil.$1, hasil.$2),
                    'Undangan terkirim ke ${hasil.$1}.',
                  );
                }
              },
            )
          : null,
      body: async.when(
        loading: () => const Memuat(),
        error: (e, _) => KeadaanGalat(
          galat: e,
          cobaLagi: () => ref.invalidate(anggotaProvider),
        ),
        data: (d) => ListView(
          // Bawah 96: tombol Undang tidak boleh menutupi baris terakhir.
          padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 96),
          children: [
            Text(
              '${d.anggota.where((a) => a.aktif).length} dari ${d.maksAnggota} kursi terpakai',
              style: t.bodySmall,
            ),
            const SizedBox(height: 8),
            Kertas(
              child: Column(
                children: [
                  for (var i = 0; i < d.anggota.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 16),
                    _BarisAnggota(
                      anggota: d.anggota[i],
                      bisaKelola: pic,
                      onNonaktifkan: () => _aksi(
                        context,
                        ref,
                        () => layanan.nonaktifkanAnggota(d.anggota[i].id),
                        '${d.anggota[i].nama} dinonaktifkan.',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (d.undanganMenunggu.isNotEmpty) ...[
              const JudulSeksi('Undangan belum dipakai'),
              Kertas(
                child: Column(
                  children: [
                    for (final u in d.undanganMenunggu)
                      ListTile(
                        leading: const Icon(Icons.mail_outline),
                        title: Text(u.email),
                        subtitle: Text(
                          '${u.peran == 'pic_utama' ? 'PIC utama' : 'Staf'} · berlaku s.d. ${Format.tanggal(u.kedaluwarsa)}',
                        ),
                        trailing: pic
                            ? IconButton(
                                tooltip: 'Batalkan undangan',
                                icon: const Icon(Icons.close),
                                onPressed: () => _aksi(
                                  context,
                                  ref,
                                  () => layanan.batalkanUndangan(u.id),
                                  'Undangan ke ${u.email} dibatalkan.',
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarisAnggota extends StatelessWidget {
  const _BarisAnggota({
    required this.anggota,
    required this.bisaKelola,
    required this.onNonaktifkan,
  });

  final Anggota anggota;
  final bool bisaKelola;
  final VoidCallback onNonaktifkan;

  @override
  Widget build(BuildContext context) {
    final a = anggota;
    return ListTile(
      title: Text(a.saya ? '${a.nama} (Anda)' : a.nama),
      subtitle: Text(
        [a.labelPeran, a.email, if (!a.aktif) 'nonaktif'].join(' · '),
      ),
      // Aksi merusak masuk menu "⋮", bukan ikon tong sampah di tiap baris —
      // satu ketukan meleset tidak boleh mengeluarkan orang dari tim.
      trailing: bisaKelola && a.aktif && !a.saya
          ? PopupMenuButton<String>(
              tooltip: 'Aksi lainnya',
              onSelected: (_) async {
                final yakin = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: Text('Nonaktifkan ${a.nama}?'),
                    content: const Text(
                      'Dia tidak bisa lagi membuka data perusahaan ini. Riwayatnya tetap tersimpan.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(d).pop(false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(d).pop(true),
                        child: const Text('Nonaktifkan'),
                      ),
                    ],
                  ),
                );
                if (yakin == true) onNonaktifkan();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'nonaktif', child: Text('Nonaktifkan')),
              ],
            )
          : null,
    );
  }
}

class _LembarUndang extends StatefulWidget {
  const _LembarUndang();

  @override
  State<_LembarUndang> createState() => _LembarUndangState();
}

class _LembarUndangState extends State<_LembarUndang> {
  final _email = TextEditingController();
  String _peran = 'staf';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Undang anggota', style: t.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Kode undangan dikirim ke email ini dan berlaku terbatas.',
            style: t.bodySmall,
          ),
          const SizedBox(height: jarak),
          TextField(
            controller: _email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: jarak),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'staf', label: Text('Staf')),
              ButtonSegment(value: 'pic_utama', label: Text('PIC utama')),
            ],
            selected: {_peran},
            onSelectionChanged: (s) => setState(() => _peran = s.first),
          ),
          const SizedBox(height: 20),
          SidikTombol(
            label: 'Kirim undangan',
            ragam: RagamTombol.utama,
            penuh: true,
            onPressed: () {
              if (_email.text.trim().isEmpty) return;
              Navigator.of(context).pop((_email.text.trim(), _peran));
            },
          ),
        ],
      ),
    );
  }
}
