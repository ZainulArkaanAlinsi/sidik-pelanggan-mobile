import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../core/api_pelanggan.dart';
import '../models/akun.dart';
import '../models/data_pelanggan.dart';

/// Hasil masuk / terima undangan: token + akunnya.
class SesiBaru {
  const SesiBaru(this.token, this.akun);

  final String token;
  final Akun akun;
}

/// Semua panggilan ke `/api/pelanggan/v1`, dalam satu kelas yang tipis.
///
/// Tidak ada logika bisnis di sini — status jatuh tempo dan
/// kepemilikan dihitung SERVER. Aplikasi yang menghitung ulang sendiri pasti
/// suatu hari berbeda pendapat dengan layar lab.
class LayananPelanggan {
  LayananPelanggan(this.api);

  final ApiPelanggan api;

  // ── Tanpa token ──────────────────────────────────────────────────────

  Future<StatusAplikasi> statusAplikasi() async => StatusAplikasi.dariJson(
    (await api.get('/app/status'))['data'] as Map<String, dynamic>,
  );

  /// Kontak, dokumen, alamat lab (kontrak lengkap §6). Tanpa token.
  Future<InfoAplikasi> infoAplikasi() async {
    final d = (await api.get('/app/info'))['data'];
    return d is Map<String, dynamic>
        ? InfoAplikasi.dariJson(d)
        : InfoAplikasi.kosong;
  }

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

  /// Cabut SEMUA token akun ini, termasuk HP ini (F03). Jawaban: jumlah sesi
  /// yang dicabut.
  Future<int> keluarSemua() async {
    final b = await api.post('/auth/keluar-semua');
    final n = (b['data'] as Map?)?['sesi_dicabut'];
    return n is num ? n.toInt() : 0;
  }

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
}
