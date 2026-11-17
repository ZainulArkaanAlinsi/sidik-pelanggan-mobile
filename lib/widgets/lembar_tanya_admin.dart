import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/pesan_admin.dart';
import '../core/tautan_luar.dart';
import '../core/tema/bentuk.dart';
import '../core/tema/elevasi.dart';
import '../core/tema/spasi.dart';
import '../core/tema/ukuran.dart';
import '../core/tema/warna_sidik.dart';
import '../models/akun.dart';
import '../providers/sesi_provider.dart';
import '../providers/tautan_provider.dart';
import 'tombol_sidik.dart';

/// Tombol "Tanya admin tentang ini" di layar detail. Membuka [LembarTanyaAdmin]:
/// pratinjau pesan terisi dari data layar, lalu WhatsApp (atau email bila tidak
/// ada WhatsApp) atau salin. Aplikasi tetap BACA-SAJA: yang terjadi hanya
/// membuka aplikasi lain dengan teks yang boleh disunting pengguna; tidak ada
/// panggilan tulis ke server.
///
/// Tombol hanya muncul bila `GET /app/info` sudah terbaca dan memberi jalan
/// yang bisa memuat pesan ([InfoAplikasi.bisaTanyaAdmin]: tautan `wa.me/<nomor>`
/// atau email yang wajar). Memuat, gagal, atau kedua kanal kosong = tidak ada
/// tombol (tidak ada tombol mati yang membingungkan). [pesan] dibangun saat
/// tombol ditekan, dari data layar yang paling baru.
class TombolTanyaAdmin extends ConsumerWidget {
  const TombolTanyaAdmin({
    super.key,
    required this.label,
    required this.pesan,
    this.ikon = Icons.support_agent,
    this.ragam = RagamTombol.sekunder,
  });

  final String label;
  final PesanAdmin Function() pesan;
  final IconData ikon;
  final RagamTombol ragam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(infoAplikasiProvider).value;
    if (info == null || !info.bisaTanyaAdmin) return const SizedBox.shrink();
    return TombolSidik(
      label: label,
      ikon: ikon,
      ragam: ragam,
      penuh: true,
      onPressed: () => tampilkanLembarTanyaAdmin(
        context,
        info: info,
        pesan: pesan(),
        judul: label,
      ),
    );
  }
}

