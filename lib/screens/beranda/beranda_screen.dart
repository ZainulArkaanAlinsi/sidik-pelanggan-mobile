import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/sidik_material.dart';
import '../../models/data_pelanggan.dart';
import '../../models/status_berlaku.dart';
import '../../providers/data_provider.dart';
import '../../providers/koneksi_provider.dart';
import '../../providers/push_provider.dart';
import '../../widgets/banner.dart';
import '../../widgets/kerangka.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/sidik/sidik_tombol.dart';
import '../../widgets/umum.dart';
import '../alat/alat_detail_screen.dart';
import '../alat/daftar_alat_screen.dart';
import '../paket/paket_detail_screen.dart';
import '../paket/paket_screen.dart';
import '../rangka.dart';
import '../sertifikat/sertifikat_detail_screen.dart';

/// Beranda — ringkasan: apa yang perlu perhatian, tanpa mencari.
///
/// Dari atas: alat yang lewat jadwal atau jatuh tempo dalam 30 / 60 / 90 hari
/// (ketuk kotaknya untuk daftar alatnya), tiga alat paling mendesak,
/// sertifikat terbaru, dan paket yang sedang dikerjakan lab. Daftar lengkap
/// alat ada di [DaftarAlatScreen], sertifikat di tab Sertifikat, paket di
/// [PaketScreen].
///
/// Data: `GET /beranda` (angka 0–30 hari, sertifikat terbaru, paket berjalan)
/// dan `GET /alat` (kelompok 31–60 dan 61–90 hari, [jatuhTempoProvider]). Tarik
/// layar untuk memuat ulang.
class BerandaScreen extends ConsumerStatefulWidget {
  const BerandaScreen({super.key});

  @override
  ConsumerState<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends ConsumerState<BerandaScreen> {
  bool _izinDitawarkan = false;

  Future<void> _segarkan() async {
    ref.invalidate(berandaProvider);
    ref.invalidate(jatuhTempoProvider);
    ref.invalidate(jumlahBelumDibacaProvider);
    try {
      await ref.read(berandaProvider.future);
    } catch (_) {
      // Galatnya tampil di layar (KeadaanGalat); jangan dilempar ke pemicu tarik.
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(berandaProvider);
    // Selama dimuat ulang karena perusahaan/akun berganti (`isReloading`),
    // nilai lama MASIH ada di `async.value`. Jangan dipakai: nama perusahaan
    // lama tidak boleh tampil di judul sambil menunggu yang baru. Tarik-untuk-
    // segarkan (`isRefreshing`) tetap menampilkan data yang ada.
    final beranda = async.isReloading ? null : async.value;
    // Momen kontekstual izin notifikasi (REQ-NTF-08): begitu pengguna melihat
    // alatnya untuk pertama kali, pengingat jadwal punya alasan yang jelas.
    // `tawarkanNotifikasi` sendiri sekali per HP dan diam kalau izin sudah ada.
    if (!_izinDitawarkan && (beranda?.jumlahAlat ?? 0) > 0) {
      _izinDitawarkan = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) tawarkanNotifikasi(context, ref);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          beranda?.namaPerusahaan.isNotEmpty == true
              ? beranda!.namaPerusahaan
              : 'Beranda',
        ),
      ),
      body: Column(
        children: [
          const BannerIzinNotifikasi(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _segarkan,
              child: async.when(
                loading: () => const Memuat(),
                error: (e, _) => KeadaanGalat(
                  galat: e,
                  cobaLagi: () => ref.invalidate(berandaProvider),
                ),
                data: (b) => _Isi(beranda: b),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _bukaDaftarAlat(BuildContext context, FilterAlat filter) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DaftarAlatScreen(filterAwal: filter),
      ),
    );

class _Isi extends ConsumerWidget {
  const _Isi({required this.beranda});

  final Beranda beranda;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = beranda;
    final t = Theme.of(context).textTheme;
    final koneksi = ref.watch(koneksiProvider);
    final jt = ref.watch(jatuhTempoProvider);
    // Sama seperti judul: hitungan perusahaan lama tidak boleh bocor saat
    // hitungan perusahaan baru masih dimuat.
    final r = jt.isReloading ? null : jt.value;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
      children: [
        if (koneksi.offline && koneksi.dataTerakhir != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Terakhir diperbarui '
              '${Format.jamAtauTanggal(koneksi.dataTerakhir!)}',
              style: t.bodySmall,
            ),
          ),
        const JudulSeksi('Jatuh tempo kalibrasi'),
        _KotakJatuhTempo(
          beranda: b,
          kelompok2: r?.kelompok2.length,
          kelompok3: r?.kelompok3.length,
        ),
        if (jt.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Hitungan 31–90 hari belum bisa dimuat. Tarik layar ke bawah '
              'untuk mencoba lagi.',
              style: t.bodySmall,
            ),
          ),
        if (b.jumlahAlat == 0) ...[
          const SizedBox(height: jarak),
          const Kertas(
            padding: EdgeInsets.all(jarak),
            child: KeadaanKosongIsi(
              ikon: Icons.straighten_outlined,
              judul: 'Belum ada alat',
              keterangan:
                  'Alat yang pernah dikalibrasi di PT Sidik muncul di sini.',
            ),
          ),
        ] else
          ..._perluPerhatian(context, jt, r),
        JudulSeksi(
          'Sertifikat terbaru',
          aksi: _AksiLihatSemua(
            semantik: 'Lihat semua sertifikat',
            onTap: () =>
                ref.read(tabProvider.notifier).pilih(IndeksTab.sertifikat),
          ),
        ),
        if (b.sertifikatTerbaru.isEmpty)
          const _KosongSingkat('Belum ada sertifikat yang terbit.')
        else
          for (final s in b.sertifikatTerbaru.take(3))
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
        JudulSeksi(
          'Paket yang sedang dikerjakan',
          aksi: _AksiLihatSemua(
            semantik: 'Lihat semua paket',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PaketScreen()),
            ),
          ),
        ),
        if (b.paketBerjalan.isEmpty)
          const _KosongSingkat('Tidak ada paket yang sedang dikerjakan.')
        else ...[
          for (final p in b.paketBerjalan.take(3))
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
          if (b.jumlahPaketBerjalan > b.paketBerjalan.take(3).length)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'dan ${b.jumlahPaketBerjalan - b.paketBerjalan.take(3).length} '
                'paket lainnya',
                style: t.bodySmall,
              ),
            ),
        ],
      ],
    );
  }

  /// Tiga alat paling mendesak + jalan ke daftar lengkap.
  List<Widget> _perluPerhatian(
    BuildContext context,
    AsyncValue<RingkasanJatuhTempo> jt,
    RingkasanJatuhTempo? r,
  ) {
    final Widget isi;
    if (r != null) {
      final alat = r.urut.take(3).toList();
      isi = alat.isEmpty
          ? _KosongSingkat(
              'Tidak ada alat yang '
              '${StatusBerlaku.lewatJadwal.label.toLowerCase()} atau jatuh '
              'tempo dalam 90 hari.',
            )
          : Column(
              children: [
                for (final a in alat)
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
            );
    } else if (jt.isLoading) {
      isi = const KerangkaKartu();
    } else {
      isi = const SizedBox.shrink();
    }
    return [
      const JudulSeksi('Perlu perhatian'),
      isi,
      const SizedBox(height: 2),
      SidikTombol(
        label: 'Lihat semua alat (${beranda.jumlahAlat})',
        ikon: Icons.straighten_outlined,
        penuh: true,
        onPressed: () => _bukaDaftarAlat(context, FilterAlat.semua),
      ),
    ];
  }
}

