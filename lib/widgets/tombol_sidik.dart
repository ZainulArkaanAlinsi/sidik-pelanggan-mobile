import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';

/// Ragam tombol. Satu layar cuma boleh punya SATU [RagamTombol.utama].
enum RagamTombol {
  /// Isi kobalt. Aksi utama layar.
  utama,

  /// Garis tipis. Aksi pendamping.
  sekunder,

  /// Hanya teks. Aksi tersier (Lupa sandi, Lewati).
  teks,

  /// Garis dan teks merah galat. Aksi merusak.
  bahaya,
}

/// Tombol aplikasi di atas `FilledButton`/`OutlinedButton`/`TextButton`:
/// ripple standar, tinggi minimal 48 dp, tumbuh ke bawah bila label membungkus
/// (huruf besar di layar sempit).
///
/// [sibuk] mengganti ikon dengan pemutar dan mematikan tombol: per tombol,
/// bukan satu penanda untuk seluruh layar. [penuh] membentang selebar induk.
class TombolSidik extends StatelessWidget {
  const TombolSidik({
    super.key,
    required this.label,
    this.onPressed,
    this.ragam = RagamTombol.sekunder,
    this.ikon,
    this.sibuk = false,
    this.penuh = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final RagamTombol ragam;
  final IconData? ikon;
  final bool sibuk;
  final bool penuh;

  @override
  Widget build(BuildContext context) {
    final aksi = sibuk ? null : onPressed;
    final isiTeks = Text(label, textAlign: TextAlign.center);
    final Widget? penanda = sibuk
        ? const SizedBox.square(
            dimension: UkuranIkon.kecil + Spasi.xs,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (ikon == null ? null : Icon(ikon, size: UkuranIkon.sedang - 4));

    final Widget tombol = switch (ragam) {
      RagamTombol.utama =>
        penanda == null
            ? FilledButton(onPressed: aksi, child: isiTeks)
            : FilledButton.icon(onPressed: aksi, icon: penanda, label: isiTeks),
      RagamTombol.sekunder =>
        penanda == null
            ? OutlinedButton(onPressed: aksi, child: isiTeks)
            : OutlinedButton.icon(
                onPressed: aksi,
                icon: penanda,
                label: isiTeks,
              ),
      RagamTombol.teks =>
        penanda == null
            ? TextButton(onPressed: aksi, child: isiTeks)
            : TextButton.icon(onPressed: aksi, icon: penanda, label: isiTeks),
      RagamTombol.bahaya => _tombolBahaya(context, aksi, isiTeks, penanda),
    };

    return penuh ? SizedBox(width: double.infinity, child: tombol) : tombol;
  }

  Widget _tombolBahaya(
    BuildContext context,
    VoidCallback? aksi,
    Widget isiTeks,
    Widget? penanda,
  ) {
    final galat = Theme.of(context).colorScheme.error;
    final gaya = OutlinedButton.styleFrom(
      foregroundColor: galat,
      side: BorderSide(color: galat),
    );
    return penanda == null
        ? OutlinedButton(onPressed: aksi, style: gaya, child: isiTeks)
        : OutlinedButton.icon(
            onPressed: aksi,
            style: gaya,
            icon: penanda,
            label: isiTeks,
          );
  }
}
