import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/konfigurasi.dart';
import '../models/rilis_aplikasi.dart';
import '../services/klien_rilis.dart';
import '../services/pemasang_apk.dart';
import 'sesi_provider.dart';

/// Jam — disuntik di test supaya jeda pemeriksaan bisa diuji tanpa menunggu.
final jamProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Pembaruan APK berlaku di perangkat ini? `false` di bawah `flutter test`
/// (test yang menguji pembaruan menimpanya) dan di luar Android.
final pembaruanAktifProvider = Provider<bool>((ref) => pembaruanApkDidukung);

/// Klien GitHub Releases — BUKAN `ApiPelanggan`: token pelanggan tidak boleh
/// pernah dikirim ke github.com.
final klienRilisProvider = Provider<KlienRilis>(
  (ref) => ref.watch(pembaruanAktifProvider)
      ? KlienRilisGithub()
      : const KlienRilisMati(),
);

final pemasangApkProvider = Provider<PemasangApk>(
  (ref) => ref.watch(pembaruanAktifProvider)
      ? const PemasangApkAndroid()
      : const PemasangApkMati(),
);

enum TahapPembaruan { diam, mengunduh, siap, memasang }

@immutable
class KeadaanPembaruan {
  const KeadaanPembaruan({
    this.rilis,
    this.tahap = TahapPembaruan.diam,
    this.progres,
    this.apk,
    this.pesan,
    this.disembunyikan = false,
  });

  /// Rilis yang LEBIH BARU dari terpasang, atau `null`.
  final RilisAplikasi? rilis;
  final TahapPembaruan tahap;

  /// 0..1, atau `null` kalau ukuran total tidak diketahui.
  final double? progres;

  /// APK yang sudah diunduh dan sidiknya cocok.
  final File? apk;

  /// Galat/petunjuk terakhir untuk pelanggan.
  final String? pesan;

  /// Banner ditutup "Nanti" — hanya untuk rilis ini, selama aplikasi hidup.
  final bool disembunyikan;

  bool get tersedia => rilis != null;
  bool get wajib => rilis?.wajib ?? false;
  bool get sibuk =>
      tahap == TahapPembaruan.mengunduh || tahap == TahapPembaruan.memasang;

  KeadaanPembaruan salin({
    TahapPembaruan? tahap,
    double? progres,
    File? apk,
    String? pesan,
    bool hapusPesan = false,
    bool? disembunyikan,
  }) => KeadaanPembaruan(
    rilis: rilis,
    tahap: tahap ?? this.tahap,
    progres: progres,
    apk: apk ?? this.apk,
    pesan: hapusPesan ? null : (pesan ?? this.pesan),
    disembunyikan: disembunyikan ?? this.disembunyikan,
  );
}

final pembaruanProvider =
    NotifierProvider<PembaruanController, KeadaanPembaruan>(
      PembaruanController.new,
    );

/// Memeriksa manifes rilis, mengunduh (otomatis hanya di jaringan tak
/// berbayar; kapan saja kalau diketuk), memverifikasi SHA-256, lalu
/// menyerahkan ke pemasang Android. Pemasang TIDAK pernah dibuka tanpa
/// ketukan pelanggan — unduhan yang selesai di latar cuma mengubah banner
/// jadi "siap dipasang".
class PembaruanController extends Notifier<KeadaanPembaruan> {
  DateTime? _terakhirCek;
  Future<void>? _cekBerjalan;
  Future<bool>? _unduhBerjalan;

  @override
  KeadaanPembaruan build() => const KeadaanPembaruan();

  /// Periksa manifes. Tanpa [paksa], tidak lebih sering dari
  /// [Konfigurasi.selangCekPembaruan]. Tidak pernah melempar.
  Future<void> periksa({bool paksa = false}) {
    if (!ref.read(pembaruanAktifProvider)) return Future.value();
    final sekarang = ref.read(jamProvider)();
    final terakhir = _terakhirCek;
    if (!paksa &&
        terakhir != null &&
        sekarang.difference(terakhir) < Konfigurasi.selangCekPembaruan) {
      return Future.value();
    }
    return _cekBerjalan ??= _periksa(
      sekarang,
    ).whenComplete(() => _cekBerjalan = null);
  }

  Future<void> _periksa(DateTime sekarang) async {
    _terakhirCek = sekarang;
    final klien = ref.read(klienRilisProvider);
    final RilisAplikasi? rilis;
    final int terpasang;
    try {
      rilis = await klien.ambilTerbaru();
      terpasang =
          int.tryParse((await ref.read(infoPaketProvider.future)).build) ?? 0;
    } catch (_) {
      return;
    }
    if (!ref.mounted) return;

    if (rilis == null || !rilis.lebihBaruDari(terpasang)) {
      // Manifes tak terjangkau = "belum tahu"; rilis yang sudah diketahui
      // tetap ditawarkan. Rilis yang tidak lebih baru = tidak ada pembaruan.
      if (rilis != null && !state.sibuk) state = const KeadaanPembaruan();
      return;
    }

    if (state.rilis?.build != rilis.build) {
      if (state.sibuk) return; // unduhan rilis lama sedang jalan
      state = KeadaanPembaruan(rilis: rilis);
    }
    if (state.tahap != TahapPembaruan.diam) return;

    // APK dari sesi sebelumnya yang sudah utuh.
    final siap = await klien.apkSiap(rilis);
    if (!ref.mounted || state.rilis?.build != rilis.build) return;
    if (siap != null) {
      state = state.salin(tahap: TahapPembaruan.siap, apk: siap);
      return;
    }

    if (await ref.read(pemasangApkProvider).jaringanTakBerbayar()) {
      await _unduh(otomatis: true);
    }
  }