/// Empat kotak: lewat jadwal, lalu tiga rentang jatuh tempo. 0–30 hari dan
/// lewat jadwal dari hitungan server (sama dengan daftar yang terbuka saat
/// diketuk); 31–60 dan 61–90 dari hitungan aplikasi ([kelompok2], [kelompok3],
/// `null` = belum/tidak bisa dimuat, tampil "–").
class _KotakJatuhTempo extends StatelessWidget {
  const _KotakJatuhTempo({
    required this.beranda,
    required this.kelompok2,
    required this.kelompok3,
  });

  final Beranda beranda;
  final int? kelompok2;
  final int? kelompok3;

  @override
  Widget build(BuildContext context) {
    Widget baris(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 10),
          Expanded(child: b),
        ],
      ),
    );

    return Column(
      children: [
        baris(
          _Angka(
            angka: beranda.lewatJatuhTempo,
            label: FilterAlat.lewatJadwal.label,
            nada: beranda.lewatJatuhTempo > 0 ? _Nada.gagal : _Nada.netral,
            onTap: () => _bukaDaftarAlat(context, FilterAlat.lewatJadwal),
          ),
          _Angka(
            angka: beranda.segeraJatuhTempo,
            label: FilterAlat.hari30.label,
            nada: beranda.segeraJatuhTempo > 0 ? _Nada.awas : _Nada.netral,
            onTap: () => _bukaDaftarAlat(context, FilterAlat.hari30),
          ),
        ),
        const SizedBox(height: 10),
        baris(
          _Angka(
            angka: kelompok2,
            label: FilterAlat.hari60.label,
            onTap: () => _bukaDaftarAlat(context, FilterAlat.hari60),
          ),
          _Angka(
            angka: kelompok3,
            label: FilterAlat.hari90.label,
            onTap: () => _bukaDaftarAlat(context, FilterAlat.hari90),
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

  /// `null` = belum bisa dihitung.
  final int? angka;
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
    return Semantics(
      button: true,
      label: '$label: ${angka == null ? 'belum tersedia' : '$angka alat'}',
      excludeSemantics: true,
      child: Kertas(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              angka == null ? '–' : '$angka',
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
      ),
    );
  }
}

/// Tombol teks di ujung judul seksi. Tinggi sentuhnya 48 dp dari tema.
/// [semantik] = kalimat lengkap untuk pembaca layar (teksnya sendiri pendek
/// supaya judul seksi di sebelahnya tidak terjepit di layar sempit).
class _AksiLihatSemua extends StatelessWidget {
  const _AksiLihatSemua({required this.semantik, required this.onTap});

  final String semantik;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Flexible(
    child: TextButton(
      onPressed: onTap,
      child: Text('Lihat semua', semanticsLabel: semantik),
    ),
  );
}

/// Satu kalimat di dalam kertas untuk bagian yang kosong.
class _KosongSingkat extends StatelessWidget {
  const _KosongSingkat(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) => Kertas(
    padding: const EdgeInsets.all(14),
    child: Text(teks, style: Theme.of(context).textTheme.bodyMedium),
  );
}
