import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/data_pelanggan.dart';
import '../services/layanan_pelanggan.dart';
import 'paginasi.dart';
import 'sesi_provider.dart';

export 'paginasi.dart' show DataBerhalaman, PaginasiController;

/// Semua data diikat ke PERUSAHAAN AKTIF: begitu pengguna berganti perusahaan
/// (akun anggota dua PT), seluruh provider di bawah ini dibangun ulang dan
/// tidak ada angka PT lama yang tertinggal di layar.
int? _perusahaan(Ref ref) => ref.watch(sesiProvider).value?.perusahaanId;

/// Daftar berhalaman yang diambil lewat [LayananPelanggan]. Satu kelas untuk
/// semua daftar; yang berbeda cuma cara mengambil satu halaman.
class DaftarController<T> extends PaginasiController<T> {
  DaftarController(this._ambil, this._kunci, {this.perPengguna = false});

  final Future<Halaman<T>> Function(LayananPelanggan layanan, int halaman)
  _ambil;
  final Object Function(T butir) _kunci;

  /// Notifikasi milik PENGGUNA, bukan perusahaan — dibangun ulang saat sesi
  /// berganti, tidak saat perusahaan aktif berganti.
  final bool perPengguna;

  @override
  Future<DataBerhalaman<T>> build() {
    if (perPengguna) {
      ref.watch(sesiProvider);
    } else {
      _perusahaan(ref);
    }
    ref.watch(layananProvider);
    return super.build();
  }

  @override
  Future<Halaman<T>> ambil(int halaman) =>
      _ambil(ref.read(layananProvider), halaman);

  @override
  Object kunciButir(T butir) => _kunci(butir);
}

final berandaProvider = FutureProvider.autoDispose<Beranda>((ref) {
  _perusahaan(ref);
  return ref.watch(layananProvider).beranda();
});

/// Kunci daftar alat: kata cari + saringan (`segera`, `lewat`, atau null).
typedef KunciAlat = ({String cari, String? saring});

final daftarAlatProvider = AsyncNotifierProvider.autoDispose
    .family<DaftarController<Alat>, DataBerhalaman<Alat>, KunciAlat>(
      (k) => DaftarController(
        (l, h) => l.daftarAlat(cari: k.cari, saring: k.saring, halaman: h),
        (a) => a.id,
      ),
    );

final detailAlatProvider = FutureProvider.autoDispose.family<Alat, int>((
  ref,
  id,
) {
  _perusahaan(ref);
  return ref.watch(layananProvider).alat(id);
});

typedef KunciSertifikat = ({String cari, bool termasukDigantikan});

final daftarSertifikatProvider = AsyncNotifierProvider.autoDispose
    .family<
      DaftarController<Sertifikat>,
      DataBerhalaman<Sertifikat>,
      KunciSertifikat
    >(
      (k) => DaftarController(
        (l, h) => l.daftarSertifikat(
          cari: k.cari,
          termasukDigantikan: k.termasukDigantikan,
          halaman: h,
        ),
        (s) => s.id,
      ),
    );

final detailSertifikatProvider = FutureProvider.autoDispose
    .family<Sertifikat, int>((ref, id) {
      _perusahaan(ref);
      return ref.watch(layananProvider).sertifikat(id);
    });

final notifikasiProvider =
    AsyncNotifierProvider.autoDispose<
      DaftarController<Notifikasi>,
      DataBerhalaman<Notifikasi>
    >(
      () => DaftarController(
        (l, h) => l.daftarNotifikasi(halaman: h),
        (n) => n.id,
        perPengguna: true,
      ),
    );

final jumlahBelumDibacaProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(sesiProvider);
  return ref.watch(layananProvider).jumlahNotifikasiBelumDibaca();
});
