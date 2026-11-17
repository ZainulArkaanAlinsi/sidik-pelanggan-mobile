import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tautan_luar.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/akun.dart';
import '../../providers/sesi_provider.dart';
import '../../providers/tautan_provider.dart';
import '../../widgets/baris_menu.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/keadaan_galat.dart';
import '../../widgets/kerangka.dart';

/// Kerangka layar yang isinya dari `GET /app/info`: dimuat ulang tiap layar
/// dibuka (kontrak §6). Isi yang sudah ada tetap tampil selagi memuat DAN bila
/// pemuatan ulang gagal (mis. tanpa sinyal atau server sedang pemeliharaan):
/// kontak yang pernah terbaca lebih berguna daripada layar galat. Galat hanya
/// bila belum pernah ada isi.
class LayarInfoAplikasi extends ConsumerStatefulWidget {
  const LayarInfoAplikasi({super.key, required this.judul, required this.isi});

  final String judul;
  final List<Widget> Function(
    BuildContext context,
    InfoAplikasi info,
    WidgetRef ref,
  )
  isi;

  @override
  ConsumerState<LayarInfoAplikasi> createState() => _LayarInfoAplikasiState();
}

class _LayarInfoAplikasiState extends ConsumerState<LayarInfoAplikasi> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(infoAplikasiProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(infoAplikasiProvider);
    return HalamanSidik(
      judul: widget.judul,
      isi: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(infoAplikasiProvider);
          try {
            await ref.read(infoAplikasiProvider.future);
          } catch (_) {
            // Galat tampil lewat `KeadaanGalat` bila belum ada isi.
          }
        },
        child: async.when(
          skipError: true,
          loading: () => const Memuat.detail(),
          error: (e, _) => KeadaanGalat(
            galat: e,
            cobaLagi: () => ref.invalidate(infoAplikasiProvider),
          ),
          data: (info) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: Spasi.daftar(context),
            children: widget.isi(context, info, ref),
          ),
        ),
      ),
    );
  }
}

/// S17 → Privasi & ketentuan (REQ-PRV-01/03). Dokumen dibuka di peramban.
/// Hanya tautan `https` yang sah yang ditawarkan ([TautanLuar.web]).
class PrivasiScreen extends StatelessWidget {
  const PrivasiScreen({super.key});

  @override
  Widget build(BuildContext context) => LayarInfoAplikasi(
    judul: 'Privasi & ketentuan',
    isi: (context, info, ref) {
      final t = context.teks;
      String? versi(String? v) => v == null ? null : 'Versi $v';
      final privasi = TautanLuar.web(info.kebijakanPrivasiUrl);
      final syarat = TautanLuar.web(info.syaratUrl);
      final hapus = TautanLuar.web(info.hapusAkunUrl);
      final baris = <Widget>[
        if (privasi != null)
          BarisMenu(
            ikon: Icons.privacy_tip_outlined,
            judul: 'Kebijakan privasi',
            keterangan: versi(info.kebijakanPrivasiVersi),
            luar: true,
            onTap: () => bukaAtauBeritahu(context, ref, privasi),
          ),
        if (syarat != null)
          BarisMenu(
            ikon: Icons.gavel_outlined,
            judul: 'Syarat & ketentuan',
            keterangan: versi(info.syaratVersi),
            luar: true,
            onTap: () => bukaAtauBeritahu(context, ref, syarat),
          ),
        if (hapus != null)
          BarisMenu(
            ikon: Icons.person_remove_outlined,
            judul: 'Permintaan hapus akun (web)',
            keterangan: 'Untuk yang tidak bisa masuk ke aplikasi lagi',
            luar: true,
            onTap: () => bukaAtauBeritahu(context, ref, hapus),
          ),
      ];
      return [
        if (baris.isEmpty)
          Text(
            'Dokumen privasi dan ketentuan belum tersedia di aplikasi.',
            style: t.bodyMedium,
          )
        else
          KelompokBaris(baris: baris),
        const SizedBox(height: Spasi.lg),
        Text(
          'Data alat dan sertifikat perusahaan adalah rekaman '
          'laboratorium dan tetap disimpan walau akun Anda dihapus; data '
          'pribadi Anda dianonimkan.',
          style: t.bodySmall,
        ),
      ];
    },
  );
}
