import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/pesan_admin.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/data_provider.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/bagian_sidik.dart';
import '../../widgets/baris_info.dart';
import '../../widgets/garis_waktu_sertifikat.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/keadaan_galat.dart';
import '../../widgets/keadaan_kosong.dart';
import '../../widgets/kerangka.dart';
import '../../widgets/lembar_tanya_admin.dart';
import '../../widgets/panel_sidik.dart';
import '../../widgets/pemetaan_status.dart';
import '../../widgets/status_tampil.dart';
import '../../widgets/stempel.dart';
import '../../widgets/tombol_sidik.dart';
import '../../widgets/ubin_alat.dart';
import '../paket/paket_detail_screen.dart';
import '../sertifikat/sertifikat_detail_screen.dart';

/// Teks untuk data wajib yang belum dikirim server (REVISI-2 butir 3).
const String _belumTersedia = 'Belum tersedia';

/// Detail satu alat (S09), dipisah menjadi empat kelompok yang tidak saling
/// meminjam arti (REVISI-2 butir 3):
///
/// 1. **Identitas alat**: nama (SEKALI, di sini, bukan lagi di judul layar dan di
///    kartu), merk/model, nomor seri dan nomor identifikasi (bisa disalin),
///    rentang ukur, lokasi, catatan. Merk/model dan nomor seri selalu tampil
///    ("Belum tersedia" bila kosong); kolom opsional yang kosong disembunyikan.
/// 2. **Jadwal kalibrasi**: lencana status jadwal berwaktu (kata yang sama
///    dengan kartu alat), jadwal kalibrasi ulang, kalibrasi terakhir. Alat tidak
///    aktif TIDAK punya hitung mundur: lencana "Tidak aktif" dan jadwal hanya
///    tercatat sebagai konteks (aturan alat nonaktif R1b).
/// 3. **Status layanan**: hanya bila alat sedang di laboratorium (tahap paket,
///    nomor order, tautan ke paketnya).
/// 4. **Riwayat kalibrasi**: sertifikat, terbaru di atas, tiap baris punya
///    "Buka sertifikat". Status jadwal (alat), status dokumen, dan hasil teknis
///    (sertifikat) tidak dicampur: yang pertama di kelompok 2, dua lainnya di
///    simpul riwayat dan di detail sertifikat.
///
/// Tarik layar untuk memuat ulang. "Minta kalibrasi ulang" (Tanya admin) hanya
/// untuk alat aktif.
class AlatDetailScreen extends ConsumerWidget {
  const AlatDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(detailAlatProvider(id));
    final t = context.teks;

