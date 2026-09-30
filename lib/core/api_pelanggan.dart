import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import 'konfigurasi.dart';

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
/// Dua header dipasang di SATU tempat ini:
/// - `Authorization: Bearer` — token pelanggan (ability `pelanggan`);
/// - `X-Perusahaan-Id` — perusahaan aktif, untuk akun yang jadi anggota lebih
///   dari satu perusahaan. Server tetap memeriksa keanggotaannya sendiri;
///   header ini cuma MEMILIH, tidak pernah memberi akses.
class ApiPelanggan {
  ApiPelanggan({
    http.Client? klien,
    this.token,
    this.perusahaanId,
    this.saatTokenDitolak,
  }) : _klien = klien ?? http.Client();

  final http.Client _klien;
  String? token;
  int? perusahaanId;

  /// Dipanggil sekali waktu server menjawab 401 — sesi dianggap berakhir.
  void Function()? saatTokenDitolak;

  Uri _uri(String jalur, [Map<String, String?>? query]) {
    final bersih = <String, String>{
      for (final e in (query ?? const <String, String?>{}).entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    return Uri.parse(
      '${Konfigurasi.apiBaseUrl}${Konfigurasi.prefix}$jalur',
    ).replace(queryParameters: bersih.isEmpty ? null : bersih);
  }

  Map<String, String> get _header => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
    if (perusahaanId != null) 'X-Perusahaan-Id': '$perusahaanId',
  };

  Future<Map<String, dynamic>> get(
    String jalur, {
    Map<String, String?>? query,
  }) => _kirim(() => _klien.get(_uri(jalur, query), headers: _header));

  Future<Map<String, dynamic>> post(String jalur, [Object? badan]) => _kirim(
    () => _klien.post(
      _uri(jalur),
      headers: _header,
      body: jsonEncode(badan ?? {}),
    ),
  );

  Future<Map<String, dynamic>> put(String jalur, Object badan) => _kirim(
    () => _klien.put(_uri(jalur), headers: _header, body: jsonEncode(badan)),
  );

  Future<Map<String, dynamic>> patch(String jalur, Object badan) => _kirim(
    () => _klien.patch(_uri(jalur), headers: _header, body: jsonEncode(badan)),
  );

  Future<Map<String, dynamic>> delete(String jalur, [Object? badan]) => _kirim(
    () => _klien.delete(
      _uri(jalur),
      headers: _header,
      body: badan == null ? null : jsonEncode(badan),
    ),
  );

  /// Unduh berkas (PDF sertifikat) sebagai byte — lewat header Bearer yang
  /// sama. Tidak bisa diserahkan ke peramban: peramban tidak membawa token.
  ///
  /// [terima] = tipe berkas yang diharapkan (`application/pdf` bawaan,
  /// `image/*` untuk foto pelat nama).
  Future<Uint8List> unduh(
    String jalur, {
    String terima = 'application/pdf',
  }) async {
    final http.Response r;
    try {
      r = await _klien
          .get(_uri(jalur), headers: {..._header, 'Accept': terima})
          .timeout(const Duration(seconds: 60));
    } on SocketException {
      throw GalatApi.jaringan();
    } on TimeoutException {
      throw GalatApi.jaringan();
    } on http.ClientException {
      throw GalatApi.jaringan();
    }
    if (r.statusCode >= 200 && r.statusCode < 300) return r.bodyBytes;
    throw _galatDari(r);
  }

  /// Unggah satu berkas sebagai multipart (bidang [bidang], mis. `foto`).
  /// `Content-Type` sengaja TIDAK dipasang: `MultipartRequest` menulis sendiri
  /// dengan batas (boundary) yang benar.
  Future<Map<String, dynamic>> unggah(
    String jalur,
    Uint8List byte, {
    String bidang = 'foto',
    String namaBerkas = 'foto.jpg',
    String tipe = 'image/jpeg',
  }) => _kirim(() async {
    final req = http.MultipartRequest('POST', _uri(jalur))
      ..headers.addAll({
        for (final e in _header.entries)
          if (e.key != 'Content-Type') e.key: e.value,
      })
      ..files.add(
        http.MultipartFile.fromBytes(
          bidang,
          byte,
          filename: namaBerkas,
          contentType: MediaType.parse(tipe),
        ),
      );
    return http.Response.fromStream(await _klien.send(req));
  }, batas: const Duration(seconds: 60));

  Future<Map<String, dynamic>> _kirim(
    Future<http.Response> Function() aksi, {
    Duration batas = Konfigurasi.batasWaktu,
  }) async {
    final http.Response r;
    try {
      r = await aksi().timeout(batas);
    } on SocketException {
      throw GalatApi.jaringan();
    } on TimeoutException {
      throw GalatApi.jaringan();
    } on http.ClientException {
      throw GalatApi.jaringan();
    }

    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return const {};
      final isi = jsonDecode(r.body);
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
      pesan: (isi['message'] as String?) ?? _pesanUmum(r.statusCode),
      isian: isian,
      data: isi['data'] is Map<String, dynamic>
          ? isi['data'] as Map<String, dynamic>
          : null,
    );
  }

  static String _pesanUmum(int status) => switch (status) {
    401 => 'Sesi Anda berakhir. Silakan masuk lagi.',
    403 => 'Akun ini belum boleh membuka bagian ini.',
    404 => 'Data tidak ditemukan.',
    429 => 'Terlalu banyak percobaan. Tunggu sebentar, lalu coba lagi.',
    503 => 'Layanan sedang dalam perbaikan. Coba lagi sebentar lagi.',
    _ => 'Terjadi kesalahan di server ($status). Coba lagi.',
  };
}
