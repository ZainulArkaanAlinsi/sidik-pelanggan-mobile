import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/umum.dart';
import '../koreksi/koreksi_detail_screen.dart';
import '../permintaan/permintaan_detail_screen.dart';
import '../sertifikat/sertifikat_detail_screen.dart';

/// Kotak masuk. Yang belum dibaca diberi titik biru di kiri, bukan latar
/// berwarna — latar berwarna di sepuluh baris sekaligus cuma jadi bising.
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
  static Widget? tujuanTautan(String? tipe, int? id) {
    if (id == null) return null;
    return switch (tipe) {
      'pelanggan_permintaan' => PermintaanDetailScreen(id: id),
      'pelanggan_sertifikat' => SertifikatDetailScreen(id: id),
      'pelanggan_koreksi' => KoreksiDetailScreen(id: id),
      _ => null,
    };
  }

  Widget? _tujuan(Notifikasi n) => tujuanTautan(n.tautanTipe, n.tautanId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notifikasiProvider);
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(layananProvider).tandaiSemuaDibaca();
              ref.invalidate(notifikasiProvider);
              ref.invalidate(jumlahBelumDibacaProvider);
            },
            child: const Text('Tandai semua dibaca'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notifikasiProvider);
          await ref.read(notifikasiProvider.future);
        },
        child: async.when(
          loading: () => const Memuat(),
          error: (e, _) => KeadaanGalat(
            galat: e,
            cobaLagi: () => ref.invalidate(notifikasiProvider),
          ),
          data: (h) => h.isi.isEmpty
              ? const KeadaanKosong(
                  ikon: Icons.notifications_none,
                  judul: 'Belum ada notifikasi',
                  keterangan:
                      'Pengingat jatuh tempo dan kabar sertifikat terbit akan muncul di sini.',
                )
              : ListView.separated(
                  itemCount: h.isi.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final n = h.isi[i];
                    return ListTile(
                      onTap: () {
                        _dibaca(ref, n);
                        // Tautan → layar tujuannya; yang tanpa tautan cukup
                        // ditandai dibaca.
                        final tujuan = _tujuan(n);
                        if (tujuan != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => tujuan),
                          );
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
                        style: t.titleSmall?.copyWith(
                          fontWeight: n.dibaca
                              ? FontWeight.w500
                              : FontWeight.w700,
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
                  },
                ),
        ),
      ),
    );
  }
}
