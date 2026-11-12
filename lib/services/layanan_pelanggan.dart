import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../core/api_pelanggan.dart';
import '../models/akun.dart';
import '../models/anggota.dart';
import '../models/data_pelanggan.dart';
import '../models/paket.dart';

/// Hasil masuk / terima undangan: token + akunnya.
class SesiBaru {
  const SesiBaru(this.token, this.akun, {this.akunSudahAda = false});

  final String token;
  final Akun akun;

  /// Hanya diisi oleh terima-undangan: email undangan SUDAH punya akun, jadi
  /// yang dipakai akun lama itu (nama & sandi isian diabaikan server). Lihat
  /// [tampakAkunLama].
  final bool akunSudahAda;
}

/// Apakah [akun] yang dijawab `POST /auth/terima-undangan` tampak akun LAMA,
/// bukan akun yang baru dibuat dari isian [namaDiketik].
///
/// Server (kontrak §1) tidak mengirim penanda "akun sudah ada": untuk email
/// yang sudah terdaftar ia menambahkan perusahaan ke akun itu dan membalas 201
/// biasa, mengabaikan `nama` dan `sandi` isian. Satu-satunya petunjuk ada di
/// jawabannya sendiri:
/// - akun yang baru lahir punya TEPAT satu keanggotaan, jadi lebih dari satu =
///   akun lama;
/// - akun yang baru lahir memakai nama isian apa adanya (server hanya
///   merapikan spasi di ujung), jadi nama yang berbeda = akun lama.
/// Akun lama yang kebetulan bernama sama dan baru punya satu perusahaan tidak
/// terdeteksi (tidak ada pesan, sama seperti sebelumnya). Penanda eksplisit
/// dari server diminta di `docs/kebutuhan-api-pelanggan.md`.
bool tampakAkunLama(String namaDiketik, Akun akun) {
  String rapi(String s) =>
      s.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');
  return akun.keanggotaan.length > 1 || rapi(akun.nama) != rapi(namaDiketik);
}

/// Tahap yang gagal setelah PDF berhasil diunduh.
enum JenisGagalPdf { simpan, tidakAdaPembuka, buka }

/// Galat lokal sesudah unduhan selesai (bukan galat server/jaringan).
class GalatBerkasPdf implements Exception {
  const GalatBerkasPdf(this.jenis);

  final JenisGagalPdf jenis;

  String get pesan => switch (jenis) {
    JenisGagalPdf.simpan =>
      'PDF berhasil diunduh, tapi gagal disimpan di HP. Periksa ruang penyimpanan, lalu coba lagi.',
    JenisGagalPdf.tidakAdaPembuka =>
      'PDF terunduh, tapi tidak ada aplikasi pembuka PDF di HP ini.',
    JenisGagalPdf.buka =>
      'PDF terunduh, tapi gagal dibuka. Coba lagi, atau pasang aplikasi pembuka PDF lain.',
  };

  @override
  String toString() => pesan;
}

/// Semua panggilan ke `/api/pelanggan/v1`, dalam satu kelas yang tipis.
///
/// Tidak ada logika bisnis di sini — status jatuh tempo dan
/// kepemilikan dihitung SERVER. Aplikasi yang menghitung ulang sendiri pasti
/// suatu hari berbeda pendapat dengan layar lab.
class LayananPelanggan {
  /// [folderDokumen] dan [pembukaBerkas] hanya untuk tes; bawaannya folder
  /// dokumen aplikasi dan penampil PDF HP.
  LayananPelanggan(
    this.api, {
    Future<Directory> Function()? folderDokumen,
    Future<OpenResult> Function(String path)? pembukaBerkas,
  }) : _folderDokumen = folderDokumen ?? getApplicationDocumentsDirectory,
       _bukaBerkas =
           pembukaBerkas ??
           ((path) => OpenFilex.open(path, type: 'application/pdf'));

  final ApiPelanggan api;
  final Future<Directory> Function() _folderDokumen;
  final Future<OpenResult> Function(String path) _bukaBerkas;

  // ── Tanpa token ──────────────────────────────────────────────────────

  Future<StatusAplikasi> statusAplikasi() async => StatusAplikasi.dariJson(
    (await api.get('/app/status'))['data'] as Map<String, dynamic>,
  );

