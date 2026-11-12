import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Salinan sementara PDF sertifikat untuk pratinjau di dalam aplikasi.
///
/// - Folder CACHE aplikasi (`getApplicationCacheDirectory`): privat untuk
///   aplikasi, tidak ikut cadangan, bukan folder publik seperti Download atau
///   Dokumen, dan boleh dibuang OS kalau ruang penuh.
/// - Nama berkas memakai ID sertifikat, bukan nomor sertifikat atau nama alat,
///   jadi nama berkas tidak membocorkan isi dokumen.
/// - Dibuang saat keluar akun, saat sesi berakhir, dan saat berganti
///   perusahaan (`SesiController`): PDF milik satu perusahaan tidak boleh
///   tertinggal sesudah pengguna pindah perusahaan atau akun.
/// - Paling banyak [maks] berkas; yang tertua dibuang lebih dulu.
class PenyimpanPratinjau {
  PenyimpanPratinjau({
    Future<Directory> Function()? akar,
    Future<Directory> Function()? akarLama,
    this.maks = 12,
  }) : _akar = akar ?? getApplicationCacheDirectory,
       _akarLama = akarLama ?? getApplicationDocumentsDirectory;

  static const namaFolder = 'sidik_pratinjau';

  final Future<Directory> Function() _akar;

  /// Folder Dokumen aplikasi: tempat versi lama (≤ 0.2.2) menyimpan unduhan
  /// sebagai `Sertifikat-<nomor>.pdf` dan tidak pernah membersihkannya.
  final Future<Directory> Function() _akarLama;
  final int maks;
  static int _urut = 0;

  Future<Directory> _folder({bool buat = true}) async {
    final akar = await _akar();
    final d = Directory('${akar.path}/$namaFolder');
    if (buat && !await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// Simpan [byte] sebagai berkas sertifikat [idSertifikat]; berkas yang sama
  /// ditimpa. Ditulis ke berkas sementara lalu diganti nama, supaya proses
  /// yang mati di tengah jalan tidak meninggalkan PDF separuh. Berkas sementara
  /// yang gagal dipindah dibuang lagi.
  Future<File> simpan(int idSertifikat, Uint8List byte) async {
    final dir = await _folder();
    final tujuan = File('${dir.path}/sertifikat-$idSertifikat.pdf');
    // Nama sementara unik per panggilan: dua simpan untuk sertifikat yang sama
    // (ketuk ganda, dua layar) tidak saling menimpa atau saling memindahkan
    // berkas sementara; yang terakhir selesai yang menang, utuh.
    final sementara = File('${tujuan.path}.${_urut++}.tmp');
    try {
      await sementara.writeAsBytes(byte, flush: true);
      await sementara.rename(tujuan.path);
    } catch (_) {
      try {
        if (await sementara.exists()) await sementara.delete();
      } catch (_) {}
      rethrow;
    }
    await _rapikan(dir);
    return tujuan;
  }

  /// Buang semua salinan. Dicoba sebaik mungkin: gagal atau macet (batas 3
  /// detik) tidak boleh menahan pengguna keluar dari akunnya.
  ///
  /// Ikut dibuang: sisa unduhan versi lama di folder Dokumen aplikasi
  /// (`Sertifikat-*.pdf`); hanya berkas bernama itu, tidak ada yang lain.
  Future<void> bersihkan() async {
    for (final langkah in [_hapusFolder, _hapusSisaVersiLama]) {
      try {
        await langkah().timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Salinan PDF gagal dibersihkan: $e');
      }
    }
  }

  static final _namaVersiLama = RegExp(r'^Sertifikat-.*\.pdf$');

  Future<void> _hapusSisaVersiLama() async {
    final dir = await _akarLama();
    if (!await dir.exists()) return;
    await for (final e in dir.list()) {
      if (e is File && _namaVersiLama.hasMatch(e.uri.pathSegments.last)) {
        try {
          await e.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _hapusFolder() async {
    final dir = await _folder(buat: false);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> _rapikan(Directory dir) async {
    if (maks <= 0) return;
    final berkas = <(File, DateTime)>[];
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.pdf')) {
        berkas.add((e, (await e.stat()).modified));
      }
    }
    if (berkas.length <= maks) return;
    berkas.sort((a, b) => a.$2.compareTo(b.$2));
    for (final (f, _) in berkas.take(berkas.length - maks)) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }
}
