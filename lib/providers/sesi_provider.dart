import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/api_pelanggan.dart';
import '../core/penyimpan_sesi.dart';
import '../models/akun.dart';
import '../services/layanan_pelanggan.dart';
import '../services/push_pelanggan.dart';

final penyimpanSesiProvider = Provider<PenyimpanSesi>((ref) => PenyimpanSesi());

/// Satu `ApiPelanggan` untuk seluruh aplikasi. Token & perusahaan aktif
/// dipasang ke objek ini oleh [SesiController] — layar tidak pernah
/// menyentuh header sendiri.
final apiProvider = Provider<ApiPelanggan>((ref) => ApiPelanggan());

final layananProvider = Provider<LayananPelanggan>(
  (ref) => LayananPelanggan(ref.watch(apiProvider)),
);

final versiAplikasiProvider = FutureProvider<String>((ref) async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    return '0.0.0';
  }
});

/// `GET /app/status` — pemeliharaan & versi minimum. Dibaca SEBELUM masuk.
final statusAplikasiProvider = FutureProvider<StatusAplikasi>(
  (ref) => ref.watch(layananProvider).statusAplikasi(),
);

/// Keadaan sesi: `null` = belum masuk.
class Sesi {
  const Sesi({required this.akun, this.perusahaanId});

  final Akun akun;

  /// Perusahaan aktif. `null` hanya boleh terjadi kalau akunnya anggota LEBIH
  /// dari satu perusahaan dan belum memilih — gerbang menampilkan layar pilih.
  final int? perusahaanId;

  Keanggotaan? get keanggotaanAktif {
    for (final k in akun.keanggotaan) {
      if (k.customerId == perusahaanId) return k;
    }
    return null;
  }

  bool get perluPilihPerusahaan =>
      akun.lebihDariSatuPerusahaan && keanggotaanAktif == null;
}

final sesiProvider = AsyncNotifierProvider<SesiController, Sesi?>(
  SesiController.new,
);

class SesiController extends AsyncNotifier<Sesi?> {
  PenyimpanSesi get _penyimpan => ref.read(penyimpanSesiProvider);
  ApiPelanggan get _api => ref.read(apiProvider);
  LayananPelanggan get _layanan => ref.read(layananProvider);

  @override
  Future<Sesi?> build() async {
    // 401 dari rute mana pun = token dicabut (ganti sandi di HP lain, keluar
    // semua perangkat, akun dinonaktifkan PIC). Sesi lokal ikut dibuang.
    _api.saatTokenDitolak = () {
      if (state.value != null) _bersihkanLokal();
    };

    final token = await _penyimpan.token();
    if (token == null) return null;

    _api.token = token;
    _api.perusahaanId = await _penyimpan.perusahaanId();

    try {
      final akun = await _layanan.saya();
      final sesi = _sesiUntuk(akun, _api.perusahaanId);
      _pasangPerusahaan(sesi.perusahaanId);
      _daftarkanPush();
      return sesi;
    } on GalatApi catch (e) {
      if (e.tokenTidakBerlaku) {
        await _penyimpan.hapus();
        _api.token = null;
        _api.perusahaanId = null;
        return null;
      }
      rethrow;
    }
  }

  /// Satu perusahaan → langsung aktif. Lebih dari satu → pakai pilihan
  /// tersimpan kalau masih berlaku, selain itu biarkan kosong (layar pilih).
  Sesi _sesiUntuk(Akun akun, int? tersimpan) {
    if (akun.keanggotaan.length == 1) {
      return Sesi(akun: akun, perusahaanId: akun.keanggotaan.first.customerId);
    }
    final masihAnggota = akun.keanggotaan.any((k) => k.customerId == tersimpan);
    return Sesi(akun: akun, perusahaanId: masihAnggota ? tersimpan : null);
  }

  void _pasangPerusahaan(int? id) {
    _api.perusahaanId = id;
    _penyimpan.simpanPerusahaan(id);
  }

  Future<void> _daftarkanPush() async {
    final versi = await ref.read(versiAplikasiProvider.future);
    await PushPelanggan.daftarkan(_layanan, versiApp: versi);
  }

  Future<void> _mulai(SesiBaru baru) async {
    await _penyimpan.simpanToken(baru.token);
    _api.token = baru.token;
    final sesi = _sesiUntuk(baru.akun, null);
    _pasangPerusahaan(sesi.perusahaanId);
    state = AsyncData(sesi);
    _daftarkanPush();
  }

  Future<void> masuk(String email, String sandi) async =>
      _mulai(await _layanan.masuk(email, sandi));

  Future<void> terimaUndangan({
    required String email,
    required String kode,
    required String nama,
    required String telepon,
    String? jabatan,
    required String sandi,
    required bool setujuSyarat,
  }) async => _mulai(
    await _layanan.terimaUndangan(
      email: email,
      kode: kode,
      nama: nama,
      telepon: telepon,
      jabatan: jabatan,
      sandi: sandi,
      setujuSyarat: setujuSyarat,
    ),
  );

  void pilihPerusahaan(int customerId) {
    final s = state.value;
    if (s == null) return;
    _pasangPerusahaan(customerId);
    state = AsyncData(Sesi(akun: s.akun, perusahaanId: customerId));
  }

  /// Muat ulang akun — mis. setelah admin lab memverifikasi akun ini.
  Future<void> segarkan() async {
    final s = state.value;
    if (s == null) return;
    final akun = await _layanan.saya();
    state = AsyncData(_sesiUntuk(akun, s.perusahaanId));
  }

  Future<void> perbaruiProfil({
    required String nama,
    required String telepon,
    String? jabatan,
  }) async {
    final s = state.value;
    if (s == null) return;
    final akun = await _layanan.perbaruiProfil(
      nama: nama,
      telepon: telepon,
      jabatan: jabatan,
    );
    state = AsyncData(_sesiUntuk(akun, s.perusahaanId));
  }

  /// Hapus akun. Push dicabut DULU (token sesi masih berlaku), lalu akun
  /// dihapus; sesudahnya server sudah mencabut semua token, jadi sesi lokal
  /// cukup dibuang tanpa memanggil `/auth/keluar`.
  Future<({List<String> dihapus, List<String> tetap})> hapusAkun(
    String sandi,
  ) async {
    await PushPelanggan.cabut(_layanan);
    final hasil = await _layanan.hapusAkun(sandi);
    await _bersihkanLokal();
    return hasil;
  }

  Future<void> keluar() async {
    // Urutan penting: cabut push SELAGI token masih berlaku, baru keluar.
    await PushPelanggan.cabut(_layanan);
    try {
      await _layanan.keluar();
    } catch (_) {
      // Server tidak terjangkau: sesi lokal tetap dibuang. Token di server
      // kedaluwarsa sendiri; menahan orang di aplikasi karena sinyal jelek
      // lebih buruk.
    }
    await _bersihkanLokal();
  }

  Future<void> _bersihkanLokal() async {
    await _penyimpan.hapus();
    _api.token = null;
    _api.perusahaanId = null;
    state = const AsyncData(null);
  }
}
