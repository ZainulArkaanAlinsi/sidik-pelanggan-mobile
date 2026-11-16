import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'dasar/dasar_ubin.dart';
import 'status_tampil.dart';
import 'stempel.dart';

/// Kartu alat ringkas (REVISI-2 butir 2, R1b): satu alat, satu kartu NETRAL
/// (permukaan putih, garis halus; warna hanya pada lencana status). Dipakai
/// daftar "Alat saya" dan Beranda (alat paling mendesak): satu bentuk di dua
/// tempat.
///
/// Isi dari atas, lima baris:
/// 1. [nama] 20/26 semibold, paling menonjol (paling banyak [maksBarisNama]);
/// 2. [merkTipe] lalu `SN` + [serial] dalam IBM Plex Mono, satu baris
///    ("Mitutoyo CD-15CPX · SN 2201-0457"; membungkus bila sempit);
/// 3. [lokasi] (hanya bila terisi; pembeda dua alat sejenis tanpa nomor seri);
/// 4. baris status: [Stempel] status, ditambah [tahap] (alat sedang di lab)
///    bila ada. Waktunya ikut di kata lencana untuk tiga status jadwal:
///    "Lewat jadwal 4 hari", "Segera jatuh tempo 12 hari lagi", "Berlaku 120
///    hari lagi" (lihat [labelStatus]);
/// 5. "Lihat detail →" dan, di kanan, tanggal jadwalnya ("sejak 8 Nov 2026" /
///    "jatuh tempo 12 Mar 2027"). Hanya bila [onTap] ada.
///
/// ALAT NONAKTIF ([nonaktif]): tanpa hitung mundur sama sekali. Lencana tetap
/// "Tidak aktif" (netral), namanya diredupkan ke teks kedua, dan tanggal
/// jadwal, bila ada, tampil sebagai konteks "Alat nonaktif, jadwal tercatat 22
/// Nov 2026" supaya tidak dibaca sebagai tindakan yang harus segera dilakukan.
///
/// Tinggi [UkuranUbin.alatRingkas] adalah MINIMUM: kartu tumbuh bersama isi dan
/// huruf. Status tidak hanya warna: lencana selalu ikon + kata. Seluruh kartu
/// satu tombol bila [onTap] ada; pembaca layar menerima [semantik] atau, bila
/// kosong, [kalimat] yang disusun dari isi kartu.
class UbinAlat extends StatelessWidget {
  const UbinAlat({
    super.key,
    required this.nama,
    required this.status,
    this.merkTipe,
    this.serial,
    this.awalanSerial,
    this.lokasi,
    this.hari,
    this.tanggal,
    this.tahap,
    this.nonaktif = false,
    this.onTap,
    this.semantik,
    this.urutan,
    this.maksBarisNama,
  });

  final String nama;
  final StatusTampil status;
  final String? merkTipe;

  /// Nomor seri apa adanya (tanpa awalan).
  final String? serial;

  /// Awalan yang HANYA tampil di depan [serial] (mis. "SN"); pembaca layar
  /// menerima nomornya saja, supaya tidak terbaca "S N" dua kali.
  final String? awalanSerial;

  /// Lokasi alat; kosong atau spasi saja = tidak ada baris.
  final String? lokasi;

  /// Sisa hari menuju jadwal; negatif = lewat; null = belum ada jadwal. Tidak
  /// dipakai bila [nonaktif].
  final int? hari;

  /// Tanggal jadwal yang sudah diformat pemanggil (mis. `Format.tanggal`),
  /// TANPA kata depan: kata depannya ("sejak", "jatuh tempo") dari [hari].
  final String? tanggal;

  /// Tahap alat yang sedang di lab (mis. "Sedang dikalibrasi"), satu lencana
  /// sendiri di samping status. Null = alat tidak sedang di lab.
  final StatusTampil? tahap;

  /// Alat dinonaktifkan: tanpa hitung mundur, dengan konteks "Alat nonaktif".
  final bool nonaktif;

  final VoidCallback? onTap;
  final String? semantik;

  /// Urutan masuk layar (35 ms per indeks); null = tanpa animasi masuk.
  final int? urutan;

  /// Batas baris nama; null (bawaan) = nama utuh, membungkus sebanyak perlu
  /// (nama alat tidak boleh terpotong, juga pada huruf besar).
  final int? maksBarisNama;

  /// Teks aksi di dasar kartu.
  static const String teksAksi = 'Lihat detail';

  /// [lokasi] tanpa spasi pinggir; null bila kosong, jadi tidak ada baris dan
  /// tidak ada kata "Lokasi" di kalimat pembaca layar.
  String? get _lokasiTampil {
    final l = lokasi?.trim();
    return l == null || l.isEmpty ? null : l;
  }

