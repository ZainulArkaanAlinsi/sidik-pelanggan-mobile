import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/sidik_material.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/umum.dart';
import '../alat/alat_detail_screen.dart';
import '../notifikasi/notifikasi_screen.dart';
import '../paket/paket_detail_screen.dart';
import '../paket/paket_screen.dart';
import '../rangka.dart';
import '../sertifikat/sertifikat_detail_screen.dart';

/// Beranda — urutannya urutan KEPENTINGAN, bukan urutan data:
/// 1. angka yang butuh tindakan (lewat / segera jatuh tempo),
/// 2. alat yang perlu diperhatikan,
/// 3. paket yang sedang di lab,
/// 4. sertifikat terbaru.
class BerandaScreen extends ConsumerWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(berandaProvider);
    final belumDibaca = ref.watch(jumlahBelumDibacaProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(async.value?.namaPerusahaan ?? 'Beranda'),
        actions: [
          IconButton(
            tooltip: belumDibaca == 0
                ? 'Notifikasi'
                : 'Notifikasi, $belumDibaca belum dibaca',
            icon: Badge(
              isLabelVisible: belumDibaca > 0,
              label: Text('$belumDibaca'),
              child: const Icon(Icons.notifications_none),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const NotifikasiScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(berandaProvider);
          ref.invalidate(jumlahBelumDibacaProvider);
          await ref.read(berandaProvider.future);
        },
        child: async.when(
          loading: () => const Memuat(),
          error: (e, _) => KeadaanGalat(
            galat: e,
            cobaLagi: () => ref.invalidate(berandaProvider),
          ),
          data: (b) => _Isi(beranda: b),
        ),
      ),
    );
  }
}

class _Isi extends ConsumerWidget {
  const _Isi({required this.beranda});

  final Beranda beranda;

  void _keAlat(WidgetRef ref, String? saring) {
    ref.read(saringanAlatAwalProvider.notifier).atur(saring);
    ref.read(tabProvider.notifier).pilih(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = beranda;
    return ListView(
      padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _Angka(
                angka: b.lewatJatuhTempo,
                label: 'Lewat jatuh tempo',
                nada: b.lewatJatuhTempo > 0 ? _Nada.gagal : _Nada.netral,
                onTap: () => _keAlat(ref, 'lewat'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Angka(
                angka: b.segeraJatuhTempo,
                label: 'Jatuh tempo ≤ ${b.jendelaHari} hari',
                nada: b.segeraJatuhTempo > 0 ? _Nada.awas : _Nada.netral,
                onTap: () => _keAlat(ref, 'segera'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Angka(
                angka: b.jumlahAlat,
                label: 'Alat terdaftar',
                onTap: () => _keAlat(ref, null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Angka(
                angka: b.paketBerjalan,
                label: 'Paket di lab',
                // Paket bukan tab lagi (tabnya dipakai Permintaan), jadi dibuka
                // sebagai layar biasa.
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PaketScreen()),
                ),
              ),
            ),
          ],
        ),

        if (b.perluPerhatian.isNotEmpty) ...[
          const JudulSeksi('Perlu dijadwalkan'),
          for (final a in b.perluPerhatian)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: KartuAlat(
                alat: a,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AlatDetailScreen(id: a.id),
                  ),
                ),
              ),
            ),
        ],

        if (b.daftarPaket.isNotEmpty) ...[
          const JudulSeksi('Paket di laboratorium'),
          for (final p in b.daftarPaket)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: KartuPaket(
                paket: p,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PaketDetailScreen(id: p.id),
                  ),
                ),
              ),
            ),
        ],

        const JudulSeksi('Sertifikat terbaru'),
        if (b.sertifikatTerbaru.isEmpty)
          Text(
            'Belum ada sertifikat terbit.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final s in b.sertifikatTerbaru)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: KartuSertifikat(
                sertifikat: s,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SertifikatDetailScreen(id: s.id),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

enum _Nada { netral, awas, gagal }

/// Satu angka ringkasan. Warna status HANYA kalau angkanya bukan nol — nol
/// alat terlambat itu kabar baik, bukan peringatan merah.
class _Angka extends StatelessWidget {
  const _Angka({
    required this.angka,
    required this.label,
    this.nada = _Nada.netral,
    required this.onTap,
  });

  final int angka;
  final String label;
  final _Nada nada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    final t = Theme.of(context).textTheme;
    final warna = switch (nada) {
      _Nada.gagal => m.gagal,
      _Nada.awas => m.awas,
      _Nada.netral => m.tinta,
    };
    return Kertas(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$angka',
            style: t.headlineMedium?.copyWith(
              color: warna,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: t.bodySmall, maxLines: 2),
        ],
      ),
    );
  }
}
