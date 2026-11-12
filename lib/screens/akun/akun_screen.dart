import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_pelanggan.dart';
import '../../core/konfigurasi.dart';
import '../../core/tema/spasi.dart';
import '../../core/tema/ukuran.dart';
import '../../core/tema/warna_sidik.dart';
import '../../providers/sesi_provider.dart';
import '../../widgets/bagian_sidik.dart';
import '../../widgets/baris_menu.dart';
import '../../widgets/halaman_sidik.dart';
import '../../widgets/kartu_sidik.dart';
import '../../widgets/tombol_sidik.dart';
import '../gerbang.dart';
import '../paket/paket_screen.dart';
import 'anggota_screen.dart';
import 'bantuan_screen.dart';
import 'ganti_sandi_screen.dart';
import 'preferensi_notifikasi_screen.dart';

/// Teks kaki Akun (S17): versi + build + ID pengguna, untuk dukungan.
String teksVersi({
  required String versi,
  required String build,
  required int idPengguna,
  String lingkungan = Konfigurasi.lingkungan,
}) => [
  'SIDIK Pelanggan $versi (build $build)',
  'ID pengguna $idPengguna',
  if (lingkungan != 'prod') lingkungan.toUpperCase(),
].join(' · ');

/// Akun (S17): siapa saya, perusahaan aktif (ganti kalau anggota lebih dari
/// satu), bantuan dan privasi, keluar (HP ini / semua perangkat), dan versi.
class AkunScreen extends ConsumerWidget {
  const AkunScreen({super.key});

  Future<bool> _konfirmasi(
    BuildContext context, {
    required String judul,
    required String isi,
    required String aksi,
  }) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: Text(aksi),
          ),
        ],
      ),
    );
    return yakin == true;
  }

  Future<void> _keluarSemua(BuildContext context, WidgetRef ref) async {
    final yakin = await _konfirmasi(
      context,
      judul: 'Keluar dari semua perangkat?',
      isi:
          'Sesi akun Anda di SEMUA HP — termasuk HP ini — langsung berakhir, '
          'dan HP-HP itu berhenti menerima notifikasi. Anda perlu masuk lagi.',
      aksi: 'Keluar dari semua',
    );
    if (!yakin || !context.mounted) return;
    final pesan = ScaffoldMessenger.of(context);
    try {
      final n = await ref.read(sesiProvider.notifier).keluarSemua();
      pesan.showSnackBar(
        SnackBar(content: Text('Anda keluar dari $n sesi perangkat.')),
      );
    } on GalatApi catch (e) {
      // Sesi lokal TIDAK dibuang: token di HP lain belum tentu tercabut.
      pesan.showSnackBar(SnackBar(content: Text(e.pesan)));
    }
  }

  Future<void> _keluar(BuildContext context, WidgetRef ref) async {
    final yakin = await _konfirmasi(
      context,
      judul: 'Keluar dari aplikasi?',
      isi:
          'HP ini berhenti menerima notifikasi akun Anda sampai Anda masuk lagi.',
      aksi: 'Keluar',
    );
    if (yakin) await ref.read(sesiProvider.notifier).keluar();
  }

  void _buka(BuildContext context, Widget tujuan) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => tujuan));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesi = ref.watch(sesiProvider).value;
    final paket = ref.watch(infoPaketProvider).value;
    final t = context.teks;
    if (sesi == null) return const SizedBox.shrink();
    final aktif = sesi.keanggotaanAktif;

    return HalamanSidik(
      judul: 'Akun',
      isi: ListView(
        padding: Spasi.daftar(context),
        children: [
          KartuSidik(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(nama: sesi.akun.nama),
                    const SizedBox(width: Spasi.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sesi.akun.nama, style: t.titleMedium),
                          Text(sesi.akun.email, style: t.bodySmall),
                          if (sesi.akun.jabatan != null)
                            Text(sesi.akun.jabatan!, style: t.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: Spasi.md),
                  child: Divider(),
                ),
                Text('Perusahaan aktif', style: t.bodySmall),
                const SizedBox(height: Spasi.xs),
                Text(aktif?.namaPerusahaan ?? '—', style: t.titleSmall),
                if ((aktif?.labelPeran ?? '').isNotEmpty)
                  Text(aktif!.labelPeran, style: t.bodySmall),
              ],
            ),
          ),
          if (sesi.akun.lebihDariSatuPerusahaan) ...[
            const SizedBox(height: Spasi.md),
            KelompokBaris(
              baris: [
                BarisMenu(
                  ikon: Icons.swap_horiz,
                  judul: 'Ganti perusahaan',
                  onTap: () => _buka(
                    context,
                    const PilihPerusahaanScreen(bisaKembali: true),
                  ),
                ),
              ],
            ),
          ],
          const BagianSidik('Perusahaan'),
          KelompokBaris(
            baris: [
              BarisMenu(
                ikon: Icons.inventory_2_outlined,
                judul: 'Pelacakan paket',
                onTap: () => _buka(context, const PaketScreen()),
              ),
              BarisMenu(
                ikon: Icons.groups_outlined,
                judul: 'Anggota perusahaan',
                onTap: () => _buka(context, const AnggotaScreen()),
              ),
            ],
          ),
          const BagianSidik('Akun'),
          KelompokBaris(
            baris: [
              BarisMenu(
                ikon: Icons.notifications_active_outlined,
                judul: 'Pengaturan notifikasi',
                onTap: () => _buka(context, const PreferensiNotifikasiScreen()),
              ),
              BarisMenu(
                ikon: Icons.lock_reset_outlined,
                judul: 'Ganti sandi',
                onTap: () => _buka(context, const GantiSandiScreen()),
              ),
            ],
          ),
          const BagianSidik('Bantuan'),
          KelompokBaris(
            baris: [
              BarisMenu(
                ikon: Icons.support_agent,
                judul: 'Bantuan & kontak',
                onTap: () => _buka(context, const BantuanScreen()),
              ),
              BarisMenu(
                ikon: Icons.privacy_tip_outlined,
                judul: 'Privasi & ketentuan',
                onTap: () => _buka(context, const PrivasiScreen()),
              ),
            ],
          ),
          const SizedBox(height: Spasi.xl),
          TombolSidik(
            label: 'Keluar',
            ikon: Icons.logout,
            penuh: true,
            onPressed: () => _keluar(context, ref),
          ),
          const SizedBox(height: Spasi.xs),
          TombolSidik(
            label: 'Keluar dari semua perangkat',
            ragam: RagamTombol.teks,
            penuh: true,
            onPressed: () => _keluarSemua(context, ref),
          ),
          const SizedBox(height: Spasi.lg),
          SelectableText(
            teksVersi(
              versi: paket?.versi ?? '-',
              build: paket?.build ?? '-',
              idPengguna: sesi.akun.id,
            ),
            textAlign: TextAlign.center,
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Lingkaran berinisial nama (dua kata pertama).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.nama});

  final String nama;

  String get _inisial {
    final kata = nama.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty);
    final huruf = kata
        .take(2)
        .map((k) => String.fromCharCode(k.runes.first).toUpperCase());
    final hasil = huruf.join();
    return hasil.isEmpty ? '?' : hasil;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.skema;
    return ExcludeSemantics(
      child: Container(
        width: AreaSentuh.minimum + Spasi.sm,
        height: AreaSentuh.minimum + Spasi.sm,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: s.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Text(
          _inisial,
          style: context.teks.titleMedium?.copyWith(
            color: s.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
