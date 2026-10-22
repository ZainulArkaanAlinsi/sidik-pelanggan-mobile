import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

/// Hasil usaha membuka pemasang Android.
enum HasilPasang {
  /// Pemasang terbuka (atau, di Android 12+ sesudah pembaruan pertama lewat
  /// aplikasi ini, pemasangan langsung berjalan). Yang menyetujui tetap
  /// pelanggan — aplikasi tidak pernah tahu dia jadi memasang atau membatalkan.
  dimulai,

  /// "Instal aplikasi tidak dikenal" belum diizinkan untuk aplikasi ini.
  /// Layar setelannya sudah dibuka; pelanggan kembali lalu menekan lagi.
  perluIzin,

  /// Android menolak membuka pemasang.
  gagal,
}

/// Jembatan ke sisi native pembaruan (`MainActivity.kt` + `PemasangSesi.kt`,
/// kanal `sidik_pelanggan/pembaruan`).
abstract class PemasangApk {
  /// Serahkan APK yang SUDAH diverifikasi ke `PackageInstaller`.
  Future<HasilPasang> pasang(File apk);

  /// Jaringan aktif tidak berbayar per-MB (Wi-Fi/ethernet, bukan hotspot
  /// seluler yang ditandai metered). Unduhan OTOMATIS hanya di sini — kuota
  /// pelanggan bukan milik kita.
  Future<bool> jaringanTakBerbayar();
}

class PemasangApkAndroid implements PemasangApk {
  const PemasangApkAndroid();

  static const _kanal = MethodChannel('sidik_pelanggan/pembaruan');

  @override
  Future<HasilPasang> pasang(File apk) async {
    String? hasil;
    try {
      hasil = await _kanal.invokeMethod<String>('pasang', {'jalur': apk.path});
    } on MissingPluginException {
      hasil = null;
    } catch (_) {
      hasil = 'gagal';
    }

    if (hasil == 'dimulai') return HasilPasang.dimulai;
    if (hasil == 'izin') {
      try {
        await _kanal.invokeMethod<bool>('bukaIzinPasang');
      } catch (_) {}
      return HasilPasang.perluIzin;
    }

    // Sesi gagal / kanal tidak ada: jalur lama lewat intent VIEW, supaya
    // pembaruan tidak pernah lebih buruk dari membuka berkasnya sendiri.
    try {
      final r = await OpenFilex.open(
        apk.path,
        type: 'application/vnd.android.package-archive',
      );
      return r.type == ResultType.done
          ? HasilPasang.dimulai
          : HasilPasang.gagal;
    } catch (_) {
      return HasilPasang.gagal;
    }
  }

  @override
  Future<bool> jaringanTakBerbayar() async {
    try {
      // Dibatasi waktu: jawaban yang tidak pernah datang tidak boleh
      // menahan pemeriksaan pembaruan berikutnya selamanya.
      return await _kanal
              .invokeMethod<bool>('jaringanTakBerbayar')
              .timeout(const Duration(seconds: 5)) ??
          false;
    } catch (_) {
      return false;
    }
  }
}

/// Di luar Android dan di bawah `flutter test`: tidak pernah memasang.
class PemasangApkMati implements PemasangApk {
  const PemasangApkMati();

  @override
  Future<HasilPasang> pasang(File apk) async => HasilPasang.gagal;

  @override
  Future<bool> jaringanTakBerbayar() async => false;
}

/// Pembaruan lewat APK hanya berlaku di Android sungguhan.
bool get pembaruanApkDidukung =>
    !kIsWeb &&
    Platform.isAndroid &&
    !Platform.environment.containsKey('FLUTTER_TEST');

/// Pesan untuk [hasil], atau `null` kalau pemasangnya terbuka.
String? pesanHasilPasang(HasilPasang hasil) => switch (hasil) {
  HasilPasang.dimulai => null,
  HasilPasang.perluIzin =>
    'Izinkan "Instal aplikasi tidak dikenal" untuk SIDIK Pelanggan di '
        'layar Setelan yang terbuka, lalu kembali dan tekan Perbarui lagi.',
  HasilPasang.gagal =>
    'Pemasang Android tidak bisa dibuka. Coba lagi, atau unduh APK dari '
        'halaman rilis SIDIK Pelanggan.',
};
