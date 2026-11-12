import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../models/status_berlaku.dart';
import '../../providers/data_provider.dart';
import '../../providers/koneksi_provider.dart';
import '../../providers/push_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/bagian_sidik.dart';
import '../../widgets/banner.dart';
import '../../widgets/baris_menu.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kartu_alat.dart';
import '../../widgets/kartu_paket.dart';
import '../../widgets/kartu_sertifikat.dart';
import '../../widgets/kartu_sidik.dart';
import '../../widgets/keadaan_galat.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/kerangka.dart';
import '../../widgets/logo_sidik.dart';
import '../../widgets/tombol_sidik.dart';
import '../akun/bantuan_screen.dart';
import '../alat/alat_detail_screen.dart';
import '../paket/paket_detail_screen.dart';
import '../paket/paket_screen.dart';
import '../rangka.dart';
import '../sertifikat/sertifikat_detail_screen.dart';
import 'beranda_kpi.dart';

/// Beranda: ringkasan apa yang perlu perhatian, tanpa mencari.
///
/// Dari atas: sapaan dan perusahaan aktif, empat kartu jatuh tempo (lewat
/// jadwal, 0–30, 31–60, 61–90 hari; ketuk untuk daftar alatnya), tiga alat
/// paling mendesak, sertifikat terbaru, paket yang sedang dikerjakan lab, dan
/// jalan pintas "Hubungi lab". Daftar lengkap alat ada di tab Alat
/// ([DaftarAlatScreen]), sertifikat di tab Sertifikat, paket di [PaketScreen].
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
    // lama tidak boleh tampil sambil menunggu yang baru. Tarik-untuk-segarkan
    // (`isRefreshing`) tetap menampilkan data yang ada.
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

    return HalamanSidik(
      judulKustom: const _JudulMerek(),
      isi: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(Spasi.lg, Spasi.md, Spasi.lg, 0),
            child: BannerIzinNotifikasi(),
          ),
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

/// Judul app bar Beranda: logo kecil + nama aplikasi.
class _JudulMerek extends StatelessWidget {
  const _JudulMerek();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const LogoSidik(tinggi: UkuranIkon.besar),
      const SizedBox(width: Spasi.md),
      Flexible(
        child: Text(
          'SIDIK Pelanggan',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.teks.titleMedium,
        ),
      ),
    ],
  );
}

class _Isi extends ConsumerWidget {
  const _Isi({required this.beranda});

  final Beranda beranda;

