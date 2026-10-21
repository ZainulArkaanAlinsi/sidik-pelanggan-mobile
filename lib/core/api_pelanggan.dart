import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'id_unik.dart';
import 'konfigurasi.dart';
import 'penyimpan_cache.dart';

/// Galat dari server, dalam bentuk kontrak `/api/pelanggan/v1`:
/// `{"kode": "...", "message": "...", "errors": {...}}`.
///
/// [kode] yang dipakai untuk bercabang, bukan [pesan]: pesannya boleh
/// disunting server kapan saja, kodenya dibekukan di
/// `docs/kontrak-api-pelanggan.md`.
class GalatApi implements Exception {
  const GalatApi({
    required this.status,
    required this.pesan,
    this.kode,
    this.isian = const {},
    this.data,
  });

  final int status;
  final String pesan;
  final String? kode;

  /// Galat validasi per kolom (422). Kunci = nama kolom yang dikirim.
  final Map<String, String> isian;

  /// Muatan tambahan — mis. daftar `pilihan` perusahaan pada
  /// `perusahaan_belum_dipilih`.
  final Map<String, dynamic>? data;

  bool get tidakDitemukan => status == 404;
  bool get tokenTidakBerlaku => status == 401;
  bool get jaringan => status == 0;

  factory GalatApi.jaringan() => const GalatApi(
    status: 0,
    kode: 'jaringan',
    pesan:
        'Tidak bisa terhubung ke server. Periksa koneksi internet, lalu coba lagi.',
  );

  @override
  String toString() => pesan;
}

/// Klien HTTP satu-satunya untuk aplikasi pelanggan.
///
/// Header yang dipasang di SATU tempat ini:
/// - `Authorization: Bearer` — token pelanggan (ability `pelanggan`);
/// - `X-Perusahaan-Id` — perusahaan aktif, untuk akun yang jadi anggota lebih
///   dari satu perusahaan. Server tetap memeriksa keanggotaannya sendiri;
///   header ini cuma MEMILIH, tidak pernah memberi akses;
/// - `X-App-Versi` — versi aplikasi terpasang (gerbang versi minimum di server
///   dan bahan dukungan);
/// - `X-Request-Id` — UUID per panggilan (NFR-11), supaya keluhan "tadi pagi
///   gagal" bisa dicari di log server. Percobaan ulang memakai ID yang sama.
///
/// Jaringan (NFR-06):
/// - `GET` diulang otomatis 2× kalau koneksi gagal CEPAT (soket/klien).
/// - Server gratis (Render) tidur sesudah 15 menit sepi; bangunnya 30-90
///   detik. `GET` yang kena batas waktu 20 detik, atau 502/504 dari proxy
///   saat server bangun, diulang SEKALI dengan [batasBangun]. `POST` tidak
///   pernah diulang (bisa terkirim dua kali).
/// - Jawaban `GET` yang berhasil disimpan ke [cache]; kalau jaringan putus,
///   jawaban terakhir itu yang dikembalikan dan [saatOffline] dipanggil
///   dengan waktunya (banner "Anda sedang offline…"). Galat server (4xx/5xx)
///   TIDAK pernah dijawab dari cache: data yang ditolak server tidak boleh
///   tampil seolah masih boleh dilihat.
class ApiPelanggan {
  ApiPelanggan({
    http.Client? klien,
    this.token,
    this.perusahaanId,
    this.saatTokenDitolak,
    this.cache,
    this.lingkupCache,
    this.versiApp,
    this.saatOffline,
    this.saatOnline,
    this.jedaUlang = const [
      Duration(milliseconds: 500),
      Duration(milliseconds: 1500),
    ],
    this.batasWaktu = Konfigurasi.batasWaktu,
    this.batasBangun = Konfigurasi.batasBangun,
    this.jedaBangun = const Duration(seconds: 2),
  }) : _klien = klien ?? http.Client();

  final http.Client _klien;
  String? token;
  int? perusahaanId;

  /// Dipanggil sekali waktu server menjawab 401 — sesi dianggap berakhir.
  void Function()? saatTokenDitolak;

  /// Cache jawaban `GET`. `null` = tanpa cache.
  PenyimpanCache? cache;

  /// Pemilik cache — `u{id pengguna}`. Tanpa ini tidak ada yang disimpan
  /// maupun dibaca, jadi data akun A tidak pernah tersaji ke akun B.
  String? lingkupCache;

