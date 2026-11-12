import 'package:flutter/material.dart';

import '../../core/tema/spasi.dart';
import '../../models/data_pelanggan.dart';
import '../../widgets/kartu_kpi.dart';
import '../../widgets/status_tampil.dart';
import '../alat/daftar_alat_screen.dart';

/// Buka daftar alat yang sudah disaring ke [filter].
void bukaDaftarAlat(BuildContext context, FilterAlat filter) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DaftarAlatScreen(filterAwal: filter),
      ),
    );

/// Empat kartu KPI: lewat jadwal, lalu tiga rentang jatuh tempo. 0–30 hari dan
/// lewat jadwal dari hitungan server (sama dengan daftar yang terbuka saat
/// diketuk); 31–60 dan 61–90 dari hitungan aplikasi ([kelompok2], [kelompok3],
/// `null` = belum/tidak bisa dimuat, tampil "–").
///
/// Di HP susunannya 2 × 2; di lebar >= [_batasSebaris] keempatnya sebaris.
class KotakJatuhTempo extends StatelessWidget {
  const KotakJatuhTempo({
    super.key,
    required this.beranda,
    required this.kelompok2,
    required this.kelompok3,
  });

  final Beranda beranda;
  final int? kelompok2;
  final int? kelompok3;

  static const double _batasSebaris = 560;

  @override
  Widget build(BuildContext context) {
    final kartu = [
      KartuKpi(
        angka: beranda.lewatJatuhTempo,
        label: FilterAlat.lewatJadwal.label,
        ikon: Icons.event_busy_outlined,
        nada: NadaStatus.gagal,
        onTap: () => bukaDaftarAlat(context, FilterAlat.lewatJadwal),
      ),
      KartuKpi(
        angka: beranda.segeraJatuhTempo,
        label: FilterAlat.hari30.label,
        ikon: Icons.schedule,
        nada: NadaStatus.awas,
        onTap: () => bukaDaftarAlat(context, FilterAlat.hari30),
      ),
      KartuKpi(
        angka: kelompok2,
        label: FilterAlat.hari60.label,
        ikon: Icons.date_range_outlined,
        onTap: () => bukaDaftarAlat(context, FilterAlat.hari60),
      ),
      KartuKpi(
        angka: kelompok3,
        label: FilterAlat.hari90.label,
        ikon: Icons.calendar_month_outlined,
        onTap: () => bukaDaftarAlat(context, FilterAlat.hari90),
      ),
    ];

    return LayoutBuilder(
      builder: (context, batas) {
        final sebaris = batas.maxWidth >= _batasSebaris;
        final lajur = sebaris ? 4 : 2;
        return Column(
          children: [
            for (var i = 0; i < kartu.length; i += lajur) ...[
              if (i > 0) const SizedBox(height: Spasi.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = i; j < i + lajur; j++) ...[
                      if (j > i) const SizedBox(width: Spasi.md),
                      Expanded(child: kartu[j]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
