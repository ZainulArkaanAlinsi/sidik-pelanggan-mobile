import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/tema/bentuk.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../widgets/kolom_formulir.dart';
import '../../widgets/logo_sidik.dart';
import '../../widgets/tombol_bulat.dart';

/// Kerangka bersama keempat layar auth (Sambutan, Masuk, Lupa sandi, Terima
/// undangan): susunan E0 Masuk.
///
/// - Kepala biru muda ([WarnaSidik.ubinBiru]) dari tepi atas layar: plat logo
///   putih dan nama aplikasi bertinta navy. Tetap terang di tema gelap, jadi
///   kepala, plat, dan tintanya sama di dua tema. Penyusunan ulang layar auth
///   (kepala lebih kecil, label di atas kolom) menyusul di PR berikutnya.
/// - [kartu]: kartu putih sudut 16 yang menumpang [UkuranAuth.kartuTumpang]
///   ke bawah tepi kepala. Isinya formulir/tombol milik layar.
/// - [bawah]: di luar kartu, di atas latar halaman (panel undangan, lencana
///   akreditasi, nama PT).
/// - [ringkas]: layar anak (Lupa sandi, Terima undangan). Hero pendek dengan
///   tombol kembali bulat di kiri bila layar ini bisa ditutup; formulirnya
///   panjang, jadi tidak boleh terkubur di bawah hero setinggi 330.
///
/// Seluruhnya satu `ListView` (bergulir bila isinya lebih tinggi dari layar;
/// keyboard menggulirkan isian yang fokus ke tempat terlihat). Tanpa animasi:
/// tidak ada yang berulang, jadi "kurangi gerak" tidak mengubah apa pun di
/// sini. Hanya tata letak dan gaya; logika, validasi, dan navigasi milik
/// layar pemakai.
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

  /// Kunci untuk tes tata letak: kepala (biru muda, dari tepi atas layar
  /// sampai tepi atas kartu), biru muda di belakang tepi atas kartu, plat logo,
  /// kartu.
  static const kunciHero = ValueKey<String>('auth-hero');
  static const kunciTumpang = ValueKey<String>('auth-hero-tumpang');
  static const kunciPlat = ValueKey<String>('auth-plat-logo');
  static const kunciKartu = ValueKey<String>('auth-kartu');

  @override
  Widget build(BuildContext context) {
    final bawahSistem = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: ListView(
        // Hero menggambar sampai ke bawah status bar sendiri.
        padding: EdgeInsets.zero,
        children: [
          _Hero(ringkas: ringkas),
          Stack(
            children: [
              // Biru muda di belakang tepi atas kartu: kartu tampak menumpang
              // di dalam kepala, bukan tergantung di bawahnya.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: UkuranAuth.kartuTumpang,
                child: ColoredBox(
                  key: kunciTumpang,
                  color: context.warna.ubinBiru,
                ),
              ),
              _Lebar(child: _Kartu(anak: kartu)),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: bawah.isEmpty ? 0 : Spasi.xl,
              bottom: Spasi.xl + bawahSistem,
            ),
            child: bawah.isEmpty
                ? null
                : _Lebar(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: bawah,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Judul kartu (20/26): penanda judul untuk pembaca layar. Layar anak tidak
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
    child: Text(teks, style: context.teks.headlineSmall),
  );
}

/// Pesan galat formulir: ikon + kalimat dalam merah galat (warna bukan satu-
/// satunya penanda), diumumkan pembaca layar begitu muncul.
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

/// Kartu putih sudut 16. `Material` (bukan `DecoratedBox`) supaya riak
/// `ListTile` dan kawan-kawannya tidak tertutup warna kartu.
class _Kartu extends StatelessWidget {
  const _Kartu({required this.anak});

  final List<Widget> anak;

  @override
  Widget build(BuildContext context) => Material(
    key: KerangkaAuth.kunciKartu,
    color: context.skema.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: Bentuk.sudutUbin),
    child: Padding(
      padding: const EdgeInsets.all(Spasi.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: anak,
      ),
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.ringkas});

  final bool ringkas;

  @override
  Widget build(BuildContext context) {
    final w = context.warna;
    final atas = MediaQuery.paddingOf(context).top;
    // Seperti AppBar: tombol kembali hanya bila ada layar di bawah ini.
    final bisaKembali = ringkas && (ModalRoute.of(context)?.canPop ?? false);
    final plat = ringkas ? UkuranAuth.platLogoAnak : UkuranAuth.platLogo;

    final Widget isi;
    if (ringkas) {
      // Tombol kembali, plat di tengah, dan pengimbang selebar tombol di
      // kanan supaya plat tetap di tengah layar.
      isi = Row(
        children: [
          if (bisaKembali)
            TombolBulat.kembali(onTap: () => Navigator.of(context).maybePop())
          else
            const SizedBox(width: AreaSentuh.minimum),
          Expanded(
            child: Center(child: _PlatLogo(sisi: plat)),
          ),
          const SizedBox(width: AreaSentuh.minimum),
        ],
      );
    } else {
      isi = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PlatLogo(sisi: plat),
          const SizedBox(height: Spasi.lg),
          // 28 sp ke atas dijepit 1,15x (SkalaHuruf): empat baris di 320 dp
          // bila tidak.
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: SkalaHuruf.batasBesar,
            child: Semantics(
              header: true,
              container: true,
              child: Text(
                'SIDIK Pelanggan',
                textAlign: TextAlign.center,
                style: context.teks.displaySmall?.copyWith(color: w.tintaUbin),
              ),
            ),
          ),
        ],
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Ikon status bar gelap di atas biru muda (juga di tema gelap). Hanya
      // selama hero ada di puncak layar; sesudah tergulir, bawaan sistem.
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        key: KerangkaAuth.kunciHero,
        color: w.ubinBiru,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: ringkas ? 0 : UkuranAuth.hero - UkuranAuth.kartuTumpang,
          ),
          child: Align(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Spasi.sisi,
                atas + Spasi.lg,
                Spasi.sisi,
                Spasi.xl,
              ),
              child: isi,
            ),
          ),
        ),
      ),
    );
  }
}

/// Plat logo putih. Putih di dua tema: berkas logonya berlatar putih.
class _PlatLogo extends StatelessWidget {
  const _PlatLogo({required this.sisi});

  final double sisi;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: KerangkaAuth.kunciPlat,
    decoration: BoxDecoration(
      color: context.warna.kertasUbin,
      borderRadius: Bentuk.sudutPanel,
    ),
    child: SizedBox.square(
      dimension: sisi,
      child: Center(child: LogoSidik(tinggi: sisi - 2 * Spasi.lg)),
    ),
  );
}
