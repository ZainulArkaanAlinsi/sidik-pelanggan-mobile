import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_pelanggan.dart';
import '../models/anggota.dart';
import '../models/arsip.dart';
import '../models/data_pelanggan.dart';
import '../models/paket.dart';
import '../models/status_berlaku.dart';
import '../services/layanan_pelanggan.dart';
import 'paginasi.dart';
import 'sesi_provider.dart';

export 'paginasi.dart' show DataBerhalaman, PaginasiController;

/// Semua data diikat ke PERUSAHAAN AKTIF: begitu pengguna berganti perusahaan
/// (akun anggota dua PT), seluruh provider di bawah ini dibangun ulang dan
/// tidak ada angka PT lama yang tertinggal di layar.
int? _perusahaan(Ref ref) => ref.watch(sesiProvider).value?.perusahaanId;

/// Galat 4xx dari server (tidak ditemukan, parameter salah, terlalu banyak
/// permintaan) tidak berubah dengan diulang, jadi TIDAK dicoba ulang
/// otomatis. Bawaan Riverpod 3 mengulang sampai 10× dengan jeda: layar
/// berkedip antara "Tidak ditemukan" dan kerangka puluhan detik dan server
/// dipukul berulang. Galat jaringan dan 5xx tetap memakai bawaan. Dipakai
/// provider sertifikat (daftar/cari dan arsip).
Duration? _ulangiBilaMungkin(int percobaan, Object galat) =>
    galat is GalatApi && galat.status >= 400 && galat.status < 500
    ? null
    : ProviderContainer.defaultRetry(percobaan, galat);

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

/// Jam HP — hanya CADANGAN "hari ini" untuk status masa berlaku sertifikat,
/// dipakai bila payload alat tidak membawa acuan server (`Alat.hariIniServer`).
/// Dinamai `jamHp...` karena `pembaruan_provider.dart` sudah punya
/// `jamProvider` untuk keperluan lain. Dipisah dari `DateTime.now` supaya
/// bisa diuji dengan tanggal yang tetap.
final jamHpProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Alat yang lewat jadwal atau jatuh tempo dalam 90 hari, dikelompokkan untuk
/// Beranda dan daftar alat. Diikat ke perusahaan aktif seperti provider data
/// lain, jadi berganti perusahaan = dihitung ulang dari nol.
final jatuhTempoProvider = FutureProvider.autoDispose<RingkasanJatuhTempo>((
  ref,
) async {
  _perusahaan(ref);
  final alat = await ref.watch(layananProvider).alatMenujuJatuhTempo();
  return RingkasanJatuhTempo.dari(alat);
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
      retry: _ulangiBilaMungkin,
    );

final detailSertifikatProvider = FutureProvider.autoDispose
    .family<Sertifikat, int>((ref, id) {
      _perusahaan(ref);
      return ref.watch(layananProvider).sertifikat(id);
    });

/// Satu tampilan arsip sertifikat (tahun, bulan, pekan, atau hari) menurut
/// [ParameterArsip]. Kelompok dan sertifikat datang sebagai baris-baris satu
/// daftar berhalaman; halaman berikut hanya ada di tingkat hari. Diikat ke
/// perusahaan aktif seperti daftar lain.
final garisWaktuProvider = AsyncNotifierProvider.autoDispose
    .family<
      DaftarController<BarisArsip>,
      DataBerhalaman<BarisArsip>,
      ParameterArsip
    >(
      (p) => DaftarController(
        (l, h) async =>
            (await l.garisWaktuSertifikat(p, halaman: h)).sebagaiHalaman,
        (b) => b.kunci,
      ),
      retry: _ulangiBilaMungkin,
    );

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

/// Anggota perusahaan aktif. Dibangun ulang saat perusahaan berganti.
final anggotaProvider = FutureProvider.autoDispose<DaftarAnggota>((ref) {
  _perusahaan(ref);
  return ref.watch(layananProvider).anggota();
});

/// Kunci daftar paket: nomor order yang dicari + riwayat (selesai) atau yang
/// masih berjalan.
typedef KunciPaket = ({String cari, bool selesai});

final daftarPaketProvider = AsyncNotifierProvider.autoDispose
    .family<DaftarController<Paket>, DataBerhalaman<Paket>, KunciPaket>(
      (k) => DaftarController(
        (l, h) => l.daftarPaket(cari: k.cari, selesai: k.selesai, halaman: h),
        (p) => p.id,
      ),
    );

final detailPaketProvider = FutureProvider.autoDispose.family<DetailPaket, int>(
  (ref, id) {
    _perusahaan(ref);
    return ref.watch(layananProvider).paket(id);
  },
);
