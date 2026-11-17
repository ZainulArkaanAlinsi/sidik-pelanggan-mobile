import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tautan_luar.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../models/akun.dart';
import '../../providers/tautan_provider.dart';
import '../../widgets/bagian_sidik.dart';
import '../../widgets/lencana_kan.dart';
import '../../widgets/panel_sidik.dart';
import '../../widgets/tombol_sidik.dart';
import 'bantuan_screen.dart';

/// Hubungi PT SIDIK (REVISI-2 butir 12; menggantikan layar "Bantuan & kontak").
/// Isinya dari `GET /app/info`, dimuat ulang tiap layar dibuka (kontak yang
/// pernah terbaca tetap tampil bila pemuatan ulang gagal).
///
/// Dari atas: identitas perusahaan + akreditasi KAN, jam layanan (HANYA bila
/// server mengirimnya), tombol utama "Chat dengan admin" (WhatsApp), kanal
/// ringkas (telepon, email, email pemasaran, alamat) dengan salin satu ketuk,
/// lalu tautan sekunder (Instagram, LinkedIn, ruang lingkup akreditasi).
///
/// Field `null` atau tidak aman = barisnya tidak ada; server lama tanpa field
/// baru tetap jalan. Hanya tautan `https`, `mailto`, dan `tel` yang dibuka
/// ([TautanLuar]); aplikasi tidak mengarang nomor atau alamat.
class HubungiScreen extends StatelessWidget {
  const HubungiScreen({super.key});

  @override
  Widget build(BuildContext context) => LayarInfoAplikasi(
    judul: 'Hubungi PT SIDIK',
    isi: (context, info, ref) => _isi(context, info, ref),
  );

  static List<Widget> _isi(
    BuildContext context,
    InfoAplikasi info,
    WidgetRef ref,
  ) {
    final t = context.teks;
    final s = context.skema;

    final wa = TautanLuar.whatsapp(info.whatsappUrl);
    final telepon = TautanLuar.telepon(info.teleponOrganisasi);
    final email = TautanLuar.alamatEmail(info.email);
    final emailPemasaran = TautanLuar.alamatEmail(info.emailPemasaran);
    final alamat = info.alamatOrganisasi?.trim();
    final peta = TautanLuar.peta(alamat);
    final instagram = TautanLuar.web(info.instagramUrl);
    final linkedin = TautanLuar.web(info.linkedinUrl);
    final lingkup = TautanLuar.web(info.ruangLingkupUrl);

    final kanal = <Widget>[
      if (telepon != null)
        _BarisKanal(
          ikon: Icons.call_outlined,
          judul: 'Telepon',
          nilai: info.teleponOrganisasi!.trim(),
          aksiBuka: 'menelepon',
          onBuka: () => bukaAtauBeritahu(context, ref, telepon),
          salin: (
            tooltip: 'Salin nomor telepon',
            teks: info.teleponOrganisasi!.trim(),
            konfirmasi: 'Nomor telepon disalin.',
          ),
        ),
      if (email != null)
        _BarisKanal(
          ikon: Icons.mail_outline,
          judul: 'Email',
          nilai: email,
          aksiBuka: 'menulis email',
          onBuka: () => bukaAtauBeritahu(context, ref, TautanLuar.email(email)),
          salin: (
            tooltip: 'Salin alamat email',
            teks: email,
            konfirmasi: 'Alamat email disalin.',
          ),
        ),
      if (emailPemasaran != null)
        _BarisKanal(
          ikon: Icons.campaign_outlined,
          judul: 'Email pemasaran',
          nilai: emailPemasaran,
          aksiBuka: 'menulis email',
          onBuka: () =>
              bukaAtauBeritahu(context, ref, TautanLuar.email(emailPemasaran)),
          salin: (
            tooltip: 'Salin alamat email pemasaran',
            teks: emailPemasaran,
            konfirmasi: 'Alamat email pemasaran disalin.',
          ),
        ),
      if (alamat != null && alamat.isNotEmpty && peta != null)
        _BarisKanal(
          ikon: Icons.place_outlined,
          judul: 'Alamat',
          nilai: alamat,
          aksiBuka: 'membuka di peta',
          onBuka: () => bukaAtauBeritahu(context, ref, peta),
          salin: (
            tooltip: 'Salin alamat',
            teks: alamat,
            konfirmasi: 'Alamat disalin.',
          ),
        ),
    ];

    final tautan = <Widget>[
      if (instagram != null)
        _BarisKanal(
          ikon: Icons.photo_camera_outlined,
          judul: 'Instagram',
          nilai: _ringkasTautan(instagram),
          aksiBuka: 'membuka di aplikasi lain',
          onBuka: () => bukaAtauBeritahu(context, ref, instagram),
        ),
      if (linkedin != null)
        _BarisKanal(
          ikon: Icons.business_center_outlined,
          judul: 'LinkedIn',
          nilai: _ringkasTautan(linkedin),
          aksiBuka: 'membuka di aplikasi lain',
          onBuka: () => bukaAtauBeritahu(context, ref, linkedin),
        ),
      if (lingkup != null)
        _BarisKanal(
          ikon: Icons.description_outlined,
          judul: 'Ruang lingkup akreditasi',
          nilai: 'Dokumen PDF, dibuka di aplikasi lain',
          aksiBuka: 'membuka dokumen',
          onBuka: () => bukaAtauBeritahu(context, ref, lingkup),
        ),
    ];

    final nama = info.namaOrganisasi?.trim();
    final jam = info.jamLayanan?.trim();
    final adaApaPun = wa != null || kanal.isNotEmpty || tautan.isNotEmpty;

    return [
      PanelSidik(
        padding: PanelSidik.paddingIsi,
        anak: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  nama == null || nama.isEmpty ? 'PT SIDIK' : nama,
                  style: t.titleMedium,
                ),
              ),
              const SizedBox(height: Spasi.sm),
              const LencanaKan(),
              const SizedBox(height: Spasi.sm),
              Text(
                'Laboratorium kalibrasi terakreditasi.',
                style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
              ),
              if (jam != null && jam.isNotEmpty) ...[
                const SizedBox(height: Spasi.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.schedule_outlined,
                        size: UkuranIkon.kecil,
                        color: s.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: Spasi.sm),
                    Expanded(
                      child: Text('Jam layanan: $jam', style: t.bodyMedium),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
      if (wa != null) ...[
        const SizedBox(height: Spasi.lg),
        TombolSidik(
          label: 'Chat dengan admin',
          ikon: Icons.chat_outlined,
          ragam: RagamTombol.utama,
          penuh: true,
          onPressed: () => bukaAtauBeritahu(
            context,
            ref,
            wa,
            galat: 'WhatsApp belum terpasang di HP ini.',
          ),
        ),
        if (info.whatsapp != null)
          Padding(
            padding: const EdgeInsets.only(top: Spasi.sm),
            child: Text(
              'WhatsApp ${info.whatsapp}',
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: s.onSurfaceVariant),
            ),
          ),
      ],
      if (kanal.isNotEmpty) ...[
        const BagianSidik('Kontak'),
        PanelSidik(anak: kanal),
      ],
      if (tautan.isNotEmpty) ...[
        const BagianSidik('Tautan'),
        PanelSidik(anak: tautan),
      ],
      if (!adaApaPun) ...[
        const SizedBox(height: Spasi.lg),
        Text('Informasi kontak belum tersedia.', style: t.bodyMedium),
      ],
    ];
  }

