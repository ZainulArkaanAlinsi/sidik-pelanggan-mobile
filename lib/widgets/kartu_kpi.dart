import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/tipografi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'kartu_sidik.dart';
import 'status_tampil.dart';

/// Kartu angka ringkasan (KPI): ubin ikon, angka besar, keterangan. Seluruh
/// kartu bisa diketuk.
///
/// Warna status HANYA dipakai bila angkanya bukan nol: nol alat terlambat itu
/// kabar baik, bukan peringatan. [angka] `null` = belum bisa dihitung ("–").
class KartuKpi extends StatelessWidget {
  /// Penyambung kata (U+2060): mencegah rentang "31–60" putus di tanda
  /// – pada huruf besar. Dibangun dari kode titik supaya berkas sumber tetap
  /// ASCII-aman (karakternya tak terlihat).
  static final String _penyambung = String.fromCharCode(0x2060);

  const KartuKpi({
    super.key,
    required this.angka,
    required this.label,
    required this.ikon,
    required this.onTap,
    this.nada = NadaStatus.netral,
  });

  final int? angka;
  final String label;
  final IconData ikon;
  final NadaStatus nada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final aktif = nada != NadaStatus.netral && (angka ?? 0) > 0;
    final (tinta, latar) = aktif
        ? StatusTampil(label, nada, ikon).warna(context)
        : (s.onPrimaryContainer, s.primaryContainer);
    return KartuSidik(
      onTap: onTap,
      labelSemantik:
          '$label: ${angka == null ? 'belum tersedia' : '$angka alat'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AreaSentuh.minimum - Spasi.sm,
                height: AreaSentuh.minimum - Spasi.sm,
                decoration: BoxDecoration(
                  color: latar,
                  borderRadius: BorderRadius.circular(Bentuk.kontrol),
                ),
                child: Icon(ikon, size: UkuranIkon.sedang, color: tinta),
              ),
              const SizedBox(width: Spasi.sm),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      angka == null ? '–' : '$angka',
                      style: t.displaySmall?.tabular,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spasi.md),
          Text(
            label.replaceAll('–', '–$_penyambung'),
            style: t.bodySmall,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
