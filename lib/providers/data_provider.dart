import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/anggota.dart';
import '../models/data_pelanggan.dart';
import 'sesi_provider.dart';

/// Semua data diikat ke PERUSAHAAN AKTIF: begitu pengguna berganti perusahaan
/// (akun anggota dua PT), seluruh provider di bawah ini dibangun ulang dan
/// tidak ada angka PT lama yang tertinggal di layar.
int? _perusahaan(Ref ref) => ref.watch(sesiProvider).value?.perusahaanId;

final berandaProvider = FutureProvider.autoDispose<Beranda>((ref) {
  _perusahaan(ref);
  return ref.watch(layananProvider).beranda();
});

/// Kunci daftar alat: kata cari + saringan (`segera`, `lewat`, atau null).
typedef KunciAlat = ({String cari, String? saring});

final daftarAlatProvider = FutureProvider.autoDispose
    .family<Halaman<Alat>, KunciAlat>((ref, k) {
      _perusahaan(ref);
      return ref
          .watch(layananProvider)
          .daftarAlat(cari: k.cari, saring: k.saring);
    });

final detailAlatProvider = FutureProvider.autoDispose.family<Alat, int>((
  ref,
  id,
) {
  _perusahaan(ref);
  return ref.watch(layananProvider).alat(id);
});

typedef KunciSertifikat = ({String cari, bool termasukDigantikan});

final daftarSertifikatProvider = FutureProvider.autoDispose
    .family<Halaman<Sertifikat>, KunciSertifikat>((ref, k) {
      _perusahaan(ref);
      return ref
          .watch(layananProvider)
          .daftarSertifikat(
            cari: k.cari,
            termasukDigantikan: k.termasukDigantikan,
          );
    });

final detailSertifikatProvider = FutureProvider.autoDispose
    .family<Sertifikat, int>((ref, id) {
      _perusahaan(ref);
      return ref.watch(layananProvider).sertifikat(id);
    });

/// `true` = paket yang sudah selesai; `false` = yang masih berjalan.
final daftarPaketProvider = FutureProvider.autoDispose
    .family<Halaman<Paket>, bool>((ref, selesai) {
      _perusahaan(ref);
      return ref.watch(layananProvider).daftarPaket(selesai: selesai);
    });

final detailPaketProvider = FutureProvider.autoDispose.family<Paket, int>((
  ref,
  id,
) {
  _perusahaan(ref);
  return ref.watch(layananProvider).paket(id);
});

final notifikasiProvider = FutureProvider.autoDispose<Halaman<Notifikasi>>((
  ref,
) {
  ref.watch(sesiProvider);
  return ref.watch(layananProvider).daftarNotifikasi();
});

final jumlahBelumDibacaProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(sesiProvider);
  return ref.watch(layananProvider).jumlahNotifikasiBelumDibaca();
});

final anggotaProvider = FutureProvider.autoDispose<DaftarAnggota>((ref) {
  _perusahaan(ref);
  return ref.watch(layananProvider).anggota();
});
