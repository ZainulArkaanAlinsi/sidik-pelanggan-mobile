import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/daftar_berhalaman.dart';
import '../../widgets/umum.dart';
import '../rangka.dart';
import '../tautan.dart';

/// Kotak masuk (S16): per tanggal, yang belum dibaca diberi titik biru di
/// kiri (bukan latar berwarna — latar berwarna di sepuluh baris sekaligus cuma
/// jadi bising), infinite scroll.
class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});

  Future<void> _dibaca(WidgetRef ref, Notifikasi n) async {
    if (n.dibaca) return;
    try {
      await ref.read(layananProvider).tandaiDibaca(n.id);
    } catch (_) {
      // Gagal menandai bukan alasan menahan pengguna — tanda dibaca akan
      // terkirim lagi lain kali dibuka.
    }
    ref.invalidate(notifikasiProvider);
    ref.invalidate(jumlahBelumDibacaProvider);
  }

  /// `tautan.tipe` dari server → layar tujuan. Tipe yang belum dikenal
  /// (server lebih baru dari aplikasi) tidak membuka apa-apa.
  @visibleForTesting
  static Widget? tujuanTautan(String? tipe, int? id) =>
      layarUntukTautan(tipe, id);

  Widget? _tujuan(Notifikasi n) => tujuanTautan(n.tautanTipe, n.tautanId);

  static DateTime? _hari(DateTime? t) =>
      t == null ? null : DateTime(t.year, t.month, t.day);

  static String _labelHari(DateTime? hari) {
    if (hari == null) return 'Sebelumnya';
    final kini = _hari(DateTime.now())!;
    final selisih = kini.difference(hari).inDays;
    if (selisih == 0) return 'Hari ini';
    if (selisih == 1) return 'Kemarin';
    return Format.tanggal(hari);
  }

  Future<void> _tandaiSemua(BuildContext context, WidgetRef ref) async {
    final pesan = ScaffoldMessenger.of(context);
    try {
      await ref.read(layananProvider).tandaiSemuaDibaca();
    } on GalatApi catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(e.pesan)));
    }
    ref.invalidate(notifikasiProvider);
    ref.invalidate(jumlahBelumDibacaProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notifikasiProvider);
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    final semua = async.value?.isi ?? const <Notifikasi>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () => _tandaiSemua(context, ref),
            child: const Text('Tandai semua dibaca'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notifikasiProvider);
          ref.invalidate(jumlahBelumDibacaProvider);
          await ref.read(notifikasiProvider.future);
        },
        child: DaftarBerhalaman<Notifikasi>(
          async: async,
          namaButir: 'notifikasi',
          padding: const EdgeInsets.only(bottom: 32),
          pemisah: const Divider(height: 1),
          muatLagi: ({ulangiGalat = false}) => ref
              .read(notifikasiProvider.notifier)
              .muatLagi(ulangiGalat: ulangiGalat),
          cobaLagi: () => ref.invalidate(notifikasiProvider),
          kosong: const KeadaanKosong(
            ikon: Icons.notifications_none,
            judul: 'Belum ada notifikasi',
            keterangan:
                'Pengingat jadwal kalibrasi ulang dan kabar sertifikat baru '
                'muncul di sini.',
          ),
          butir: (context, n) {
            final i = semua.indexOf(n);
            final hari = _hari(n.dibuat);
            final kepala = i <= 0 || _hari(semua[i - 1].dibuat) != hari;
            final baris = ListTile(
              onTap: () {
                _dibaca(ref, n);
                // Tautan → layar tujuannya; yang tanpa tautan cukup
                // ditandai dibaca.
                final tujuan = _tujuan(n);
                if (tujuan != null) {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => tujuan));
                } else if (n.kategori == 'pelanggan_alat_jatuh_tempo') {
                  // Pengingat jadwal → daftar alat di Beranda.
                  ref.read(saringanAlatAwalProvider.notifier).atur(null);
                  ref.read(tabProvider.notifier).pilih(IndeksTab.beranda);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
              leading: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: n.dibaca ? Colors.transparent : m.biruTinta,
                ),
              ),
              minLeadingWidth: 10,
              title: Text(
                n.judul,
                semanticsLabel: n.dibaca ? n.judul : 'Belum dibaca. ${n.judul}',
                style: t.titleSmall?.copyWith(
                  fontWeight: n.dibaca ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (n.isi != null) Text(n.isi!, style: t.bodyMedium),
                  const SizedBox(height: 2),
                  Text(Format.tanggalJam(n.dibuat), style: t.bodySmall),
                ],
              ),
              isThreeLine: n.isi != null,
            );
            if (!kepala) return baris;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: jarak),
                  child: JudulSeksi(_labelHari(hari)),
                ),
                baris,
              ],
            );
          },
        ),
      ),
    );
  }
}
