import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../core/api_pelanggan.dart';
import '../models/akun.dart';
import '../models/anggota.dart';
import '../models/data_pelanggan.dart';
import '../models/permintaan.dart';

/// Hasil masuk / terima undangan: token + akunnya.
class SesiBaru {
  const SesiBaru(this.token, this.akun);

  final String token;
  final Akun akun;
}

/// Semua panggilan ke `/api/pelanggan/v1`, dalam satu kelas yang tipis.
///
/// Tidak ada logika bisnis di sini — status jatuh tempo, tahap paket, dan
/// kepemilikan dihitung SERVER. Aplikasi yang menghitung ulang sendiri pasti
/// suatu hari berbeda pendapat dengan layar lab.
class LayananPelanggan {
  LayananPelanggan(this.api);

  final ApiPelanggan api;

  // ── Tanpa token ──────────────────────────────────────────────────────

  Future<StatusAplikasi> statusAplikasi() async => StatusAplikasi.dariJson(
    (await api.get('/app/status'))['data'] as Map<String, dynamic>,
  );

  Future<SesiBaru> masuk(
    String email,
    String sandi, {
    String? namaPerangkat,
  }) async {
    final b = await api.post('/auth/masuk', {
      'email': email.trim(),
      'sandi': sandi,
      'nama_perangkat': ?namaPerangkat,
    });
    return _sesi(b);
  }

  Future<SesiBaru> terimaUndangan({
    required String email,
    required String kode,
    required String nama,
    required String telepon,
    String? jabatan,
    required String sandi,
    required bool setujuSyarat,
  }) async {
    final b = await api.post('/auth/terima-undangan', {
      'email': email.trim(),
      'kode': kode.trim(),
      'nama': nama.trim(),
      'telepon': telepon.trim(),
      if (jabatan != null && jabatan.trim().isNotEmpty)
        'jabatan': jabatan.trim(),
      'sandi': sandi,
      'setuju_syarat': setujuSyarat,
    });
    return _sesi(b);
  }

  Future<void> lupaSandi(String email) =>
      api.post('/auth/lupa-sandi', {'email': email.trim()});

  Future<void> aturUlangSandi({
    required String email,
    required String otp,
    required String sandi,
  }) => api.post('/auth/atur-ulang-sandi', {
    'email': email.trim(),
    'otp': otp.trim(),
    'sandi': sandi,
  });

  SesiBaru _sesi(Map<String, dynamic> b) {
    final d = b['data'] as Map<String, dynamic>;
    return SesiBaru(
      '${d['token']}',
      Akun.dariJson(d['user'] as Map<String, dynamic>),
    );
  }

  // ── Akun ─────────────────────────────────────────────────────────────

  Future<Akun> saya() async =>
      Akun.dariJson((await api.get('/saya'))['data'] as Map<String, dynamic>);

  Future<void> keluar() => api.post('/auth/keluar');

  Future<Akun> perbaruiProfil({
    required String nama,
    required String telepon,
    String? jabatan,
  }) async {
    final b = await api.patch('/saya', {
      'nama': nama.trim(),
      'telepon': telepon.trim(),
      'jabatan': jabatan?.trim(),
    });
    return Akun.dariJson(b['data'] as Map<String, dynamic>);
  }

  /// Hapus akun (REQ-AUTH-11). Server mengembalikan apa yang dihapus dan apa
  /// yang TETAP disimpan lab — kalimatnya ditampilkan apa adanya.
  Future<({List<String> dihapus, List<String> tetap})> hapusAkun(
    String sandi,
  ) async {
    final b = await api.delete('/saya', {'sandi': sandi, 'konfirmasi': true});
    final d = (b['data'] as Map?) ?? const {};
    List<String> daftar(Object? x) => [
      for (final v in (x as List? ?? const [])) '$v',
    ];
    return (dihapus: daftar(d['dihapus']), tetap: daftar(d['tetap_tersimpan']));
  }

  Future<void> gantiSandi(String lama, String baru) =>
      api.post('/saya/ganti-sandi', {'sandi_lama': lama, 'sandi': baru});

  Future<void> daftarPerangkat(String token, String platform, String? versi) =>
      api.post('/perangkat', {
        'token': token,
        'platform': platform,
        'versi_app': versi,
      });

  Future<void> cabutPerangkat(String token) =>
      api.delete('/perangkat', {'token': token});

  // ── Data perusahaan (slice F) ─────────────────────────────────────────

  Future<Beranda> beranda() async =>
      Beranda.dariJson(await api.get('/beranda'));

  Future<Halaman<Alat>> daftarAlat({
    String? cari,
    String? saring,
    int halaman = 1,
  }) async => Halaman.dariJson(
    await api.get(
      '/alat',
      query: {'q': cari, 'saring': saring, 'page': '$halaman'},
    ),
    Alat.dariJson,
  );

  Future<Alat> alat(int id) async => Alat.dariJson(
    (await api.get('/alat/$id'))['data'] as Map<String, dynamic>,
  );

