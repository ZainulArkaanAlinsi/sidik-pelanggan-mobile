import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_pelanggan.dart';
import 'perangkat_provider.dart';

/// Izin notifikasi HP ini. Dibaca ulang tiap aplikasi kembali ke depan
/// (pengguna bisa menyalakannya dari setelan HP).
final izinNotifikasiProvider = FutureProvider<IzinNotifikasi>(
  (ref) => PushPelanggan.statusIzin(),
);

/// Sudah pernah menawarkan notifikasi (dialog penjelasan) di HP ini?
final izinSudahDitawarkanProvider = FutureProvider<bool>((ref) async {
  try {
    return await ref.read(penyimpanPerangkatProvider).izinNotifDitawarkan();
  } catch (_) {
    return false;
  }
});

/// Banner beranda "Notifikasi mati…" (REQ-NTF-08): tampil kalau izin
/// DITOLAK, atau kalau pengguna menjawab "Nanti saja" di tawaran kontekstual
/// (sistem belum pernah bertanya, tapi jawabannya sudah jelas). Tidak tampil
/// kalau push memang tidak tersedia di build ini — tidak ada yang bisa
/// dinyalakan.
final bannerIzinProvider = Provider<bool>((ref) {
  final izin = ref.watch(izinNotifikasiProvider).value;
  final ditawarkan = ref.watch(izinSudahDitawarkanProvider).value ?? false;
  return izin == IzinNotifikasi.ditolak ||
      (izin == IzinNotifikasi.belumDitanya && ditawarkan);
});

/// Tawarkan notifikasi pada momen yang bermakna (REQ-NTF-08: saat alat
/// pertama tampil di Beranda), DENGAN penjelasan manfaatnya, sekali
/// per HP. Tidak melakukan apa-apa kalau izin sudah ada, push tidak
/// tersedia, atau tawaran sudah pernah muncul.
Future<void> tawarkanNotifikasi(BuildContext context, WidgetRef ref) async {
  final izin = await PushPelanggan.statusIzin();
  if (izin != IzinNotifikasi.belumDitanya) return;
  final penyimpan = ref.read(penyimpanPerangkatProvider);
  try {
    if (await penyimpan.izinNotifDitawarkan()) return;
  } catch (_) {}
  if (!context.mounted) return;

  final mau = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      icon: const Icon(Icons.notifications_active_outlined),
      title: const Text('Nyalakan notifikasi?'),
      content: const Text(
        'Kami kabari saat sertifikat terbit dan saat jadwal kalibrasi ulang '
        'alat Anda mendekat.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(d, false),
          child: const Text('Nanti saja'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(d, true),
          child: const Text('Nyalakan'),
        ),
      ],
    ),
  );
  try {
    await penyimpan.tandaiIzinNotifDitawarkan();
  } catch (_) {}
  if (mau == true) await PushPelanggan.mintaIzin();
  ref.invalidate(izinSudahDitawarkanProvider);
  ref.invalidate(izinNotifikasiProvider);
}

/// Tombol [Nyalakan] di banner: minta izin sistem; kalau sistem tidak lagi
/// menampilkan dialog (sudah ditolak permanen), buka setelan notifikasi HP.
Future<void> nyalakanNotifikasi(WidgetRef ref) async {
  final hasil = await PushPelanggan.mintaIzin();
  if (hasil != IzinNotifikasi.diizinkan) await PushPelanggan.bukaSetelan();
  ref.invalidate(izinNotifikasiProvider);
}

/// Push yang diketuk dan belum dibuka layarnya. Rangka yang membukanya
/// begitu pengguna sudah masuk (push bisa diketuk sebelum sesi pulih).
final tautanTertundaProvider = NotifierProvider<TautanTertunda, TautanPush?>(
  TautanTertunda.new,
);

class TautanTertunda extends Notifier<TautanPush?> {
  StreamSubscription<TautanPush>? _langganan;

  @override
  TautanPush? build() {
    _langganan = PushPelanggan.ketukan.listen((t) => state = t);
    ref.onDispose(() => _langganan?.cancel());
    return PushPelanggan.ambilKetukanAwal();
  }

  void atur(TautanPush? t) => state = t;

  /// Ambil lalu kosongkan — satu ketukan dibuka sekali.
  TautanPush? ambil() {
    final t = state;
    if (t != null) state = null;
    return t;
  }
}
