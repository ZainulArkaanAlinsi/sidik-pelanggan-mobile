import 'package:flutter/material.dart';

import '../core/api_pelanggan.dart';
import '../core/format.dart';
import '../core/theme/sidik_material.dart';
import '../models/data_pelanggan.dart';
import '../models/paket.dart';
import '../models/status_berlaku.dart';
import 'kerangka.dart';
import 'sidik/sidik_permukaan.dart';
import 'sidik/sidik_status.dart';
import 'sidik/sidik_tombol.dart';

/// Potongan tampilan yang dipakai lebih dari satu layar aplikasi pelanggan.
/// Semuanya mengikuti "Meja Kerja Lab": KERTAS untuk yang dibaca, LOGAM untuk
/// yang ditekan, warna status HANYA untuk status.

const jarak = 16.0;

/// [dasar] + tinggi navigasi sistem di bawah (gesture bar / tiga tombol).
///
/// Android 15+ (targetSdk 35+) memaksa edge-to-edge: layar penuh yang didorong
/// di atas Rangka menggambar sampai ke bawah navigasi sistem, dan isi terakhir
/// daftar (tombol kirim, baris terakhir sertifikat) tertutup tombol HP. Di tab
/// Rangka nilainya 0 — `Scaffold` induk sudah memakainya untuk NavigationBar.
/// `paddingOf` (bukan `viewPaddingOf`): 0 saat keyboard terbuka, karena
/// `adjustResize` sudah mengecilkan layarnya.
EdgeInsets denganTepiBawah(BuildContext context, EdgeInsets dasar) =>
    dasar + EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom);

/// Keadaan memuat: KERANGKA, bukan pemutar kosong (04-UI-UX §1.2).
/// [Memuat.new] untuk daftar, [Memuat.detail] untuk layar detail.
class Memuat extends StatelessWidget {
  const Memuat({super.key}) : _detail = false;

  const Memuat.detail({super.key}) : _detail = true;

  final bool _detail;

  @override
  Widget build(BuildContext context) =>
      _detail ? const KerangkaDetail() : const KerangkaDaftar();
}

/// Galat yang MENJELASKAN langkah berikutnya, bukan cuma "error".
class KeadaanGalat extends StatelessWidget {
  const KeadaanGalat({super.key, required this.galat, required this.cobaLagi});

  final Object galat;
  final VoidCallback cobaLagi;

  @override
  Widget build(BuildContext context) {
    final teks = galat is GalatApi
        ? (galat as GalatApi).pesan
        : 'Terjadi kesalahan. Coba lagi.';
    final jaringan = galat is GalatApi && (galat as GalatApi).jaringan;
    return ListView(
      padding: const EdgeInsets.all(jarak * 2),
      children: [
        Icon(
          jaringan ? Icons.wifi_off_outlined : Icons.error_outline,
          size: 44,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: jarak),
        Text(
          teks,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: jarak),
        Center(
          child: SidikTombol(
            label: 'Coba lagi',
            ikon: Icons.refresh,
            onPressed: cobaLagi,
          ),
        ),
      ],
    );
  }
}

/// Keadaan kosong: ikon + judul + satu kalimat yang bilang apa artinya,
/// dan bila ada, satu ajakan tindakan ([aksi], 04-UI-UX §1.2). Berupa
/// `ListView` supaya tarik-untuk-muat-ulang tetap jalan.
class KeadaanKosong extends StatelessWidget {
  const KeadaanKosong({
    super.key,
    required this.ikon,
    required this.judul,
    required this.keterangan,
    this.aksi,
  });

  final IconData ikon;
  final String judul;
  final String keterangan;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(jarak * 2),
    children: [
      KeadaanKosongIsi(ikon: ikon, judul: judul, keterangan: keterangan),
      if (aksi != null) ...[const SizedBox(height: jarak), Center(child: aksi)],
    ],
  );
}

/// Isi [KeadaanKosong] tanpa daftar bergulir — untuk ditaruh di dalam
/// daftar lain.
class KeadaanKosongIsi extends StatelessWidget {
  const KeadaanKosongIsi({
    super.key,
    required this.ikon,
    required this.judul,
    required this.keterangan,
  });

  final IconData ikon;
  final String judul;
  final String keterangan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Icon(
          ikon,
          size: 44,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: jarak),
        Text(judul, textAlign: TextAlign.center, style: t.titleMedium),
        const SizedBox(height: 6),
        Text(keterangan, textAlign: TextAlign.center, style: t.bodyMedium),
      ],
    );
  }
}

