import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../core/konfigurasi.dart';
import '../models/rilis_aplikasi.dart';

/// Unduhan pembaruan gagal. [pesan] siap ditampilkan ke pelanggan.
class UnduhGagal implements Exception {
  const UnduhGagal(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}

/// APK yang terunduh tidak sama dengan yang diumumkan manifes. TIDAK pernah
/// diserahkan ke pemasang.
class ShaTidakCocok extends UnduhGagal {
  const ShaTidakCocok()
    : super(
        'Berkas pembaruan rusak atau tidak sesuai (sidik SHA-256 berbeda). '
        'Berkas dibuang; coba lagi.',
      );
}

/// Sumber rilis aplikasi: manifes `versi-pelanggan.json` dan APK-nya.
abstract class KlienRilis {
  /// Rilis terbaru yang diumumkan, atau `null` kalau belum ada / tidak
  /// terjangkau / manifesnya cacat. **Tidak pernah melempar.**
  Future<RilisAplikasi?> ambilTerbaru();

  /// APK [rilis] yang SUDAH utuh di HP (sidiknya cocok), atau `null`.
  Future<File?> apkSiap(RilisAplikasi rilis);

  /// Unduh APK [rilis] dan pastikan SHA-256-nya cocok. Melempar [UnduhGagal]
  /// (termasuk [ShaTidakCocok]); berkas yang gagal tidak ditinggalkan.
  Future<File> unduh(
    RilisAplikasi rilis, {
    void Function(double? progres)? onProgres,
  });
}

/// Klien GitHub Releases.
///
/// ## Kenapa bukan klien API aplikasi
///
/// Klien API aplikasi menempelkan kredensial sesi pelanggan dan perusahaan
/// aktif ke tiap panggilan; kredensial itu tidak boleh pernah sampai ke
/// github.com. Berkas ini memakai `http.Client` sendiri yang TIDAK tahu apa pun
/// soal sesi — dijaga `test/guard_tulis_test.dart` (tidak boleh mengimpor
/// klien API / penyimpan sesi, tidak boleh menyebut header otorisasi) — dan
/// hanya mengirim `GET`.
class KlienRilisGithub implements KlienRilis {
  KlienRilisGithub({
    http.Client? client,
    Uri? urlManifes,
    Future<Directory> Function()? direktori,
    this.batasSambung = const Duration(seconds: 30),
    this.batasDiam = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _urlManifes = urlManifes ?? Uri.parse(Konfigurasi.urlManifesRilis),
       _direktori = direktori ?? _direktoriBawaan;

  final http.Client _client;
  final Uri _urlManifes;
  final Future<Directory> Function() _direktori;

  /// Paling lama menunggu kepala respons.
  final Duration batasSambung;

  /// Paling lama menunggu potongan berikutnya di tengah unduhan. Bukan batas
  /// total: unduhan lambat yang sehat dibiarkan, yang DIAM diputus.
  final Duration batasDiam;

  static int _urut = 0;

  /// Folder sendiri di cache aplikasi: tanpa izin penyimpanan, dan
  /// dibersihkan sistem kalau HP kehabisan ruang.
  static Future<Directory> _direktoriBawaan() async {
    final d = Directory('${(await getTemporaryDirectory()).path}/pembaruan');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  /// Host yang boleh muncul di `url` manifes: GitHub, plus host manifes itu
  /// sendiri (supaya `URL_MANIFES_RILIS` ke server uji tetap bisa dipakai).
  Set<String> get hostDiizinkan => {'github.com', _urlManifes.host};

  /// Host TUJUAN AKHIR unduhan (sesudah redirect) yang diterima: GitHub,
  /// CDN aset GitHub (`*.githubusercontent.com`), atau host manifes itu
  /// sendiri. Redirect ke tempat lain ditolak sebelum satu byte pun ditulis.
  bool hostAkhirSah(String host) =>
      host == 'github.com' ||
      host.endsWith('.githubusercontent.com') ||
      host == _urlManifes.host;

  static String namaBerkas(RilisAplikasi r) => 'sidik-pelanggan-${r.build}.apk';

  @override
  Future<RilisAplikasi?> ambilTerbaru() async {
    try {
      final respons = await _client
          .get(_urlManifes, headers: const {'Accept': 'application/json'})
          .timeout(Konfigurasi.batasWaktu);
      if (respons.statusCode != 200) return null;
      var teks = utf8.decode(respons.bodyBytes, allowMalformed: true);
      // PowerShell lama menulis BOM di depan JSON; jsonDecode menolaknya.
      if (teks.isNotEmpty && teks.codeUnitAt(0) == 0xFEFF) {
        teks = teks.substring(1);
      }
      final j = jsonDecode(teks);
      if (j is! Map<String, dynamic>) return null;
      return RilisAplikasi.dariJson(j, hostDiizinkan: hostDiizinkan);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<File?> apkSiap(RilisAplikasi rilis) async {
    try {
      final f = File('${(await _direktori()).path}/${namaBerkas(rilis)}');
      if (!f.existsSync()) return null;
      if (await sha256Berkas(f) == rilis.sha256) return f;
      f.deleteSync();
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<File> unduh(
    RilisAplikasi rilis, {
    void Function(double? progres)? onProgres,
  }) async {
    final dir = await _direktori();
    _buangSisaLama(dir, rilis);
    final akhir = File('${dir.path}/${namaBerkas(rilis)}');
    final parsial = File(
      '${akhir.path}.${DateTime.now().microsecondsSinceEpoch}-${_urut++}.part',
    );

    final batal = Completer<void>();
    void hentikan() {
      if (!batal.isCompleted) batal.complete();
    }

    final http.StreamedResponse respons;
    try {
      respons = await _client
          .send(
            http.AbortableRequest('GET', rilis.url, abortTrigger: batal.future),
          )
          .timeout(batasSambung);
    } on TimeoutException {
      hentikan();
      throw const UnduhGagal('Server unduhan tidak menjawab. Coba lagi nanti.');
    } catch (_) {
      hentikan();
      throw const UnduhGagal(
        'Tidak bisa mengunduh pembaruan. Periksa koneksi internet, lalu coba lagi.',
      );
    }

    if (respons.statusCode != 200) {
      hentikan();
      throw UnduhGagal('Server unduhan menjawab ${respons.statusCode}.');
    }

    // URL akhir sesudah redirect. Klien bawaan (IOClient) selalu
    // melaporkannya; respons tanpa URL akhir tidak bisa diperiksa → ditolak.
    final akhirUrl = switch (respons) {
      http.BaseResponseWithUrl(:final url) => url,
      _ => null,
    };
    if (akhirUrl == null ||
        akhirUrl.scheme != 'https' ||
        !hostAkhirSah(akhirUrl.host)) {
      hentikan();
      throw const UnduhGagal(
        'Unduhan dialihkan ke alamat yang tidak dikenal. Pembaruan dibatalkan.',
      );
    }

    final total = respons.contentLength ?? rilis.ukuran;
    var terunduh = 0;
    final tulis = parsial.openWrite();
    try {
      await for (final potongan in respons.stream.timeout(batasDiam)) {
        tulis.add(potongan);
        terunduh += potongan.length;
        onProgres?.call(
          total == null || total <= 0
              ? null
              : (terunduh / total).clamp(0.0, 1.0),
        );
      }
      await tulis.close();
    } catch (e) {
      hentikan();
      try {
        await tulis.close();
      } catch (_) {}
      _hapus(parsial);
      throw UnduhGagal(
        e is TimeoutException
            ? 'Unduhan macet. Periksa koneksi internet, lalu coba lagi.'
            : 'Unduhan terputus. Periksa koneksi internet, lalu coba lagi.',
      );
    }

    // Server yang memutus di tengah menutup stream tanpa melempar.
    final ukuranHarus = rilis.ukuran ?? respons.contentLength;
    if (terunduh == 0 || (ukuranHarus != null && terunduh != ukuranHarus)) {
      _hapus(parsial);
      throw const UnduhGagal('Unduhan tidak utuh. Coba lagi.');
    }

    if (await sha256Berkas(parsial) != rilis.sha256) {
      _hapus(parsial);
      throw const ShaTidakCocok();
    }

    try {
      // Rename di folder yang sama itu atomik: nama akhir hanya pernah berisi
      // APK utuh yang sidiknya sudah dicocokkan.
      return await parsial.rename(akhir.path);
    } catch (_) {
      _hapus(parsial);
      throw const UnduhGagal('Berkas pembaruan gagal disimpan. Coba lagi.');
    }
  }

  /// Buang APK build lain dan `.part` yang ditinggal unduhan yang mati.
  void _buangSisaLama(Directory dir, RilisAplikasi rilis) {
    try {
      final batas = DateTime.now().subtract(batasDiam * 2);
      final milikRilis = namaBerkas(rilis);
      for (final e in dir.listSync()) {
        if (e is! File) continue;
        final nama = e.uri.pathSegments.last;
        if (!nama.startsWith('sidik-pelanggan-')) continue;
        final punyaRilisIni = nama.startsWith(milikRilis);
        if (!punyaRilisIni) {
          e.deleteSync();
        } else if (nama.endsWith('.part') &&
            e.lastModifiedSync().isBefore(batas)) {
          e.deleteSync();
        }
      }
    } catch (_) {
      // Gagal bersih-bersih tidak boleh menghalangi unduhan.
    }
  }

  static void _hapus(File f) {
    try {
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}

/// SHA-256 isi [berkas], hex huruf kecil.
Future<String> sha256Berkas(File berkas) async =>
    (await crypto.sha256.bind(berkas.openRead()).first).toString();

/// Dipakai di luar Android dan di bawah `flutter test`: tidak pernah ada rilis.
class KlienRilisMati implements KlienRilis {
  const KlienRilisMati();

  @override
  Future<RilisAplikasi?> ambilTerbaru() async => null;

  @override
  Future<File?> apkSiap(RilisAplikasi rilis) async => null;

  @override
  Future<File> unduh(
    RilisAplikasi rilis, {
    void Function(double? progres)? onProgres,
  }) => throw const UnduhGagal('Pembaruan tidak tersedia di perangkat ini.');
}
