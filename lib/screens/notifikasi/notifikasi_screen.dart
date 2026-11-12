import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/format.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/bagian_sidik.dart';
import '../../widgets/daftar_berhalaman.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kartu_sidik.dart';
import '../../widgets/keadaan_kosong.dart';
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

  void _buka(BuildContext context, WidgetRef ref, Notifikasi n) {
    _dibaca(ref, n);
    // Tautan → layar tujuannya; yang tanpa tautan cukup ditandai dibaca.
    final tujuan = _tujuan(n);
    if (tujuan != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => tujuan));
    } else if (n.kategori == 'pelanggan_alat_jatuh_tempo') {
      // Pengingat jadwal → ringkasan jatuh tempo di Beranda.
      ref.read(tabProvider.notifier).pilih(IndeksTab.beranda);
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notifikasiProvider);
    final semua = async.value?.isi ?? const <Notifikasi>[];

    return HalamanSidik(
      judul: 'Notifikasi',
      aksi: [
        IconButton(
          tooltip: 'Tandai semua dibaca',
          icon: const Icon(Icons.done_all),
          onPressed: () => _tandaiSemua(context, ref),
        ),
      ],
      isi: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notifikasiProvider);
          ref.invalidate(jumlahBelumDibacaProvider);
          await ref.read(notifikasiProvider.future);
        },
        child: DaftarBerhalaman<Notifikasi>(
          async: async,
          namaButir: 'notifikasi',
          padding: Spasi.daftar(context),
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
            final baris = _KartuNotifikasi(
              notifikasi: n,
              onTap: () => _buka(context, ref, n),
            );
            if (!kepala) return baris;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [BagianSidik(_labelHari(hari)), baris],
            );
          },
        ),
      ),
    );
  }
}

/// Satu notifikasi: titik penanda di kiri untuk yang belum dibaca (bukan latar
/// berwarna, yang di sepuluh baris sekaligus cuma jadi bising), judul tebal
/// selama belum dibaca, isi, dan waktu.
class _KartuNotifikasi extends StatelessWidget {
  const _KartuNotifikasi({required this.notifikasi, required this.onTap});

  final Notifikasi notifikasi;
  final VoidCallback onTap;

  /// Garis tengah titik penanda.
  static const double _titik = 10;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final n = notifikasi;
    return KartuSidik(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _titik,
            height: _titik,
            margin: const EdgeInsets.only(top: Spasi.xs + 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: n.dibaca ? Colors.transparent : s.primary,
            ),
          ),
          const SizedBox(width: Spasi.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.judul,
                  semanticsLabel: n.dibaca
                      ? n.judul
                      : 'Belum dibaca. ${n.judul}',
                  style: n.dibaca
                      ? t.bodyMedium?.copyWith(fontWeight: FontWeight.w500)
                      : t.titleSmall,
                ),
                if (n.isi != null) ...[
                  const SizedBox(height: Spasi.xs / 2),
                  Text(
                    n.isi!,
                    style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: Spasi.xs),
                Text(Format.tanggalJam(n.dibuat), style: t.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
