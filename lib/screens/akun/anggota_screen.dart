import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/anggota.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_status.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';

/// Anggota perusahaan yang sedang dibuka (REQ-ANG-03: semua peran boleh
/// melihat). PIC utama juga bisa menonaktifkan anggota lain; server tetap
/// yang menegakkan aturannya (`peran:pic_utama`), tombolnya disembunyikan dari
/// staf supaya tidak ada tombol yang pasti gagal.
///
/// Layar ini TIDAK membuat atau membatalkan undangan, dan tidak pernah
/// menawarkan penonaktifan diri sendiri (baris milik pemanggil ditandai server
/// lewat `saya`).
class AnggotaScreen extends ConsumerStatefulWidget {
  const AnggotaScreen({super.key});

  @override
  ConsumerState<AnggotaScreen> createState() => _AnggotaScreenState();
}

class _AnggotaScreenState extends ConsumerState<AnggotaScreen> {
  int? _sedangDinonaktifkan;

  Future<void> _nonaktifkan(Anggota a) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Nonaktifkan ${a.nama}?'),
        content: Text(
          '${a.nama} tidak bisa lagi membuka data perusahaan ini. Sesi masuknya '
          'diakhiri, kecuali ia masih anggota perusahaan lain. Ia bisa diundang '
          'kembali nanti.',
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
    if (yakin != true || !mounted) return;
    final pesan = ScaffoldMessenger.of(context);
    // Diambil SEBELUM await: layar bisa saja ditutup selagi permintaan jalan,
    // dan `ref` milik State yang sudah dilepas tidak boleh dipakai lagi.
    final container = ProviderScope.containerOf(context);
    final layanan = ref.read(layananProvider);
    setState(() => _sedangDinonaktifkan = a.id);
    try {
      await layanan.nonaktifkanAnggota(a.id);
      pesan.showSnackBar(SnackBar(content: Text('${a.nama} dinonaktifkan.')));
    } on GalatApi catch (e) {
      // 404 sudah dijawab kalimat umum oleh ApiPelanggan; 422 `sudah_nonaktif`
      // dan 403 membawa pesan server yang memang untuk ditampilkan.
      pesan.showSnackBar(SnackBar(content: Text(e.pesan)));
    } finally {
      if (mounted) setState(() => _sedangDinonaktifkan = null);
      // Selalu muat ulang: sesudah gagal pun daftar di layar bisa sudah
      // basi (mis. orang lain sudah menonaktifkannya).
      container.invalidate(anggotaProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(anggotaProvider);
    final aktif = ref.watch(sesiProvider).value?.keanggotaanAktif;
    return Scaffold(
      appBar: AppBar(title: const Text('Anggota perusahaan')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(anggotaProvider);
          await ref.read(anggotaProvider.future);
        },
        child: async.when(
          loading: () => const Memuat(),
          error: (e, _) => KeadaanGalat(
            galat: e,
            cobaLagi: () => ref.invalidate(anggotaProvider),
          ),
          data: (d) => _Isi(
            data: d,
            namaPerusahaan: aktif?.namaPerusahaan,
            sedangDinonaktifkan: _sedangDinonaktifkan,
            onNonaktifkan: _nonaktifkan,
          ),
        ),
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({
    required this.data,
    required this.namaPerusahaan,
    required this.sedangDinonaktifkan,
    required this.onNonaktifkan,
  });

  final DaftarAnggota data;
  final String? namaPerusahaan;
  final int? sedangDinonaktifkan;
  final void Function(Anggota) onNonaktifkan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final aktif = data.anggota.where((a) => a.aktif).toList();
    final nonaktif = data.anggota.where((a) => !a.aktif).toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: denganTepiBawah(
        context,
        const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
      ),
      children: [
        if (namaPerusahaan != null) Text(namaPerusahaan!, style: t.titleMedium),
        Text(
          data.maksAnggota > 0
              ? '${data.jumlahAktif} dari ${data.maksAnggota} anggota aktif'
              : '${data.jumlahAktif} anggota aktif',
          style: t.bodySmall,
        ),
        if (!data.sayaPicUtama) ...[
          const SizedBox(height: 8),
          Text(
            'Mengubah keanggotaan hanya bisa dilakukan PIC utama perusahaan.',
            style: t.bodySmall,
          ),
        ],
        const JudulSeksi('Anggota aktif'),
        for (final a in aktif)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _KartuAnggota(
              anggota: a,
              bisaDinonaktifkan: data.sayaPicUtama && !a.saya,
              sibuk: sedangDinonaktifkan == a.id,
              onNonaktifkan: () => onNonaktifkan(a),
            ),
          ),
        if (nonaktif.isNotEmpty) ...[
          const JudulSeksi('Nonaktif'),
          for (final a in nonaktif)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _KartuAnggota(
                anggota: a,
                bisaDinonaktifkan: false,
                sibuk: false,
                onNonaktifkan: () {},
              ),
            ),
        ],
        // Alamat email orang yang diundang hanya untuk PIC utama — staf tidak
        // perlu melihat siapa yang sedang diundang.
        if (data.sayaPicUtama && data.undangan.isNotEmpty) ...[
          const JudulSeksi('Undangan menunggu'),
          for (final u in data.undangan)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Kertas(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.email, style: t.titleSmall),
                          Text(
                            '${u.labelPeran} · berlaku sampai '
                            '${Format.tanggal(u.kedaluwarsa)}',
                            style: t.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _KartuAnggota extends StatelessWidget {
  const _KartuAnggota({
    required this.anggota,
    required this.bisaDinonaktifkan,
    required this.sibuk,
    required this.onNonaktifkan,
  });

  final Anggota anggota;
  final bool bisaDinonaktifkan;
  final bool sibuk;
  final VoidCallback onNonaktifkan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);
    final a = anggota;
    return Kertas(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.person_outline, color: a.aktif ? null : m.tinta2),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.saya ? '${a.nama} (Anda)' : a.nama,
                      style: t.titleSmall,
                    ),
                    if (a.jabatan != null) Text(a.jabatan!, style: t.bodySmall),
                    if (a.email != null) Text(a.email!, style: t.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: SidikLencana(
                  a.aktif
                      ? StatusSidik(
                          a.labelPeran,
                          a.picUtama ? NadaStatus.lulus : NadaStatus.draf,
                          a.picUtama
                              ? Icons.verified_user_outlined
                              : Icons.person_outline,
                        )
                      : const StatusSidik(
                          'Nonaktif',
                          NadaStatus.draf,
                          Icons.pause_circle_outline,
                        ),
                ),
              ),
            ],
          ),
          if (bisaDinonaktifkan) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: SidikTombol(
                label: 'Nonaktifkan',
                ragam: RagamTombol.bahayaGaris,
                kecil: true,
                sibuk: sibuk,
                onPressed: onNonaktifkan,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
