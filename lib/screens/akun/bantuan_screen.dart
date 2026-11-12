import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/tema/spasi.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/akun.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/bagian_sidik.dart';
import '../../widgets/baris_menu.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kartu_sidik.dart';
import '../../widgets/keadaan_galat.dart';
import '../../widgets/kerangka.dart';

/// Buka tautan di aplikasi luar (WhatsApp, email, telepon, peramban).
/// `false` kalau HP tidak punya aplikasi untuk membukanya.
Future<bool> bukaTautanLuar(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<void> _buka(BuildContext context, Uri uri) async {
  final pesan = ScaffoldMessenger.of(context);
  if (!await bukaTautanLuar(uri)) {
    pesan.showSnackBar(
      const SnackBar(content: Text('Tidak ada aplikasi untuk membukanya.')),
    );
  }
}

/// Kerangka layar yang isinya dari `GET /app/info`: dimuat ulang tiap layar
/// dibuka (kontrak §6), cache selama aplikasi hidup tetap tampil selagi
/// memuat.
class _LayarInfo extends ConsumerStatefulWidget {
  const _LayarInfo({required this.judul, required this.isi});

  final String judul;
  final List<Widget> Function(BuildContext context, InfoAplikasi info) isi;

  @override
  ConsumerState<_LayarInfo> createState() => _LayarInfoState();
}

class _LayarInfoState extends ConsumerState<_LayarInfo> {
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
          await ref.read(infoAplikasiProvider.future);
        },
        child: async.when(
          loading: () => const Memuat.detail(),
          error: (e, _) => KeadaanGalat(
            galat: e,
            cobaLagi: () => ref.invalidate(infoAplikasiProvider),
          ),
          data: (info) => ListView(
            padding: Spasi.daftar(context),
            children: widget.isi(context, info),
          ),
        ),
      ),
    );
  }
}

/// S17 → Bantuan & kontak. Hanya kanal yang DIISI lab yang tampil — tidak
/// ada nomor atau alamat karangan (kontrak §6).
class BantuanScreen extends StatelessWidget {
  const BantuanScreen({super.key});

  @override
  Widget build(BuildContext context) => _LayarInfo(
    judul: 'Bantuan & kontak',
    isi: (context, info) {
      final t = context.teks;
      final baris = <Widget>[
        if (info.whatsappUrl != null)
          BarisMenu(
            ikon: Icons.chat_outlined,
            judul: 'WhatsApp',
            keterangan: info.whatsapp,
            luar: true,
            onTap: () => _buka(context, Uri.parse(info.whatsappUrl!)),
          ),
        if (info.email != null)
          BarisMenu(
            ikon: Icons.mail_outline,
            judul: 'Email',
            keterangan: info.email,
            luar: true,
            onTap: () =>
                _buka(context, Uri(scheme: 'mailto', path: info.email)),
          ),
        if (info.teleponOrganisasi != null)
          BarisMenu(
            ikon: Icons.call_outlined,
            judul: 'Telepon',
            keterangan: info.teleponOrganisasi,
            luar: true,
            onTap: () => _buka(
              context,
              Uri(
                scheme: 'tel',
                path: info.teleponOrganisasi!.replaceAll(
                  RegExp(r'[^0-9+]'),
                  '',
                ),
              ),
            ),
          ),
      ];
      return [
        if (info.namaOrganisasi != null || info.alamatOrganisasi != null)
          KartuSidik(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info.namaOrganisasi != null)
                  Text(info.namaOrganisasi!, style: t.titleMedium),
                if (info.alamatOrganisasi != null) ...[
                  const SizedBox(height: Spasi.xs),
                  SelectableText(info.alamatOrganisasi!, style: t.bodyMedium),
                ],
              ],
            ),
          ),
        if (info.jamLayanan != null) ...[
          const SizedBox(height: Spasi.md),
          Text('Jam layanan: ${info.jamLayanan}', style: t.bodyMedium),
        ],
        const BagianSidik('Hubungi Tim PT Sidik'),
        if (baris.isEmpty)
          Text('Informasi kontak belum tersedia.', style: t.bodyMedium)
        else
          KelompokBaris(baris: baris),
      ];
    },
  );
}

/// S17 → Privasi & ketentuan (REQ-PRV-01/03). Dokumen dibuka di peramban.
class PrivasiScreen extends StatelessWidget {
  const PrivasiScreen({super.key});

  @override
  Widget build(BuildContext context) => _LayarInfo(
    judul: 'Privasi & ketentuan',
    isi: (context, info) {
      final t = context.teks;
      String? versi(String? v) => v == null ? null : 'Versi $v';
      final baris = <Widget>[
        if (info.kebijakanPrivasiUrl != null)
          BarisMenu(
            ikon: Icons.privacy_tip_outlined,
            judul: 'Kebijakan privasi',
            keterangan: versi(info.kebijakanPrivasiVersi),
            luar: true,
            onTap: () => _buka(context, Uri.parse(info.kebijakanPrivasiUrl!)),
          ),
        if (info.syaratUrl != null)
          BarisMenu(
            ikon: Icons.gavel_outlined,
            judul: 'Syarat & ketentuan',
            keterangan: versi(info.syaratVersi),
            luar: true,
            onTap: () => _buka(context, Uri.parse(info.syaratUrl!)),
          ),
        if (info.hapusAkunUrl != null)
          BarisMenu(
            ikon: Icons.person_remove_outlined,
            judul: 'Permintaan hapus akun (web)',
            keterangan: 'Untuk yang tidak bisa masuk ke aplikasi lagi',
            luar: true,
            onTap: () => _buka(context, Uri.parse(info.hapusAkunUrl!)),
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
