import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/api_pelanggan.dart';
import '../core/penyimpan_cache.dart';
import '../core/penyimpan_sesi.dart';
import '../models/akun.dart';
import '../services/layanan_pelanggan.dart';
import '../services/push_pelanggan.dart';
import 'koneksi_provider.dart';

final penyimpanSesiProvider = Provider<PenyimpanSesi>((ref) => PenyimpanSesi());

/// Cache jawaban `GET` (NFR-06) — folder cache aplikasi.
final penyimpanCacheProvider = Provider<PenyimpanCache>(
  (ref) => PenyimpanCacheBerkas.cache(),
);

/// Satu `ApiPelanggan` untuk seluruh aplikasi. Token & perusahaan aktif
/// dipasang ke objek ini oleh [SesiController] — layar tidak pernah
/// menyentuh header sendiri.
final apiProvider = Provider<ApiPelanggan>((ref) {
  final koneksi = ref.read(koneksiProvider.notifier);
  return ApiPelanggan(
    cache: ref.watch(penyimpanCacheProvider),
    saatOffline: koneksi.offline,
    saatOnline: koneksi.online,
  );
});

final layananProvider = Provider<LayananPelanggan>(
  (ref) => LayananPelanggan(ref.watch(apiProvider)),
);

/// Versi & nomor build terpasang (`package_info_plus`).
typedef InfoPaket = ({String versi, String build});

final infoPaketProvider = FutureProvider<InfoPaket>((ref) async {
  try {
    final p = await PackageInfo.fromPlatform();
    return (versi: p.version, build: p.buildNumber);
  } catch (_) {
    return (versi: '0.0.0', build: '0');
  }
});

/// Versi untuk gerbang versi minimum (`1.2.0`, tanpa build).
final versiAplikasiProvider = FutureProvider<String>(
  (ref) async => (await ref.watch(infoPaketProvider.future)).versi,
);

/// Pasang `X-App-Versi` sekali, sebelum panggilan pertama.
Future<void> _pastikanVersi(Ref ref) async {
  final api = ref.read(apiProvider);
  if (api.versiApp != null) return;
  final p = await ref.read(infoPaketProvider.future);
  api.versiApp = p.build.isEmpty || p.build == '0'
      ? p.versi
      : '${p.versi}+${p.build}';
}

/// `GET /app/status` — pemeliharaan & versi minimum. Dibaca SEBELUM masuk.
final statusAplikasiProvider = FutureProvider<StatusAplikasi>((ref) async {
  await _pastikanVersi(ref);
  return ref.watch(layananProvider).statusAplikasi();
});

/// `GET /app/info` — kontak, dokumen, alamat lab. Publik; disimpan selama
/// aplikasi hidup dan dimuat ulang saat layar bantuan dibuka.
final infoAplikasiProvider = FutureProvider<InfoAplikasi>((ref) async {
  await _pastikanVersi(ref);
  return ref.watch(layananProvider).infoAplikasi();
});

/// `true` sesudah sesi berakhir karena server menolak token (401) — layar
/// Masuk menampilkan "Sesi Anda berakhir…" (04-UI-UX §6). Dihapus begitu
/// pengguna masuk lagi.
final sesiBerakhirProvider = NotifierProvider<SesiBerakhir, bool>(
  SesiBerakhir.new,
);

class SesiBerakhir extends Notifier<bool> {
  @override
  bool build() => false;

  void atur(bool v) {
    if (state != v) state = v;
  }
}

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
    // semua perangkat, akun dinonaktifkan PIC). Sesi lokal ikut dibuang;
    // cache & DRAF tetap (REQ-AUTH-08: "tanpa kehilangan draf lokal").
    _api.saatTokenDitolak = () {
      if (state.value != null) {
        ref.read(sesiBerakhirProvider.notifier).atur(true);
        _bersihkanLokal();
      }
    };

    await _pastikanVersi(ref);
    final token = await _penyimpan.token();
    if (token == null) return null;

    _api.token = token;
    _api.perusahaanId = await _penyimpan.perusahaanId();
    final pengguna = await _penyimpan.penggunaId();
    _api.lingkupCache = pengguna == null ? null : 'u$pengguna';

    try {
      // Tanpa sinyal, `/saya` terakhir datang dari cache — aplikasi tetap
      // terbuka dengan data terakhir alih-alih layar galat.
      final akun = await _layanan.saya();
      await _pasangPemilik(akun.id);
      final sesi = _sesiUntuk(akun, _api.perusahaanId);
      _pasangPerusahaan(sesi.perusahaanId);
      _daftarkanPush();
      return sesi;
    } on GalatApi catch (e) {
      if (e.tokenTidakBerlaku) {
        await _penyimpan.hapus();
        _api.token = null;
        _api.perusahaanId = null;
        _api.lingkupCache = null;
        return null;
      }
      rethrow;
    }
  }

  Future<void> _pasangPemilik(int id) async {
    _api.lingkupCache = 'u$id';
    try {
      await _penyimpan.simpanPengguna(id);
    } catch (_) {
      // Tanpa ID tersimpan, cache offline tidak terbaca di peluncuran
      // berikut — bukan alasan menggagalkan masuk.
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

  /// Token push didaftarkan TANPA meminta izin notifikasi: izin diminta
  /// kontekstual (saat alat pertama tampil di Beranda, REQ-NTF-08), bukan saat
  /// masuk. Token yang sudah terdaftar langsung terpakai begitu izin
  /// diberikan.
  Future<void> _daftarkanPush() async {
    final p = await ref.read(infoPaketProvider.future);
    await PushPelanggan.daftarkan(_layanan, versiApp: p.versi);
  }

  Future<void> _mulai(SesiBaru baru) async {
    await _penyimpan.simpanToken(baru.token);
    _api.token = baru.token;
    await _pasangPemilik(baru.akun.id);
    final sesi = _sesiUntuk(baru.akun, null);
    _pasangPerusahaan(sesi.perusahaanId);
    ref.read(sesiBerakhirProvider.notifier).atur(false);
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
    await _bersihkanLokal(hapusData: true);
  }

  /// Keluar dari SEMUA perangkat (F03). Berbeda dari [keluar]: kalau server
  /// tidak terjangkau, galatnya DILEMPAR dan sesi lokal TIDAK dibuang —
  /// pengguna yang menekan tombol ini mau token di HP lain dicabut, dan
  /// "sudah keluar" yang ternyata cuma di HP ini adalah kebohongan.
  Future<int> keluarSemua() async {
    await PushPelanggan.cabut(_layanan);
    final jumlah = await _layanan.keluarSemua();
    await _bersihkanLokal(hapusData: true);
    return jumlah;
  }

  /// [hapusData]: buang juga cache di HP ini (keluar sengaja). Sesi yang berakhir sendiri (401) TIDAK menghapusnya.
  Future<void> _bersihkanLokal({bool hapusData = false}) async {
    await _penyimpan.hapus();
    _api.token = null;
    _api.perusahaanId = null;
    _api.lingkupCache = null;
    if (hapusData) {
      await ref.read(penyimpanCacheProvider).hapusSemua();
    }
    state = const AsyncData(null);
  }
}
