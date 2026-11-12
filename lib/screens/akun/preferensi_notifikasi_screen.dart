import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kartu_sidik.dart';
import '../../widgets/keadaan_galat.dart';
import '../../widgets/kerangka.dart';

/// Satu saklar yang ditampilkan. Hanya saklar yang SEKARANG mengatur sesuatu
/// di server: `pesan_lab` (balasan di utas permintaan) tidak ditampilkan
/// karena permintaan kalibrasi dicabut (K-50-09) dan tidak ada lagi
/// pengirimnya — nilainya di server dibiarkan apa adanya.
class SaklarNotifikasi {
  const SaklarNotifikasi(this.kunci, this.judul, this.keterangan);

  final String kunci;
  final String judul;
  final String keterangan;
}

const daftarSaklarNotifikasi = <SaklarNotifikasi>[
  SaklarNotifikasi(
    'pengingat_jadwal',
    'Pengingat jadwal kalibrasi',
    'Kabar saat alat mendekati atau melewati jadwal kalibrasi ulang.',
  ),
  // Kunci lamanya `status_permintaan`; sejak permintaan dicabut, saklar ini
  // memegang kabar sertifikat terbit (kontrak §8).
  SaklarNotifikasi(
    'status_permintaan',
    'Sertifikat terbit',
    'Kabar saat sertifikat alat perusahaan Anda sudah terbit. Kabar revisi '
        'atau pembatalan sertifikat selalu dikirim.',
  ),
  SaklarNotifikasi(
    'ringkasan_email_mingguan',
    'Ringkasan mingguan lewat email',
    'Email tiap Senin pagi berisi alat yang mendekati jadwal dan sertifikat '
        'terbaru. Tidak dikirim pada minggu tanpa isi.',
  ),
];

/// Saklar notifikasi anggota ini untuk perusahaan yang sedang aktif. Server
/// menyimpannya per anggota per perusahaan, jadi akun di dua perusahaan punya
/// dua set — nama perusahaannya ditulis di layar supaya tidak membingungkan.
class PreferensiNotifikasiScreen extends ConsumerWidget {
  const PreferensiNotifikasiScreen({super.key});

  Future<void> _ubah(
    BuildContext context,
    WidgetRef ref,
    String kunci,
    bool nilai,
  ) async {
    final pesan = ScaffoldMessenger.of(context);
    try {
      await ref.read(preferensiNotifikasiProvider.notifier).setel(kunci, nilai);
    } on GalatApi catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(e.pesan)));
    } catch (_) {
      pesan.showSnackBar(
        const SnackBar(content: Text('Pengaturan belum tersimpan. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(preferensiNotifikasiProvider);
    final aktif = ref.watch(sesiProvider).value?.keanggotaanAktif;
    final t = context.teks;
    return HalamanSidik(
      judul: 'Pengaturan notifikasi',
      isi: async.when(
        loading: () => const Memuat(),
        error: (e, _) => KeadaanGalat(
          galat: e,
          cobaLagi: () => ref.invalidate(preferensiNotifikasiProvider),
        ),
        data: (nilai) => ListView(
          padding: Spasi.daftar(context),
          children: [
            Text(
              aktif == null
                  ? 'Pengaturan ini berlaku untuk perusahaan yang sedang dibuka.'
                  : 'Pengaturan ini khusus untuk ${aktif.namaPerusahaan}. '
                        'Perusahaan lain di akun Anda punya pengaturan sendiri.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: Spasi.lg),
            KartuSidik(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, s) in daftarSaklarNotifikasi.indexed) ...[
                    if (i > 0) const Divider(),
                    SwitchListTile(
                      key: ValueKey('saklar-${s.kunci}'),
                      title: Text(s.judul),
                      subtitle: Text(s.keterangan),
                      value: nilai[s.kunci] ?? false,
                      onChanged: (v) => _ubah(context, ref, s.kunci, v),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Spasi.lg),
            Text(
              'Saklar yang dimatikan berarti kabarnya tidak dikirim sama sekali. '
              'Notifikasi yang dimatikan lewat pengaturan HP tetap masuk ke '
              'kotak Notifikasi di aplikasi.',
              style: t.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