    return HalamanSidik(
      judul: 'Detail alat',
      isi: async.when(
        loading: () => const Memuat.detail(),
        error: (e, _) => KeadaanGalat(
          galat: e,
          cobaLagi: () => ref.invalidate(detailAlatProvider(id)),
        ),
        data: (a) {
          final nonaktif = a.status == StatusKalibrasi.nonaktif;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(detailAlatProvider(id));
              await ref.read(detailAlatProvider(id).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Spasi.daftar(context),
              children: [
                _Identitas(alat: a),
                const BagianSidik('Jadwal kalibrasi'),
                _Jadwal(alat: a),
                if (a.sedangDikerjakan != null) ...[
                  const BagianSidik('Status layanan'),
                  _Layanan(dikerjakan: a.sedangDikerjakan!),
                ],
                // Alat tidak aktif tidak ditawari "minta kalibrasi ulang":
                // jadwalnya hanya catatan.
                if (!nonaktif) ...[
                  const SizedBox(height: Spasi.lg),
                  TombolTanyaAdmin(
                    label: 'Minta kalibrasi ulang',
                    pesan: () => PembangunPesanAdmin.kalibrasiUlang(
                      perusahaan: ref
                          .read(sesiProvider)
                          .value
                          ?.keanggotaanAktif
                          ?.namaPerusahaan,
                      namaAlat: a.nama,
                      merkTipe: _merkModel(a),
                      serial: a.serial,
                      jadwal: a.jatuhTempo == null
                          ? null
                          : Format.tanggal(a.jatuhTempo),
                    ),
                  ),
                ],
                const BagianSidik('Riwayat kalibrasi'),
                if (a.riwayat.isEmpty)
                  const PanelSidik(
                    padding: PanelSidik.paddingIsi,
                    anak: [
                      KeadaanKosongIsi(
                        ikon: Icons.history,
                        judul: 'Belum ada sertifikat',
                        keterangan:
                            'Sertifikat alat ini muncul di sini setelah alat '
                            'dikalibrasi di PT Sidik.',
                      ),
                    ],
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spasi.md),
                    child: Text(
                      '${a.riwayat.length} sertifikat, yang terbaru di atas. '
                      'Ketuk untuk membuka.',
                      style: t.bodySmall,
                    ),
                  ),
                  GarisWaktuSertifikat(
                    riwayat: terbaruDiAtas(a.riwayat),
                    // "Hari ini" menurut server (jatuh tempo − sisa hari); jam HP
                    // hanya cadangan. Lihat `Alat.hariIniServer`.
                    sekarang: a.hariIniServer ?? ref.read(jamHpProvider)(),
                    onBuka: (s) => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SertifikatDetailScreen(id: s.id),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// "Merk Model" dalam satu baris, tanpa pemisah titik tengah; kosong bila
  /// keduanya kosong.
  static String _merkModel(Alat a) =>
      [a.merk, a.model].where((x) => x != null && x.isNotEmpty).join(' ');

  /// Riwayat dengan tanggal terbit TERBARU di atas, apa pun urutan dari server;
  /// yang sama tanggalnya tetap berurutan seperti dari server, dan yang tanpa
  /// tanggal di dasar.
  static List<Sertifikat> terbaruDiAtas(List<Sertifikat> riwayat) {
    final berindeks = [for (final (i, s) in riwayat.indexed) (i, s)];
    berindeks.sort((a, b) {
      final x = a.$2.diterbitkan;
      final y = b.$2.diterbitkan;
      if (x == null && y == null) return a.$1.compareTo(b.$1);
      if (x == null) return 1;
      if (y == null) return -1;
      final c = y.compareTo(x);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    return [for (final e in berindeks) e.$2];
  }
}

/// Kelompok 1: nama alat dan identitasnya.
class _Identitas extends StatelessWidget {
  const _Identitas({required this.alat});

  final Alat alat;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final merk = AlatDetailScreen._merkModel(alat);
    String? isi(String? x) => x == null || x.trim().isEmpty ? null : x.trim();
    final seri = isi(alat.serial);
    final noId = isi(alat.noIdentifikasi);
    final rentang = isi(alat.rentang);
    final lokasi = isi(alat.lokasi);
    final catatan = isi(alat.catatan);
    return PanelSidik(
      padding: PanelSidik.paddingIsi,
      anak: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(alat.nama, style: t.titleLarge),
            ),
            const SizedBox(height: Spasi.md),
            BarisInfo('Merk / model', merk.isEmpty ? _belumTersedia : merk),
            if (seri == null)
              const BarisInfo('Nomor seri', _belumTersedia)
            else
              BarisInfoSalin(
                'Nomor seri',
                seri,
                tooltip: 'Salin nomor seri',
                konfirmasi: 'Nomor seri disalin.',
              ),
            if (noId != null)
              BarisInfoSalin(
                'No. identifikasi',
                noId,
                tooltip: 'Salin nomor identifikasi',
                konfirmasi: 'Nomor identifikasi disalin.',
              ),
            if (rentang != null) BarisInfo('Rentang ukur', rentang),
            if (lokasi != null) BarisInfo('Lokasi', lokasi),
            if (catatan != null) BarisInfo('Catatan', catatan),
          ],
        ),
      ],
    );
  }
}

/// Kelompok 2: status jadwal, jadwal kalibrasi ulang, kalibrasi terakhir.
class _Jadwal extends StatelessWidget {
  const _Jadwal({required this.alat});

  final Alat alat;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final nonaktif = alat.status == StatusKalibrasi.nonaktif;
    final dasar = statusAlat(alat.status);
    final tanggal = alat.jatuhTempo == null
        ? null
        : Format.tanggal(alat.jatuhTempo);
    // Kata lencana berwaktu yang sama dengan kartu alat; alat tidak aktif
    // hanya "Tidak aktif" (tanpa hitung mundur).
    final lencana = StatusTampil(
      labelStatusJadwal(
        dasar,
        alat.jatuhTempo == null ? null : alat.hariKeJatuhTempo,
        nonaktif: nonaktif,
      ),
      dasar.nada,
      dasar.ikon,
    );
    return PanelSidik(
      padding: PanelSidik.paddingIsi,
      anak: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Stempel(lencana),
            ),
            const SizedBox(height: Spasi.md),
            if (nonaktif) ...[
              Text(
                tanggal == null
                    ? 'Alat tidak aktif.'
                    : 'Alat tidak aktif, jadwal tercatat $tanggal.',
                style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
              ),
              const SizedBox(height: Spasi.sm),
            ] else
              BarisInfo(
                'Jadwal kalibrasi ulang',
                tanggal ?? 'Belum ada jadwal',
              ),
            BarisInfo(
              'Kalibrasi terakhir',
              alat.kalibrasiTerakhir == null
                  ? _belumTersedia
                  : Format.tanggal(alat.kalibrasiTerakhir),
            ),
          ],
        ),
      ],
    );
  }
}

/// Kelompok 3: alat sedang di laboratorium (tahap paket berjalan).
class _Layanan extends StatelessWidget {
  const _Layanan({required this.dikerjakan});

  final SedangDikerjakan dikerjakan;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final paketId = dikerjakan.paketId;
    final order = dikerjakan.nomorOrder?.trim();
    return PanelSidik(
      padding: PanelSidik.paddingIsi,
      anak: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text('Sedang di laboratorium', style: t.titleSmall),
            ),
            const SizedBox(height: Spasi.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Stempel(
                statusPaket(dikerjakan.tahap, dikerjakan.tahapLabel),
              ),
            ),
            if (order != null && order.isNotEmpty) ...[
              const SizedBox(height: Spasi.md),
              BarisInfo('Nomor order', order, angka: true),
            ],
            if (paketId != null) ...[
              const SizedBox(height: Spasi.sm),
              TombolSidik(
                label: 'Lihat paket',
                ikon: Icons.inventory_2_outlined,
                ragam: RagamTombol.teks,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PaketDetailScreen(id: paketId),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
