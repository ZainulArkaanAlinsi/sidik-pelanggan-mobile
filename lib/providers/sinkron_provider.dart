import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/push_pelanggan.dart';
import 'data_provider.dart';

/// Data yang sama di HP mana pun akun ini masuk.
///
/// Semua data tinggal di server; aplikasi cuma menampilkan. Yang perlu
/// dipastikan tinggal KAPAN layar menarik ulang. Pelanggan yang membuka
/// sertifikat di HP kantor lalu di HP pribadi, atau PIC yang mengundang
/// anggota dari satu HP sementara rekannya membuka daftar yang sama di HP lain,
/// harus melihat keadaan terbaru tanpa menarik layar sendiri.
///
/// Kenapa ini perlu ditulis: `Rangka` memakai `IndexedStack`, jadi kelima tab
/// tetap hidup dan provider `autoDispose`-nya tidak pernah dibuang. Tanpa
/// pemicu di bawah, angka yang dimuat pagi hari masih tampil sore harinya.
///
/// Dua pemicu, dua-duanya murah:
/// - aplikasi kembali ke layar depan (dari latar belakang / HP dibuka lagi);
/// - push masuk selagi aplikasi terbuka.
///
/// Tidak ada tarikan berkala: data pelanggan berubah dalam hitungan hari
/// (sertifikat terbit, alat diserahkan), dan lima tab × tiap HP × tiap beberapa
/// menit membebani server yang sama dengan yang dipakai teknisi di lapangan.
final sinkronProvider = Provider<void>((ref) {
  final daur = AppLifecycleListener(onResume: () => segarkanSemua(ref));
  final push = PushPelanggan.pesanDiLayarDepan.listen(
    (_) => segarkanSemua(ref),
  );
  ref.onDispose(() {
    daur.dispose();
    push.cancel();
  });
});

/// Tarik ulang semua data layar. `invalidate` itu lazy — yang benar-benar
/// ditarik cuma provider yang sedang didengarkan, dan data lama tetap tampil
/// sampai yang baru datang (tidak ada kedip kerangka muat).
void segarkanSemua(Ref ref) {
  ref.invalidate(berandaProvider);
  ref.invalidate(daftarAlatProvider);
  ref.invalidate(detailAlatProvider);
  ref.invalidate(daftarSertifikatProvider);
  ref.invalidate(detailSertifikatProvider);
  ref.invalidate(daftarPaketProvider);
  ref.invalidate(detailPaketProvider);
  ref.invalidate(notifikasiProvider);
  ref.invalidate(jumlahBelumDibacaProvider);
  ref.invalidate(anggotaProvider);
  ref.invalidate(daftarPermintaanProvider);
  ref.invalidate(detailPermintaanProvider);
  ref.invalidate(pesanPermintaanProvider);
  ref.invalidate(preferensiProvider);
  ref.invalidate(daftarKoreksiProvider);
  ref.invalidate(detailKoreksiProvider);
}