/// Buka lembar bawah pratinjau pesan.
Future<void> tampilkanLembarTanyaAdmin(
  BuildContext context, {
  required InfoAplikasi info,
  required PesanAdmin pesan,
  required String judul,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => LembarTanyaAdmin(info: info, pesan: pesan, judul: judul),
);

/// Isi lembar bawah: pratinjau pesan (teks utuh seperti yang akan dibuka),
/// tombol WhatsApp (utama) dan/atau email, "Salin pesan", dan "Batal".
///
/// Tautan WhatsApp dibangun dari nomor `wa.me/<nomor>` dari server; email dari
/// alamat yang wajar; keduanya dengan isi pesan ter-encode per komponen
/// ([TautanLuar]). Kalau aplikasinya tidak ada di HP, lembar tetap terbuka dan
/// menyuruh menyalin pesan (tidak pernah diam).
class LembarTanyaAdmin extends ConsumerStatefulWidget {
  const LembarTanyaAdmin({
    super.key,
    required this.info,
    required this.pesan,
    required this.judul,
  });

  final InfoAplikasi info;
  final PesanAdmin pesan;
  final String judul;

  @override
  ConsumerState<LembarTanyaAdmin> createState() => _LembarTanyaAdminState();
}

class _LembarTanyaAdminState extends ConsumerState<LembarTanyaAdmin> {
  String? _galat;
  bool _tersalin = false;
  bool _membuka = false;

  Uri? get _uriWa =>
      TautanLuar.whatsappDenganPesan(widget.info.whatsappUrl, widget.pesan.isi);

  Uri? get _uriEmail => TautanLuar.email(
    widget.info.email,
    subjek: widget.pesan.subjek,
    isi: widget.pesan.isi,
  );

  Future<void> _buka(Uri uri, String galat) async {
    setState(() {
      _membuka = true;
      _galat = null;
      _tersalin = false;
    });
    final navigator = Navigator.of(context);
    final berhasil = await ref.read(pembukaTautanProvider)(uri);
    if (!mounted) return;
    if (berhasil) {
      navigator.pop();
    } else {
      setState(() {
        _membuka = false;
        _galat = galat;
      });
    }
  }

  /// Salin pesan; konfirmasinya di dalam lembar (snackbar halaman di bawah
  /// lembar tertutup lapisan gelap, jadi tidak terlihat).
  Future<void> _salin() async {
    await Clipboard.setData(ClipboardData(text: widget.pesan.isi));
    if (!mounted) return;
    setState(() {
      _tersalin = true;
      _galat = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.teks;
    final s = context.skema;
    final wa = _uriWa;
    final email = _uriEmail;
    final lewatWa = wa != null;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Spasi.sisi,
        Spasi.xs,
        Spasi.sisi,
        Spasi.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(widget.judul, style: t.titleLarge),
          ),
          const SizedBox(height: Spasi.sm),
          Text(
            lewatWa
                ? 'Pesan ini dibuka di WhatsApp. Anda bisa menyuntingnya di '
                      'sana sebelum mengirim; aplikasi ini tidak mengirim apa '
                      'pun sendiri.'
                : 'Pesan ini dibuka di aplikasi email Anda. Anda bisa '
                      'menyuntingnya di sana sebelum mengirim; aplikasi ini '
                      'tidak mengirim apa pun sendiri.',
            style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant),
          ),
          const SizedBox(height: Spasi.md),
          Semantics(
            container: true,
            label: 'Pratinjau pesan',
            child: Container(
              padding: const EdgeInsets.all(Spasi.md),
              decoration: BoxDecoration(
                color: s.surfaceContainerLow,
                borderRadius: Bentuk.sudutKartu,
                border: Border.all(
                  color: s.outlineVariant,
                  width: Elevasi.garis,
                ),
              ),
              child: SelectableText(widget.pesan.isi, style: t.bodyMedium),
            ),
          ),
          if (_galat != null || _tersalin) ...[
            const SizedBox(height: Spasi.md),
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _galat != null
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: UkuranIkon.kecil,
                    color: _galat != null ? s.error : s.onSurface,
                  ),
                  const SizedBox(width: Spasi.sm),
                  Expanded(
                    child: Text(
                      _galat ?? 'Pesan disalin.',
                      style: t.bodyMedium?.copyWith(
                        color: _galat != null ? s.error : s.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Spasi.lg),
          if (wa != null)
            TombolSidik(
              label: 'Buka WhatsApp',
              ikon: Icons.chat_outlined,
              ragam: RagamTombol.utama,
              penuh: true,
              sibuk: _membuka,
              onPressed: () => _buka(
                wa,
                'WhatsApp belum terpasang di HP ini. Salin pesan, lalu kirim '
                'lewat aplikasi lain.',
              ),
            ),
          if (email != null) ...[
            if (wa != null) const SizedBox(height: Spasi.sm),
            TombolSidik(
              label: 'Kirim lewat email',
              ikon: Icons.mail_outline,
              ragam: wa == null ? RagamTombol.utama : RagamTombol.sekunder,
              penuh: true,
              sibuk: _membuka,
              onPressed: () => _buka(
                email,
                'Tidak ada aplikasi email di HP ini. Salin pesan, lalu kirim '
                'lewat aplikasi lain.',
              ),
            ),
          ],
          const SizedBox(height: Spasi.sm),
          TombolSidik(
            label: 'Salin pesan',
            ikon: Icons.copy_outlined,
            penuh: true,
            onPressed: _salin,
          ),
          const SizedBox(height: Spasi.xs),
          TombolSidik(
            label: 'Batal',
            ragam: RagamTombol.teks,
            penuh: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
