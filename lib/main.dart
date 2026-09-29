import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'services/push_pelanggan.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nama bulan Indonesia ("12 Okt 2026") untuk DateFormat('…', 'id_ID').
  await initializeDateFormatting('id_ID');
  // Gagal diam-diam kalau Firebase belum dikonfigurasi — aplikasi tetap jalan.
  await PushPelanggan.nyalakan();
  runApp(const ProviderScope(child: SidikPelangganApp()));
}