  /// Versi aplikasi terpasang (`1.2.0+7`), dikirim sebagai `X-App-Versi`.
  String? versiApp;

  /// Jaringan putus. Argumennya waktu data cache yang disajikan, atau `null`
  /// kalau tidak ada cache untuk permintaan itu.
  void Function(DateTime? dataTerakhir)? saatOffline;

  /// Satu permintaan berhasil sampai ke server (apa pun status HTTP-nya).
  void Function()? saatOnline;

  /// Jeda sebelum percobaan ulang GET ke-1, ke-2. Panjangnya = jumlah ulang.
  final List<Duration> jedaUlang;

  /// Batas waktu satu panggilan JSON (NFR-06: 20 detik).
  final Duration batasWaktu;

  /// Batas waktu percobaan ulang GET waktu server sedang bangun.
  final Duration batasBangun;

  /// Jeda sebelum mengulang GET yang dijawab 502/504.
  final Duration jedaBangun;

  Uri _uri(String jalur, [Map<String, String?>? query]) {
    final bersih = <String, String>{
      for (final e in (query ?? const <String, String?>{}).entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    return Uri.parse(
      '${Konfigurasi.apiBaseUrl}${Konfigurasi.prefix}$jalur',
    ).replace(queryParameters: bersih.isEmpty ? null : bersih);
  }

  Map<String, String> _header(String idPermintaan) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
    if (perusahaanId != null) 'X-Perusahaan-Id': '$perusahaanId',
    'X-App-Versi': ?versiApp,
    'X-Request-Id': idPermintaan,
  };

  /// Kunci cache: pemilik + perusahaan + jalur lengkap dengan query. `null`
  /// kalau belum ada pemilik (belum masuk) — tidak ada yang disimpan.
  String? _kunciCache(Uri uri) {
    final lingkup = lingkupCache;
    if (cache == null || lingkup == null) return null;
    final jalur = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    return '$lingkup|p${perusahaanId ?? '-'}|$jalur';
  }

  Future<Map<String, dynamic>> get(
    String jalur, {
    Map<String, String?>? query,
  }) async {
    final uri = _uri(jalur, query);
    final kunci = _kunciCache(uri);
    final id = IdUnik.uuid4();
    try {
      return await _kirim(
        () => _klien.get(uri, headers: _header(id)),
        ulang: true,
        simpanKe: kunci,
      );
    } on GalatApi catch (e) {
      // Tanpa kunci, `_kirim` sudah memanggil `saatOffline` sendiri.
      if (!e.jaringan || kunci == null) rethrow;
      final simpanan = await cache!.baca(kunci);
      saatOffline?.call(simpanan?.waktu);
      if (simpanan == null) rethrow;
      final isi = jsonDecode(simpanan.isi);
      return isi is Map<String, dynamic> ? isi : {'data': isi};
    }
  }

  Future<Map<String, dynamic>> post(String jalur, [Object? badan]) {
    final id = IdUnik.uuid4();
    return _kirim(
      () => _klien.post(
        _uri(jalur),
        headers: _header(id),
        body: jsonEncode(badan ?? {}),
      ),
    );
  }

  Future<Map<String, dynamic>> put(String jalur, Object badan) {
    final id = IdUnik.uuid4();
    return _kirim(
      () => _klien.put(
        _uri(jalur),
        headers: _header(id),
        body: jsonEncode(badan),
      ),
    );
  }

  Future<Map<String, dynamic>> patch(String jalur, Object badan) {
    final id = IdUnik.uuid4();
    return _kirim(
      () => _klien.patch(
        _uri(jalur),
        headers: _header(id),
        body: jsonEncode(badan),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(String jalur, [Object? badan]) {
    final id = IdUnik.uuid4();
    return _kirim(
      () => _klien.delete(
        _uri(jalur),
        headers: _header(id),
        body: badan == null ? null : jsonEncode(badan),
      ),
    );
  }

  /// Unduh berkas (PDF sertifikat) sebagai byte — lewat header Bearer yang
  /// sama. Tidak bisa diserahkan ke peramban: peramban tidak membawa token.

  Future<Uint8List> unduh(
    String jalur, {
    String terima = 'application/pdf',
  }) async {
    final http.Response r;
    try {
      r = await _klien
          .get(
            _uri(jalur),
            headers: {..._header(IdUnik.uuid4()), 'Accept': terima},
          )
          .timeout(const Duration(seconds: 60));
    } on SocketException {
      saatOffline?.call(null);
      throw GalatApi.jaringan();
    } on TimeoutException {
      throw GalatApi.jaringan();
    } on http.ClientException {
      saatOffline?.call(null);
      throw GalatApi.jaringan();
    }
    saatOnline?.call();
    if (r.statusCode >= 200 && r.statusCode < 300) return r.bodyBytes;
    throw _galatDari(r);
  }

  Future<Map<String, dynamic>> _kirim(
    Future<http.Response> Function() aksi, {
    Duration? batas,
    bool ulang = false,
    String? simpanKe,
  }) async {
    http.Response? r;
    var menungguBangun = false;
    for (var percobaan = 0; r == null; percobaan++) {
      try {
        r = await aksi().timeout(
          menungguBangun ? batasBangun : (batas ?? batasWaktu),
        );
        // 502/504 = proxy Render belum tersambung ke server yang sedang bangun.
        if (ulang &&
            !menungguBangun &&
            (r.statusCode == 502 || r.statusCode == 504)) {
          r = null;
          menungguBangun = true;
          await Future<void>.delayed(jedaBangun);
          continue;
        }
      } on TimeoutException {
        if (ulang && !menungguBangun) {
          menungguBangun = true;
          continue;
        }
        if (simpanKe == null) saatOffline?.call(null);
        throw GalatApi.jaringan();
      } on Exception catch (e) {
        if (e is! SocketException && e is! http.ClientException) rethrow;
        if (ulang && percobaan < jedaUlang.length) {
          await Future<void>.delayed(jedaUlang[percobaan]);
          continue;
        }
        // GET yang punya cache memanggil saatOffline sendiri, bersama waktu
        // datanya — jangan dua kali.
        if (simpanKe == null) saatOffline?.call(null);
        throw GalatApi.jaringan();
      }
    }
    saatOnline?.call();

    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return const {};
      final isi = jsonDecode(r.body);
      if (simpanKe != null) {
        // Tidak ditunggu: menulis cache tidak boleh memperlambat layar.
        unawaited(cache?.simpan(simpanKe, r.body));
      }
      return isi is Map<String, dynamic> ? isi : {'data': isi};
    }

    throw _galatDari(r);
  }

  GalatApi _galatDari(http.Response r) {
    if (r.statusCode == 401) saatTokenDitolak?.call();

    Map<String, dynamic> isi = const {};
    try {
      final d = jsonDecode(r.body);
      if (d is Map<String, dynamic>) isi = d;
    } catch (_) {
      // Badan bukan JSON (mis. halaman galat proxy) — pakai pesan umum.
    }

    final isian = <String, String>{};
    final errors = isi['errors'];
    if (errors is Map) {
      for (final e in errors.entries) {
        final v = e.value;
        isian['${e.key}'] = v is List && v.isNotEmpty ? '${v.first}' : '$v';
      }
    }

    return GalatApi(
      status: r.statusCode,
      kode: isi['kode'] as String?,
      // 404 selalu memakai kalimat yang sama (04-UI-UX §6): pesan bawaan
      // Laravel menyebut nama model ("No query results for model …"), dan
      // "tidak ditemukan" saja membuat pelanggan mengira datanya hilang
      // padahal bisa jadi milik perusahaan lain (BR-02).
      pesan: r.statusCode == 404
          ? pesan404
          : (isi['message'] as String?) ?? _pesanUmum(r.statusCode),
      isian: isian,
      data: isi['data'] is Map<String, dynamic>
          ? isi['data'] as Map<String, dynamic>
          : null,
    );
  }

  static const pesan404 =
      'Data ini tidak ditemukan atau Anda tidak punya akses.';

  static String _pesanUmum(int status) => switch (status) {
    401 => 'Sesi Anda berakhir. Silakan masuk lagi.',
    403 => 'Akun ini belum boleh membuka bagian ini.',
    404 => pesan404,
    429 => 'Terlalu banyak percobaan. Tunggu sebentar, lalu coba lagi.',
    503 => 'Layanan sedang dalam perbaikan. Coba lagi sebentar lagi.',
    502 || 504 =>
      'Server sedang dinyalakan dan belum siap. Tunggu sebentar, lalu coba lagi.',
    _ => 'Terjadi kendala di server. Coba lagi sebentar lagi. (kode $status)',
  };
}
