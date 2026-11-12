import 'package:flutter/material.dart';

import '../models/data_pelanggan.dart';
import '../models/status_berlaku.dart';
import 'status_tampil.dart';

/// Pemetaan status → nada dan ikon. SATU-SATUNYA tempat pemetaan itu ditulis,
/// jadi kata yang sama tidak bisa tampil beda di dua layar. Teks dari
/// [StatusBerlaku.label] (satu sumber istilah; keputusan K3: bukan
/// "kedaluwarsa").
///
/// Sisa hari tidak ikut di label: tampil di baris tanggal ([Format.sisaHari]),
/// supaya chip pendek dan muat di layar 320 dp.
StatusTampil statusBerlaku(StatusBerlaku s) => StatusTampil(
  s.label,
  switch (s) {
    StatusBerlaku.berlaku => NadaStatus.lulus,
    StatusBerlaku.segera || StatusBerlaku.digantikan => NadaStatus.awas,
    StatusBerlaku.lewatJadwal || StatusBerlaku.dibatalkan => NadaStatus.gagal,
    StatusBerlaku.diproses => NadaStatus.tunggu,
    StatusBerlaku.berakhir ||
    StatusBerlaku.belumPernah ||
    StatusBerlaku.tidakAktif => NadaStatus.netral,
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

/// Status alat (dihitung server) sebagai chip.
StatusTampil statusAlat(StatusKalibrasi s) =>
    statusBerlaku(StatusBerlaku.dariAlat(s));

/// Status dokumen sertifikat (dikirim server), tanpa menilai tanggal. Untuk
/// status lengkap dengan masa berlaku: [statusSertifikat].
StatusTampil statusDokumen(StatusDokumen s) =>
    statusBerlaku(StatusBerlaku.dariDokumen(s));

/// Status sertifikat termasuk masa berlakunya pada waktu [sekarang].
/// [adaPenerus] = di riwayat alat ada sertifikat berlaku yang lebih baru.
StatusTampil statusSertifikat(
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
/// "Tidak memenuhi toleransi", nada gagal, dengan ikon.
StatusTampil? statusKeputusan(String? keputusan) => switch (keputusan) {
  'PASS' => const StatusTampil(
    'Memenuhi toleransi',
    NadaStatus.lulus,
    Icons.check_circle_outline,
  ),
  'FAIL' => const StatusTampil(
    'Tidak memenuhi toleransi',
    NadaStatus.gagal,
    Icons.cancel_outlined,
  ),
  _ => null,
};

/// Chip tahap paket. Teksnya dari server (label versi pelanggan); aplikasi
/// hanya memilih nada dan ikon untuk tiap kode tahap, dan kode yang tidak
/// dikenal tampil netral: daftar tahap boleh bertambah tanpa merusak layar.
StatusTampil statusPaket(String kode, String label) => switch (kode) {
  'diterima' => StatusTampil(label, NadaStatus.netral, Icons.inbox_outlined),
  'dikalibrasi' => StatusTampil(label, NadaStatus.tunggu, Icons.tune),
  'perlu_diulang' => StatusTampil(label, NadaStatus.awas, Icons.replay),
  'menunggu_pemeriksaan' || 'menunggu_pengesahan' => StatusTampil(
    label,
    NadaStatus.tunggu,
    Icons.fact_check_outlined,
  ),
  'sertifikat_terbit' => StatusTampil(
    label,
    NadaStatus.lulus,
    Icons.verified_outlined,
  ),
  'siap_diambil' => StatusTampil(
    label,
    NadaStatus.lulus,
    Icons.inventory_2_outlined,
  ),
  'diserahkan' => StatusTampil(
    label,
    NadaStatus.lulus,
    Icons.check_circle_outline,
  ),
  _ => StatusTampil(label, NadaStatus.netral, Icons.help_outline),
};
