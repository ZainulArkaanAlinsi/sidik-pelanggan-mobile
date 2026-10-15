import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../services/push_pelanggan.dart';
import 'data_provider.dart';
import 'push_provider.dart';
import 'sesi_provider.dart';

/// Data yang sama di HP mana pun akun ini masuk.
///
/// Semua data tinggal di server; aplikasi cuma menampilkan. Yang perlu
/// dipastikan tinggal KAPAN layar menarik ulang. Pelanggan yang membuka
/// sertifikat di HP kantor lalu di HP pribadi harus melihat keadaan terbaru tanpa menarik layar sendiri.
///
/// Kenapa ini perlu ditulis: `Rangka` memakai `IndexedStack`, jadi semua tab
/// tetap hidup dan provider `autoDispose`-nya tidak pernah dibuang. Tanpa
/// pemicu di bawah, angka yang dimuat pagi hari masih tampil sore harinya.
///
/// Dua pemicu, dua-duanya murah:
/// - aplikasi kembali ke layar depan (dari latar belakang / HP dibuka lagi) —
///   termasuk status aplikasi (versi minimum / pemeliharaan) dan izin
///   notifikasi, yang bisa berubah selagi aplikasi di belakang;
/// - push masuk selagi aplikasi terbuka.
///
/// Tidak ada tarikan berkala: data pelanggan berubah dalam hitungan hari
/// (sertifikat terbit, alat diserahkan), dan tiga tab × tiap HP × tiap
/// beberapa menit membebani server yang sama dengan yang dipakai teknisi di
/// lapangan.
final sinkronProvider = Provider<void>((ref) {
  final daur = AppLifecycleListener(
    onResume: () {
      ref.invalidate(statusAplikasiProvider);
      ref.invalidate(izinNotifikasiProvider);
      segarkanSemua(ref.invalidate);
    },
  );
  final push = PushPelanggan.pesanDiLayarDepan.listen(
    (_) => segarkanSemua(ref.invalidate),
  );
  ref.onDispose(() {
    daur.dispose();
    push.cancel();
  });
});

/// Semua provider data layar. `invalidate` itu lazy — yang benar-benar
/// ditarik cuma provider yang sedang didengarkan, dan data lama tetap tampil
/// sampai yang baru datang (tidak ada kedip kerangka muat).
final List<ProviderOrFamily> providerDataLayar = [
  berandaProvider,
  daftarAlatProvider,
  detailAlatProvider,
  daftarSertifikatProvider,
  detailSertifikatProvider,
  notifikasiProvider,
  jumlahBelumDibacaProvider,
];

/// Tarik ulang semua data layar. Terima `ref.invalidate` dari `Ref` maupun
/// `WidgetRef` (tombol "Coba lagi" di banner offline).
void segarkanSemua(
  void Function(ProviderOrFamily provider, {bool asReload}) invalidate,
) {
  for (final p in providerDataLayar) {
    invalidate(p);
  }
}
