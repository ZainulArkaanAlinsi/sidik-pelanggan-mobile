import 'package:flutter/material.dart';

import '../core/api_pelanggan.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'tombol_sidik.dart';

/// Galat yang MENJELASKAN langkah berikutnya, bukan cuma "error": ikon sesuai
/// jenis galat (tanpa jaringan atau lainnya), pesan dari server bila ada, dan
/// satu tombol "Coba lagi". Berupa `ListView` supaya tarik-untuk-muat-ulang
/// tetap jalan.
class KeadaanGalat extends StatelessWidget {
  const KeadaanGalat({super.key, required this.galat, required this.cobaLagi});

  final Object galat;
  final VoidCallback cobaLagi;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final teks = galat is GalatApi
        ? (galat as GalatApi).pesan
        : 'Terjadi kesalahan. Coba lagi.';
    final jaringan = galat is GalatApi && (galat as GalatApi).jaringan;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Spasi.denganTepiBawah(
        context,
        const EdgeInsets.all(Spasi.xl),
      ).copyWith(top: Spasi.xxl),
      children: [
        Center(
          child: ExcludeSemantics(
            child: Container(
              width: UkuranIkon.ilustrasi + Spasi.xl,
              height: UkuranIkon.ilustrasi + Spasi.xl,
              decoration: BoxDecoration(
                color: s.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                jaringan ? Icons.wifi_off_outlined : Icons.error_outline,
                size: UkuranIkon.besar,
                color: s.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spasi.lg),
        Text(teks, textAlign: TextAlign.center, style: context.teks.bodyLarge),
        const SizedBox(height: Spasi.lg),
        Center(
          child: TombolSidik(
            label: 'Coba lagi',
            ikon: Icons.refresh,
            ragam: RagamTombol.utama,
            onPressed: cobaLagi,
          ),
        ),
      ],
    );
  }
}
