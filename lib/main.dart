import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/pelapor_galat.dart';
import 'services/push_pelanggan.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Penangkap galat dipasang PALING AWAL (pelapor lokal dulu): galat di
  // inisialisasi di bawah ikut tertangkap, dan aplikasi jalan terus.
  pasangPenangkapGalat();
  // Nama bulan Indonesia ("12 Okt 2026") untuk DateFormat('…', 'id_ID').
  await initializeDateFormatting('id_ID');
  // Gagal diam-diam kalau Firebase belum dikonfigurasi — aplikasi tetap jalan.
  // `Firebase.initializeApp()` ada di sini; Crashlytics butuh sesudahnya.
  await PushPelanggan.nyalakan();
  final pelapor = await _pelaporCrashlytics(firebaseHidup: PushPelanggan.hidup);
  if (pelapor != null) pelaporGalat = pelapor;
  runApp(const ProviderScope(child: SidikPelangganApp()));
}

/// Crashlytics cuma di build RILIS dengan Firebase hidup. Manifest mematikan
/// pengumpulannya secara bawaan (`firebase_crashlytics_collection_enabled`);
/// di sini dinyalakan untuk rilis dan dimatikan eksplisit di debug/profile
/// supaya crash waktu ngoding tidak mencemari laporan HP pelanggan.
/// Gagal menyalakan = tetap jalan, tanpa laporan.
Future<PelaporGalat?> _pelaporCrashlytics({required bool firebaseHidup}) async {
  if (!firebaseHidup) return null;
  try {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      kReleaseMode,
    );
    return kReleaseMode ? PelaporGalatCrashlytics() : null;
  } catch (e) {
    debugPrint('Crashlytics nonaktif: $e');
    return null;
  }
}