  /// Kata lencana status. Tiga status jadwal (lewat jadwal, segera jatuh tempo,
  /// berlaku) membawa waktunya: "Lewat jadwal 4 hari", "Segera jatuh tempo 12
  /// hari lagi", "Segera jatuh tempo hari ini", "Berlaku 120 hari lagi". Status
  /// lain (tidak aktif, belum pernah, sedang diproses) memakai katanya saja,
  /// juga bila [nonaktif]: alat nonaktif tidak punya hitung mundur.
  String get labelStatus {
    final h = hari;
    if (nonaktif || h == null) return status.label;
    final nada = status.nada;
    if (nada == NadaStatus.gagal && h < 0) return '${status.label} ${-h} hari';
    if ((nada == NadaStatus.awas || nada == NadaStatus.lulus) && h >= 0) {
      return h == 0
          ? '${status.label} hari ini'
          : '${status.label} $h hari lagi';
    }
    return status.label;
  }

  /// Konteks alat nonaktif (menggantikan hitung mundur); null bila aktif.
  String? get konteksNonaktif {
    if (!nonaktif) return null;
    final t = tanggal;
    return t == null || t.isEmpty
        ? 'Alat nonaktif'
        : 'Alat nonaktif, jadwal tercatat $t';
  }

  /// Tanggal jadwal di dasar kartu: "sejak ..." bila sudah lewat, "jatuh tempo
  /// ..." bila belum; null untuk alat nonaktif (konteksnya di atas) dan tanpa
  /// jadwal.
  String? get keteranganJadwal {
    final h = hari;
    final t = tanggal;
    if (nonaktif || h == null || t == null || t.isEmpty) return null;
    return h < 0 ? 'sejak $t' : 'jatuh tempo $t';
  }

  /// Kalimat bawaan untuk pembaca layar, dari isi kartu.
  String get kalimat => [
    nama,
    'Status: $labelStatus',
    if (tahap != null) 'Di lab: ${tahap!.label}',
    if (merkTipe != null && merkTipe!.isNotEmpty) merkTipe!,
    if (serial != null && serial!.isNotEmpty) 'Nomor seri $serial',
    if (_lokasiTampil != null) 'Lokasi $_lokasiTampil',
    ?(konteksNonaktif ?? keteranganJadwal),
  ].join('. ');

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final t = context.teks;
    final gayaKet = t.bodySmall?.copyWith(color: s.onSurfaceVariant);
    final adaMerk = (merkTipe ?? '').isNotEmpty;
    final adaSerial = (serial ?? '').isNotEmpty;
    final awalan = (awalanSerial ?? '').isEmpty ? '' : '$awalanSerial ';

    return DasarUbin(
      latar: s.surface,
      sudut: Bentuk.sudutUbin,
      tinggiMin: UkuranUbin.alatRingkas,
      padding: const EdgeInsets.all(UkuranUbin.paddingAlat),
      onTap: onTap,
      semantik: semantik ?? (onTap == null ? null : kalimat),
      urutan: urutan,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            nama,
            maxLines: maksBarisNama,
            // Ellipsis tanpa batas baris memaksa SATU baris (nama terpotong
            // dengan "..." di huruf besar): tanpa batas, tanpa ellipsis.
            overflow: maksBarisNama == null
                ? TextOverflow.clip
                : TextOverflow.ellipsis,
            style: t.headlineMedium?.copyWith(
              color: nonaktif ? s.onSurfaceVariant : s.onSurface,
            ),
          ),
          if (adaMerk || adaSerial)
            Padding(
              padding: const EdgeInsets.only(top: Spasi.xs),
              child: Text.rich(
                TextSpan(
                  children: [
                    if (adaMerk) TextSpan(text: merkTipe),
                    if (adaMerk && adaSerial) const TextSpan(text: ' · '),
                    if (adaSerial)
                      TextSpan(text: '$awalan$serial', style: gayaKet?.nomor),
                  ],
                ),
                style: gayaKet,
              ),
            ),
          if (_lokasiTampil != null)
            Padding(
              padding: const EdgeInsets.only(top: Spasi.xs),
              child: Text(
                _lokasiTampil!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: gayaKet,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: Spasi.sm),
            child: Wrap(
              spacing: Spasi.sm,
              runSpacing: Spasi.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Stempel(StatusTampil(labelStatus, status.nada, status.ikon)),
                if (tahap != null) Stempel(tahap!),
              ],
            ),
          ),
          if (konteksNonaktif != null)
            Padding(
              padding: const EdgeInsets.only(top: Spasi.sm),
              child: Text(konteksNonaktif!, style: gayaKet),
            ),
          if (onTap != null)
            Padding(
              padding: const EdgeInsets.only(top: Spasi.sm),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Spasi.md,
                runSpacing: Spasi.xs,
                children: [
                  _Aksi(warna: s.primary, gaya: t.labelLarge),
                  if (keteranganJadwal != null)
                    Text(keteranganJadwal!, style: gayaKet),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Lihat detail →": hiasan penunjuk bahwa kartu bisa diketuk (kartunya yang
/// tombol, jadi tanpa semantik sendiri). Warna aksi, bukan status.
class _Aksi extends StatelessWidget {
  const _Aksi({required this.warna, required this.gaya});

  final Color warna;
  final TextStyle? gaya;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            UbinAlat.teksAksi,
            style: gaya?.copyWith(
              color: warna,
              fontWeight: TipografiSidik.beratTebal,
            ),
          ),
        ),
        const SizedBox(width: Spasi.xs),
        Icon(Icons.arrow_forward, size: UkuranIkon.kecil, color: warna),
      ],
    ),
  );
}