/// Label terukir di atas satu kelompok (huruf besar, spasi lebar) — pelat
/// nama laci, bukan isi yang dibaca.
class JudulSeksi extends StatelessWidget {
  const JudulSeksi(this.teks, {super.key, this.aksi});

  final String teks;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    final m = SidikMaterial.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, jarak, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(teks.toUpperCase(), style: m.gayaEtsa(ukuran: 11.5)),
          ),
          ?aksi,
        ],
      ),
    );
  }
}

/// Satu baris "label — nilai" di lembar detail.
class BarisInfo extends StatelessWidget {
  const BarisInfo(this.label, this.nilai, {super.key});

  final String label;
  final String? nilai;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isi = Text(
      (nilai == null || nilai!.isEmpty) ? '—' : nilai!,
      style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, batas) {
          // HP sempit / huruf diperbesar: label di atas nilai, supaya nilai
          // panjang (alamat, nomor sertifikat) tidak terjepit kolom 130 dp.
          if (batas.maxWidth < 300) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.bodySmall),
                const SizedBox(height: 2),
                isi,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 130, child: Text(label, style: t.bodySmall)),
              Expanded(child: isi),
            ],
          );
        },
      ),
    );
  }
}

/// Lencana status masa berlaku — SATU-SATUNYA pemetaan status → warna dan
/// ikon untuk alat dan sertifikat (04-UI-UX §5: abu / biru / hijau / kuning /
/// merah, selalu dengan teks dan ikon). Teksnya dari [StatusBerlaku.label]
/// (satu sumber, termasuk keputusan istilah K3: bukan "kedaluwarsa").
/// [statusAlat], [statusDokumen], dan [statusSertifikat] hanya memilih nilai
/// [StatusBerlaku] lalu lewat sini, jadi kata yang sama tidak bisa tampil
/// beda di dua layar.
///
/// Sisa hari tidak ikut di label: tampil di baris tanggal ([Format.sisaHari]),
/// supaya lencananya pendek dan muat di layar 320 dp.
StatusSidik statusBerlaku(StatusBerlaku s) => StatusSidik(
  s.label,
  switch (s) {
    StatusBerlaku.berlaku => NadaStatus.lulus,
    StatusBerlaku.segera || StatusBerlaku.digantikan => NadaStatus.awas,
    StatusBerlaku.lewatJadwal || StatusBerlaku.dibatalkan => NadaStatus.gagal,
    StatusBerlaku.diproses => NadaStatus.tunggu,
    StatusBerlaku.berakhir ||
    StatusBerlaku.belumPernah ||
    StatusBerlaku.tidakAktif => NadaStatus.draf,
  },
  switch (s) {
    StatusBerlaku.berlaku => Icons.verified_outlined,
    StatusBerlaku.segera => Icons.schedule,
    StatusBerlaku.lewatJadwal => Icons.error_outline,
    StatusBerlaku.digantikan => Icons.swap_horiz,
    StatusBerlaku.dibatalkan => Icons.block,
    StatusBerlaku.berakhir => Icons.history,
    StatusBerlaku.belumPernah => Icons.event_busy_outlined,
    StatusBerlaku.diproses => Icons.autorenew,
    StatusBerlaku.tidakAktif => Icons.pause_circle_outline,
  },
);

/// Status alat (dihitung server) sebagai lencana.
StatusSidik statusAlat(StatusKalibrasi s) =>
    statusBerlaku(StatusBerlaku.dariAlat(s));

/// Status dokumen sertifikat (dikirim server) sebagai lencana, tanpa menilai
/// tanggal. Untuk status lengkap dengan masa berlaku: [statusSertifikat].
StatusSidik statusDokumen(StatusDokumen s) =>
    statusBerlaku(StatusBerlaku.dariDokumen(s));

/// Status sertifikat termasuk masa berlakunya pada waktu [sekarang].
/// [adaPenerus] = di riwayat alat ada sertifikat berlaku yang lebih baru.
StatusSidik statusSertifikat(
  Sertifikat s, {
  required DateTime sekarang,
  int jendela = 30,
  bool adaPenerus = false,
}) => statusBerlaku(
  StatusBerlaku.dariSertifikat(
    s,
    sekarang: sekarang,
    jendela: jendela,
    adaPenerus: adaPenerus,
  ),
);

/// Keputusan sertifikat. FAIL TIDAK dilunakkan (REQ-SRT-04): labelnya
/// "Tidak memenuhi toleransi", merah, dengan ikon.
StatusSidik? statusKeputusan(String? keputusan) => switch (keputusan) {
  'PASS' => const StatusSidik(
    'Memenuhi toleransi',
    NadaStatus.lulus,
    Icons.check_circle_outline,
  ),
  'FAIL' => const StatusSidik(
    'Tidak memenuhi toleransi',
    NadaStatus.gagal,
    Icons.cancel_outlined,
  ),
  _ => null,
};

