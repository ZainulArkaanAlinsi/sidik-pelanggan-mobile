import 'package:flutter/material.dart';

import '../core/tema/bentuk.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import 'tombol_sidik.dart';

/// Keadaan kosong atau galat sebagai TEKS rata kiri: judul 22/28, satu kalimat
/// yang bilang apa artinya, dan satu tindakan berikutnya. Tanpa lingkaran ikon
/// dan tanpa ilustrasi (pengganti `KeadaanKosong` dan `KeadaanGalat`).
///
/// [aksi] + [onAksi] harus diisi bersama. Tindakan biasa = tombol sekunder 48
/// dp ("Tampilkan semua alat"); [utama] = tombol utama 56 dp, untuk tindakan
/// yang satu-satunya jalan keluar layar ("Coba lagi"). Tidak berupa daftar
/// bergulir: bungkus dengan `ListView` bila perlu tarik-untuk-muat-ulang.
class KeadaanTeks extends StatelessWidget {
  const KeadaanTeks({
    super.key,
    required this.judul,
    required this.isi,
    this.aksi,
    this.onAksi,
    this.utama = false,
  }) : assert(
         (aksi == null) == (onAksi == null),
         'aksi dan onAksi harus diisi bersama',
       );

  final String judul;
  final String isi;
  final String? aksi;
  final VoidCallback? onAksi;
  final bool utama;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    return Padding(
      padding: const EdgeInsets.only(top: Spasi.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(judul, style: t.headlineSmall)),
          const SizedBox(height: Spasi.sm),
          Text(isi, style: t.bodyLarge?.copyWith(color: s.onSurfaceVariant)),
          if (aksi != null) ...[
            const SizedBox(height: Spasi.lg),
            TombolSidik(
              label: aksi!,
              ragam: utama ? RagamTombol.utama : RagamTombol.sekunder,
              onPressed: onAksi,
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner satu kalimat di atas daftar saat tidak ada sambungan: data terakhir
/// tetap terbaca. Latar `surfaceContainerHigh`, ikon awan, sudut 4. Teks dari
/// pemanggil ("Tidak ada sambungan. Yang tampil adalah data terakhir, 12 Nov
/// 2026 08.12."); pembaca layar menerima teks yang sama.
class BannerDataTerakhir extends StatelessWidget {
  const BannerDataTerakhir({super.key, required this.teks});

  final String teks;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    return Semantics(
      container: true,
      label: teks,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: s.surfaceContainerHigh,
          borderRadius: Bentuk.sudutKecil,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spasi.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: UkuranIkon.sedang,
                color: s.onSurfaceVariant,
              ),
              const SizedBox(width: Spasi.md),
              Expanded(
                child: Text(
                  teks,
                  style: context.teks.bodyMedium?.copyWith(color: s.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
