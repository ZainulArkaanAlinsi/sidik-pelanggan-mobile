import 'package:flutter/material.dart';

import '../../core/api_pelanggan.dart';
import '../../core/tema/bentuk.dart';
import '../../core/tema/elevasi.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/tipografi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/data_pelanggan.dart';
import '../../providers/paginasi.dart';
import '../../widgets/kartu_alat.dart';
import '../../widgets/tombol_sidik.dart';

// Bagian layar "Alat saya" (daftar_alat_screen.dart) yang hanya dipakai di sana:
// kerangka memuat statis, ubin kosong, catatan luring, pil jumlah, dan daftar
// ubin. Daftar ditulis di sini, bukan memakai `DaftarBerhalaman`, karena
// kerangka `kerangka.dart` berdenyut tanpa henti (`repeat`) sedangkan layar ini
// meminta kerangka STATIS; `DaftarBerhalaman` dan `kerangka.dart` dipakai layar
// lain dan tidak diubah.

/// Jumlah alat yang boleh DIKLAIM layar dari satu daftar berhalaman, atau null
/// bila belum terbaca utuh.
///
/// Semua halaman sudah dimuat: yang tampil itulah jumlahnya. Masih ada halaman:
/// hanya `total` dari server yang boleh dipercaya, dan hanya bila ia memang
/// lebih besar dari yang sudah dimuat (server yang tidak mengirim `total`
/// menjatuhkannya ke ukuran satu halaman). Selain itu tidak ada klaim.
int? jumlahTerbaca(DataBerhalaman<Alat> d) {
  if (!d.adaLagi) return d.isi.length;
  return d.total > d.isi.length ? d.total : null;
}

/// Kerangka memuat STATIS: kartu putih setinggi kartu alat ringkas dengan balok
/// abu sebesar isinya. Tanpa denyut dan tanpa animasi apa pun, jadi tidak ada
/// gerak berulang dan "kurangi gerak" tidak punya yang perlu dimatikan. Pembaca
/// layar menerima satu pengumuman "Memuat".
class KerangkaAlat extends StatelessWidget {
  const KerangkaAlat({super.key, this.jumlah = 4, this.padding});

  final int jumlah;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Memuat',
    liveRegion: true,
    child: ListView.separated(
      // Tetap bisa ditarik (RefreshIndicator) selama memuat.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding ?? Spasi.daftar(context),
      itemCount: jumlah,
      separatorBuilder: (_, _) => const SizedBox(height: Spasi.antarUbin),
      itemBuilder: (_, _) => const UbinKerangkaAlat(),
    ),
  );
}

