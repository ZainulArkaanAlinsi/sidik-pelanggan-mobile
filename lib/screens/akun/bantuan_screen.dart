import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/akun.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/sidik/sidik_permukaan.dart';
import '../../widgets/umum.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(widget.judul)),
      body: RefreshIndicator(
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
            padding: denganTepiBawah(
              context,
              const EdgeInsets.fromLTRB(jarak, 8, jarak, 32),
            ),
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
      final t = Theme.of(context).textTheme;
      final baris = <Widget>[
        if (info.whatsappUrl != null)
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('WhatsApp'),
            subtitle: info.whatsapp == null ? null : Text(info.whatsapp!),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _buka(context, Uri.parse(info.whatsappUrl!)),
          ),
        if (info.email != null)
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Email'),
            subtitle: Text(info.email!),
            trailing: const Icon(Icons.open_in_new),
            onTap: () =>
                _buka(context, Uri(scheme: 'mailto', path: info.email)),
          ),
        if (info.teleponOrganisasi != null)
          ListTile(
            leading: const Icon(Icons.call_outlined),
            title: const Text('Telepon'),
            subtitle: Text(info.teleponOrganisasi!),
            trailing: const Icon(Icons.open_in_new),
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
          Kertas(
            padding: const EdgeInsets.all(jarak),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info.namaOrganisasi != null)
                  Text(info.namaOrganisasi!, style: t.titleMedium),
                if (info.alamatOrganisasi != null) ...[
                  const SizedBox(height: 4),
                  SelectableText(info.alamatOrganisasi!, style: t.bodyMedium),
                ],
              ],
            ),
          ),
        if (info.jamLayanan != null) ...[
          const SizedBox(height: 12),
          Text('Jam layanan: ${info.jamLayanan}', style: t.bodyMedium),
        ],
        const JudulSeksi('Hubungi Tim PT Sidik'),
        if (baris.isEmpty)
          Text(
            'Kontak PT Sidik belum tersedia di aplikasi.',
            style: t.bodyMedium,
          )
        else
          Kertas(
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  for (var i = 0; i < baris.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 56),
                    baris[i],
                  ],
                ],
              ),
            ),
          ),
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
      final t = Theme.of(context).textTheme;
      String? versi(String? v) => v == null ? null : 'Versi $v';
      final baris = <Widget>[
        if (info.kebijakanPrivasiUrl != null)
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Kebijakan privasi'),
            subtitle: versi(info.kebijakanPrivasiVersi) == null
                ? null
                : Text(versi(info.kebijakanPrivasiVersi)!),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _buka(context, Uri.parse(info.kebijakanPrivasiUrl!)),
          ),
        if (info.syaratUrl != null)
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Syarat & ketentuan'),
            subtitle: versi(info.syaratVersi) == null
                ? null
                : Text(versi(info.syaratVersi)!),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _buka(context, Uri.parse(info.syaratUrl!)),
          ),
        if (info.hapusAkunUrl != null)
          ListTile(
            leading: const Icon(Icons.person_remove_outlined),
            title: const Text('Permintaan hapus akun (web)'),
            subtitle: const Text(
              'Untuk yang tidak bisa masuk ke aplikasi lagi',
            ),
            trailing: const Icon(Icons.open_in_new),
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
          Kertas(
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  for (var i = 0; i < baris.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 56),
                    baris[i],
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
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