  /// Kontak, dokumen, alamat lab (kontrak lengkap §6). Tanpa token.
  ///
  /// 404 = server belum punya endpoint ini: dianggap "belum ada informasi"
  /// (layar menyembunyikan tombol kontak/dokumen), bukan galat.
  Future<InfoAplikasi> infoAplikasi() async {
    final Map<String, dynamic> badan;
    try {
      badan = await api.get('/app/info');
    } on GalatApi catch (e) {
      if (e.tidakDitemukan) return InfoAplikasi.kosong;
      rethrow;
    }
    final d = badan['data'];
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
    final sesi = _sesi(b);
    return SesiBaru(
      sesi.token,
      sesi.akun,
      akunSudahAda: tampakAkunLama(nama, sesi.akun),
    );
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

  /// Ganti sandi sendiri (`POST /saya/ganti-sandi`). Sesi di HP ini tetap
  /// hidup; sesi di perangkat LAIN dicabut server. Jawaban: jumlah sesi lain
  /// yang dicabut.
  ///
  /// Sandi tidak pernah disimpan atau dicatat di sini; hanya dikirim sekali.
  Future<int> gantiSandi({
    required String sandiLama,
    required String sandiBaru,
  }) async {
    final b = await api.post('/saya/ganti-sandi', {
      'sandi_lama': sandiLama,
      'sandi': sandiBaru,
    });
    final n = (b['data'] as Map?)?['sesi_dicabut'];
    return n is num ? n.toInt() : 0;
  }

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
  ///
  /// Galat dipisah menurut tahapnya: gagal unduh/jaringan = [GalatApi] (dari
  /// [ApiPelanggan.unduh]); gagal menulis berkas atau tak ada aplikasi
  /// pembuka = [GalatBerkasPdf].
  Future<String> unduhDanBukaPdf(Sertifikat s) async {
    final byte = await api.unduh('/sertifikat/${s.id}/unduh');
    final String path;
    try {
      final folder = await _folderDokumen();
      final nama =
          'Sertifikat-${s.nomor.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-')}.pdf';
      final berkas = File('${folder.path}/$nama');
      await berkas.writeAsBytes(byte, flush: true);
      path = berkas.path;
    } on Object {
      throw const GalatBerkasPdf(JenisGagalPdf.simpan);
    }

    final OpenResult hasil;
    try {
      hasil = await _bukaBerkas(path);
    } on Object {
      throw const GalatBerkasPdf(JenisGagalPdf.buka);
    }
    switch (hasil.type) {
      case ResultType.done:
        return path;
      case ResultType.noAppToOpen:
        throw const GalatBerkasPdf(JenisGagalPdf.tidakAdaPembuka);
      case ResultType.fileNotFound:
        throw const GalatBerkasPdf(JenisGagalPdf.simpan);
      case ResultType.permissionDenied:
      case ResultType.error:
        throw const GalatBerkasPdf(JenisGagalPdf.buka);
    }
  }

  // ── Anggota, preferensi, paket ────────────────────────────────────────

  /// Anggota perusahaan AKTIF (header `X-Perusahaan-Id`). Semua peran boleh
  /// melihat.
  Future<DaftarAnggota> anggota() async => DaftarAnggota.dariJson(
    (await api.get('/anggota'))['data'] as Map<String, dynamic>,
  );

  /// Nonaktifkan satu anggota (PIC utama saja — server yang menegakkan).
  /// [idAnggota] = `Anggota.id` (ID keanggotaan).
  Future<void> nonaktifkanAnggota(int idAnggota) =>
      api.post('/anggota/$idAnggota/nonaktifkan');

  /// Saklar notifikasi anggota ini di perusahaan aktif.
  Future<Map<String, bool>> preferensiNotifikasi() async =>
      _saklar(await api.get('/preferensi-notifikasi'));

  /// Simpan SEBAGIAN saklar (yang tidak dikirim tidak berubah). Jawaban:
  /// seluruh set terkini.
  Future<Map<String, bool>> simpanPreferensiNotifikasi(
    Map<String, bool> sebagian,
  ) async => _saklar(await api.put('/preferensi-notifikasi', sebagian));

  Map<String, bool> _saklar(Map<String, dynamic> badan) {
    final d = (badan['data'] as Map?) ?? const {};
    return {
      for (final e in d.entries)
        if (e.value is bool) '${e.key}': e.value as bool,
    };
  }

  /// Pelacakan paket (order). [selesai] = riwayat; bawaan server = yang masih
  /// berjalan. [cari] mencari NOMOR order.
  Future<Halaman<Paket>> daftarPaket({
    String? cari,
    bool selesai = false,
    int halaman = 1,
  }) async => Halaman.dariJson(
    await api.get(
      '/paket',
      query: {'q': cari, 'selesai': selesai ? '1' : null, 'page': '$halaman'},
    ),
    Paket.dariJson,
  );

  Future<DetailPaket> paket(int id) async =>
      DetailPaket.dariJson(await api.get('/paket/$id'));

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
