import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'dekode_json.dart';

/// Satu isian tersimpan + kapan disimpan.
@immutable
class EntriCache {
  const EntriCache(this.isi, this.waktu);

  final String isi;
  final DateTime waktu;
}

/// Penyimpan teks per kunci di HP ini.
///
/// **Cache baca** jawaban `GET` terakhir yang berhasil (NFR-06: daftar alat
/// & sertifikat terbaca offline) — di folder CACHE aplikasi: tidak ikut
/// cadangan, dan boleh dibuang OS kalau ruang penuh.
///
/// Sengaja berkas JSON polos lewat `path_provider` yang sudah jadi dependensi,
/// bukan `shared_preferences`/database baru: isinya cuma beberapa ratus KB.
/// Kunci SELALU memuat ID pengguna dan perusahaan (lihat pemanggilnya), jadi
/// HP yang dipakai gantian tidak pernah membaca data akun lain; tombol Keluar
/// menghapus semuanya ([hapusSemua]).
abstract class PenyimpanCache {
  Future<void> simpan(String kunci, String isi);

  Future<EntriCache?> baca(String kunci);

  Future<void> hapus(String kunci);

  Future<void> hapusSemua();
}

/// Untuk test dan untuk platform tanpa sistem berkas.
class PenyimpanCacheMemori implements PenyimpanCache {
  PenyimpanCacheMemori({DateTime Function()? jam}) : _jam = jam ?? DateTime.now;

  final DateTime Function() _jam;
  final Map<String, EntriCache> isi = {};

  @override
  Future<void> simpan(String kunci, String teks) async =>
      isi[kunci] = EntriCache(teks, _jam());

  @override
  Future<EntriCache?> baca(String kunci) async => isi[kunci];

  @override
  Future<void> hapus(String kunci) async => isi.remove(kunci);

  @override
  Future<void> hapusSemua() async => isi.clear();
}

class PenyimpanCacheBerkas implements PenyimpanCache {
  PenyimpanCacheBerkas._(this._akar, this._nama, {this.batasBerkas = 400});

  /// Cache jawaban server — folder cache (tidak dicadangkan, boleh dibuang OS).
  factory PenyimpanCacheBerkas.cache() =>
      PenyimpanCacheBerkas._(getApplicationCacheDirectory, 'sidik_cache');

  /// Untuk test: folder sementara.
  @visibleForTesting
  factory PenyimpanCacheBerkas.di(Directory folder, {int batasBerkas = 400}) =>
      PenyimpanCacheBerkas._(() async => folder, '', batasBerkas: batasBerkas);

  final Future<Directory> Function() _akar;
  final String _nama;

  /// Lebih dari ini, berkas tertua dibuang. 0 = tanpa batas.
  final int batasBerkas;

  Directory? _folder;
  int _tulisSejakRapikan = 0;

  Future<Directory> _dir() async {
    final ada = _folder;
    if (ada != null) return ada;
    final akar = await _akar();
    final d = _nama.isEmpty ? akar : Directory('${akar.path}/$_nama');
    if (!await d.exists()) await d.create(recursive: true);
    return _folder = d;
  }

  /// Nama berkas dari kunci: dua FNV-1a 32-bit (portabel, tanpa paket hash).
  /// Kuncinya juga disimpan di dalam berkas dan dicocokkan waktu dibaca, jadi
  /// tabrakan hash tidak pernah menyajikan data milik kunci lain.
  @visibleForTesting
  static String namaBerkas(String kunci) {
    int fnv(int awal) {
      var h = awal;
      for (final b in utf8.encode(kunci)) {
        h ^= b;
        h = (h * 0x01000193) & 0xFFFFFFFF;
      }
      return h;
    }

    String hex(int v) => v.toRadixString(16).padLeft(8, '0');
    return '${hex(fnv(0x811c9dc5))}${hex(fnv(0x050c5d1f))}.json';
  }

  @override
  Future<void> simpan(String kunci, String isi) async {
    try {
      final dir = await _dir();
      final tujuan = File('${dir.path}/${namaBerkas(kunci)}');
      final sementara = File('${tujuan.path}.tmp');
      await sementara.writeAsString(
        jsonEncode({
          'k': kunci,
          't': DateTime.now().toUtc().toIso8601String(),
          'b': isi,
        }),
        flush: true,
      );
      // Tulis-lalu-ganti-nama: aplikasi yang mati di tengah penulisan tidak
      // meninggalkan berkas separuh yang gagal diurai besok.
      await sementara.rename(tujuan.path);
      if (batasBerkas > 0 && ++_tulisSejakRapikan >= 50) {
        _tulisSejakRapikan = 0;
        await _rapikan(dir);
      }
    } catch (e) {
      // Cache yang gagal ditulis cuma berarti tidak ada cadangan offline.
      debugPrint('Cache gagal ditulis: $e');
    }
  }

  @override
  Future<EntriCache?> baca(String kunci) async {
    try {
      final dir = await _dir();
      final f = File('${dir.path}/${namaBerkas(kunci)}');
      if (!await f.exists()) return null;
      final j = await dekodeJson(await f.readAsString());
      if (j is! Map || j['k'] != kunci || j['b'] is! String) return null;
      final waktu = DateTime.tryParse('${j['t']}')?.toLocal();
      if (waktu == null) return null;
      return EntriCache(j['b'] as String, waktu);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> hapus(String kunci) async {
    try {
      final dir = await _dir();
      final f = File('${dir.path}/${namaBerkas(kunci)}');
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  @override
  Future<void> hapusSemua() async {
    try {
      final dir = await _dir();
      await for (final e in dir.list()) {
        if (e is File) await e.delete();
      }
    } catch (e) {
      debugPrint('Cache gagal dibersihkan: $e');
    }
  }

  Future<void> _rapikan(Directory dir) async {
    final berkas = <(File, DateTime)>[];
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.json')) {
        berkas.add((e, (await e.stat()).modified));
      }
    }
    if (berkas.length <= batasBerkas) return;
    berkas.sort((a, b) => a.$2.compareTo(b.$2));
    for (final (f, _) in berkas.take(berkas.length - batasBerkas)) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }
}