  /// Alat yang ditampilkan di "Perlu perhatian", dan sertifikat/paket terbaru.
  static const _tampilMaks = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = beranda;
    final t = context.teks;
    final koneksi = ref.watch(koneksiProvider);
    final jt = ref.watch(jatuhTempoProvider);
    // Hitungan perusahaan lama tidak boleh bocor saat hitungan perusahaan baru
    // masih dimuat.
    final r = jt.isReloading ? null : jt.value;
    final sisaPaket =
        b.jumlahPaketBerjalan - b.paketBerjalan.take(_tampilMaks).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Spasi.daftar(context),
      children: [
        _Sapaan(namaPerusahaan: b.namaPerusahaan),
        if (koneksi.offline && koneksi.dataTerakhir != null)
          Padding(
            padding: const EdgeInsets.only(top: Spasi.sm),
            child: Text(
              'Terakhir diperbarui '
              '${Format.jamAtauTanggal(koneksi.dataTerakhir!)}',
              style: t.bodySmall,
            ),
          ),
        const BagianSidik('Jatuh tempo kalibrasi'),
        KotakJatuhTempo(
          beranda: b,
          kelompok2: r?.kelompok2.length,
          kelompok3: r?.kelompok3.length,
        ),
        if (jt.hasError)
          Padding(
            padding: const EdgeInsets.only(top: Spasi.sm),
            child: Text(
              'Hitungan 31–90 hari belum bisa dimuat. Tarik layar ke bawah '
              'untuk mencoba lagi.',
              style: t.bodySmall,
            ),
          ),
        if (b.jumlahAlat == 0) ...[
          const SizedBox(height: Spasi.lg),
          const KartuSidik(
            child: KeadaanKosongIsi(
              ikon: Icons.straighten_outlined,
              judul: 'Belum ada alat',
              keterangan:
                  'Alat yang pernah dikalibrasi di PT Sidik muncul di sini.',
            ),
          ),
        ] else
          ..._perluPerhatian(context, ref, jt, r),
        BagianSidik(
          'Sertifikat terbaru',
          aksi: AksiBagian(
            label: 'Lihat semua',
            semantik: 'Lihat semua sertifikat',
            onTap: () =>
                ref.read(tabProvider.notifier).pilih(IndeksTab.sertifikat),
          ),
        ),
        if (b.sertifikatTerbaru.isEmpty)
          const _KosongSingkat('Belum ada sertifikat yang terbit.')
        else
          for (final s in b.sertifikatTerbaru.take(_tampilMaks))
            Padding(
              padding: const EdgeInsets.only(bottom: Spasi.md),
              child: KartuSertifikat(
                sertifikat: s,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SertifikatDetailScreen(id: s.id),
                  ),
                ),
              ),
            ),
        BagianSidik(
          'Paket yang sedang dikerjakan',
          aksi: AksiBagian(
            label: 'Lihat semua',
            semantik: 'Lihat semua paket',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PaketScreen()),
            ),
          ),
        ),
        if (b.paketBerjalan.isEmpty)
          const _KosongSingkat('Tidak ada paket yang sedang dikerjakan.')
        else ...[
          for (final p in b.paketBerjalan.take(_tampilMaks))
            Padding(
              padding: const EdgeInsets.only(bottom: Spasi.md),
              child: KartuPaket(
                paket: p,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PaketDetailScreen(id: p.id),
                  ),
                ),
              ),
            ),
          if (sisaPaket > 0)
            Text('dan $sisaPaket paket lainnya', style: t.bodySmall),
        ],
        const BagianSidik('Butuh bantuan?'),
        KelompokBaris(
          baris: [
            BarisMenu(
              ikon: Icons.support_agent,
              judul: 'Hubungi lab',
              keterangan: 'Tanya jadwal, sertifikat, atau paket',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const BantuanScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Tiga alat paling mendesak + jalan ke tab Alat.
  List<Widget> _perluPerhatian(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<RingkasanJatuhTempo> jt,
    RingkasanJatuhTempo? r,
  ) {
    final Widget isi;
    if (r != null) {
      final alat = r.urut.take(_tampilMaks).toList();
      isi = alat.isEmpty
          ? _KosongSingkat(
              'Tidak ada alat yang '
              '${StatusBerlaku.lewatJadwal.label.toLowerCase()} atau jatuh '
              'tempo dalam 90 hari.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final a in alat)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spasi.md),
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
      const BagianSidik('Perlu perhatian'),
      isi,
      TombolSidik(
        label: 'Lihat semua alat (${beranda.jumlahAlat})',
        ikon: Icons.precision_manufacturing_outlined,
        penuh: true,
        onPressed: () => ref.read(tabProvider.notifier).pilih(IndeksTab.alat),
      ),
    ];
  }
}

/// Sapaan menurut jam, dan perusahaan yang sedang dibuka.
class _Sapaan extends ConsumerWidget {
  const _Sapaan({required this.namaPerusahaan});

  final String namaPerusahaan;

  static String _salam(int jam) => switch (jam) {
    < 11 => 'Selamat pagi',
    < 15 => 'Selamat siang',
    < 18 => 'Selamat sore',
    _ => 'Selamat malam',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.teks;
    final s = context.skema;
    final nama = ref.watch(sesiProvider).value?.akun.nama;
    final salam = _salam(ref.read(jamHpProvider)().hour);
    return Padding(
      padding: const EdgeInsets.only(top: Spasi.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nama == null || nama.isEmpty ? salam : '$salam, $nama',
            style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
          ),
          if (namaPerusahaan.isNotEmpty) ...[
            const SizedBox(height: Spasi.xs),
            Row(
              children: [
                Icon(
                  Icons.apartment_outlined,
                  size: UkuranIkon.sedang,
                  color: s.primary,
                ),
                const SizedBox(width: Spasi.sm),
                Expanded(child: Text(namaPerusahaan, style: t.headlineSmall)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Satu kalimat di dalam kartu untuk bagian yang kosong.
class _KosongSingkat extends StatelessWidget {
  const _KosongSingkat(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) =>
      KartuSidik(child: Text(teks, style: context.teks.bodyMedium));
}
