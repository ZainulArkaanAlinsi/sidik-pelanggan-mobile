import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'layanan_pelanggan.dart';

/// Push notification (pengingat jatuh tempo, sertifikat terbit).
///
/// **Aplikasi tetap jalan penuh tanpa push.** Kalau Firebase belum
/// dikonfigurasi (belum ada `google-services.json` / `GoogleService-Info.plist`
/// untuk aplikasi ini), [nyalakan] gagal diam-diam dan kotak masuk di dalam
/// aplikasi tetap jadi sumber kebenarannya — persis pola aplikasi lab.
///
/// Firebase project-nya SAMA dengan aplikasi lab (server cuma punya satu
/// `FCM_PROJECT_ID`); yang beda aplikasi Android/iOS-nya di dalam project itu.
/// Server memisahkan tujuan lewat kolom `device_tokens.aplikasi`, jadi kabar
/// kerja lab tidak pernah mendarat di aplikasi ini.
class PushPelanggan {
  static bool _hidup = false;
  static StreamSubscription<String>? _langganan;
  static String? _tokenTerakhir;

  static bool get didukung => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Kabar yang masuk selagi aplikasi terbuka di layar depan. Kosong kalau
  /// push mati — yang mendengarkan tidak perlu memeriksa apa pun.
  static Stream<void> get pesanDiLayarDepan => _hidup
      ? FirebaseMessaging.onMessage.map((_) {})
      : const Stream<void>.empty();

  /// Panggil sekali di `main()` sebelum `runApp`.
  static Future<void> nyalakan() async {
    if (!didukung) return;
    try {
      await Firebase.initializeApp();
      _hidup = true;
    } catch (e) {
      debugPrint('Push pelanggan nonaktif (Firebase belum dikonfigurasi): $e');
    }
  }

  /// Daftarkan HP ini ke akun yang baru masuk. Aman dipanggil berulang.
  static Future<void> daftarkan(
    LayananPelanggan layanan, {
    String? versiApp,
  }) async {
    if (!_hidup) return;
    try {
      final fcm = FirebaseMessaging.instance;
      final izin = await fcm.requestPermission();
      if (izin.authorizationStatus == AuthorizationStatus.denied) return;

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
}