  /// Unduh rilis aktif. `true` kalau APK siap.
  Future<bool> _unduh({required bool otomatis}) =>
      _unduhBerjalan ??= _unduhSekali(
        otomatis: otomatis,
      ).whenComplete(() => _unduhBerjalan = null);

  Future<bool> _unduhSekali({required bool otomatis}) async {
    final rilis = state.rilis;
    if (rilis == null) return false;
    state = state.salin(tahap: TahapPembaruan.mengunduh, hapusPesan: true);
    try {
      final apk = await ref
          .read(klienRilisProvider)
          .unduh(
            rilis,
            onProgres: (p) {
              if (ref.mounted && state.tahap == TahapPembaruan.mengunduh) {
                state = state.salin(progres: p);
              }
            },
          );
      if (!ref.mounted) return false;
      state = state.salin(tahap: TahapPembaruan.siap, apk: apk);
      return true;
    } on UnduhGagal catch (e) {
      if (!ref.mounted) return false;
      // Unduhan latar yang gagal diam saja — pelanggan belum meminta apa pun.
      // Sidik yang tidak cocok tetap diberitahukan: itu bukan soal sinyal.
      state = state.salin(
        tahap: TahapPembaruan.diam,
        pesan: otomatis && e is! ShaTidakCocok ? null : e.pesan,
      );
      return false;
    } catch (_) {
      if (!ref.mounted) return false;
      state = state.salin(
        tahap: TahapPembaruan.diam,
        pesan: otomatis ? null : 'Unduhan gagal. Coba lagi.',
      );
      return false;
    }
  }

  /// Tombol "Perbarui"/"Pasang": unduh kalau belum, lalu buka pemasang.
  Future<void> perbarui() async {
    if (!ref.read(pembaruanAktifProvider)) return;
    if (state.tahap == TahapPembaruan.memasang) return;

    if (state.rilis == null) {
      await periksa(paksa: true);
      if (!ref.mounted) return;
      if (state.rilis == null) {
        state = state.salin(
          pesan:
              'Versi baru belum bisa diunduh. Periksa koneksi internet, '
              'atau hubungi PT Sidik.',
        );
        return;
      }
    }

    // Unduhan latar yang sedang jalan dilanjutkan, bukan dimulai dua kali.
    final berjalan = _unduhBerjalan;
    if (berjalan != null) {
      if (!await berjalan) {
        if (ref.mounted && state.pesan == null) {
          state = state.salin(pesan: 'Unduhan gagal. Coba lagi.');
        }
        return;
      }
    } else if (state.apk == null || state.tahap != TahapPembaruan.siap) {
      if (!await _unduh(otomatis: false)) return;
    }
    if (!ref.mounted) return;

    final apk = state.apk;
    if (apk == null) return;
    state = state.salin(tahap: TahapPembaruan.memasang, hapusPesan: true);
    final hasil = await ref.read(pemasangApkProvider).pasang(apk);
    if (!ref.mounted) return;
    // Kembali ke "siap": kalau pemasangnya dibatalkan, ketukan berikut
    // langsung membuka pemasang lagi tanpa mengunduh ulang.
    state = state.salin(
      tahap: TahapPembaruan.siap,
      pesan: pesanHasilPasang(hasil),
    );
  }

  /// "Nanti" — rilis wajib tidak bisa disembunyikan.
  void sembunyikan() {
    if (state.wajib) return;
    state = state.salin(disembunyikan: true, progres: state.progres);
  }
}

/// Pemicu pemeriksaan selama pelanggan berada di Rangka (sesudah gerbang
/// sesi): sekali saat masuk, tiap kembali ke layar depan, dan tiap jam selagi
/// terbuka. Jeda 1 jam dijaga [PembaruanController.periksa], jadi resume yang
/// sering tidak memukul GitHub berkali-kali. Tidak memblokir layar apa pun.
final penjadwalPembaruanProvider = Provider<void>((ref) {
  if (!ref.watch(pembaruanAktifProvider)) return;
  final pengendali = ref.read(pembaruanProvider.notifier);
  Future.microtask(pengendali.periksa);
  final daur = AppLifecycleListener(onResume: () => pengendali.periksa());
  final berkala = Timer.periodic(
    Konfigurasi.selangCekPembaruan,
    (_) => pengendali.periksa(),
  );
  ref.onDispose(() {
    daur.dispose();
    berkala.cancel();
  });
});
