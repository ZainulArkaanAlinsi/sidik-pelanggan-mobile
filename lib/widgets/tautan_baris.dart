import 'package:flutter/material.dart';

import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';

/// Tautan teks selebar baris ("Lihat semua alat (9)") dengan panah: pengganti
/// tombol outline lebar yang bersaing dengan aksi utama. Setinggi sentuh
/// minimal 48 dp dan tumbuh bila teks membungkus. Tanpa [onTap] tampil mati
/// (bukan tautan palsu yang tidak berbuat apa-apa).
///
/// [semantik] = kalimat lengkap untuk pembaca layar bila tulisan di layar
/// sengaja pendek.
class TautanBaris extends StatelessWidget {
  const TautanBaris(this.teks, {super.key, this.onTap, this.semantik});

  final String teks;
  final VoidCallback? onTap;
  final String? semantik;

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    final warna = onTap == null ? s.onSurfaceVariant : s.primary;
    return Semantics(
      button: true,
      enabled: onTap != null,
      onTap: onTap,
      label: semantik ?? teks,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AreaSentuh.minimum),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spasi.sm),
                  child: Text(
                    teks,
                    style: context.teks.labelLarge?.copyWith(color: warna),
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: warna),
            ],
          ),
        ),
      ),
    );
  }
}