  /// "www.instagram.com/ptsidikbdg": alamat tanpa skema dan tanpa garis miring
  /// penutup, supaya terlihat ke mana tautannya (diturunkan dari data).
  static String _ringkasTautan(Uri u) {
    final jalur = u.path.endsWith('/')
        ? u.path.substring(0, u.path.length - 1)
        : u.path;
    return '${u.host}$jalur';
  }
}

/// Isi satu tombol salin: [tooltip] untuk pembaca layar, [teks] yang disalin,
/// dan [konfirmasi] yang muncul sesudahnya.
typedef _Salin = ({String tooltip, String teks, String konfirmasi});

/// Satu kanal: ikon, judul, nilai. Mengetuk barisnya membuka kanal itu
/// ([onBuka]); tombol di kanan menyalin nilainya ([salin], satu ketuk + konfirmasi).
/// Dua kontrol bersaudara (BUKAN satu di dalam yang lain), jadi pembaca layar
/// menerima dua tombol terpisah: "Telepon, 0822..., ketuk untuk menelepon" dan
/// "Salin nomor telepon".
class _BarisKanal extends ConsumerWidget {
  const _BarisKanal({
    required this.ikon,
    required this.judul,
    required this.nilai,
    required this.aksiBuka,
    required this.onBuka,
    this.salin,
  });

  final IconData ikon;
  final String judul;
  final String nilai;

  /// Kata kerja untuk pembaca layar ("menelepon").
  final String aksiBuka;
  final VoidCallback onBuka;
  final _Salin? salin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.teks;
    final s = context.skema;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: '$judul, $nilai. Ketuk untuk $aksiBuka.',
            onTap: onBuka,
            excludeSemantics: true,
            child: InkWell(
              onTap: onBuka,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: UkuranBaris.minimum,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spasi.lg,
                    vertical: Spasi.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(ikon, size: UkuranIkon.sedang, color: s.primary),
                      const SizedBox(width: Spasi.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(judul, style: t.titleSmall),
                            const SizedBox(height: Spasi.xs / 2),
                            Text(
                              nilai,
                              style: t.bodyMedium?.copyWith(
                                color: s.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (salin != null)
          IconButton(
            tooltip: salin!.tooltip,
            icon: const Icon(Icons.copy_outlined, size: UkuranIkon.sedang),
            onPressed: () =>
                salinDenganKonfirmasi(context, salin!.teks, salin!.konfirmasi),
          )
        else
          const SizedBox(width: Spasi.lg),
      ],
    );
  }
}