/// Satu kartu kerangka: bentuk kartu alat ringkas (nama, merk dan seri, lencana
/// status, "Lihat detail"), tanpa teks dan tanpa gerak. Dihitung dari token
/// kartu supaya tidak melompat saat data tiba.
class UbinKerangkaAlat extends StatelessWidget {
  const UbinKerangkaAlat({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    return ExcludeSemantics(
      child: Material(
        color: s.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Bentuk.sudutUbin,
          side: BorderSide(color: s.outlineVariant, width: Elevasi.garis),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: UkuranUbin.alatRingkas),
          child: const Padding(
            padding: EdgeInsets.all(UkuranUbin.paddingAlat),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Balok(lebar: 0.6, tinggi: Spasi.xl),
                SizedBox(height: Spasi.sm),
                _Balok(lebar: 0.75, tinggi: Spasi.md),
                SizedBox(height: Spasi.md),
                _Balok(
                  lebar: 0.4,
                  tinggi: UkuranKontrol.stempel,
                  sudutStempel: true,
                ),
                SizedBox(height: Spasi.md),
                _Balok(lebar: 0.25, tinggi: Spasi.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Balok abu statis; [lebar] = bagian dari lebar kartu (0 sampai 1).
/// [sudutStempel] = sudut lencana (6), selain itu sudut kecil (4).
class _Balok extends StatelessWidget {
  const _Balok({
    required this.lebar,
    required this.tinggi,
    this.sudutStempel = false,
  });

  final double lebar;
  final double tinggi;
  final bool sudutStempel;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: lebar,
    child: SizedBox(
      height: tinggi,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.skema.surfaceContainerHigh,
          borderRadius: sudutStempel ? Bentuk.sudutStempel : Bentuk.sudutKecil,
        ),
      ),
    ),
  );
}

/// Keadaan kosong daftar alat (R1b): kartu putih bergaris halus, ikon dalam
/// kotak biru muda, judul 18, satu kalimat, dan (bila ada) SATU tindakan
/// sekunder. Netral: keadaan kosong bukan peringatan (krem = "perlu diperiksa").
/// Dipakai untuk "belum ada alat" dan hasil cari/saring yang kosong; pembedanya
/// kata dan [ikon], keduanya dari pemanggil. [aksi] dan [onAksi] diisi bersama
/// (mis. "Tampilkan semua alat" bila saringan yang menyempitkan daftar).
class UbinKosongAlat extends StatelessWidget {
  const UbinKosongAlat({
    super.key,
    required this.ikon,
    required this.judul,
    required this.keterangan,
    this.aksi,
    this.onAksi,
  }) : assert(
         (aksi == null) == (onAksi == null),
         'aksi dan onAksi harus diisi bersama',
       );

  final IconData ikon;
  final String judul;
  final String keterangan;
  final String? aksi;
  final VoidCallback? onAksi;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final t = context.teks;
    return Material(
      color: s.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Bentuk.sudutUbin,
        side: BorderSide(color: s.outlineVariant, width: Elevasi.garis),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spasi.xl),
        child: Semantics(
          container: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: UkuranUbin.avatar,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: s.primaryContainer,
                      borderRadius: Bentuk.sudutIkon,
                    ),
                    child: Icon(
                      ikon,
                      size: UkuranIkon.sedang,
                      color: s.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spasi.lg),
              Semantics(header: true, child: Text(judul, style: t.titleLarge)),
              const SizedBox(height: Spasi.sm),
              Text(
                keterangan,
                style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
              ),
              if (aksi != null) ...[
                const SizedBox(height: Spasi.lg),
                TombolSidik(label: aksi!, onPressed: onAksi),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lencana jumlah di kepala layar: "N alat" (putih bergaris halus, sudut 12).
/// Hanya digambar bila [jumlah] benar-benar terbaca; memuat atau gagal = tidak
/// ada lencana, bukan "0 alat".
class PilJumlahAlat extends StatelessWidget {
  const PilJumlahAlat({super.key, required this.jumlah});

  final int jumlah;

  /// Tinggi pil kepala (spesifikasi 36): saringan 44 dikurangi 8.
  static const double tinggi = UkuranKontrol.saringan - Spasi.sm;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: Spasi.sisi),
      child: Material(
        color: s.surface,
        shape: RoundedRectangleBorder(
          borderRadius: Bentuk.sudutKapsul,
          side: BorderSide(color: s.outlineVariant, width: Elevasi.garis),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: tinggi),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spasi.md),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                '$jumlah alat',
                style: context.teks.bodySmall?.copyWith(
                  color: s.onSurface,
                  fontWeight: TipografiSidik.beratLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Catatan tanpa koneksi di atas daftar: kotak putih (sudut 12) berikon awan
/// coret. Daftar
/// di bawahnya tetap data terakhir yang tersimpan; teks dari pemanggil.
class CatatanLuring extends StatelessWidget {
  const CatatanLuring({super.key, required this.teks});

  final String teks;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spasi.md),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          container: true,
          label: teks,
          excludeSemantics: true,
          child: Material(
            color: s.surface,
            shape: RoundedRectangleBorder(
              borderRadius: Bentuk.sudutKapsul,
              side: BorderSide(color: s.outline, width: Elevasi.garis),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spasi.lg,
                vertical: Spasi.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: UkuranIkon.kecil,
                    color: s.onSurfaceVariant,
                  ),
                  const SizedBox(width: Spasi.sm),
                  Flexible(
                    child: Text(
                      teks,
                      style: context.teks.bodySmall?.copyWith(
                        color: s.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Daftar ubin alat bergulir: [kepala] di atas, satu [KartuAlat] per alat
/// berjarak [Spasi.antarUbin], lalu [ujung] (bila ada) di akhir. Hanya enam ubin
/// pertama masuk layar berurutan ([maksUrutan]); sisanya langsung tampil.
/// Ubin berkunci id alat, jadi ubin yang tetap ada tidak masuk ulang saat daftar
/// bertambah, dan ubin dari hasil cari/saring baru masuk sebagai yang baru.
class DaftarUbinAlat extends StatelessWidget {
  const DaftarUbinAlat({
    super.key,
    required this.alat,
    required this.onBuka,
    this.kepala = const [],
    this.ujung,
    this.padding,
  }) : assert(alat.length > 0, 'daftar kosong ditangani pemanggil');

  final List<Alat> alat;
  final ValueChanged<Alat> onBuka;
  final List<Widget> kepala;
  final Widget? ujung;
  final EdgeInsetsGeometry? padding;

  static const int maksUrutan = 6;

  @override
  Widget build(BuildContext context) {
    final n = alat.length;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding ?? Spasi.daftar(context),
      itemCount: kepala.length + (n * 2 - 1) + (ujung == null ? 0 : 1),
      itemBuilder: (context, i) {
        if (i < kepala.length) return kepala[i];
        final j = i - kepala.length;
        if (j < n * 2 - 1) {
          if (j.isOdd) return const SizedBox(height: Spasi.antarUbin);
          final indeks = j ~/ 2;
          final a = alat[indeks];
          return KartuAlat(
            key: ValueKey<int>(a.id),
            alat: a,
            onTap: () => onBuka(a),
            urutan: indeks < maksUrutan ? indeks : null,
          );
        }
        return ujung!;
      },
    );
  }
}

/// Ujung daftar berhalaman: galat halaman berikut ("Coba lagi"), pemuat
/// halaman berikut (ubin kerangka statis), atau kalimat penutup. Halaman
/// berikut diminta begitu ujung ini dibangun, artinya pengguna sudah dekat
/// akhir daftar (sama dengan `DaftarBerhalaman`).
class UjungDaftarAlat extends StatelessWidget {
  const UjungDaftarAlat({
    super.key,
    required this.data,
    required this.muatLagi,
  });

  final DataBerhalaman<Alat> data;
  final void Function({bool ulangiGalat}) muatLagi;

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    if (data.galatLagi != null) {
      final e = data.galatLagi;
      return Padding(
        padding: const EdgeInsets.only(top: Spasi.lg),
        child: Column(
          children: [
            Text(
              e is GalatApi ? e.pesan : 'Halaman berikutnya gagal dimuat.',
              textAlign: TextAlign.center,
              style: t.bodySmall,
            ),
            const SizedBox(height: Spasi.sm),
            TombolSidik(
              label: 'Coba lagi',
              ikon: Icons.refresh,
              ragam: RagamTombol.teks,
              onPressed: () => muatLagi(ulangiGalat: true),
            ),
          ],
        ),
      );
    }
    if (data.adaLagi) {
      if (!data.memuatLagi) {
        // Dibangun = sudah dekat ujung. Minta halaman berikut sesudah frame
        // ini (tidak boleh mengubah state di tengah build).
        WidgetsBinding.instance.addPostFrameCallback((_) => muatLagi());
      }
      return const Padding(
        padding: EdgeInsets.only(top: Spasi.antarUbin),
        child: UbinKerangkaAlat(),
      );
    }
    if (data.halaman > 1) {
      return Padding(
        padding: const EdgeInsets.only(top: Spasi.lg),
        child: Text(
          'Semua ${data.total} alat sudah tampil.',
          textAlign: TextAlign.center,
          style: t.bodySmall,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
