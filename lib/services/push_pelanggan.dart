import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'layanan_pelanggan.dart';

/// Tujuan sebuah push yang diketuk — bentuk `data` yang dikirim server
/// (`NotifikasiSistem::toPush`: `kategori`, `tautan_tipe`, `tautan_id`).
@immutable
class TautanPush {
  const TautanPush({this.tipe, this.id, this.kategori});

  final String? tipe;
  final int? id;
  final String? kategori;

  /// `null` kalau push tidak membawa tujuan sama sekali.
  static TautanPush? dariData(Map<String, dynamic> data) {
    String? teks(Object? v) {
      final s = v == null ? null : '$v'.trim();
      return s == null || s.isEmpty ? null : s;
    }

    final tipe = teks(data['tautan_tipe']);
    final kategori = teks(data['kategori']);
    if (tipe == null && kategori == null) return null;
    return TautanPush(
      tipe: tipe,
      id: int.tryParse(teks(data['tautan_id']) ?? ''),
      kategori: kategori,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TautanPush &&
      other.tipe == tipe &&
      other.id == id &&
      other.kategori == kategori;

  @override
  int get hashCode => Object.hash(tipe, id, kategori);
}

/// Izin menampilkan notifikasi di HP ini.
enum IzinNotifikasi {
  /// Diizinkan (termasuk "provisional" iOS).
  diizinkan,

  /// Ditolak pengguna — beranda menampilkan banner (REQ-NTF-08).
  ditolak,

  /// Belum pernah ditanya (Android 13+ sebelum momen kontekstual).
  belumDitanya,

  /// Push tidak hidup di build ini (Firebase belum dikonfigurasi) — tidak
  /// ada yang bisa dinyalakan, jadi tidak ada banner.
  tidakTersedia,
}

/// Push notification (pengingat jadwal, sertifikat terbit).
///
/// **Aplikasi tetap jalan penuh tanpa push.** Kalau Firebase belum
/// dikonfigurasi (belum ada `google-services.json`), [nyalakan] gagal
/// diam-diam dan kotak masuk di dalam aplikasi tetap jadi sumber kebenarannya.
///
/// Izin TIDAK diminta saat masuk (REQ-NTF-08): token didaftarkan begitu
/// masuk, izin diminta lewat [mintaIzin] saat alat pertama tampil di Beranda.
///
/// Firebase project-nya SAMA dengan aplikasi lab (server cuma punya satu
/// `FCM_PROJECT_ID`); yang beda aplikasi Android-nya. Server memisahkan tujuan
/// lewat `device_tokens.aplikasi`.
class PushPelanggan {
  static bool _hidup = false;
  static StreamSubscription<String>? _langganan;
  static StreamSubscription<RemoteMessage>? _ketukanLatar;
  static String? _tokenTerakhir;
  static final _ketukan = StreamController<TautanPush>.broadcast();
  static TautanPush? _ketukanAwal;

  static const _setelan = MethodChannel('sidik_pelanggan/setelan');

  static bool get didukung => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool get hidup => _hidup;

  /// Kabar yang masuk selagi aplikasi terbuka di layar depan. Kosong kalau
  /// push mati — yang mendengarkan tidak perlu memeriksa apa pun.
  static Stream<void> get pesanDiLayarDepan => _hidup
      ? FirebaseMessaging.onMessage.map((_) {})
      : const Stream<void>.empty();

  /// Push yang DIKETUK selagi aplikasi hidup di latar belakang.
  static Stream<TautanPush> get ketukan => _ketukan.stream;

  /// Push yang membuka aplikasi dari keadaan mati. Diambil SEKALI.
  static TautanPush? ambilKetukanAwal() {
    final t = _ketukanAwal;
    _ketukanAwal = null;
    return t;
  }

  /// Panggil sekali di `main()` sebelum `runApp`.
  static Future<void> nyalakan() async {
    if (!didukung) return;
    try {
      await Firebase.initializeApp();
      _hidup = true;
    } catch (e) {
      debugPrint('Push pelanggan nonaktif (Firebase belum dikonfigurasi): $e');
      return;
    }
    try {
      final awal = await FirebaseMessaging.instance.getInitialMessage();
      if (awal != null) _ketukanAwal = TautanPush.dariData(awal.data);
      _ketukanLatar = FirebaseMessaging.onMessageOpenedApp.listen((m) {
        final t = TautanPush.dariData(m.data);
        if (t != null) _ketukan.add(t);
      });
    } catch (e) {
      debugPrint('Ketukan push tidak bisa didengarkan: $e');
    }
  }

  /// Untuk test: suntik ketukan seolah dari Firebase.
  @visibleForTesting
  static void suntikKetukan(TautanPush t) => _ketukan.add(t);

  @visibleForTesting
  static void suntikKetukanAwal(TautanPush? t) => _ketukanAwal = t;

  /// Daftarkan token HP ini ke akun yang baru masuk. TIDAK meminta izin.
  /// Aman dipanggil berulang.
  static Future<void> daftarkan(
    LayananPelanggan layanan, {
    String? versiApp,
  }) async {
    if (!_hidup) return;
    try {
      final fcm = FirebaseMessaging.instance;
      final token = await fcm.getToken();
      if (token == null) return;
      _tokenTerakhir = token;
      await layanan.daftarPerangkat(
        token,
        Platform.isIOS ? 'ios' : 'android',
        versiApp,
      );

      await _langganan?.cancel();
      _langganan = fcm.onTokenRefresh.listen((baru) async {
        _tokenTerakhir = baru;
        try {
          await layanan.daftarPerangkat(
            baru,
            Platform.isIOS ? 'ios' : 'android',
            versiApp,
          );
        } catch (e) {
          debugPrint('Token push baru gagal didaftarkan: $e');
        }
      });
    } catch (e) {
      debugPrint('Pendaftaran push gagal: $e');
    }
  }

  static IzinNotifikasi _dari(AuthorizationStatus s) => switch (s) {
    AuthorizationStatus.authorized ||
    AuthorizationStatus.provisional => IzinNotifikasi.diizinkan,
    AuthorizationStatus.notDetermined => IzinNotifikasi.belumDitanya,
    // `denied`, `deniedPermanently`, dan nilai baru dari plugin versi
    // berikut: diperlakukan ditolak — banner menawarkan setelan HP.
    _ => IzinNotifikasi.ditolak,
  };

  static Future<IzinNotifikasi> statusIzin() async {
    if (!_hidup) return IzinNotifikasi.tidakTersedia;
    try {
      final s = await FirebaseMessaging.instance.getNotificationSettings();
      return _dari(s.authorizationStatus);
    } catch (_) {
      return IzinNotifikasi.tidakTersedia;
    }
  }

  /// Tampilkan dialog izin sistem (Android 13+/iOS). Sesudah ditolak dua
  /// kali, Android tidak lagi menampilkan dialog — pakai [bukaSetelan].
  static Future<IzinNotifikasi> mintaIzin() async {
    if (!_hidup) return IzinNotifikasi.tidakTersedia;
    try {
      final s = await FirebaseMessaging.instance.requestPermission();
      return _dari(s.authorizationStatus);
    } catch (_) {
      return IzinNotifikasi.tidakTersedia;
    }
  }

  /// Buka setelan notifikasi aplikasi ini di HP (Android). `false` kalau
  /// tidak bisa dibuka.
  static Future<bool> bukaSetelan() async {
    try {
      return await _setelan.invokeMethod<bool>('bukaSetelanNotifikasi') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Cabut HP ini SEBELUM token sesi dihapus — HP yang dipakai gantian tidak
  /// boleh terus menerima kabar akun yang sudah keluar.
  static Future<void> cabut(LayananPelanggan layanan) async {
    await _langganan?.cancel();
    _langganan = null;
    final token = _tokenTerakhir;
    if (!_hidup || token == null) return;
    try {
      await layanan.cabutPerangkat(token);
    } catch (e) {
      debugPrint('Pencabutan token push gagal: $e');
    }
  }

  /// Hanya untuk kelengkapan pembersihan di test.
  @visibleForTesting
  static Future<void> hentikan() async {
    await _ketukanLatar?.cancel();
    _ketukanLatar = null;
  }
}
