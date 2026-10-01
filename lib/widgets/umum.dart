import 'package:flutter/material.dart';

import '../core/api_pelanggan.dart';
import '../core/format.dart';
import '../core/theme/sidik_material.dart';
import '../models/data_pelanggan.dart';
import 'koreksi.dart' show statusDokumen;
import 'sidik/sidik_permukaan.dart';
import 'sidik/sidik_status.dart';
import 'sidik/sidik_tombol.dart';

/// Potongan tampilan yang dipakai lebih dari satu layar aplikasi pelanggan.
/// Semuanya mengikuti "Meja Kerja Lab": KERTAS untuk yang dibaca, LOGAM untuk
/// yang ditekan, warna status HANYA untuk status.

const jarak = 16.0;

/// Pemutar di tengah — dipakai waktu data pertama kali dimuat.
class Memuat extends StatelessWidget {
  const Memuat({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
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

/// Keadaan kosong: ikon + judul + satu kalimat yang bilang apa artinya.
class KeadaanKosong extends StatelessWidget {
  const KeadaanKosong({
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
    return ListView(
      padding: const EdgeInsets.all(jarak * 2),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: t.bodySmall)),
          Expanded(
            child: Text(
              (nilai == null || nilai!.isEmpty) ? '—' : nilai!,
              style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status kalibrasi alat sebagai lencana — satu-satunya pemetaan
/// status → warna di aplikasi ini.
StatusSidik statusAlat(StatusKalibrasi s) => switch (s) {
  StatusKalibrasi.aman => const StatusSidik(
    'Aman',
    NadaStatus.lulus,
    Icons.check_circle_outline,
  ),
  StatusKalibrasi.segera => const StatusSidik(
    'Segera jatuh tempo',
    NadaStatus.awas,
    Icons.schedule,
  ),
  StatusKalibrasi.lewat => const StatusSidik(
    'Lewat jatuh tempo',
    NadaStatus.gagal,
    Icons.error_outline,
  ),
  StatusKalibrasi.nonaktif => const StatusSidik(
    'Tidak aktif',
    NadaStatus.draf,
    Icons.pause_circle_outline,
  ),
  StatusKalibrasi.belumAda => const StatusSidik(
    'Belum ada jadwal',
    NadaStatus.tunggu,
    Icons.event_busy_outlined,
  ),
};

StatusSidik? statusKeputusan(String? keputusan) => switch (keputusan) {
  'PASS' => const StatusSidik(
    'PASS',
    NadaStatus.lulus,
    Icons.check_circle_outline,
  ),
  'FAIL' => const StatusSidik('FAIL', NadaStatus.gagal, Icons.cancel_outlined),
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
              SidikLencana(statusAlat(alat.status)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              alat.merkModel,
              if (alat.serial != null) 'SN ${alat.serial}',
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
                      ? 'Belum ada jadwal kalibrasi'
                      : 'Jatuh tempo ${Format.tanggal(alat.jatuhTempo)} · ${Format.sisaHari(alat.hariKeJatuhTempo)}',
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

/// Kartu satu paket: nomor, tahap, dan batang kemajuan "x dari y alat".
class KartuPaket extends StatelessWidget {
  const KartuPaket({super.key, required this.paket, required this.onTap});

  final Paket paket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = SidikMaterial.of(context);
    return Kertas(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(paket.nomor, style: t.titleSmall)),
              if (paket.terlambat)
                const SidikLencana(
                  StatusSidik(
                    'Melewati janji',
                    NadaStatus.awas,
                    Icons.schedule,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            paket.tahapLabel,
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: paket.kemajuan,
              minHeight: 8,
              backgroundColor: m.kertas2,
              color: m.lulus,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${paket.jumlahSelesai} dari ${paket.jumlahAlat} alat selesai'
            '${paket.janjiSelesai == null ? '' : ' · janji ${Format.tanggal(paket.janjiSelesai)}'}',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}
