import 'package:flutter/material.dart';

import '../../core/tema/bentuk.dart';
import '../../core/tema/elevasi.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../widgets/kolom_formulir.dart';
import '../../widgets/logo_sidik.dart';
import '../../widgets/tombol_bulat.dart';

/// Kerangka bersama keempat layar auth (Sambutan, Masuk, Lupa sandi, Terima
/// undangan), arah tenang-formal (REVISI-1 §5, REVISI-2 butir 1).
///
/// - Kepala ringkas di atas latar halaman: logo kecil di plat putih
///   ([UkuranAuth.platLogo]) dan nama aplikasi di sebelahnya. Tanpa bidang
///   berwarna, tanpa logo besar (dulu kepala biru muda 240 dp dengan plat 80).
/// - [kartu]: kartu putih bergaris halus sudut 16, tanpa bayangan. Isinya
///   formulir/tombol milik layar: judul, penjelasan, isian berlabel
///   (`KolomIsian`), SATU tombol utama.
/// - [bawah]: di luar kartu, di atas latar halaman (panel undangan, lencana
///   akreditasi, nama PT).
/// - [ringkas]: layar anak (Lupa sandi, Terima undangan): kepala membawa tombol
///   kembali bulat di kiri bila layar ini bisa ditutup.
///
/// Seluruhnya satu `ListView` di dalam `SafeArea` (bergulir bila isinya lebih
/// tinggi dari layar; `Scaffold` menyusutkan isi saat papan ketik terbuka dan
/// isian yang fokus digulirkan ke tempat terlihat bersama tombol di
/// bawahnya). Tanpa animasi: tidak ada yang berulang, jadi "kurangi gerak"
/// tidak mengubah apa pun di sini. Hanya tata letak dan gaya; logika, validasi,
/// dan navigasi milik layar pemakai.
class KerangkaAuth extends StatelessWidget {
  const KerangkaAuth({
    super.key,
    required this.kartu,
    this.bawah = const [],
    this.ringkas = false,
  });

  final List<Widget> kartu;
  final List<Widget> bawah;
  final bool ringkas;

  /// Kunci untuk tes tata letak: kepala, plat logo, kartu.
  static const kunciKepala = ValueKey<String>('auth-kepala');
  static const kunciPlat = ValueKey<String>('auth-plat-logo');
  static const kunciKartu = ValueKey<String>('auth-kartu');

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: Spasi.xl),
        children: [
          _Lebar(child: _Kepala(ringkas: ringkas)),
          const SizedBox(height: Spasi.lg),
          _Lebar(child: _Kartu(anak: kartu)),
          if (bawah.isNotEmpty) ...[
            const SizedBox(height: Spasi.xl),
            _Lebar(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: bawah,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Judul kartu (24/30): penanda judul untuk pembaca layar. Layar anak tidak
/// punya app bar lagi, jadi judulnya yang menamai layar. `container: true`
/// wajib: tanpa itu simpul judul melebur ke teks di sebelahnya dan seluruh
/// paragraf terbaca sebagai judul.
class JudulAuth extends StatelessWidget {
  const JudulAuth(this.teks, {super.key});

  final String teks;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    container: true,
    child: Text(teks, style: context.teks.displaySmall),
  );
}

/// Pesan galat formulir: ikon + kalimat dalam merah galat (warna bukan satu-
/// satunya penanda), diumumkan pembaca layar begitu muncul. Diletakkan tepat
/// di bawah isian terakhir; galat per isian memakai `KolomIsian.galat`.
class PesanGalatAuth extends StatelessWidget {
  const PesanGalatAuth(this.pesan, {super.key});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.error_outline,
              size: UkuranIkon.sedang,
              color: s.error,
            ),
          ),
          const SizedBox(width: Spasi.sm),
          Expanded(
            child: Text(
              pesan,
              style: context.teks.bodyMedium?.copyWith(color: s.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lebar isi: kolom sempit di tengah (440 dp) dengan margin halaman.
class _Lebar extends StatelessWidget {
  const _Lebar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: Spasi.halaman,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: KolomFormulir.lebarMaks),
        child: child,
      ),
    ),
  );
}

/// Kartu putih sudut 16 bergaris halus. `Material` (bukan `DecoratedBox`)
/// supaya riak `ListTile` dan kawan-kawannya tidak tertutup warna kartu.
class _Kartu extends StatelessWidget {
  const _Kartu({required this.anak});

  final List<Widget> anak;

  @override
  Widget build(BuildContext context) => Material(
    key: KerangkaAuth.kunciKartu,
    color: context.skema.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: Bentuk.sudutPanel,
      side: BorderSide(
        color: context.skema.outlineVariant,
        width: Elevasi.garis,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(Spasi.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: anak,
      ),
    ),
  );
}

/// Kepala: [tombol kembali bila layar anak dan bisa ditutup] + plat logo +
/// nama aplikasi. Rata kiri, satu baris tinggi tombol (48).
class _Kepala extends StatelessWidget {
  const _Kepala({required this.ringkas});

  final bool ringkas;

  @override
  Widget build(BuildContext context) {
    // Seperti AppBar: tombol kembali hanya bila ada layar di bawah ini.
    final bisaKembali = ringkas && (ModalRoute.of(context)?.canPop ?? false);
    final plat = ringkas ? UkuranAuth.platLogoAnak : UkuranAuth.platLogo;
    return ConstrainedBox(
      key: KerangkaAuth.kunciKepala,
      constraints: const BoxConstraints(minHeight: AreaSentuh.minimum),
      child: Padding(
        padding: const EdgeInsets.only(top: Spasi.sm),
        child: Row(
          children: [
            if (bisaKembali) ...[
              // Simpul sendiri: tanpa `container`, tombol berlabel melebur ke
              // logo dan nama aplikasi di sebelahnya (satu simpul "Kembali,
              // Logo PT Sidik, ...").
              Semantics(
                container: true,
                child: TombolBulat.kembali(
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(width: Spasi.md),
            ],
            _PlatLogo(sisi: plat),
            const SizedBox(width: Spasi.md),
            Expanded(
              child: Text('SIDIK Pelanggan', style: context.teks.titleLarge),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plat logo putih bergaris halus. Putih di dua tema: berkas logonya berlatar
/// putih.
class _PlatLogo extends StatelessWidget {
  const _PlatLogo({required this.sisi});

  final double sisi;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: KerangkaAuth.kunciPlat,
    decoration: BoxDecoration(
      color: context.warna.kertasUbin,
      borderRadius: Bentuk.sudutIkon,
      border: Border.all(
        color: context.skema.outlineVariant,
        width: Elevasi.garis,
      ),
    ),
    child: SizedBox.square(
      dimension: sisi,
      child: Center(child: LogoSidik(tinggi: sisi - 2 * Spasi.sm)),
    ),
  );
}