  Future<Halaman<Sertifikat>> daftarSertifikat({
    String? cari,
    bool termasukDigantikan = false,
    int halaman = 1,
  }) async => Halaman.dariJson(
    await api.get(
      '/sertifikat',
      query: {
        'q': cari,
        'termasuk_digantikan': termasukDigantikan ? '1' : null,
        'page': '$halaman',
      },
    ),
    Sertifikat.dariJson,
  );

  Future<Sertifikat> sertifikat(int id) async => Sertifikat.dariJson(
    (await api.get('/sertifikat/$id'))['data'] as Map<String, dynamic>,
  );

  /// Unduh PDF ke folder dokumen aplikasi, lalu buka dengan penampil PDF HP.
  /// Berkas yang sama ditimpa kalau diunduh ulang — tidak menumpuk salinan.
  Future<String> unduhDanBukaPdf(Sertifikat s) async {
    final byte = await api.unduh('/sertifikat/${s.id}/unduh');
    final folder = await getApplicationDocumentsDirectory();
    final nama =
        'Sertifikat-${s.nomor.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-')}.pdf';
    final berkas = File('${folder.path}/$nama');
    await berkas.writeAsBytes(byte, flush: true);
    await OpenFilex.open(berkas.path, type: 'application/pdf');
    return berkas.path;
  }

  Future<Halaman<Paket>> daftarPaket({
    bool selesai = false,
    int halaman = 1,
  }) async => Halaman.dariJson(
    await api.get(
      '/paket',
      query: {'selesai': selesai ? '1' : null, 'page': '$halaman'},
    ),
    Paket.dariJson,
  );

  Future<Paket> paket(int id) async {
    final b = await api.get('/paket/$id');
    return Paket.dariJson(
      b['data'] as Map<String, dynamic>,
      b['garis_waktu'] as List?,
    );
  }

  Future<Halaman<Notifikasi>> daftarNotifikasi({int halaman = 1}) async =>
      Halaman.dariJson(
        await api.get('/notifikasi', query: {'page': '$halaman'}),
        Notifikasi.dariJson,
      );

  Future<int> jumlahNotifikasiBelumDibaca() async =>
      ((await api.get('/notifikasi/jumlah'))['data']['belum_dibaca'] as num)
          .toInt();

  Future<void> tandaiDibaca(String id) => api.post('/notifikasi/$id/dibaca');

  Future<void> tandaiSemuaDibaca() => api.post('/notifikasi/dibaca-semua');

  // ── Anggota ──────────────────────────────────────────────────────────

  Future<DaftarAnggota> anggota() async =>
      DaftarAnggota.dariJson(await api.get('/anggota'));

  Future<void> undangAnggota(String email, String peran) =>
      api.post('/anggota/undangan', {'email': email.trim(), 'peran': peran});

  Future<void> batalkanUndangan(int id) => api.delete('/anggota/undangan/$id');

  Future<void> nonaktifkanAnggota(int id) =>
      api.post('/anggota/$id/nonaktifkan');

  // ── Permintaan kalibrasi ──────────────────────────────────────────────

  /// [saring]: `aktif` | `selesai` | `semua`. Angka tab datang di
  /// `meta.jumlah` dan tidak bergantung pada saringan.
  Future<DaftarPermintaan> daftarPermintaan({String saring = 'aktif'}) async =>
      DaftarPermintaan.dariJson(
        await api.get('/permintaan', query: {'saring': saring}),
      );

  Future<Permintaan> permintaan(int id) async => Permintaan.dariJson(
    (await api.get('/permintaan/$id'))['data'] as Map<String, dynamic>,
  );

  /// Badannya `draft.toJson()` — tidak pernah memuat `customer_id`.
  Future<Permintaan> ajukanPermintaan(DraftPermintaan draft) async =>
      Permintaan.dariJson(
        (await api.post('/permintaan', draft.toJson()))['data']
            as Map<String, dynamic>,
      );

  Future<Permintaan> batalkanPermintaan(int id) async => Permintaan.dariJson(
    (await api.post('/permintaan/$id/batal'))['data'] as Map<String, dynamic>,
  );

  Future<UtasPesan> pesanPermintaan(int id) async =>
      UtasPesan.dariJson(await api.get('/permintaan/$id/pesan'));

  Future<PesanPermintaan> kirimPesan(int id, String isi) async =>
      PesanPermintaan.dariJson(
        (await api.post('/permintaan/$id/pesan', {'isi': isi.trim()}))['data']
            as Map<String, dynamic>,
      );

  // ── Preferensi notifikasi (per anggota per perusahaan, di server) ─────

  Future<PreferensiNotifikasi> preferensiNotifikasi() async =>
      PreferensiNotifikasi.dariJson(
        (await api.get('/preferensi-notifikasi'))['data']
            as Map<String, dynamic>,
      );

  /// Kirim SEBAGIAN (satu ketukan = satu kunci); jawabannya seluruh set.
  Future<PreferensiNotifikasi> simpanPreferensi(
    Map<String, bool> perubahan,
  ) async => PreferensiNotifikasi.dariJson(
    (await api.put('/preferensi-notifikasi', perubahan))['data']
        as Map<String, dynamic>,
  );
}