/// Kartu satu alat di daftar.
class KartuAlat extends StatelessWidget {
  const KartuAlat({super.key, required this.alat, required this.onTap});

  final Alat alat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Kertas(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(alat.nama, style: t.titleSmall)),
              const SizedBox(width: 8),
              Flexible(child: SidikLencana(statusAlat(alat.status))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              alat.merkModel,
              if (alat.serial != null) 'SN ${alat.serial}',
              ?alat.lokasi,
            ].where((s) => s.isNotEmpty).join(' · '),
            style: t.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  alat.jatuhTempo == null
                      ? 'Belum ada jadwal kalibrasi ulang'
                      : '${Format.sisaHari(alat.hariKeJatuhTempo)} · '
                            '${Format.tanggal(alat.jatuhTempo)}',
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kartu satu sertifikat di daftar.
class KartuSertifikat extends StatelessWidget {
  const KartuSertifikat({
    super.key,
    required this.sertifikat,
    required this.onTap,
  });

  final Sertifikat sertifikat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final vonis = statusKeputusan(sertifikat.keputusan);
    return Kertas(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.description_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sertifikat.nomor,
                  style: t.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    sertifikat.namaAlat ?? '-',
                    if (sertifikat.serial != null) 'SN ${sertifikat.serial}',
                  ].join(' · '),
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Terbit ${Format.tanggal(sertifikat.diterbitkan)}'
                  '${sertifikat.berlakuSampai == null ? '' : ' · berlaku s.d. ${Format.tanggal(sertifikat.berlakuSampai)}'}',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
          if (vonis != null || sertifikat.status != StatusDokumen.berlaku) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (sertifikat.status != StatusDokumen.berlaku)
                  SidikLencana(statusDokumen(sertifikat.status)),
                if (vonis != null && !sertifikat.dibatalkan) ...[
                  if (sertifikat.status != StatusDokumen.berlaku)
                    const SizedBox(height: 4),
                  SidikLencana(vonis),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Lencana tahap paket. Teksnya dari server (label versi pelanggan); aplikasi
/// hanya memilih nada & ikon untuk tiap kode tahap, dan kode yang tidak
/// dikenal tampil netral — daftar tahap boleh bertambah tanpa merusak layar.
StatusSidik statusPaket(String kode, String label) => switch (kode) {
  'diterima' => StatusSidik(label, NadaStatus.draf, Icons.inbox_outlined),
  'dikalibrasi' => StatusSidik(label, NadaStatus.tunggu, Icons.tune),
  'perlu_diulang' => StatusSidik(label, NadaStatus.awas, Icons.replay),
  'menunggu_pemeriksaan' || 'menunggu_pengesahan' => StatusSidik(
    label,
    NadaStatus.tunggu,
    Icons.fact_check_outlined,
  ),
  'sertifikat_terbit' => StatusSidik(
    label,
    NadaStatus.lulus,
    Icons.verified_outlined,
  ),
  'siap_diambil' => StatusSidik(
    label,
    NadaStatus.lulus,
    Icons.inventory_2_outlined,
  ),
  'diserahkan' => StatusSidik(
    label,
    NadaStatus.lulus,
    Icons.check_circle_outline,
  ),
  _ => StatusSidik(label, NadaStatus.draf, Icons.help_outline),
};

/// Kartu satu paket (order) di daftar pelacakan dan di Beranda.
class KartuPaket extends StatelessWidget {
  const KartuPaket({super.key, required this.paket, required this.onTap});

  final Paket paket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Kertas(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(paket.nomor, style: t.titleSmall)),
              const SizedBox(width: 8),
              Flexible(
                child: SidikLencana(statusPaket(paket.tahap, paket.tahapLabel)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${paket.jumlahSelesai} dari ${paket.jumlahAlat} alat selesai',
            style: t.bodySmall,
          ),
          Text(
            'Masuk ${Format.tanggal(paket.tanggalMasuk)}'
            '${paket.tanggalJanjiSelesai == null ? '' : ' · target selesai ${Format.tanggal(paket.tanggalJanjiSelesai)}'}',
            style: t.bodySmall,
          ),
          if (paket.terlambat) ...[
            const SizedBox(height: 6),
            const SidikLencana(
              StatusSidik(
                'Melewati target selesai',
                NadaStatus.awas,
                Icons.schedule,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
